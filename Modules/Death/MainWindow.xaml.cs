using System;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Threading;
using Microsoft.Win32;

namespace Sakshi.Death
{
    public partial class MainWindow : Window
    {
        private IntPtr _windowHandle;
        private readonly uint _myPid;
        private int _secondsRemaining = 60;
        private string _customQuote = "KEEP CALM AND STUDY HARD.";
        private string? _tempAudioPath;
        private readonly string? _snapshotPath;

        private readonly bool _isTestMode;
        private readonly DispatcherTimer _countdownTimer;
        private readonly DispatcherTimer _focusTimer;
        private readonly MediaPlayer _mediaPlayer = new();

        public MainWindow(string? quoteOverride = null, int countdownSeconds = 60, string? snapshotPath = null, bool isTestMode = false)
        {
            InitializeComponent();
            _myPid = (uint)Process.GetCurrentProcess().Id;
            _secondsRemaining = countdownSeconds;
            _snapshotPath = snapshotPath;
            _isTestMode = isTestMode;
            CountdownDisplay.Text = _secondsRemaining.ToString();

            if (!string.IsNullOrWhiteSpace(quoteOverride))
            {
                _customQuote = quoteOverride.Trim();
            }

            AcceptButton.Content = $" {_customQuote} ";

            // 1-second countdown timer
            _countdownTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(1) };
            _countdownTimer.Tick += CountdownTimer_Tick;

            // 200ms non-glitching focus enforcer
            _focusTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(200) };
            _focusTimer.Tick += FocusTimer_Tick;
        }

        private async void Window_Loaded(object sender, RoutedEventArgs e)
        {
            _windowHandle = new WindowInteropHelper(this).Handle;

            // 1. Full System Takeover: Pause active media & mute other audio sessions
            await AudioEngine.PauseActiveMediaAsync();
            AudioEngine.MuteOtherSessions(true, _myPid);

            // 2. Start Embedded Ambient Audio
            InitializeAmbientAudio();

            // 3. Start Timers and Header Storyboard
            _countdownTimer.Start();
            _focusTimer.Start();

            if (Resources["HeaderPulseAnimation"] is Storyboard headerPulse)
            {
                headerPulse.Begin(this);
            }

            // 4. Initial Topmost Activation
            AudioEngine.EnforceTopmost(_windowHandle);

            // 5. If countdown is <= 0 (e.g. Snapshot mode), reveal button immediately
            if (_secondsRemaining <= 0)
            {
                _countdownTimer.Stop();
                CountdownDisplay.Visibility = Visibility.Collapsed;
                AcceptButton.Visibility = Visibility.Visible;

                if (!string.IsNullOrEmpty(_snapshotPath))
                {
                    _ = Dispatcher.BeginInvoke(DispatcherPriority.ApplicationIdle, new Action(() =>
                    {
                        SaveSnapshot(_snapshotPath);
                        UnlockAndExit();
                    }));
                }
            }
        }

        private void SaveSnapshot(string filePath)
        {
            try
            {
                UpdateLayout();
                int width = (int)Math.Max(ActualWidth, 1920);
                int height = (int)Math.Max(ActualHeight, 1080);
                var rtb = new System.Windows.Media.Imaging.RenderTargetBitmap(width, height, 96, 96, System.Windows.Media.PixelFormats.Pbgra32);
                rtb.Render(this);
                var encoder = new System.Windows.Media.Imaging.PngBitmapEncoder();
                encoder.Frames.Add(System.Windows.Media.Imaging.BitmapFrame.Create(rtb));

                string dir = Path.GetDirectoryName(filePath) ?? "";
                if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
                {
                    Directory.CreateDirectory(dir);
                }

                using var fs = new FileStream(filePath, FileMode.Create, FileAccess.Write);
                encoder.Save(fs);
            }
            catch { }
        }

        private void InitializeAmbientAudio()
        {
            try
            {
                var assembly = Assembly.GetExecutingAssembly();
                var resourceName = "Sakshi.Death.The Whistle of Death.mp3";

                using var stream = assembly.GetManifestResourceStream(resourceName);
                if (stream != null)
                {
                    _tempAudioPath = Path.Combine(Path.GetTempPath(), "sakshi_death_ambient.mp3");
                    using (var fs = new FileStream(_tempAudioPath, FileMode.Create, FileAccess.Write, FileShare.Read))
                    {
                        stream.CopyTo(fs);
                    }

                    _mediaPlayer.Open(new Uri(_tempAudioPath));
                    _mediaPlayer.Volume = 0.40; // Ambient whistle volume
                    _mediaPlayer.MediaEnded += (s, e) =>
                    {
                        _mediaPlayer.Position = TimeSpan.Zero;
                        _mediaPlayer.Play();
                    };
                    _mediaPlayer.Play();
                }
            }
            catch { }
        }

        private void CountdownTimer_Tick(object? sender, EventArgs e)
        {
            _secondsRemaining--;

            // Keep other audio muted in case newly launched background apps try to make noise
            AudioEngine.MuteOtherSessions(true, _myPid);

            if (_secondsRemaining > 0)
            {
                CountdownDisplay.Text = _secondsRemaining.ToString();

                // Final 10 seconds: shift to blood red
                if (_secondsRemaining <= 10)
                {
                    CountdownDisplay.Foreground = Brushes.Red;
                }

                // Subtle mechanical tick-tock (volume 0.15, calibrated below whistle)
                AudioEngine.PlayTick(_secondsRemaining % 2 == 0);
            }
            else
            {
                // Countdown Finished
                _countdownTimer.Stop();

                // 1. Play 1 single release chime (1200Hz, 1 time only)
                AudioEngine.PlaySingleEndChime();

                // 2. Reveal Acknowledgment Button
                // Ambient whistle continues playing until the user acknowledges the quote and exits!
                CountdownDisplay.Visibility = Visibility.Collapsed;
                AcceptButton.Visibility = Visibility.Visible;
                AcceptButton.Focus();

                if (Resources["ButtonPulseAnimation"] is Storyboard btnPulse)
                {
                    btnPulse.Begin(this);
                }

                // 3. In test mode, allow viewing the unlocked screen and whistle, then auto-dismiss
                if (_isTestMode)
                {
                    var autoExitTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(2.5) };
                    autoExitTimer.Tick += (s, ev) =>
                    {
                        autoExitTimer.Stop();
                        UnlockAndExit();
                    };
                    autoExitTimer.Start();
                }
            }
        }

        private void Window_StateChanged(object? sender, EventArgs e)
        {
            if (WindowState != WindowState.Maximized)
            {
                WindowState = WindowState.Maximized;
                if (_windowHandle != IntPtr.Zero)
                {
                    AudioEngine.EnforceTopmost(_windowHandle);
                }
            }
        }

        private void FocusTimer_Tick(object? sender, EventArgs e)
        {
            if (_windowHandle == IntPtr.Zero)
            {
                return;
            }

            try
            {
                // Anti-minimize guard: immediately restore if Win+D or shell attempted minimization
                if (WindowState != WindowState.Maximized)
                {
                    WindowState = WindowState.Maximized;
                }

                // 1. Virtual Desktop Snap
                if (!AudioEngine.IsOnCurrentDesktop(_windowHandle))
                {
                    using var key = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops");
                    if (key?.GetValue("CurrentVirtualDesktop") is byte[] bytes && bytes.Length == 16)
                    {
                        var desktopGuid = new Guid(bytes);
                        AudioEngine.MoveToDesktop(_windowHandle, desktopGuid);
                    }
                }

                // 2. Topmost enforcement with foreground lock bypass (keeps screen visible over all apps)
                AudioEngine.EnforceTopmost(_windowHandle);
            }
            catch { }
        }

        private void Window_KeyDown(object sender, KeyEventArgs e)
        {
            // If countdown is active, swallow Alt+F4, Esc, and Windows keys
            if (_secondsRemaining > 0)
            {
                if (e.Key == Key.System || e.Key == Key.Escape || e.Key == Key.F4)
                {
                    e.Handled = true;
                }
                return;
            }

            // Once unlocked: Enter or Space triggers the acknowledgment button
            if (e.Key == Key.Enter || e.Key == Key.Space)
            {
                UnlockAndExit();
            }
        }

        private void Window_Deactivated(object? sender, EventArgs e)
        {
            if (_windowHandle != IntPtr.Zero)
            {
                AudioEngine.EnforceTopmost(_windowHandle);
            }
        }

        private void Window_Closing(object? sender, CancelEventArgs e)
        {
            if (_secondsRemaining > 0)
            {
                // Inescapable lockdown
                e.Cancel = true;
            }
            else
            {
                CleanUpAudioAndState();
            }
        }

        private void AcceptButton_Click(object sender, RoutedEventArgs e)
        {
            UnlockAndExit();
        }

        private void UnlockAndExit()
        {
            CleanUpAudioAndState();
            Close();
        }

        private void CleanUpAudioAndState()
        {
            _countdownTimer.Stop();
            _focusTimer.Stop();

            try
            {
                _mediaPlayer.Stop();
                _mediaPlayer.Close();
            }
            catch { }

            // Restore all muted audio sessions
            try
            {
                AudioEngine.MuteOtherSessions(false, 0);
            }
            catch { }

            // Clean up temporary audio file
            if (!string.IsNullOrEmpty(_tempAudioPath) && File.Exists(_tempAudioPath))
            {
                try { File.Delete(_tempAudioPath); } catch { }
            }
        }
    }
}
