using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using Windows.Media.Control;

namespace Sakshi.Death
{
    #region --- COM INTERFACES ---
    [ComImport]
    [Guid("5CDF2C82-841E-4546-9722-0CF74078229A")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IAudioEndpointVolume
    {
        [PreserveSig] int f();
        [PreserveSig] int g();
        [PreserveSig] int h();
        [PreserveSig] int i();
        [PreserveSig] int SetMasterVolumeLevelScalar(float fLevel, Guid pguidEventContext);
        [PreserveSig] int j();
        [PreserveSig] int GetMasterVolumeLevelScalar(out float pfLevel);
        [PreserveSig] int k();
        [PreserveSig] int l();
        [PreserveSig] int m();
        [PreserveSig] int n();
        [PreserveSig] int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, Guid pguidEventContext);
        [PreserveSig] int GetMute(out bool pbMute);
    }

    [ComImport]
    [Guid("87CE5498-68D6-44E5-9215-6DA47EF883D8")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface ISimpleAudioVolume
    {
        [PreserveSig] int SetMasterVolume(float fLevel, Guid pguidEventContext);
        [PreserveSig] int GetMasterVolume(out float pfLevel);
        [PreserveSig] int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, Guid pguidEventContext);
        [PreserveSig] int GetMute(out bool pbMute);
    }

    [ComImport]
    [Guid("F4B1A599-7266-4319-A8CA-E70ACB11E8CD")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IAudioSessionControl
    {
        [PreserveSig] int GetState(out int pRetVal);
        [PreserveSig] int GetDisplayName(out IntPtr pRetVal);
        [PreserveSig] int SetDisplayName([MarshalAs(UnmanagedType.LPWStr)] string Value, Guid EventContext);
        [PreserveSig] int GetIconPath(out IntPtr pRetVal);
        [PreserveSig] int SetIconPath([MarshalAs(UnmanagedType.LPWStr)] string Value, Guid EventContext);
        [PreserveSig] int GetGroupingParam(out Guid pRetVal);
        [PreserveSig] int SetGroupingParam(Guid Override, Guid EventContext);
        [PreserveSig] int RegisterAudioSessionEvents(IntPtr NewNotifications);
        [PreserveSig] int UnregisterAudioSessionEvents(IntPtr NewNotifications);
    }

    [ComImport]
    [Guid("bfb7ff88-7239-4fc9-8fa2-07c950be9c6d")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IAudioSessionControl2
    {
        [PreserveSig] int GetState(out int pRetVal);
        [PreserveSig] int GetDisplayName(out IntPtr pRetVal);
        [PreserveSig] int SetDisplayName([MarshalAs(UnmanagedType.LPWStr)] string Value, Guid EventContext);
        [PreserveSig] int GetIconPath(out IntPtr pRetVal);
        [PreserveSig] int SetIconPath([MarshalAs(UnmanagedType.LPWStr)] string Value, Guid EventContext);
        [PreserveSig] int GetGroupingParam(out Guid pRetVal);
        [PreserveSig] int SetGroupingParam(Guid Override, Guid EventContext);
        [PreserveSig] int RegisterAudioSessionEvents(IntPtr NewNotifications);
        [PreserveSig] int UnregisterAudioSessionEvents(IntPtr NewNotifications);
        [PreserveSig] int GetSessionIdentifier(out IntPtr pRetVal);
        [PreserveSig] int GetSessionInstanceIdentifier(out IntPtr pRetVal);
        [PreserveSig] int GetProcessId(out uint pRetVal);
        [PreserveSig] int IsSystemSoundsSession();
    }

    [ComImport]
    [Guid("E2F5BB11-0570-40CA-ACDD-3AA01277DEE8")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IAudioSessionEnumerator
    {
        [PreserveSig] int GetCount(out int SessionCount);
        [PreserveSig] int GetSession(int SessionIndex, out IAudioSessionControl Session);
    }

    [ComImport]
    [Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IAudioSessionManager2
    {
        [PreserveSig] int GetAudioSessionControl(Guid AudioSessionGuid, uint StreamFlags, out IntPtr SessionControl);
        [PreserveSig] int GetSimpleAudioVolume(Guid AudioSessionGuid, uint StreamFlags, out IntPtr AudioVolume);
        [PreserveSig] int GetSessionEnumerator(out IAudioSessionEnumerator SessionList);
        [PreserveSig] int RegisterSessionNotification(IntPtr SessionNotification);
        [PreserveSig] int UnregisterSessionNotification(IntPtr SessionNotification);
        [PreserveSig] int RegisterDuckNotification([MarshalAs(UnmanagedType.LPWStr)] string sessionID, IntPtr duckNotification);
        [PreserveSig] int UnregisterDuckNotification(IntPtr duckNotification);
    }

    [ComImport]
    [Guid("a5cd92ff-29be-454c-8d04-d82879fb3f1b")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IVirtualDesktopManager
    {
        [PreserveSig] int IsWindowOnCurrentVirtualDesktop(IntPtr topLevelWindow, [MarshalAs(UnmanagedType.Bool)] out bool onCurrentDesktop);
        [PreserveSig] int GetWindowDesktopId(IntPtr topLevelWindow, out Guid desktopId);
        [PreserveSig] int MoveWindowToDesktop(IntPtr topLevelWindow, ref Guid desktopId);
    }

    [ComImport]
    [Guid("D666063F-1587-4E43-81F1-B948E807363F")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDevice
    {
        [PreserveSig] int Activate(ref Guid id, int clsCtx, int activationParams, [MarshalAs(UnmanagedType.IUnknown)] out object obj);
    }

    [ComImport]
    [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDeviceEnumerator
    {
        [PreserveSig] int f();
        [PreserveSig] int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
    }

    [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
    internal class MMDeviceEnumeratorComObject { }
    #endregion

    public static class AudioEngine
    {
        #region --- WIN32 IMPORTS ---
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

        [DllImport("user32.dll")]
        public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

        [DllImport("winmm.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern bool PlaySound(byte[] pszSound, IntPtr hmod, uint fdwSound);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

        [DllImport("user32.dll")]
        public static extern bool EnumThreadWindows(int dwThreadId, EnumThreadDelegate lpfn, IntPtr lParam);

        public delegate bool EnumThreadDelegate(IntPtr hWnd, IntPtr lParam);

        public static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
        public const uint SWP_NOSIZE = 0x0001;
        public const uint SWP_NOMOVE = 0x0002;
        public const uint SWP_SHOWWINDOW = 0x0040;
        public const uint SWP_NOACTIVATE = 0x0010;
        public const byte VK_MEDIA_STOP = 0xB2;
        public const byte VK_MEDIA_PLAY_PAUSE = 0xB3;
        public const uint KEYEVENTF_KEYUP = 0x0002;

        [DllImport("user32.dll")]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

        [DllImport("user32.dll")]
        public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

        [DllImport("kernel32.dll")]
        public static extern uint GetCurrentThreadId();

        [DllImport("user32.dll")]
        public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

        [DllImport("user32.dll")]
        public static extern bool BringWindowToTop(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        public const int SW_SHOWMAXIMIZED = 3;
        public const int SW_RESTORE = 9;

        public const uint WM_KEYDOWN = 0x0100;
        public const uint WM_KEYUP = 0x0101;
        public const int VK_SPACE = 0x20;

        public const uint WM_APPCOMMAND = 0x0319;
        public const int APPCOMMAND_MEDIA_PAUSE = 47;
        public const int APPCOMMAND_MEDIA_PLAY_PAUSE = 14;
        #endregion

        private static readonly IVirtualDesktopManager? _desktopManager;

        static AudioEngine()
        {
            try
            {
                Type? type = Type.GetTypeFromCLSID(new Guid("AA509086-5CA9-4C25-8F95-589D3C07B48A"));
                if (type != null)
                {
                    _desktopManager = (IVirtualDesktopManager?)Activator.CreateInstance(type);
                }
            }
            catch
            {
                _desktopManager = null;
            }
        }

        #region --- ACTIVE MEDIA PAUSING ---
        /// <summary>
        /// Explicitly pauses all active media across modern Windows GSMTC apps (Chrome, Edge, Spotify)
        /// and classic Win32 desktop media players (VLC, MPV, MPC-HC, PotPlayer).
        /// </summary>
        public static async Task PauseActiveMediaAsync()
        {
            // 1. If user is actively watching VLC / a media player in foreground, send Space immediately
            try
            {
                IntPtr priorFg = GetForegroundWindow();
                if (priorFg != IntPtr.Zero)
                {
                    GetWindowThreadProcessId(priorFg, out uint fgPid);
                    using var fgProc = Process.GetProcessById((int)fgPid);
                    string procName = fgProc.ProcessName.ToLowerInvariant();
                    if (procName.Contains("vlc") || procName.Contains("mpv") || procName.Contains("potplayer") || procName.Contains("mpc"))
                    {
                        PostMessage(priorFg, WM_KEYDOWN, (IntPtr)VK_SPACE, IntPtr.Zero);
                        PostMessage(priorFg, WM_KEYUP, (IntPtr)VK_SPACE, IntPtr.Zero);
                    }
                }
            }
            catch { }

            // 2. Pause Modern WinRT GSMTC Media Sessions (YouTube in Chrome/Edge, Spotify, etc.)
            try
            {
                var sessionManager = await GlobalSystemMediaTransportControlsSessionManager.RequestAsync();
                if (sessionManager != null)
                {
                    var sessions = sessionManager.GetSessions();
                    foreach (var session in sessions)
                    {
                        try
                        {
                            var playbackInfo = session.GetPlaybackInfo();
                            if (playbackInfo != null &&
                                playbackInfo.PlaybackStatus == GlobalSystemMediaTransportControlsSessionPlaybackStatus.Playing)
                            {
                                await session.TryPauseAsync();
                            }
                        }
                        catch { }
                    }
                }
            }
            catch { }

            // 3. Pause Classic Win32 Desktop Players (VLC, MPV, MPC-HC, PotPlayer) via WM_APPCOMMAND & Windows
            PauseDesktopMediaPlayers();
        }

        public static void PauseDesktopMediaPlayers()
        {
            try
            {
                string[] playerProcessNames = { "vlc", "mpv", "mpc-hc", "mpc-hc64", "potplayer", "potplayermini64", "foobar2000", "aimp" };
                foreach (string procName in playerProcessNames)
                {
                    var procs = Process.GetProcessesByName(procName);
                    foreach (var proc in procs)
                    {
                        try
                        {
                            // Send WM_APPCOMMAND and Space to the main process window
                            if (proc.MainWindowHandle != IntPtr.Zero)
                            {
                                SendMessage(proc.MainWindowHandle, WM_APPCOMMAND, proc.MainWindowHandle, (IntPtr)(APPCOMMAND_MEDIA_PAUSE << 16));
                                SendMessage(proc.MainWindowHandle, WM_APPCOMMAND, proc.MainWindowHandle, (IntPtr)(APPCOMMAND_MEDIA_PLAY_PAUSE << 16));
                                PostMessage(proc.MainWindowHandle, WM_KEYDOWN, (IntPtr)VK_SPACE, IntPtr.Zero);
                                PostMessage(proc.MainWindowHandle, WM_KEYUP, (IntPtr)VK_SPACE, IntPtr.Zero);
                            }

                            // Enumerate all thread windows (e.g. VLC separate video output or fullscreen window)
                            foreach (ProcessThread thread in proc.Threads)
                            {
                                EnumThreadWindows(thread.Id, (hWnd, lParam) =>
                                {
                                    SendMessage(hWnd, WM_APPCOMMAND, hWnd, (IntPtr)(APPCOMMAND_MEDIA_PAUSE << 16));
                                    SendMessage(hWnd, WM_APPCOMMAND, hWnd, (IntPtr)(APPCOMMAND_MEDIA_PLAY_PAUSE << 16));
                                    PostMessage(hWnd, WM_KEYDOWN, (IntPtr)VK_SPACE, IntPtr.Zero);
                                    PostMessage(hWnd, WM_KEYUP, (IntPtr)VK_SPACE, IntPtr.Zero);
                                    return true;
                                }, IntPtr.Zero);
                            }
                        }
                        catch { }
                    }
                }
            }
            catch { }

            // 4. Hardware Media Play/Pause Broadcast
            try
            {
                keybd_event(VK_MEDIA_PLAY_PAUSE, 0, 0, UIntPtr.Zero);
                keybd_event(VK_MEDIA_PLAY_PAUSE, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
            }
            catch { }
        }
        #endregion

        #region --- WASAPI AUDIO SESSION MUTE TAKEOVER ---
        private static bool IsExempt(uint pid, uint myPid)
        {
            if (pid == 0) return true; // System alert sounds
            if (pid == myPid) return true; // Our own process

            try
            {
                using var proc = Process.GetProcessById((int)pid);
                string name = proc.ProcessName.ToLowerInvariant();
                if (name.Contains("powershell") ||
                    name.Contains("pwsh") ||
                    name.Contains("conhost") ||
                    name.Contains("windowsterminal") ||
                    name.Contains("openconsole"))
                {
                    return true;
                }
            }
            catch { }
            return false;
        }

        public static void MuteOtherSessions(bool mute, uint myPid)
        {
            try
            {
                var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
                if (enumerator == null) return;

                if (enumerator.GetDefaultAudioEndpoint(0, 1, out IMMDevice endpoint) != 0 || endpoint == null)
                    return;

                var managerId = new Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F");
                if (endpoint.Activate(ref managerId, 23, 0, out object obj) != 0 || obj == null)
                {
                    Marshal.ReleaseComObject(endpoint);
                    return;
                }

                if (obj is not IAudioSessionManager2 manager)
                {
                    Marshal.ReleaseComObject(endpoint);
                    return;
                }

                if (manager.GetSessionEnumerator(out IAudioSessionEnumerator sessionEnum) != 0 || sessionEnum == null)
                {
                    Marshal.ReleaseComObject(manager);
                    Marshal.ReleaseComObject(endpoint);
                    return;
                }

                if (sessionEnum.GetCount(out int count) == 0 && count > 0)
                {
                    for (int i = 0; i < count; i++)
                    {
                        if (sessionEnum.GetSession(i, out IAudioSessionControl session) == 0 && session != null)
                        {
                            if (session is IAudioSessionControl2 session2)
                            {
                                if (session2.IsSystemSoundsSession() == 0)
                                {
                                    Marshal.ReleaseComObject(session);
                                    continue;
                                }

                                session2.GetProcessId(out uint pid);

                                if (!mute || !IsExempt(pid, myPid))
                                {
                                    if (session is ISimpleAudioVolume simpleVolume)
                                    {
                                        simpleVolume.SetMute(mute, Guid.Empty);
                                    }
                                }
                            }
                            else if (!mute)
                            {
                                if (session is ISimpleAudioVolume simpleVolume)
                                {
                                    simpleVolume.SetMute(false, Guid.Empty);
                                }
                            }
                            Marshal.ReleaseComObject(session);
                        }
                    }
                }

                Marshal.ReleaseComObject(sessionEnum);
                Marshal.ReleaseComObject(manager);
                Marshal.ReleaseComObject(endpoint);
            }
            catch { }
        }
        #endregion

        #region --- PCM SOUND SYNTHESIZER ---
        /// <summary>
        /// Synthesizes and plays an in-memory pure sine wave WAV buffer.
        /// Volume is calibrated (default 0.15) to sit subtly below the ambient whistle.
        /// </summary>
        public static void PlayBeep(double frequency, int durationMs, double volume = 0.15)
        {
            try
            {
                int sampleRate = 44100;
                int numSamples = (int)(sampleRate * (durationMs / 1000.0));
                byte[] waveBuffer = new byte[44 + numSamples * 2];

                // RIFF Header
                Buffer.BlockCopy(System.Text.Encoding.ASCII.GetBytes("RIFF"), 0, waveBuffer, 0, 4);
                int fileSize = 36 + numSamples * 2;
                Buffer.BlockCopy(BitConverter.GetBytes(fileSize), 0, waveBuffer, 4, 4);
                Buffer.BlockCopy(System.Text.Encoding.ASCII.GetBytes("WAVE"), 0, waveBuffer, 8, 4);

                // Subchunk 1 (fmt )
                Buffer.BlockCopy(System.Text.Encoding.ASCII.GetBytes("fmt "), 0, waveBuffer, 12, 4);
                int subchunk1Size = 16;
                Buffer.BlockCopy(BitConverter.GetBytes(subchunk1Size), 0, waveBuffer, 16, 4);
                short audioFormat = 1; // PCM
                Buffer.BlockCopy(BitConverter.GetBytes(audioFormat), 0, waveBuffer, 20, 2);
                short numChannels = 1; // Mono
                Buffer.BlockCopy(BitConverter.GetBytes(numChannels), 0, waveBuffer, 22, 2);
                Buffer.BlockCopy(BitConverter.GetBytes(sampleRate), 0, waveBuffer, 24, 4);
                int byteRate = sampleRate * 2;
                Buffer.BlockCopy(BitConverter.GetBytes(byteRate), 0, waveBuffer, 28, 4);
                short blockAlign = 2;
                Buffer.BlockCopy(BitConverter.GetBytes(blockAlign), 0, waveBuffer, 32, 2);
                short bitsPerSample = 16;
                Buffer.BlockCopy(BitConverter.GetBytes(bitsPerSample), 0, waveBuffer, 34, 2);

                // Subchunk 2 (data)
                Buffer.BlockCopy(System.Text.Encoding.ASCII.GetBytes("data"), 0, waveBuffer, 36, 4);
                int subchunk2Size = numSamples * 2;
                Buffer.BlockCopy(BitConverter.GetBytes(subchunk2Size), 0, waveBuffer, 40, 4);

                // Sine wave samples
                double t = 0.0;
                double dt = 2.0 * Math.PI * frequency / sampleRate;
                double amplitude = 32767.0 * volume;
                for (int i = 0; i < numSamples; i++)
                {
                    short sample = (short)(amplitude * Math.Sin(t));
                    Buffer.BlockCopy(BitConverter.GetBytes(sample), 0, waveBuffer, 44 + i * 2, 2);
                    t += dt;
                }

                // SND_MEMORY = 0x0004, SND_NODEFAULT = 0x0002
                PlaySound(waveBuffer, IntPtr.Zero, 6);
            }
            catch { }
        }

        public static void PlayBeepAsync(double frequency, int durationMs, double volume = 0.15)
        {
            ThreadPool.QueueUserWorkItem(_ => PlayBeep(frequency, durationMs, volume));
        }

        /// <summary>
        /// Mechanical clock tick-tock. Calibrated slightly lower than whistle volume (0.15 vs 0.40).
        /// </summary>
        public static void PlayTick(bool isEven)
        {
            double freq = isEven ? 1800.0 : 1500.0;
            PlayBeepAsync(freq, 15, 0.15);
        }

        /// <summary>
        /// Single resonant release chime when countdown completes (1 time only, 1200Hz).
        /// </summary>
        public static void PlaySingleEndChime()
        {
            PlayBeepAsync(1200.0, 300, 0.30);
        }
        #endregion

        #region --- TOPMOST & VIRTUAL DESKTOP INTEGRITY ---
        public static bool IsOnCurrentDesktop(IntPtr hWnd)
        {
            if (_desktopManager == null) return true;
            try
            {
                int hr = _desktopManager.IsWindowOnCurrentVirtualDesktop(hWnd, out bool onCurrent);
                if (hr == 0) return onCurrent;
            }
            catch { }
            return true;
        }

        public static void MoveToDesktop(IntPtr hWnd, Guid desktopId)
        {
            if (_desktopManager == null) return;
            try
            {
                _desktopManager.MoveWindowToDesktop(hWnd, ref desktopId);
            }
            catch { }
        }

        /// <summary>
        /// Enforces topmost placement and foreground lock bypass cleanly (zero flicker/glitch).
        /// </summary>
        public static void EnforceTopmost(IntPtr hWnd)
        {
            if (hWnd == IntPtr.Zero) return;
            try
            {
                IntPtr fgWnd = GetForegroundWindow();
                if (fgWnd != hWnd)
                {
                    uint fgThread = GetWindowThreadProcessId(fgWnd, out _);
                    uint curThread = GetCurrentThreadId();

                    if (fgThread != curThread && fgThread != 0)
                    {
                        AttachThreadInput(curThread, fgThread, true);
                        BringWindowToTop(hWnd);
                        ShowWindow(hWnd, SW_SHOWMAXIMIZED);
                        SetForegroundWindow(hWnd);
                        AttachThreadInput(curThread, fgThread, false);
                    }
                    else
                    {
                        BringWindowToTop(hWnd);
                        ShowWindow(hWnd, SW_SHOWMAXIMIZED);
                        SetForegroundWindow(hWnd);
                    }

                    SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
                }
            }
            catch { }
        }
        #endregion
    }
}
