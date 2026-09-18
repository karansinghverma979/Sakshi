using System;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows;

namespace Sakshi.Death
{
    public partial class App : Application
    {
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool AttachConsole(int dwProcessId);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool FreeConsole();

        [DllImport("kernel32.dll")]
        private static extern IntPtr GetConsoleWindow();

        [DllImport("user32.dll")]
        private static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll")]
        private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

        private const int ATTACH_PARENT_PROCESS = -1;

        private static Mutex? _instanceMutex;

        protected override void OnStartup(StartupEventArgs e)
        {
            // 1. Check for help menu: -h, --help, /?, help
            for (int i = 0; i < e.Args.Length; i++)
            {
                if (e.Args[i].Equals("--help", StringComparison.OrdinalIgnoreCase) ||
                    e.Args[i].Equals("-h", StringComparison.OrdinalIgnoreCase) ||
                    e.Args[i].Equals("/?", StringComparison.OrdinalIgnoreCase) ||
                    e.Args[i].Equals("-?", StringComparison.OrdinalIgnoreCase) ||
                    e.Args[i].Equals("help", StringComparison.OrdinalIgnoreCase))
                {
                    bool attached = AttachConsole(ATTACH_PARENT_PROCESS);
                    try
                    {
                        if (attached)
                        {
                            var stdOut = new System.IO.StreamWriter(Console.OpenStandardOutput(), new System.Text.UTF8Encoding(false)) { AutoFlush = true };
                            Console.SetOut(stdOut);

                            // Erase premature prompt line drawn by the parent shell before the GUI process attached
                            try
                            {
                                int width = Console.WindowWidth > 1 ? Console.WindowWidth - 1 : 79;
                                Console.Write("\r" + new string(' ', width) + "\r");
                            }
                            catch { }
                        }
                        PrintHelp();
                    }
                    finally
                    {
                        if (attached)
                        {
                            FreeConsole();
                            // Refresh prompt only if console is currently in the foreground
                            try
                            {
                                IntPtr consoleHwnd = GetConsoleWindow();
                                if (consoleHwnd != IntPtr.Zero && GetForegroundWindow() == consoleHwnd)
                                {
                                    keybd_event(0x0D, 0, 0, UIntPtr.Zero);
                                    keybd_event(0x0D, 0, 0x0002, UIntPtr.Zero);
                                }
                            }
                            catch { }
                        }
                    }
                    Shutdown();
                    return;
                }
            }

            // Enforce single running instance
            bool isNewInstance = false;
            _instanceMutex = new Mutex(true, @"Global\Sakshi_Death_Instance_Mutex", out isNewInstance);

            if (!isNewInstance)
            {
                // Another Death window is already on screen, exit quietly
                Shutdown();
                return;
            }

            base.OnStartup(e);

            // Parse optional CLI arguments: death --quote "My Custom Quote" or death -q My Custom Quote
            string? customQuote = null;
            for (int i = 0; i < e.Args.Length; i++)
            {
                if (e.Args[i].Equals("--quote", StringComparison.OrdinalIgnoreCase) || 
                    e.Args[i].Equals("-q", StringComparison.OrdinalIgnoreCase))
                {
                    if (i + 1 < e.Args.Length)
                    {
                        var quoteWords = new System.Collections.Generic.List<string>();
                        for (int j = i + 1; j < e.Args.Length; j++)
                        {
                            if (e.Args[j].StartsWith("-")) break;
                            quoteWords.Add(e.Args[j]);
                        }
                        if (quoteWords.Count > 0)
                        {
                            customQuote = string.Join(" ", quoteWords).Trim('"', '\'', ' ');
                        }
                    }
                    break;
                }
            }


            // Parse optional countdown duration: --test, -t, --seconds <N>, -s <N>
            int countdownSeconds = 60;
            bool isTestMode = false;
            for (int i = 0; i < e.Args.Length; i++)
            {
                if ((e.Args[i].Equals("--seconds", StringComparison.OrdinalIgnoreCase) || 
                     e.Args[i].Equals("-s", StringComparison.OrdinalIgnoreCase)) && i + 1 < e.Args.Length)
                {
                    if (int.TryParse(e.Args[i + 1], out int sec) && sec > 0)
                    {
                        countdownSeconds = sec;
                    }
                }
                else if (e.Args[i].Equals("--test", StringComparison.OrdinalIgnoreCase) || 
                         e.Args[i].Equals("-t", StringComparison.OrdinalIgnoreCase))
                {
                    countdownSeconds = 3;
                    isTestMode = true;
                }
            }

            // Parse optional snapshot argument: --snapshot [path] or --screenshot [path]
            string? snapshotPath = null;
            for (int i = 0; i < e.Args.Length; i++)
            {
                if (e.Args[i].Equals("--snapshot", StringComparison.OrdinalIgnoreCase) || 
                    e.Args[i].Equals("--screenshot", StringComparison.OrdinalIgnoreCase))
                {
                    if (i + 1 < e.Args.Length && !e.Args[i + 1].StartsWith("-"))
                    {
                        snapshotPath = e.Args[i + 1];
                    }
                    else
                    {
                        snapshotPath = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "death_snapshot.png");
                    }
                    // Snapshots run with 0-second countdown to capture the final unlocked screen immediately
                    countdownSeconds = 0;
                    break;
                }
            }

            var mainWindow = new MainWindow(customQuote, countdownSeconds, snapshotPath, isTestMode);
            mainWindow.Show();
        }

        protected override void OnExit(ExitEventArgs e)
        {
            if (_instanceMutex != null)
            {
                _instanceMutex.ReleaseMutex();
                _instanceMutex.Dispose();
            }
            base.OnExit(e);
        }

        private static void PrintHelp()
        {
            try { Console.OutputEncoding = System.Text.Encoding.UTF8; } catch { }
            Console.WriteLine("Death 4.0.0 (Memento Mori)");
            Console.WriteLine("Autonomous hardware-accelerated disciplinary overwatch for Windows.");
            Console.WriteLine();
            Console.WriteLine("Usage: Death [OPTIONS]");
            Console.WriteLine();
            Console.WriteLine("Options:");
            Console.WriteLine("  -h, --help            Show this help manual and exit");
            Console.WriteLine("  -t, --test            Quick 3-second smoke test (auto-dismisses after unlock)");
            Console.WriteLine("  -s, --seconds <N>     Lockdown duration in seconds (default: 60)");
            Console.WriteLine("  -q, --quote <TEXT>    Override acknowledgment button quote on the fly");
            Console.WriteLine("      --snapshot [PATH] Save PNG snapshot of unlocked screen and exit");
            Console.WriteLine();
            Console.WriteLine("Controls:");
            Console.WriteLine("  Enter, Space          Acknowledge quote and dismiss lockdown (when unlocked)");
            Console.WriteLine("  Alt+F4, Esc, Win      Suppressed during countdown to enforce discipline");
            Console.WriteLine();
            Console.WriteLine("Examples:");
            Console.WriteLine("  Death                 Launch default 60-second lockdown");
            Console.WriteLine("  Death -t              Run quick 3-second test");
            Console.WriteLine("  Death -s 15           15-second focus sprint");
            Console.WriteLine("  Death -q \"STAY HARD\"  Custom quote override");
            Console.WriteLine();
        }
    }
}
