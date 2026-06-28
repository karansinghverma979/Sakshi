<#
.SYNOPSIS
    Memento Mori - Absolute Finality (Mechanical Clock Edition)
.DESCRIPTION
    Features a realistic alternating Tick-Tock sound and a perfectly stable UI.
#>

#region --- Setup & Configuration ---
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$LogFilePath = Join-Path -Path $PSScriptRoot -ChildPath "Death.log"
$VisualsDir = Join-Path -Path $PSScriptRoot -ChildPath "Visuals"

function Write-Log {
    param([string]$Message)
    try {
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "[$Timestamp] | DEATH | $Message" | Out-File -FilePath $LogFilePath -Append
    } catch { }
}

# --- System Audio Takeover (WASAPI Direct Control) ---
$AudioCode = @"
using System;
using System.Runtime.InteropServices;

[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {
    int f(); int g(); int h(); int i();
    int SetMasterVolumeLevelScalar(float fLevel, Guid pguidEventContext);
    int j();
    int GetMasterVolumeLevelScalar(out float pfLevel);
    int k(); int l(); int m(); int n();
    int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, Guid pguidEventContext);
    int GetMute(out bool pbMute);
}

[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice {
    int Activate(ref Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
}

[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator {
    int f();
    int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}

[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
class MMDeviceEnumeratorComObject { }

public class Audio {
    private static IAudioEndpointVolume Vol() {
        var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
        IMMDevice dev = null;
        Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(0, 1, out dev));
        IAudioEndpointVolume epv = null;
        var epvid = typeof(IAudioEndpointVolume).GUID;
        Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, 23, 0, out epv));
        return epv;
    }

    public static bool Mute {
        get { bool mute; Marshal.ThrowExceptionForHR(Vol().GetMute(out mute)); return mute; }
        set { Marshal.ThrowExceptionForHR(Vol().SetMute(value, Guid.Empty)); }
    }
}
"@

try {
    if (-not ([System.Management.Automation.PSTypeName]"Audio").Type) {
        Add-Type -TypeDefinition $AudioCode
    }
    $script:OriginalMuteState = [Audio]::Mute
    [Audio]::Mute = $true
} catch {
    Write-Log "AUDIO INTERFERENCE WARNING: Failed to control master mute state via WASAPI. Details: $_"
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
    $MediaPlayer.Volume = 0.5 # Lower volume to hear the clock ticks better
}
#endregion

#region --- WPF GUI Definition ---
$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MEMENTO MORI"
        WindowState="Maximized" WindowStyle="None" Topmost="True"
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

    $script:SecondsRemaining = 60
    $CountdownTimer = New-Object System.Windows.Threading.DispatcherTimer
    $CountdownTimer.Interval = [TimeSpan]::FromSeconds(1)
    $CountdownTimer.Add_Tick({
        $script:SecondsRemaining--
        
        if ($script:SecondsRemaining -gt 0) {
            $CountdownDisplay.Text = $script:SecondsRemaining.ToString()
            if ($script:SecondsRemaining -le 10) { $CountdownDisplay.Foreground = [System.Windows.Media.Brushes]::Red }
            
            # --- MECHANICAL TICK-TOCK ---
            # Alternates frequency every second for a realistic clock feel
            if ($script:SecondsRemaining % 2 -eq 0) {
                [System.Console]::Beep(1800, 15) # High sharp Tick
            } else {
                [System.Console]::Beep(1500, 15) # Slightly lower Tock
            }
        }
        else {
            $CountdownTimer.Stop()
            [System.Console]::Beep(1200, 100) # Final deeper thud
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
    
    $Window.Add_Loaded({
        $CountdownTimer.Start()
        $ImageTimer.Start()
        $Window.Resources["HeaderPulseAnimation"].Begin($Window)
        if ($MediaPlayer) { 
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
            $ImageTimer.Stop()
            if ($MediaPlayer) { $MediaPlayer.Stop(); $MediaPlayer.Close() }
            try {
                if ($null -ne $script:OriginalMuteState) {
                    [Audio]::Mute = $script:OriginalMuteState
                }
            } catch { }
        }
    })

    $Window.ShowDialog() | Out-Null
} catch { Write-Log "FATAL ERROR: $_" }
#endregion
