using System.Runtime.InteropServices;
using System.Threading;
using System.Windows;

namespace Apex;

public partial class App : Application
{
    private static Mutex? _instanceMutex;
    private const string MutexName = "Global\\Apex_SingleInstance_Mutex_Karan";
    public const string SummonMessageName = "APEX_SUMMON_WINDOW_MSG";

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern uint RegisterWindowMessage(string lpString);

    [DllImport("user32.dll")]
    public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    private static readonly IntPtr HWND_BROADCAST = new IntPtr(0xffff);

    protected override void OnStartup(StartupEventArgs e)
    {
        _instanceMutex = new Mutex(true, MutexName, out bool isNewInstance);

        if (!isNewInstance)
        {
            // Another instance of Apex is already open!
            // Broadcast summon message so it teleports to user's current desktop and focuses.
            uint msg = RegisterWindowMessage(SummonMessageName);
            PostMessage(HWND_BROADCAST, msg, IntPtr.Zero, IntPtr.Zero);

            // Terminate this redundant instance immediately
            Shutdown();
            return;
        }

        base.OnStartup(e);
    }

    protected override void OnExit(ExitEventArgs e)
    {
        if (_instanceMutex != null)
        {
            try
            {
                _instanceMutex.ReleaseMutex();
            }
            catch { }
            _instanceMutex.Dispose();
            _instanceMutex = null;
        }

        base.OnExit(e);
    }
}
