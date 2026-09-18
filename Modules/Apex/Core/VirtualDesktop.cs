using System.Runtime.InteropServices;
using Microsoft.Win32;

namespace Apex.Core;

[ComImport]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
[Guid("a5cd92ff-29be-454c-8d04-d82879fb3f1b")]
public interface IVirtualDesktopManager
{
    [PreserveSig]
    int IsWindowOnCurrentVirtualDesktop(IntPtr topLevelWindow, [MarshalAs(UnmanagedType.Bool)] out bool onCurrentDesktop);

    [PreserveSig]
    int GetWindowDesktopId(IntPtr topLevelWindow, out Guid desktopId);

    [PreserveSig]
    int MoveWindowToDesktop(IntPtr topLevelWindow, [In] ref Guid desktopId);
}

[ComImport]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
[Guid("6D5140C1-7436-11CE-8034-00AA006009FA")]
public interface IServiceProvider
{
    [return: MarshalAs(UnmanagedType.IUnknown)]
    object QueryService(ref Guid guidService, ref Guid riid);
}

public class DesktopInfo
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int Order { get; set; }
    public bool IsCurrent { get; set; }
}

public static class VirtualDesktopHelper
{
    // Windows 11 24H2 / 25H2+ (Build 26100+) CLSID
    private static readonly Guid CLSID_VDM_24H2 = new Guid("AA509086-5CA9-4C25-8F95-589D3C07B48A");
    
    // Windows 10 & Windows 11 <= 23H2 (Build <= 22631) CLSID
    private static readonly Guid CLSID_VDM_Legacy = new Guid("AA509085-5CA9-4C25-8F95-589D3C07B48A");
    
    // Immersive Shell service provider
    private static readonly Guid CLSID_ImmersiveShell = new Guid("C2F03A33-21F5-47FA-B4BB-156362A2F239");

    // Well-known pinned window GUIDs
    private static readonly Guid AppOnAllDesktops = new Guid("BB64D5B7-4DE3-4AB2-A87C-DB7601AEA7DC");
    private static readonly Guid WindowOnAllDesktops = new Guid("C2DDEA68-66F2-4CF9-8264-1BFD00FBBBAC");

    private static readonly IVirtualDesktopManager? _vdm;

    static VirtualDesktopHelper()
    {
        _vdm = CreateVirtualDesktopManager();
    }

    private static IVirtualDesktopManager? CreateVirtualDesktopManager()
    {
        // 1. Try Windows 11 24H2+ CLSID
        try
        {
            var type = Type.GetTypeFromCLSID(CLSID_VDM_24H2);
            if (type != null)
            {
                var obj = Activator.CreateInstance(type);
                if (obj is IVirtualDesktopManager vdm) return vdm;
            }
        }
        catch { }

        // 2. Try Windows 10 / Windows 11 <= 23H2 Legacy CLSID
        try
        {
            var type = Type.GetTypeFromCLSID(CLSID_VDM_Legacy);
            if (type != null)
            {
                var obj = Activator.CreateInstance(type);
                if (obj is IVirtualDesktopManager vdm) return vdm;
            }
        }
        catch { }

        // 3. Try ImmersiveShell QueryService fallback
        try
        {
            var shellType = Type.GetTypeFromCLSID(CLSID_ImmersiveShell);
            if (shellType != null)
            {
                var shell = (IServiceProvider)Activator.CreateInstance(shellType)!;
                Guid serviceGuid = CLSID_VDM_24H2;
                Guid riid = typeof(IVirtualDesktopManager).GUID;
                try
                {
                    var obj = shell.QueryService(ref serviceGuid, ref riid);
                    if (obj is IVirtualDesktopManager vdm) return vdm;
                }
                catch { }

                serviceGuid = CLSID_VDM_Legacy;
                try
                {
                    var obj = shell.QueryService(ref serviceGuid, ref riid);
                    if (obj is IVirtualDesktopManager vdm) return vdm;
                }
                catch { }
            }
        }
        catch { }

        return null;
    }

    public static Guid GetCurrentDesktopId()
    {
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops");
            if (key?.GetValue("CurrentVirtualDesktop") is byte[] bytes && bytes.Length == 16)
            {
                return new Guid(bytes);
            }
        }
        catch { }
        return Guid.Empty;
    }

    public static Guid GetWindowDesktopId(IntPtr hwnd)
    {
        if (_vdm == null) return Guid.Empty;

        try
        {
            int hr = _vdm.GetWindowDesktopId(hwnd, out Guid desktopId);
            if (hr == 0 && desktopId != Guid.Empty)
            {
                // Pinned to all desktops
                if (desktopId == AppOnAllDesktops || desktopId == WindowOnAllDesktops)
                {
                    return Guid.Empty;
                }
                return desktopId;
            }

            // Fallback: Check if window is visible on current virtual desktop
            int hrCur = _vdm.IsWindowOnCurrentVirtualDesktop(hwnd, out bool onCurrent);
            if (hrCur == 0 && onCurrent)
            {
                return GetCurrentDesktopId();
            }
        }
        catch
        {
            // Fallback gracefully
        }

        return Guid.Empty;
    }

    public static bool MoveWindowToDesktop(IntPtr hwnd, Guid desktopId)
    {
        if (_vdm == null || desktopId == Guid.Empty) return false;
        try
        {
            return _vdm.MoveWindowToDesktop(hwnd, ref desktopId) == 0;
        }
        catch
        {
            return false;
        }
    }

    public static Dictionary<Guid, DesktopInfo> GetDesktops()
    {
        var map = new Dictionary<Guid, DesktopInfo>();
        Guid currentId = GetCurrentDesktopId();

        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops");
            if (key?.GetValue("VirtualDesktopIDs") is byte[] bytes)
            {
                int count = bytes.Length / 16;
                for (int i = 0; i < count; i++)
                {
                    byte[] slice = new byte[16];
                    Array.Copy(bytes, i * 16, slice, 0, 16);
                    var guid = new Guid(slice);

                    string name = $"Desktop {i + 1}";
                    using var nameKey = Registry.CurrentUser.OpenSubKey($@"Software\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops\Desktops\{{{guid}}}");
                    if (nameKey?.GetValue("Name") is string customName && !string.IsNullOrWhiteSpace(customName))
                    {
                        name = customName;
                    }

                    map[guid] = new DesktopInfo
                    {
                        Id = guid,
                        Name = name,
                        Order = i,
                        IsCurrent = (guid == currentId)
                    };
                }
            }
        }
        catch
        {
            // Fallback gracefully
        }

        return map;
    }
}
