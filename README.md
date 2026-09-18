# 👁️ SAKSHI (साक्षी - The Witness)

<p align="center">
  <img src="https://img.shields.io/badge/PLATFORM-WINDOWS%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Platform"/>
  <img src="https://img.shields.io/badge/ARCHITECTURE-.NET%209%20MODULAR-512BD4?style=for-the-badge&logo=dotnet&logoColor=white" alt=".NET 9 Modular"/>
  <img src="https://img.shields.io/badge/IDLE%20RAM-0%20MB-brightgreen?style=for-the-badge" alt="0 MB Idle RAM"/>
  <img src="https://img.shields.io/badge/ACTIVE%20MODULES-1%20PRODUCTION-orange?style=for-the-badge" alt="Active Modules"/>
  <img src="https://img.shields.io/badge/LICENSE-MIT-blue?style=for-the-badge" alt="MIT License"/>
</p>

---

> [!IMPORTANT]
> **"The unexamined machine is not worth computing on."**
> **Sakshi (साक्षी // The Witness)** is an autonomous, hardware-accelerated cognitive supervisor and behavioral governance framework engineered for Windows 11. It eliminates digital distraction, context drift, and subconscious procrastination through decoupled, zero-overhead behavioral intervention modules.

---

## 🏛️ Modular System Architecture

Sakshi enforces strict separation of concerns. The host repository governs platform orchestration, module lifecycle, and release specifications, while each disciplinary intervention runs as a dedicated, sovereign engine inside `Modules/`:

```text
┌───────────────────────────────────────────────────────────┐
│                 SAKSHI PLATFORM (THE WITNESS)             │
│   - Behavioral governance, module lifecycle & scheduling  │
│   - Zero-daemon invariant (0 MB idle RAM / 0% CPU)        │
└─────────────────────────────┬─────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│  Modules/Death/  │ │  Modules/Drift/  │ │ Modules/Posture/ │
│  (Memento Mori)  │ │ (Context Guard)  │ │ (Ergonomics)     │
│  STATUS: ACTIVE  │ │ STATUS: RESERVED │ │ STATUS: RESERVED │
└──────────────────┘ └──────────────────┘ └──────────────────┘
```

---

## 📦 Disciplinary Modules Ledger

| Module | Version | Status | Primary Capability | Documentation |
| :--- | :--- | :--- | :--- | :--- |
| **💀 Death** | **v1.0.0** | **`Active / Production`** | Unescapable AMOLED countdown lockdown, low-level Win32 keyboard hook (`WH_KEYBOARD_LL`), 4-tier media freeze, WASAPI audio isolation, and 0-RAM Task Scheduler trigger. | [**Death Module Dossier ➔**](Modules/Death/README.md) |
| **👁️ Overviews** | **v2.0.0** | **`Active / Production`** | Instant Google AI Overview summoner, `Ctrl+Alt+O` native Explorer shortcut (0 MB RAM), Win32 `SW_MAXIMIZE` full-screen enforcement, and standalone setup installer & vanisher. | [**Overviews Module Dossier ➔**](Modules/Overviews/README.md) |
| **⚡ Apex** | **v3.0.0** | **`Active / Production`** | DirectX GPU-accelerated Virtual Desktop & Z-Order (Topmost) switchboard HUD, `Ctrl+Alt+A` native Explorer shortcut (0 MB RAM), COM `IVirtualDesktopManager` discovery, and 1-minute auto-destruct. | [**Apex Module Dossier ➔**](Modules/Apex/README.md) |
| **🧭 Drift** | — | `Planned` | Real-time foreground task misalignment and tab-paralysis detection. | *Reserved* |
| **🧘 Posture** | — | `Planned` | Micro-break physical ergonomics and screen strain supervisor. | *Reserved* |
| **🛡️ Sentry** | — | `Planned` | Win32 AFK tracker and idle-aware intervention coordinator. | *Reserved* |

---

## ⚡ Active Module Spotlight: Death (Memento Mori)

The flagship active module currently shipped in **Sakshi v1.0.0** is the standalone **Death** engine:

* **Hardware-Accelerated OLED UI**: Sub-40ms DirectX WPF fullscreen takeover.
* **Overwatch Escape Suppression**: Taskbar icon eradicated (`ShowInTaskbar="False"`), Win32 keyboard hook intercepts `Win`, `Alt+Tab`, `Alt+F4`, and `Ctrl+Esc`.
* **Zero-RAM Hardware Scheduler**: Integrated directly with Windows Task Scheduler (`0 MB` idle RAM, `0%` idle CPU, Sleep-Skip enabled).
* **Audio Synthesis & Media Freeze**: WinRT GSMTC media pausing with custom in-memory synthesized mechanical clock ticks.

👉 **For full technical specifications, screenshots, and audio architecture, visit the [Death Module README](Modules/Death/README.md).**

---

## 🚀 Quick Start (Death Module Deployment)

### 1. One-Stroke Automated Installation
From PowerShell in the repository root:

```powershell
# Interactive deployment
.\Modules\Death\Install-Death.ps1

# Automated silent deployment (Runs every 30 mins with custom quote)
.\Modules\Death\Install-Death.ps1 -TaskName "Death" -IntervalMinutes 30 -Quote "KEEP CALM AND STUDY HARD." -NonInteractive
```

### 2. Standalone CLI Usage
The installer compiles and deploys the binary to `~/.local/bin/Death.exe` (automatically added to `$env:PATH`):

```powershell
# Run default 60s lockdown
Death

# Run quick 3-second smoke test
Death --test

# Run custom countdown
Death --seconds 15

# Launch with dynamic custom quote
Death --quote "DISCIPLINE EQUALS FREEDOM."
```

---

## 📁 Repository Structure

```text
Sakshi/
├── .gitignore                    # Hardened Git exclusions
├── GEMINI.md                     # Autonomous repository guidelines & invariants
├── LICENSE                       # MIT License
├── README.md                     # Master platform documentation
├── Release.md                    # Master release roadmap & version ledger
├── Release-1.md                  # Sakshi v1.0.0 Engineering Dossier (Death)
├── Release-2.md                  # Sakshi v2.0.0 Engineering Dossier (Overviews)
├── Release-3.md                  # Sakshi v3.0.0 Engineering Dossier (Apex)
├── Sakshi.ps1                    # Platform supervisory orchestrator (standby)
└── Modules/
    ├── Death/                    # 💀 Death (Memento Mori) Disciplinary Engine
    │   ├── README.md             # Sovereign module documentation
    │   ├── Death.csproj          # .NET 9 WPF single-file project configuration
    │   ├── app.manifest          # PerMonitorV2 DPI awareness manifest
    │   ├── App.xaml / .cs        # Entry point, single-instance mutex & CLI flags
    │   ├── MainWindow.xaml / .cs # AMOLED interface, keyboard hook & animations
    │   ├── AudioEngine.cs        # WASAPI isolation, GSMTC pause & PCM synth
    │   ├── The Whistle of Death.mp3 # Embedded atmospheric background audio
    │   ├── Install-Death.ps1     # Automated compiler & Task Scheduler installer
    │   ├── Uninstall-Death.ps1   # Task deregistration and cleanup script
    │   └── assets/               # Real UI screenshots (countdown & unlocked states)
    ├── Overviews/                # 👁️ Overviews (Google AI Overview Sentry)
    │   ├── README.md             # Sovereign module documentation
    │   ├── Overviews.csproj      # .NET 9 WinExe single-file project configuration
    │   ├── app.manifest          # PerMonitorV2 DPI awareness manifest
    │   ├── Program.cs            # Zero-daemon instant WebApp launcher (<15ms)
    │   ├── Install-Overviews.ps1 # Workstation compiler & triad packager
    │   ├── Uninstall-Overviews.ps1 # Clean teardown & vanish script
    │   ├── Overviews_SelfContained_Setup.ps1 # Universal PS5.1/7+ GitHub fetcher
    │   ├── Setup/                # Self-contained offline setup wizard project
    │   └── assets/               # Custom multi-res application icons (.ico / .png)
    └── Apex/                     # ⚡ Apex (Virtual Desktop & Z-Order Controller)
        ├── README.md             # Sovereign module documentation
        ├── Apex.csproj           # .NET 9 WinExe single-file project configuration
        ├── App.xaml / .cs        # Entry point & single-instance message broker
        ├── MainWindow.xaml / .cs # AMOLED switchboard HUD, geometry memory & search
        ├── Install-Apex.ps1      # Workstation compiler & shortcut installer
        ├── Uninstall-Apex.ps1    # Clean teardown & vanish script
        ├── Core/                 # Blacklist, COM VirtualDesktop & Win32 window manager
        └── Assets/               # Application icons & visual showcase screenshots
```

---

## 📝 Release Dossiers & Engineering Specifications

Sakshi tracks every version milestone through structured engineering dossiers:

* **[`Release-1.md`](Release-1.md)**: Sakshi v1.0.0 — Standalone Death Engine, 0-RAM Task Scheduler, Low-Level Hook Lockdown.
* **[`Release-2.md`](Release-2.md)**: Sakshi v2.0.0 — Overviews Module, Native `Ctrl+Alt+O` Shell Shortcut, GitHub Distribution Triad.
* **[`Release-3.md`](Release-3.md)**: Sakshi v3.0.0 — Apex Module, Native `Ctrl+Alt+A` Z-Order & Desktop Switchboard HUD.
* **[`Release.md`](Release.md)**: Master release roadmap, contributor guide, and cross-release index.

---

*   **Architect:** Karan Singh Verma
*   **System Version:** Sakshi v3.0.0 (Modular Platform Release)
