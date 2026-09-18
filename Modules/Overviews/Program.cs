using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;

namespace Sakshi.Overviews;

public static class Program
{
    private const int SW_MAXIMIZE = 3;

    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern bool IsWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    public static void Main(string[] args)
    {
        string edgePath = GetEdgePath();

        string targetUrl = args.Length > 0
            ? $"https://www.google.com/search?q={Uri.EscapeDataString(string.Join(" ", args))}"
            : "https://www.google.com";

        // Snapshot existing visible Edge window handles before launching
        var edgePids = new HashSet<uint>(Process.GetProcessesByName("msedge").Select(p => (uint)p.Id));
        var existingWindows = new HashSet<IntPtr>();

        EnumWindows((hWnd, lParam) =>
        {
            if (IsWindow(hWnd) && IsWindowVisible(hWnd))
            {
                GetWindowThreadProcessId(hWnd, out uint pid);
                if (edgePids.Contains(pid))
                {
                    existingWindows.Add(hWnd);
                }
            }
            return true;
        }, IntPtr.Zero);

        // Launch Edge in standalone WebApp mode
        Process.Start(new ProcessStartInfo
        {
            FileName = edgePath,
            Arguments = $"--app=\"{targetUrl}\"",
            UseShellExecute = true
        });

        // Poll for the new window and enforce MAXIMIZE full screen + foreground focus
        for (int i = 0; i < 60; i++)
        {
            Thread.Sleep(30);
            IntPtr newHwnd = IntPtr.Zero;

            EnumWindows((hWnd, lParam) =>
            {
                if (IsWindow(hWnd) && IsWindowVisible(hWnd))
                {
                    GetWindowThreadProcessId(hWnd, out uint pid);
                    if (edgePids.Contains(pid) && !existingWindows.Contains(hWnd))
                    {
                        newHwnd = hWnd;
                        return false;
                    }
                }
                return true;
            }, IntPtr.Zero);

            if (newHwnd != IntPtr.Zero)
            {
                // Enforce full-screen maximized state
                ShowWindow(newHwnd, SW_MAXIMIZE);
                SetForegroundWindow(newHwnd);
                break;
            }
        }
    }

    private static string GetEdgePath()
    {
        string[] candidates = {
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), @"Microsoft\Edge\Application\msedge.exe"),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), @"Microsoft\Edge\Application\msedge.exe"),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), @"Microsoft\Edge\Application\msedge.exe")
        };

        foreach (var path in candidates)
        {
            if (File.Exists(path)) return path;
        }

        return "msedge.exe";
    }
}
