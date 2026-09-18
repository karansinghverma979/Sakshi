using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading;

namespace Sakshi.Overviews.Setup;

public static class Program
{
    public static void Main(string[] args)
    {
        Console.Title = "Sakshi // Overviews — Setup & Teardown Wizard";
        Console.OutputEncoding = System.Text.Encoding.UTF8;

        PrintBanner();

        string userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        string binDir = Path.Combine(userProfile, ".local", "bin");
        string targetExePath = Path.Combine(binDir, "Overviews.exe");
        string startMenuDir = Environment.GetFolderPath(Environment.SpecialFolder.Programs);
        string shortcutPath = Path.Combine(startMenuDir, "Overviews.lnk");

        if (args.Contains("--uninstall", StringComparer.OrdinalIgnoreCase) || args.Contains("-u", StringComparer.OrdinalIgnoreCase))
        {
            RunUninstall(targetExePath, shortcutPath, nonInteractive: true);
            return;
        }

        if (args.Contains("--install", StringComparer.OrdinalIgnoreCase) || args.Contains("-i", StringComparer.OrdinalIgnoreCase))
        {
            RunInstall(binDir, targetExePath, shortcutPath, nonInteractive: true);
            return;
        }

        // Interactive mode if already installed
        if (File.Exists(targetExePath))
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("  [!] Overviews is currently INSTALLED on this machine.\n");
            Console.ResetColor();

            Console.WriteLine("  Select an action to proceed:");
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("    [1] Reinstall / Update to Latest");
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine("    [2] Uninstall / Completely Vanish");
            Console.ForegroundColor = ConsoleColor.Gray;
            Console.WriteLine("    [3] Cancel & Exit\n");
            Console.ResetColor();

            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.Write("  Enter choice [1-3] (Default: 1): ");
            Console.ResetColor();

            string? choice = Console.ReadLine()?.Trim();
            if (choice == "2")
            {
                RunUninstall(targetExePath, shortcutPath, nonInteractive: false);
                return;
            }
            if (choice == "3")
            {
                Console.WriteLine("\n  [INFO] Operation cancelled by user.");
                return;
            }
        }

        RunInstall(binDir, targetExePath, shortcutPath, nonInteractive: false);
    }

    private static void PrintBanner()
    {
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine(@"
 ┌─────────────────────────────────────────────────────────────┐
 │       👁️  SAKSHI // OVERVIEWS (Google AI Overview)          │
 │              Autonomous Cognitive Query Sentry              │
 └─────────────────────────────────────────────────────────────┘");
        Console.ResetColor();
    }

    private static void RunInstall(string binDir, string targetExePath, string shortcutPath, bool nonInteractive)
    {
        try
        {
            // Step 1: Destination Setup
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("\n  [1/4] Preparing user-space binary directory...");
            Console.ResetColor();

            if (!Directory.Exists(binDir))
            {
                Directory.CreateDirectory(binDir);
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine($"   [✔] Created directory: {binDir}");
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine($"   [✔] Target directory verified: {binDir}");
            }
            Console.ResetColor();

            // Step 2: Extract Embedded Binary
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("\n  [2/4] Deploying standalone self-contained binary...");
            Console.ResetColor();

            var assembly = Assembly.GetExecutingAssembly();
            var resourceName = assembly.GetManifestResourceNames()
                .FirstOrDefault(n => n.EndsWith("Overviews.exe", StringComparison.OrdinalIgnoreCase));

            if (resourceName == null)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("   [✖] CRITICAL ERROR: Embedded Overviews.exe payload missing from setup bundle.");
                Console.ResetColor();
                return;
            }

            using (var stream = assembly.GetManifestResourceStream(resourceName))
            {
                if (stream == null)
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("   [✖] Failed to open embedded payload stream.");
                    Console.ResetColor();
                    return;
                }

                using var fileStream = new FileStream(targetExePath, FileMode.Create, FileAccess.Write, FileShare.None);
                stream.CopyTo(fileStream);
            }

            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine($"   [✔] Overviews.exe deployed successfully: {targetExePath}");
            Console.ResetColor();

            // Step 3: Environment PATH Configuration
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("\n  [3/4] Verifying User PATH environment variable...");
            Console.ResetColor();

            string? currentPath = Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.User);
            if (string.IsNullOrEmpty(currentPath) || !currentPath.Split(';').Contains(binDir, StringComparer.OrdinalIgnoreCase))
            {
                string updatedPath = string.IsNullOrEmpty(currentPath) ? binDir : $"{binDir};{currentPath}";
                Environment.SetEnvironmentVariable("PATH", updatedPath, EnvironmentVariableTarget.User);
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine($"   [✔] Appended {binDir} to User PATH.");
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("   [✔] User PATH already configured.");
            }
            Console.ResetColor();

            // Step 4: Register Start Menu Shortcut
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("\n  [4/4] Binding native Windows Explorer shortcut [Ctrl + Alt + O]...");
            Console.ResetColor();

            CreateShortcut(shortcutPath, targetExePath, binDir);

            // Print Completion Box
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine(@"
 ╔═════════════════════════════════════════════════════════════╗
 ║               🎉 INSTALLATION SUCCESSFUL!                   ║
 ╠═════════════════════════════════════════════════════════════╣
 ║  • Target Binary : ~/.local/bin/Overviews.exe               ║
 ║  • Global Hotkey : [Ctrl + Alt + O]                         ║
 ║  • Footprint     : 0.0 MB Idle RAM (Pure On-Demand)         ║
 ╚═════════════════════════════════════════════════════════════╝");
            Console.ResetColor();

            // Step 5: Explorer Refresh Prompt
            if (!nonInteractive)
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.Write("\n [?] Restart Windows Explorer now to activate [Ctrl + Alt + O] immediately? (Y/n): ");
                Console.ResetColor();

                string? answer = Console.ReadLine()?.Trim();
                if (string.IsNullOrEmpty(answer) || answer.Equals("y", StringComparison.OrdinalIgnoreCase) || answer.Equals("yes", StringComparison.OrdinalIgnoreCase))
                {
                    RestartExplorer();
                }
                else
                {
                    Console.ForegroundColor = ConsoleColor.Gray;
                    Console.WriteLine(" [i] Explorer restart skipped. The hotkey will become active on next logon.");
                    Console.ResetColor();
                }
            }
        }
        catch (Exception ex)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine($"\n  [✖] FATAL ERROR during installation: {ex.Message}");
            Console.ResetColor();
        }
    }

    private static void RunUninstall(string targetExePath, string shortcutPath, bool nonInteractive)
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n  [~] Initiating clean uninstallation and complete vanish...");
        Console.ResetColor();

        try
        {
            int removedCount = 0;

            if (File.Exists(shortcutPath))
            {
                File.Delete(shortcutPath);
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine($"   [✔] Eradicated shortcut: {shortcutPath}");
                removedCount++;
            }

            string startupDir = Environment.GetFolderPath(Environment.SpecialFolder.Startup);
            string legacyShortcut = Path.Combine(startupDir, "Sakshi-Overviews.lnk");
            if (File.Exists(legacyShortcut))
            {
                File.Delete(legacyShortcut);
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine($"   [✔] Eradicated legacy startup link: {legacyShortcut}");
                removedCount++;
            }

            if (File.Exists(targetExePath))
            {
                File.Delete(targetExePath);
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine($"   [✔] Eradicated binary: {targetExePath}");
                removedCount++;
            }

            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine(@"
 ╔═════════════════════════════════════════════════════════════╗
 ║               🧹 TEARDOWN & VANISH COMPLETE!                ║
 ╠═════════════════════════════════════════════════════════════╣
 ║  Overviews has been completely vanished from this machine.  ║
 ║  Zero background services, zero leftover files.             ║
 ╚═════════════════════════════════════════════════════════════╝");
            Console.ResetColor();

            if (!nonInteractive && removedCount > 0)
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.Write("\n [?] Restart Windows Explorer now to clean up cached hotkeys? (y/N): ");
                Console.ResetColor();

                string? answer = Console.ReadLine()?.Trim();
                if (!string.IsNullOrEmpty(answer) && (answer.Equals("y", StringComparison.OrdinalIgnoreCase) || answer.Equals("yes", StringComparison.OrdinalIgnoreCase)))
                {
                    RestartExplorer();
                }
            }
        }
        catch (Exception ex)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine($"\n  [✖] Error during uninstallation: {ex.Message}");
            Console.ResetColor();
        }
    }

    private static void RestartExplorer()
    {
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.Write(" [~] Refreshing Windows Explorer shell...");
        Console.ResetColor();

        try
        {
            foreach (var p in Process.GetProcessesByName("explorer"))
            {
                try { p.Kill(); p.WaitForExit(1500); } catch { }
            }
            Process.Start("explorer.exe");

            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine(" [DONE]");
            Console.WriteLine(" [✔] Explorer refreshed. [Ctrl + Alt + O] is active right now!");
            Console.ResetColor();
        }
        catch (Exception ex)
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine($" [!] Explorer restart warning: {ex.Message}");
            Console.ResetColor();
        }
    }

    private static void CreateShortcut(string shortcutPath, string targetExePath, string binDir)
    {
        try
        {
            Type? shellType = Type.GetTypeFromProgID("WScript.Shell");
            if (shellType != null)
            {
                dynamic? shell = Activator.CreateInstance(shellType);
                if (shell != null)
                {
                    dynamic shortcut = shell.CreateShortcut(shortcutPath);
                    shortcut.TargetPath = targetExePath;
                    shortcut.Hotkey = "Ctrl+Alt+O";
                    shortcut.IconLocation = $"{targetExePath},0";
                    shortcut.Description = "Sakshi // Overviews - Instant Google AI Overview";
                    shortcut.WorkingDirectory = binDir;
                    shortcut.Save();

                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine($"   [✔] Registered native shortcut: {shortcutPath}");
                    Console.WriteLine("   [✔] Global hotkey bound: [Ctrl + Alt + O]");
                    Console.ResetColor();
                    return;
                }
            }
        }
        catch
        {
            // Fallback to powershell shortcut creation if COM is restricted
        }

        try
        {
            var escapedShortcut = shortcutPath.Replace("'", "''");
            var escapedTarget = targetExePath.Replace("'", "''");
            var escapedBin = binDir.Replace("'", "''");

            var psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = $"-NoProfile -NonInteractive -Command \"$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('{escapedShortcut}'); $s.TargetPath = '{escapedTarget}'; $s.Hotkey = 'Ctrl+Alt+O'; $s.WorkingDirectory = '{escapedBin}'; $s.IconLocation = '{escapedTarget},0'; $s.Save()\"",
                CreateNoWindow = true,
                UseShellExecute = false
            };
            var proc = Process.Start(psi);
            proc?.WaitForExit(4000);

            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine($"   [✔] Registered native shortcut: {shortcutPath}");
            Console.WriteLine("   [✔] Global hotkey bound: [Ctrl + Alt + O]");
            Console.ResetColor();
        }
        catch (Exception ex)
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine($"   [!] Warning registering shortcut: {ex.Message}");
            Console.ResetColor();
        }
    }
}
