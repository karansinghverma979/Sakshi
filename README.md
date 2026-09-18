# <strong><a href="https://git.io/typing-svg"><img src="https://readme-typing-svg.herokuapp.com?font=Impact&weight=900&size=50&duration=2500&pause=500&color=FF4500&center=true&vCenter=true&width=800&height=80&lines=☠️+MEMENTO+MORI+☠️;⌚+REMEMBER+THAT+YOU+MUST+DIE+⌚;⌛+YOUR+DAYS+ARE+NUMBERED+⌛" alt="Memento Mori" /></a></strong>

<p align="center">
  <img src="https://img.shields.io/badge/CORE-.NET%209%20WPF-512BD4?style=for-the-badge&logo=dotnet&logoColor=white" alt=".NET 9"/>
  <img src="https://img.shields.io/badge/MEMORY-0%20MB%20IDLE-brightgreen?style=for-the-badge" alt="0 MB Idle"/>
  <img src="https://img.shields.io/badge/LATENCY-%3C40ms%20INSTANT-red?style=for-the-badge" alt="Latency"/>
  <img src="https://img.shields.io/badge/STANDALONE-~%2F.local%2Fbin-blue?style=for-the-badge" alt="Path"/>
  <img src="https://img.shields.io/badge/PLATFORM-WINDOWS%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Platform"/>
</p>

---

> [!IMPORTANT]
> **"Memento Mori. Remember that you must die."**
> An autonomous, hardware-accelerated disciplinary enforcement system engineered for Windows 11. It combats cognitive entropy and digital distraction through unescapable, high-velocity *Memento Mori* lockdowns with zero background daemon overhead.

---

## 👁️ System Architecture & Workflow

The system operates on a decoupled, zero-overhead architecture. Windows Task Scheduler acts as the native 0-RAM kernel clock, while the standalone compiled **Death** module delivers a sub-40ms fullscreen takeover.

```text
┌───────────────────────────────────────────────────────────┐
│              Windows Task Scheduler (Kernel Clock)        │
│  - Task: Death (or custom)                                │
│  - Interval: Configurable (e.g. 15, 17, 20, 30, 45, 60m)  │
│  - Idle Footprint: 0 MB RAM / 0% CPU                      │
│  - Sleep Skip: Missed triggers while asleep are ignored   │
└─────────────────────────────┬─────────────────────────────┘
                              │ Scheduled repetition OR manual CLI `Death`
                              ▼
┌───────────────────────────────────────────────────────────┐
│             Death.exe (~/.local/bin/Death.exe)            │
│                                                           │
│  1. 4-Tier Media Freeze: Pauses YouTube, Spotify, VLC     │
│  2. WASAPI Audio Takeover: Low-level session mute         │
│  3. In-Memory PCM Synth: Calibrated 1800/1500Hz tick-tock │
│  4. DirectX OLED Lockdown: Topmost, borderless fullscreen │
│  5. Anti-Escape & Desktop Snap: IVirtualDesktopManager    │
│  6. Release: 1 resonant chime, quote unlock, unmute audio │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
              Process exits -> RAM drops back to 0 MB
```

---

## 🎨 Visual Interface & Atmosphere

<img width="1600" height="1200" alt="d1" src="https://github.com/user-attachments/assets/abb654f9-9194-4336-9ddb-afa2e9f5d3ac" />

> [!TIP]
> The lockdown window uses rich aesthetics designed to command attention and feel premium:
> * **Deep Dark Backdrop**: Pure `#000000` solid background with a high-contrast focus state.
> * **Drop-Shadow Header Glow**: Pulsating red typography (`💀MEMENTO MORI💀`) driven by a Storyboard animation shifting the blur radius between `20` and `60` dynamically.
> * **Urgency Display**: Center-staged timer fading from dark maroon to blood red as the clock winds down.
> * **Glow Button Style**: Fades in a custom drop-shadow button featuring your personalized study quote.

<img width="1600" height="1200" alt="d2" src="https://github.com/user-attachments/assets/2c97923b-adb2-46f4-82be-328e06b04c59" />

---

## 🛠️ Technology Stack & Mechanisms

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Runtime Core** | **.NET 9 (WPF)** | Standalone single-file binary (`Death.exe`) compiled for `win-x64` with sub-40ms startup. |
| **Media Freeze** | **WinRT GSMTC + Win32** | 4-tier media pause (GSMTC, `WM_APPCOMMAND`, `VK_MEDIA_PLAY_PAUSE`, and `VK_SPACE`) pausing browsers, Spotify, and VLC. |
| **Audio Isolation** | **WASAPI COM Interop** | Low-level Core Audio endpoint enumeration muting background apps while exempting internal audio. |
| **Sound Synthesis** | **Win32 Multimedia (PCM)** | Synthesizes mechanical clock ticks directly in memory; volume calibrated subtly below ambient audio. |
| **Chime Release** | **Single Resonant Chime** | Pure 1200Hz single-tone chime signaling session unlock. |
| **Anti-Escape** | **COM Desktop Manager** | Uses `IVirtualDesktopManager` to follow active virtual desktops and enforce topmost focus without flicker. |
| **Scheduler** | **Windows Task Scheduler** | Native repetition trigger eliminating persistent 24/7 background daemon processes. |

---

## 📁 Repository Structure

```text
C:\Users\karan\Void\Sakshi\
├── Modules/
│   └── Death/                        # 💀 Core Death Module Source
│       ├── Death.csproj              # .NET 9 WPF project definition
│       ├── app.manifest              # PerMonitorV2 high-DPI scaling manifest
│       ├── App.xaml / App.xaml.cs    # App entry, CLI flags & single-instance mutex
│       ├── MainWindow.xaml / .cs     # OLED black UI, animations, focus enforcement
│       ├── AudioEngine.cs            # WASAPI COM, GSMTC pause, PCM wave synth
│       ├── The Whistle of Death.mp3  # Embedded ambient background audio
│       ├── Death.cmd                 # CMD shell wrapper for synchronous terminal calls
│       ├── Install-Death.ps1         # 🛠️ Builds Death.exe & registers Death task
│       └── Uninstall-Death.ps1       # 🧹 Eradicates scheduled task, processes, and binaries
│
├── Sakshi.ps1                        # 🧠 Future Master Orchestrator (Standby Blueprint)
├── .gitignore                        # Git rules (ignores bin/, obj/, dist/, logs)
└── README.md                         # Documentation
```

---

## 🚀 Installation & Registration

Run the deployment script from PowerShell:

```powershell
.\Modules\Death\Install-Death.ps1
```

Or pass parameters directly for non-interactive automated deployment:

```powershell
.\Modules\Death\Install-Death.ps1 -TaskName "Death" -IntervalMinutes 30 -Quote "KEEP CALM AND STUDY HARD." -NonInteractive
```

### What the installer does:
1. **Pre-checks**: Verifies .NET 9 SDK, source code, and target directories.
2. **Path Setup**: Ensures `~/.local/bin` is in User `PATH`.
3. **Pre-actions**: Terminates active instances, purges old binaries, and cleans previous tasks.
4. **Build**: Compiles `Death.exe` into a single-file binary at `~/.local/bin/Death.exe`.
5. **Scheduler**: Registers the task with **Sleep Skip** (`StartWhenAvailable = $false`) consuming **0 MB RAM** while idle. The quote is manifested directly as an action parameter (`--quote "..."`), requiring **zero** disk text files.

---

## 💻 Standalone Command Line Usage

Since `~/.local/bin` is in `$env:PATH`, you can launch the Death module anytime from any terminal:

```powershell
# Display CLI help manual
Death --help
Death -h

# Launch default 60-second lockdown
Death

# Quick 3-second smoke test
Death --test

# Launch with a custom duration (e.g. 15 seconds)
Death --seconds 15

# Launch with an on-the-fly custom quote
Death --quote "STAY DISCIPLINED. NO EXCUSES."
```

---

## 🧹 Complete Deregistration & Purge

To completely remove the scheduled task, halt processes, and purge installed binaries:

```powershell
.\Modules\Death\Uninstall-Death.ps1
```

To preserve the compiled `Death.exe` binary in `~/.local/bin/` while removing the automatic schedule:

```powershell
.\Modules\Death\Uninstall-Death.ps1 -KeepBinary
```

---

*   **Architect:** Karan Singh Verma
*   **System Version:** 4.0.0 (Native .NET 9 Standalone Release)
