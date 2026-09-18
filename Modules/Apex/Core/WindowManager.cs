using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

namespace Apex.Core;

public static class WindowManager
{
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern IntPtr GetWindow(IntPtr hWnd, uint uCmd);

    [DllImport("user32.dll")]
    private static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll")]
    private static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

    [StructLayout(LayoutKind.Sequential)]
    private struct FLASHWINFO
    {
        public uint cbSize;
        public IntPtr hwnd;
        public uint dwFlags;
        public uint uCount;
        public uint dwTimeout;
    }

    [DllImport("user32.dll")]
    private static extern bool FlashWindowEx(ref FLASHWINFO pwfi);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    public const int SW_RESTORE = 9;
    public const uint WM_CLOSE = 0x0010;
    public const uint WM_NCLBUTTONDOWN = 0x00A1;
    public const int HTRIGHT = 11;
    public const int HTBOTTOM = 15;
    public const int HTBOTTOMRIGHT = 17;

    public static void TeleportToWindow(IntPtr hwnd)
    {
        ShowWindow(hwnd, SW_RESTORE);
        SetForegroundWindow(hwnd);
    }

    public static bool CloseWindow(IntPtr hwnd)
    {
        return PostMessage(hwnd, WM_CLOSE, IntPtr.Zero, IntPtr.Zero);
    }

    public static bool KillProcess(uint pid)
    {
        try
        {
            using var proc = Process.GetProcessById((int)pid);
            proc.Kill(entireProcessTree: true);
            return true;
        }
        catch
        {
            return false;
        }
    }

    private static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
    private static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);
    private const int GWL_EXSTYLE = -20;
    private const int WS_EX_TOOLWINDOW = 0x00000080;
    private const int WS_EX_TOPMOST = 0x00000008;
    private const uint GW_OWNER = 4;
    private const uint SWP_NOSIZE = 0x0001;
    private const uint SWP_NOMOVE = 0x0002;
    private const uint SWP_NOACTIVATE = 0x0010;
    private const uint SWP_NOOWNERZORDER = 0x0200;
    private const uint SWP_NOSENDCHANGING = 0x0400;
    private const uint FLASHW_ALL = 3;
    private const uint FLASHW_TIMERNOFG = 12;

    public static bool IsTopmost(IntPtr hwnd)
    {
        return (GetWindowLong(hwnd, GWL_EXSTYLE) & WS_EX_TOPMOST) != 0;
    }

    public static bool SetTopmost(IntPtr hwnd, bool topmost)
    {
        IntPtr target = topmost ? HWND_TOPMOST : HWND_NOTOPMOST;
        return SetWindowPos(hwnd, target, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOOWNERZORDER | SWP_NOSENDCHANGING);
    }

    public static void Flash(IntPtr hwnd)
    {
        try
        {
            var fi = new FLASHWINFO
            {
                cbSize = (uint)Marshal.SizeOf<FLASHWINFO>(),
                hwnd = hwnd,
                dwFlags = FLASHW_ALL | FLASHW_TIMERNOFG,
                uCount = 3,
                dwTimeout = 0
            };
            FlashWindowEx(ref fi);
        }
        catch { }
    }

    public static void SetRoundedCorners(IntPtr hwnd)
    {
        try
        {
            int val = 2; // DWMWCP_ROUND
            DwmSetWindowAttribute(hwnd, 33, ref val, sizeof(int));
        }
        catch { }
    }

    public static List<WindowItem> ScanWindows()
    {
        var list = new List<WindowItem>();
        var desktopMap = VirtualDesktopHelper.GetDesktops();

        EnumWindows((hwnd, lParam) =>
        {
            if (!IsWindowVisible(hwnd)) return true;
            int length = GetWindowTextLength(hwnd);
            if (length == 0) return true;

            int exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
            if ((exStyle & WS_EX_TOOLWINDOW) != 0) return true;
            if (GetWindow(hwnd, GW_OWNER) != IntPtr.Zero) return true;

            var sb = new StringBuilder(length + 1);
            GetWindowText(hwnd, sb, sb.Capacity);
            string title = sb.ToString().Trim();

            GetWindowThreadProcessId(hwnd, out uint pid);

            // Strictly exclude Apex itself from counting or showing
            if (pid == (uint)Environment.ProcessId)
            {
                return true;
            }

            string procName = "App";
            try
            {
                using var proc = Process.GetProcessById((int)pid);
                procName = proc.ProcessName;
            }
            catch { }

            if (procName.Equals("Apex", StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            // Filter out system containers and empty shells
            if (string.IsNullOrWhiteSpace(title) || 
                title == "Program Manager" || 
                title == "Windows Input Experience")
            {
                return true;
            }

            bool isTopmost = (exStyle & WS_EX_TOPMOST) != 0;
            Guid desktopId = VirtualDesktopHelper.GetWindowDesktopId(hwnd);
            string desktopName;
            int desktopOrder;
            bool isCurrentDesktop = false;

            if (desktopId != Guid.Empty && desktopMap.TryGetValue(desktopId, out var info))
            {
                desktopName = info.Name;
                desktopOrder = info.Order;
                isCurrentDesktop = info.IsCurrent;
            }
            else
            {
                desktopName = "Pinned to All Desktops";
                desktopOrder = 999;
            }

            // Inviolability Shield
            bool isLocked = title.Contains("MEMENTO MORI", StringComparison.OrdinalIgnoreCase) ||
                            title.Contains("Sakshi", StringComparison.OrdinalIgnoreCase);

            bool isBlacklisted = BlacklistManager.IsBlacklisted(procName);

            list.Add(new WindowItem
            {
                Hwnd = hwnd,
                Pid = pid,
                ProcessName = procName,
                Title = title,
                IsTopmost = isTopmost,
                DesktopId = desktopId,
                DesktopName = desktopName,
                DesktopOrder = desktopOrder,
                IsCurrentDesktop = isCurrentDesktop,
                IsLocked = isLocked,
                IsBlacklisted = isBlacklisted
            });

            return true;
        }, IntPtr.Zero);

        return list;
    }
}
