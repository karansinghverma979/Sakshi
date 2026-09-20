# 👁️ SAKSHI: Repository Behavioral Directives & Engineering Invariants

## 🏛️ System Identity & Philosophy
**Sakshi (साक्षी // The Witness)** is an autonomous, hardware-accelerated disciplinary supervisor and cognitive sentry engineered for Windows 11. It combats digital distraction, cognitive entropy, and procrastination through unescapable, high-velocity behavioral interventions.

Sakshi follows a strict decoupled, modular architecture:
1. **The Host (Sakshi)**: Serves as the overarching platform, orchestrator, and registry of behavioral supervisors.
2. **Modules (`Modules/<ModuleName>/`)**: Independent, sovereign disciplinary modules engineered for specific interventions:
   - `Death` (v1.0.0): AMOLED countdown lockdown & keyboard hook (.NET 9 WPF).
   - `Overviews` (v2.0.0): Instant AI Overview sentry & full-screen enforcement (.NET 9 WinExe).
   - `Apex` (v3.0.0): DirectX GPU-accelerated Virtual Desktop & Z-Order switchboard HUD (.NET 9 WPF).
   - `Spark` (v4.0.0): Sub-10ms native Rust thought capture HUD & Markdown stream (Rust LLVM).
   - `Drift`, `Posture`, `Sentry`: Reserved upcoming supervisors.

---

## ⚡ Core Engineering Invariants

### 1. 🛑 Zero-Daemon Footprint Invariant (0 MB RAM / 0% CPU)
- Never create or permit persistent 24/7 background daemon loops or idle tray polling watchdogs that sit in memory.
- All scheduled time-based triggers must leverage native **Windows Task Scheduler** with **Sleep-Skip** enabled (`StartWhenAvailable = $false`).
- Idle resource consumption must remain strictly **0 MB RAM** and **0.0% CPU**. Processes spin up instantly on trigger, enforce their intervention, and terminate completely upon acknowledgment.

### 2. 🚀 Standalone Single-File Binary Invariant (`~/.local/bin`)
- All compiled executable modules must deploy as standalone, self-contained single-file binaries directly into `~/.local/bin/` (e.g., `~/.local/bin/Death.exe`, `~/.local/bin/Spark.exe`).
- Do not rely on intermediate wrapper scripts (`.cmd`, `.bat`) when direct binary execution via `%PATH%` is available.
- Disable debug symbols in release builds (`<DebugType>none</DebugType>` in .NET, `strip = true` in Rust) to ensure zero `.pdb` residue.

### 3. 🛡️ Unescapable Focus & Lockdown Sovereignty
- Fullscreen intervention windows must be hardware-accelerated WPF (DirectX), topmost, borderless, and maximized.
- Must suppress standard window management bypasses:
  - Taskbar suppression (`ShowInTaskbar="False"`).
  - Win32 Low-Level Keyboard Hook (`WH_KEYBOARD_LL`) blocking system escape sequences (`Win`, `Alt+Tab`, `Alt+F4`, `Ctrl+Esc`, `Apps` key) during countdown.
  - Multi-virtual-desktop tracking via COM `IVirtualDesktopManager`.

### 4. 🌐 Universal Relative & Portable Paths
- Never hardcode absolute user directory paths (e.g. `C:\Users\<username>\...`) into source code, scripts, configurations, or documentation.
- Always use relative paths (`./`, `../`) or dynamic environment variables (`~/.local/bin`, `%USERPROFILE%`, `[Environment]::GetFolderPath(...)`).

### 5. 🧹 Mandatory 4-Step Post-Work Cleanup Sweep
Before concluding any modification or build task:
1. **Process Sweep**: Terminate build servers (`dotnet build-server shutdown`).
2. **Cache Purge**: Remove intermediate compilation folders (`bin/`, `obj/`) from source control.
3. **Scratch Eradication**: Remove temporary testing scripts and logs.
4. **Pristine Audit**: Run `git status` to ensure zero untracked residue.
