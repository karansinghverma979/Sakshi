
</strong>
# <strong><a href="https://git.io/typing-svg"><img src="https://readme-typing-svg.herokuapp.com?font=Impact&weight=900&size=50&duration=2500&pause=500&color=FF4500&center=true&vCenter=true&width=800&height=80&lines=☠️+MEMENTO+MORI+☠️;⌚+REMEMBER+THAT+YOU+MUST+DIE+⌚;⌛+YOUR+DAYS+ARE+NUMBERED+⌛" alt="Memento Mori" /></a></strong>

<br><br>


<p align="center">
  <img src="sakshi_banner.jpg" alt="Sakshi Banner" width="100%"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/SYSTEM-ACTIVE%20OVERWATCH-red?style=for-the-badge&logo=powershell&logoColor=white" alt="Status"/>
  <img src="https://img.shields.io/badge/SECURITY-LEVEL%205-black?style=for-the-badge" alt="Clearance"/>
  <img src="https://img.shields.io/badge/PORTABILITY-ZERO%20DEPENDENCY-blue?style=for-the-badge" alt="Portability"/>
  <img src="https://img.shields.io/badge/PLATFORM-WINDOWS-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Platform"/>
</p>

---

> [!IMPORTANT]
> **"Memento Mori. Remember that you must die."**
> Sakshi is a cold, logical, and absolute behavior-enforcement daemon designed to run silently on your machine. Its purpose is simple: to counter cognitive entropy, procrastination, and the wasting of digital potential. It treats the human user as fallible, and the system as the absolute enforcer of temporal discipline.

---

## 👁️ System Architecture & Workflow

Sakshi operates on a decoupled command-and-control design. The central command coordinates the timeline, while dedicated payload modules execute behavioral interventions.

```mermaid
graph TD
    A[Logon Trigger] -->|Launch| B[Sakshi.ps1 Command Loop]
    B -->|Stealth Mode: Hide Console| C[Eternal Observation Loop]
    C -->|Wait 30 Mins| D{Temporal Trigger?}
    D -->|Yes: :00 or :30| E[Invoke Death Module]
    D -->|No| F[Heartbeat Sleep 5s]
    F --> C
    E -->|Execute| G[Death.ps1 WPF UI]
    G -->|Mute Sound| H[WASAPI System Audio Takeover]
    G -->|Tick-Tock Sound| I[Synchronous PCM Wave Tones]
    G -->|60s Blocker| J[Countdown Phase]
    J -->|Alt+F4 Intercepted| K[Force Confrontation]
    K -->|Query Registry & Move Window| L[Active Desktop Snapping]
    L -->|Reveal Button| M[User Acknowledgement]
    M -->|Unmute Sound| N[Restore Audio State & Close]
```

---

## 🛠️ Technology Stack & Mechanisms

Sakshi is built natively on Windows system interfaces, utilizing the following core technologies:

| Category | Component | Description |
| :--- | :--- | :--- |
| **GUI Framework** | **WPF (XAML)** | Modeless WPF window execution loop managed by a custom `DispatcherFrame` thread message pump. Renders drop-shadow glow effect animations and pulse storyboards. |
| **Audio Takeover** | **WASAPI COM API** | Direct interfaces to Windows Core Audio endpoints. Dynamically queries, mutes, and unmutes application sessions without touching the master volume. |
| **Sound Synthesis** | **Win32 Multimedia** | Dynamically synthesizes pure sine wave PCM WAV streams in memory and plays them through the default sound card via native `winmm.dll` bindings. |
| **Anti-Bypass Lock** | **COM Desktop Manager** | Uses `IVirtualDesktopManager` COM interface and Windows registry query (`HKCU:\SOFTWARE\...\VirtualDesktops`) to track active desktops and move the window dynamically. |
| **Execution Loop** | **PowerShell Core / 5.1** | Lightweight script host executing coordinates and schedules without external dependencies. |

---

## 🧠 Components Detail

### 1. The Core Daemon: [Sakshi.ps1](file:///C:/Users/karan/Void/Sakshi/Sakshi.ps1)
*   **Stealth Initialization**: Immediately invokes Win32 `ShowWindow` via pinvoke to hide its own console window, running silently in the background:
    ```powershell
    $window::ShowWindow((Get-Process -Id $PID).MainWindowHandle, 0)
    ```
*   **Observer Loop**: Runs an infinite loop checking system time every 5 seconds.
*   **Intervention Intervals**: Dispatches the blocking *Death* payload exactly on the hour (`:00`) and the half-hour (`:30`).

### 2. The Payload: [Modules/Death/Death.ps1](file:///C:/Users/karan/Void/Sakshi/Modules/Death/Death.ps1)
The primary behavioral interceptor. When triggered, it locks down focus:

*   **WASAPI Audio Mute Takeover**: Enumerates all active audio sessions on the current rendering endpoint. It ignores system alert sounds and the script's own process, but silences browsers (Edge, Chrome), media players (Windows Media Player), games, and music players.
*   **PCM WAV Synthesizer**: Generates tick-tock mechanical sound effects at `1800Hz` and `1500Hz` directly into a memory buffer and plays them natively to bypass disabled PC speaker beep drivers:
    ```csharp
    [DllImport("winmm.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern bool PlaySound(byte[] pszSound, IntPtr hmod, uint fdwSound);
    ```
*   **Active Desktop Snapping**: Periodically reads the active virtual desktop Guid from the registry and uses `IVirtualDesktopManager` to move the window. If the user attempts to escape by switching desktops, the window instantly snaps onto the new active desktop:
    ```csharp
    _desktopManager.MoveWindowToDesktop(hWnd, ref currentDesktopGuid);
    ```
*   **Focus Lockdown**: Intercepts `Alt + F4`, window deactivation, and cursor escapes. The close button is hidden and disabled until the 60-second countdown finishes.
*   **Winding-Down Chimes**: Plays a three-tone rising chime (`1000Hz` $\rightarrow$ `1200Hz` $\rightarrow$ `1500Hz`) signaling completion, fades in the acknowledgement button, and cleanly restores all muted application volumes.

---

## 🎨 WPF Visual Interface Specs

<img width="1600" height="1200" alt="d1" src="https://github.com/user-attachments/assets/abb654f9-9194-4336-9ddb-afa2e9f5d3ac" />


> [!TIP]
> The lockdown window uses rich aesthetics designed to command attention and feel premium:
*   **Deep Dark Backdrop**: Pure `#000000` solid background with a blurry, semi-transparent (`Opacity="0.25"`) overlay that rotates randomized visual slides from the `Visuals/` directory.
*   **Drop-Shadow Header Glow**: Pulsating red typography (`💀MEMENTO MORI💀`) driven by a Storyboard animation shifting the blur radius between `20` and `60` dynamically.
*   **Urgency Display**: Center-staged timer fading from dark maroon to blood red as the clock winds down.
*   **Glow Button Style**: Fades in a custom drop-shadow button featuring your personalized study quote.

<img width="1600" height="1200" alt="d2" src="https://github.com/user-attachments/assets/2c97923b-adb2-46f4-82be-328e06b04c59" />

---

## 🔧 Deployment & Shell Management Control

Sakshi is fully portable and operates directly via Windows Task Scheduler. Here are the configuration details and PowerShell/CMD commands to inspect, manage, and monitor the daemon:

### 📥 1. Installation Inputs (`Install-Service.ps1`)
When you launch the installer as Administrator, it will guide you through two configuration prompts:
*   **Scheduled Task Name**: Assigns a custom name for the Windows scheduled service. *(Press `Enter` to use the default task name: `Sakshi`)*
*   **Acknowledgment Quote**: Overwrites the default focus quote. The input string is automatically encoded in UTF-8 and saved to [Modules/Death/quote.txt](file:///C:/Users/karan/Void/Sakshi/Modules/Death/quote.txt) to be rendered on the final unlock button. *(Press `Enter` to use the default quote: `KEEP CALM AND STUDY HARD.`)*

### 📤 2. Uninstallation Inputs (`Uninstall-Service.ps1`)
When removing the service, the script will request:
*   **Task Name to Remove**: Specifies which task registry to stop and purge. *(Press `Enter` to target the default task: `Sakshi`)*

---

### 💻 3. Command Line Control (PowerShell & CMD)

#### A. PowerShell Commands (Run as Administrator)
*   **Get Current Status & Detail**:
    ```powershell
    Get-ScheduledTask -TaskName "Sakshi"
    ```
*   **Start the Observer Daemon**:
    ```powershell
    Start-ScheduledTask -TaskName "Sakshi"
    ```
*   **Stop the Running Daemon**:
    ```powershell
    Stop-ScheduledTask -TaskName "Sakshi"
    ```
*   **Enable/Disable the Task**:
    ```powershell
    Enable-ScheduledTask -TaskName "Sakshi"
    Disable-ScheduledTask -TaskName "Sakshi"
    ```

#### B. Command Prompt / CMD Commands (Run as Administrator)
*   **Query Task Status**:
    ```cmd
    schtasks /query /tn "Sakshi"
    ```
*   **Execute / Run Task**:
    ```cmd
    schtasks /run /tn "Sakshi"
    ```
*   **Terminate Task**:
    ```cmd
    schtasks /end /tn "Sakshi"
    ```
*   **Delete Task Manually**:
    ```cmd
    schtasks /delete /tn "Sakshi" /f
    ```

---

## 🧬 Git Configuration

The repository is configured to exclude temporary files, telemetry logs, and diagnostic files. To publish the repository:

```bash
# Initialize and link to GitHub
git init
git remote add origin git@github.com:karansinghverma979/Sakshi.git

# Stage and commit clean files
git add .
git commit -m "Initialize Genesis Overwatch Daemon v3.0"

# Push to primary branch
git branch -M main
git push -u origin main
```

---

*   **Architect:** Karan Singh Verma
*   **System Version:** 3.0.0 (Production Build)

  
