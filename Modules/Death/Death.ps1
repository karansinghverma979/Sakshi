<#
.SYNOPSIS
    Memento Mori - Absolute Finality (Mechanical Clock Edition V6)
.DESCRIPTION
    Features a realistic alternating Tick-Tock sound, virtual desktop lock, and a perfectly stable UI.
#>

#region --- Setup & Configuration ---
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$LogFilePath = Join-Path -Path $PSScriptRoot -ChildPath "Death.log"
$VisualsDir = Join-Path -Path $PSScriptRoot -ChildPath "Visuals"
$QuoteFilePath = Join-Path -Path $PSScriptRoot -ChildPath "quote.txt"

# Default quote
$CustomQuote = " KEEP CALM AND STUDY HARD. "
if (Test-Path -Path $QuoteFilePath) {
    try {
        $LoadedQuote = Get-Content -Path $QuoteFilePath -Raw
        if (-not [string]::IsNullOrWhiteSpace($LoadedQuote)) {
            $CustomQuote = " $($LoadedQuote.Trim()) "
        }
    } catch { }
}

function Write-Log {
    param([string]$Message)
    try {
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "[$Timestamp] | DEATH | $Message" | Out-File -FilePath $LogFilePath -Append
    } catch { }
}

# --- System Audio Takeover (WASAPI & Win32 Audio control) ---
$AudioCode = @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

[ComImport]
[Guid("5CDF2C82-841E-4546-9722-0CF74078229A")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolumeV6 {
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
interface ISimpleAudioVolumeV6 {
    [PreserveSig] int SetMasterVolume(float fLevel, Guid pguidEventContext);
    [PreserveSig] int GetMasterVolume(out float pfLevel);
    [PreserveSig] int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, Guid pguidEventContext);
    [PreserveSig] int GetMute(out bool pbMute);
}

[ComImport]
[Guid("F4B1A599-7266-4319-A8CA-E70ACB11E8CD")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioSessionControlV6 {
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
interface IAudioSessionControl2V6 {
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
interface IAudioSessionEnumeratorV6 {
    [PreserveSig] int GetCount(out int SessionCount);
    [PreserveSig] int GetSession(int SessionIndex, out IAudioSessionControlV6 Session);
}

[ComImport]
[Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioSessionManager2V6 {
    [PreserveSig] int GetAudioSessionControl(Guid AudioSessionGuid, uint StreamFlags, out IntPtr SessionControl);
    [PreserveSig] int GetSimpleAudioVolume(Guid AudioSessionGuid, uint StreamFlags, out IntPtr AudioVolume);
    [PreserveSig] int GetSessionEnumerator(out IAudioSessionEnumeratorV6 SessionList);
    [PreserveSig] int RegisterSessionNotification(IntPtr SessionNotification);
    [PreserveSig] int UnregisterSessionNotification(IntPtr SessionNotification);
    [PreserveSig] int RegisterDuckNotification([MarshalAs(UnmanagedType.LPWStr)] string sessionID, IntPtr duckNotification);
    [PreserveSig] int UnregisterDuckNotification(IntPtr duckNotification);
}

[ComImport]
[Guid("a5cd92ff-29be-454c-8d04-d82879fb3f1b")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IVirtualDesktopManagerV6 {
    [PreserveSig] int IsWindowOnCurrentVirtualDesktop(IntPtr topLevelWindow, [MarshalAs(UnmanagedType.Bool)] out bool onCurrentDesktop);
    [PreserveSig] int GetWindowDesktopId(IntPtr topLevelWindow, out Guid desktopId);
    [PreserveSig] int MoveWindowToDesktop(IntPtr topLevelWindow, ref Guid desktopId);
}

[ComImport]
[Guid("D666063F-1587-4E43-81F1-B948E807363F")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceV6 {
    [PreserveSig] int Activate(ref Guid id, int clsCtx, int activationParams, [MarshalAs(UnmanagedType.IUnknown)] out object obj);
}

[ComImport]
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumeratorV6 {
    [PreserveSig] int f();
    [PreserveSig] int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDeviceV6 endpoint);
}

[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
class MMDeviceEnumeratorComObjectV6 { }

public class AudioEngineV6 {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("winmm.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern bool PlaySound(byte[] pszSound, IntPtr hmod, uint fdwSound);

    private static IVirtualDesktopManagerV6 _desktopManager;

    static AudioEngineV6() {
        try {
            Type type = Type.GetTypeFromCLSID(new Guid("AA509086-5CA9-4C25-8F95-589D3C07B48A"));
            _desktopManager = (IVirtualDesktopManagerV6)Activator.CreateInstance(type);
        } catch {
            _desktopManager = null;
        }
    }

    public static bool IsOnCurrentDesktop(IntPtr hWnd) {
        if (_desktopManager == null) return true;
        try {
            bool onCurrent = true;
            int hr = _desktopManager.IsWindowOnCurrentVirtualDesktop(hWnd, out onCurrent);
            if (hr == 0) return onCurrent;
        } catch { }
        return true;
    }

    public static void MoveToDesktop(IntPtr hWnd, Guid desktopId) {
        if (_desktopManager == null) return;
        try {
            _desktopManager.MoveWindowToDesktop(hWnd, ref desktopId);
        } catch { }
    }

    public static void PlayBeep(double frequency, int durationMs, double volume = 0.5) {
        try {
            int sampleRate = 44100;
            int numSamples = (int)(sampleRate * (durationMs / 1000.0));
            byte[] waveBuffer = new byte[44 + numSamples * 2];

            // RIFF Header
            Buffer.BlockCopy(System.Text.Encoding.ASCII.GetBytes("RIFF"), 0, waveBuffer, 0, 4);
            int fileSize = 36 + numSamples * 2;
            Buffer.BlockCopy(BitConverter.GetBytes(fileSize), 0, waveBuffer, 4, 4);
            Buffer.BlockCopy(System.Text.Encoding.ASCII.GetBytes("WAVE"), 0, waveBuffer, 8, 4);

            // Subchunk 1 (fmt)
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

            // Generate Sine Wave Samples
            double t = 0.0;
            double dt = 2.0 * Math.PI * frequency / sampleRate;
            double amplitude = 32767 * volume;
            for (int i = 0; i < numSamples; i++) {
                short sample = (short)(amplitude * Math.Sin(t));
                Buffer.BlockCopy(BitConverter.GetBytes(sample), 0, waveBuffer, 44 + i * 2, 2);
                t += dt;
            }

            // Play via native Win32 API (SND_MEMORY = 0x0004, SND_NODEFAULT = 0x0002)
            PlaySound(waveBuffer, IntPtr.Zero, 6);
        } catch { }
    }

    public static void PlayBeepAsync(double frequency, int durationMs, double volume = 0.5) {
        ThreadPool.QueueUserWorkItem(state => {
            PlayBeep(frequency, durationMs, volume);
        });
    }

    private static IAudioEndpointVolumeV6 Vol() {
        var enumerator = new MMDeviceEnumeratorComObjectV6() as IMMDeviceEnumeratorV6;
        IMMDeviceV6 dev = null;
        Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(0, 1, out dev));
        object obj = null;
        var epvid = typeof(IAudioEndpointVolumeV6).GUID;
        Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, 23, 0, out obj));
        return obj as IAudioEndpointVolumeV6;
    }

    public static bool Mute {
        get { bool mute; Marshal.ThrowExceptionForHR(Vol().GetMute(out mute)); return mute; }
        set { Marshal.ThrowExceptionForHR(Vol().SetMute(value, Guid.Empty)); }
    }

    private static bool IsExempt(uint pid, uint myPid) {
        if (pid == 0) return true; // System sounds / background tones
        if (pid == myPid) return true;
        try {
            using (var proc = System.Diagnostics.Process.GetProcessById((int)pid)) {
                string name = proc.ProcessName.ToLower();
                if (name.Contains("powershell") || 
                    name.Contains("pwsh") || 
                    name.Contains("conhost") || 
                    name.Contains("windowsterminal") || 
                    name.Contains("openconsole")) {
                    return true;
                }
            }
        } catch { }
        return false;
    }

    public static void MuteOtherSessions(bool mute, uint myPid) {
        try {
            var enumerator = new MMDeviceEnumeratorComObjectV6() as IMMDeviceEnumeratorV6;
            if (enumerator == null) return;
            IMMDeviceV6 dev = null;
            if (enumerator.GetDefaultAudioEndpoint(0, 1, out dev) != 0 || dev == null) return;
            
            object obj = null;
            var managerId = new Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F");
            if (dev.Activate(ref managerId, 23, 0, out obj) != 0 || obj == null) {
                Marshal.ReleaseComObject(dev);
                return;
            }
            
            var manager = obj as IAudioSessionManager2V6;
            if (manager == null) {
                Marshal.ReleaseComObject(dev);
                return;
            }
            
            IAudioSessionEnumeratorV6 sessionEnum = null;
            if (manager.GetSessionEnumerator(out sessionEnum) != 0 || sessionEnum == null) {
                Marshal.ReleaseComObject(manager);
                Marshal.ReleaseComObject(dev);
                return;
            }
            
            int count = 0;
            if (sessionEnum.GetCount(out count) == 0 && count > 0) {
                for (int i = 0; i < count; i++) {
                    IAudioSessionControlV6 session = null;
                    if (sessionEnum.GetSession(i, out session) == 0 && session != null) {
                        var session2 = session as IAudioSessionControl2V6;
                        if (session2 != null) {
                            // Check if it is the system sounds session (HR = 0 means true)
                            if (session2.IsSystemSoundsSession() == 0) {
                                Marshal.ReleaseComObject(session);
                                continue;
                            }
                            
                            uint pid = 0;
                            session2.GetProcessId(out pid);
                            
                            // If mute is true: only mute other non-exempt processes.
                            // If mute is false: unmute EVERYTHING unconditionally.
                            if (!mute || !IsExempt(pid, myPid)) {
                                var simpleVolume = session as ISimpleAudioVolumeV6;
                                if (simpleVolume != null) {
                                    simpleVolume.SetMute(mute, Guid.Empty);
                                }
                            }
                        } else if (!mute) {
                            // Unmute system sounds / other sessions without session2 control
                            var simpleVolume = session as ISimpleAudioVolumeV6;
                            if (simpleVolume != null) {
                                simpleVolume.SetMute(false, Guid.Empty);
                            }
                        }
                        Marshal.ReleaseComObject(session);
                    }
                }
            }
            Marshal.ReleaseComObject(sessionEnum);
            Marshal.ReleaseComObject(manager);
            Marshal.ReleaseComObject(dev);
        } catch { }
    }
}
"@

try {
    if (-not ([System.Management.Automation.PSTypeName]"AudioEngineV6").Type) {
        Add-Type -TypeDefinition $AudioCode
    }
    $script:MyPid = [System.Diagnostics.Process]::GetCurrentProcess().Id
    [AudioEngineV6]::MuteOtherSessions($true, $script:MyPid)
} catch {
    Write-Log "AUDIO INTERFERENCE WARNING: Failed to control session mute states via WASAPI. Details: $_"
}

# --- Sound Discovery ---
$AllSounds = Get-ChildItem -Path $PSScriptRoot -File | Where-Object { $_.Extension -match "\.(mp3|wav)$" }
$BackgroundSoundPath = $AllSounds | Select-Object -First 1 -ExpandProperty FullName

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

function New-BitmapImage {
    param([string]$ImagePath)
    try {
        $Bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
        $Bitmap.BeginInit()
        $Bitmap.UriSource = [System.Uri]$ImagePath
        $Bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $Bitmap.EndInit()
        $Bitmap.Freeze()
        return $Bitmap
    } catch { return $null }
}

$ImageFiles = @()
if (Test-Path -Path $VisualsDir) {
    $SupportedExtensions = @(".jpg", ".jpeg", ".png", ".bmp", ".gif")
    $ImageFiles = Get-ChildItem -Path $VisualsDir -File | Where-Object { $SupportedExtensions -contains $_.Extension.ToLower() }
}

$MediaPlayer = New-Object System.Windows.Media.MediaPlayer
if ($BackgroundSoundPath) { 
    $MediaPlayer.Open([System.Uri]$BackgroundSoundPath)
    $MediaPlayer.Volume = 0.5
}
#endregion

#region --- WPF GUI Definition ---
$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MEMENTO MORI"
        WindowState="Maximized" WindowStyle="None" Topmost="True"
        ShowInTaskbar="False" ResizeMode="NoResize"
        Background="Black">

    <Window.Resources>
        <Storyboard x:Key="HeaderPulseAnimation">
            <DoubleAnimation Storyboard.TargetName="HeaderGlow" Storyboard.TargetProperty="BlurRadius" From="20" To="60" Duration="0:0:3" AutoReverse="True" RepeatBehavior="Forever" />
        </Storyboard>

        <Storyboard x:Key="ButtonPulseAnimation">
            <DoubleAnimation Storyboard.TargetName="AcceptButton" Storyboard.TargetProperty="Opacity" From="0.6" To="1" Duration="0:0:1.5" AutoReverse="True" RepeatBehavior="Forever" />
        </Storyboard>
        
        <Style x:Key="GlowButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="#150000" />
            <Setter Property="Foreground" Value="#FF0000" />
            <Setter Property="BorderBrush" Value="#990000" />
            <Setter Property="BorderThickness" Value="2" />
            <Setter Property="FontFamily" Value="Constantia"/>
            <Setter Property="FontSize" Value="42" />
            <Setter Property="FontWeight" Value="Bold" />
            <Setter Property="Padding" Value="90,35" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Name="ButtonBorder" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8">
                            <Border.Effect>
                                <DropShadowEffect Color="#FF0000" BlurRadius="25" ShadowDepth="0" Opacity="0.9"/>
                            </Border.Effect>
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="ButtonBorder" Property="Background" Value="#440000" />
                                <Setter TargetName="ButtonBorder" Property="BorderBrush" Value="#FF0000" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid>
        <Image x:Name="BackgroundImage" Stretch="Uniform" Opacity="0.25">
            <Image.Effect><BlurEffect Radius="5"/></Image.Effect>
        </Image>

        <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Panel.ZIndex="2">
            <Viewbox MaxWidth="1600" HorizontalAlignment="Center">
                <TextBlock Text="&#x1F480;MEMENTO MORI&#x1F480;" FontFamily="Courier New" FontSize="140" FontWeight="Bold" Foreground="#FF0000" TextAlignment="Center">
                    <TextBlock.Effect>
                        <DropShadowEffect x:Name="HeaderGlow" Color="#FF0000" BlurRadius="30" ShadowDepth="0" Opacity="1"/>
                    </TextBlock.Effect>
                </TextBlock>
            </Viewbox>
            
            <TextBlock Text="Remember That You Must Die." FontFamily="Constantia" FontSize="85" Foreground="#FF0000" FontWeight="Bold" TextAlignment="Center" Margin="0,40,0,80">
                <TextBlock.Effect><DropShadowEffect Color="Black" BlurRadius="15" ShadowDepth="5"/></TextBlock.Effect>
            </TextBlock>

            <Grid Width="800" Height="200">
                <TextBlock x:Name="CountdownDisplay" Text="60" FontFamily="Constantia" FontSize="130" Foreground="#440000" FontWeight="Bold" TextAlignment="Center" VerticalAlignment="Center" HorizontalAlignment="Center">
                    <TextBlock.Effect><DropShadowEffect Color="Black" BlurRadius="10" ShadowDepth="0"/></TextBlock.Effect>
                </TextBlock>
                <Button x:Name="AcceptButton" Content=" KEEP CALM AND STUDY HARD. " Style="{StaticResource GlowButtonStyle}" Visibility="Collapsed" VerticalAlignment="Center" HorizontalAlignment="Center" />
            </Grid>
        </StackPanel>
    </Grid>
</Window>
"@
#endregion

# --- GUI Logic ---
try {
    $StringReader = [System.IO.StringReader]::new($Xaml)
    $XmlReader = [System.Xml.XmlReader]::Create($StringReader)
    $Window = [Windows.Markup.XamlReader]::Load($XmlReader)

    $AcceptButton = $Window.FindName("AcceptButton")
    $BackgroundImage = $Window.FindName("BackgroundImage")
    $CountdownDisplay = $Window.FindName("CountdownDisplay")

    if ($null -ne $AcceptButton) {
        $AcceptButton.Content = $CustomQuote
    }

    $script:SecondsRemaining = 60
    
    $FocusTimer = New-Object System.Windows.Threading.DispatcherTimer
    $FocusTimer.Interval = [TimeSpan]::FromMilliseconds(100)
    $FocusTimer.Add_Tick({
        if ($script:SecondsRemaining -gt 0 -and $null -ne $script:WindowHandle) {
            try {
                # 1. Active Virtual Desktop Snap
                $isOnCurrent = [AudioEngineV6]::IsOnCurrentDesktop($script:WindowHandle)
                if (-not $isOnCurrent) {
                    $Bytes = (Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops' -ErrorAction SilentlyContinue).CurrentVirtualDesktop
                    if ($null -ne $Bytes) {
                        $CurrentDesktopGuid = [Guid]::new($Bytes)
                        [AudioEngineV6]::MoveToDesktop($script:WindowHandle, $CurrentDesktopGuid)
                    }
                }

                # 2. Foreground Focus Lock
                $fg = [AudioEngineV6]::GetForegroundWindow()
                if ($fg -ne $script:WindowHandle) {
                    [AudioEngineV6]::SetForegroundWindow($script:WindowHandle) | Out-Null
                    $Window.Topmost = $false
                    $Window.Topmost = $true
                    $Window.Activate() | Out-Null
                    $Window.Focus() | Out-Null
                }
            } catch { }
        } else {
            $FocusTimer.Stop()
        }
    })

    $CountdownTimer = New-Object System.Windows.Threading.DispatcherTimer
    $CountdownTimer.Interval = [TimeSpan]::FromSeconds(1)
    $CountdownTimer.Add_Tick({
        $script:SecondsRemaining--
        
        try {
            [AudioEngineV6]::MuteOtherSessions($true, $script:MyPid)
        } catch { }
        
        if ($script:SecondsRemaining -gt 0) {
            $CountdownDisplay.Text = $script:SecondsRemaining.ToString()
            if ($script:SecondsRemaining -le 10) { $CountdownDisplay.Foreground = [System.Windows.Media.Brushes]::Red }
            
            # --- MECHANICAL TICK-TOCK ---
            # Alternates frequency every second for a realistic clock feel
            if ($script:SecondsRemaining % 2 -eq 0) {
                [AudioEngineV6]::PlayBeepAsync(1800, 15)
            } else {
                [AudioEngineV6]::PlayBeepAsync(1500, 15)
            }
        }
        else {
            $CountdownTimer.Stop()
            $FocusTimer.Stop()
            
            # --- SOUND EFFECT ON COMPLETION ---
            # Three-tone chime signaling unlock
            [AudioEngineV6]::PlayBeepAsync(1000, 100)
            Start-Sleep -Milliseconds 150
            [AudioEngineV6]::PlayBeepAsync(1200, 100)
            Start-Sleep -Milliseconds 150
            [AudioEngineV6]::PlayBeepAsync(1500, 250)
            
            $CountdownDisplay.Visibility = 'Collapsed'
            $AcceptButton.Visibility = 'Visible'
            $Window.Resources["ButtonPulseAnimation"].Begin($Window)
        }
    })

    $ImageTimer = New-Object System.Windows.Threading.DispatcherTimer
    $ImageTimer.Interval = [TimeSpan]::FromSeconds(3)
    $ImageTimer.Add_Tick({
        if ($ImageFiles.Count -gt 0) {
            $RandomImage = $ImageFiles | Get-Random
            $BackgroundImage.Source = New-BitmapImage -ImagePath $RandomImage.FullName
        }
    })

    $AcceptButton.Add_Click({ $Window.Close() })

    # Prevent losing focus, switching desktops, or clicking system tray
    $Window.Add_Deactivated({
        if ($script:SecondsRemaining -gt 0) {
            $Window.Topmost = $false
            $Window.Topmost = $true
            $Window.Activate() | Out-Null
            $Window.Focus() | Out-Null
        }
    })
    
    $Window.Add_Loaded({
        $script:WindowHandle = (New-Object System.Windows.Interop.WindowInteropHelper($Window)).Handle
        $CountdownTimer.Start()
        $FocusTimer.Start()
        $ImageTimer.Start()
        $Window.Topmost = $true
        $Window.Activate() | Out-Null
        $Window.Focus() | Out-Null
        $Window.Resources["HeaderPulseAnimation"].Begin($Window)
        if ($MediaPlayer -and $BackgroundSoundPath) { 
            $MediaPlayer.Play()
            $MediaPlayer.Add_MediaEnded({ $MediaPlayer.Position = [TimeSpan]::Zero; $MediaPlayer.Play() })
        }
    })

    $Window.Add_Closing({
        param($sender, $e)
        if ($script:SecondsRemaining -gt 0) {
            $e.Cancel = $true
        } else {
            $CountdownTimer.Stop()
            $FocusTimer.Stop()
            $ImageTimer.Stop()
            if ($MediaPlayer -and $BackgroundSoundPath) { $MediaPlayer.Stop(); $MediaPlayer.Close() }
            try {
                [AudioEngineV6]::MuteOtherSessions($false, 0)
                [AudioEngineV6]::Mute = $false
            } catch { }
        }
    })

    $Window.Show()
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    $Window.Add_Closed({ $frame.Continue = $false })
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
} catch { Write-Log "FATAL ERROR: $_" }
#endregion
