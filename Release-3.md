# 👁️ Sakshi v3.0.0 — Sovereign Engineering Specification

- **Product**: Sakshi (साक्षी // The Witness)
- **Milestone**: Version 3.0.0 (Production Release)
- **Date**: 2026-09-19
- **Architect**: Karan Singh Verma
- **Flagship Module**: Apex (DirectX Virtual Desktop & Z-Order Controller) v2.0.0

---

## 🎯 Executive Overview

**Sakshi v3.0.0** incorporates **Apex**, a high-performance, DirectX hardware-accelerated Virtual Desktop and Z-Order (`HWND_TOPMOST`) switchboard HUD engineered for Windows 11. Built strictly adhering to Sakshi's **Zero-Daemon Footprint Invariant (0 MB idle RAM / 0% CPU)**, Apex provides a high-speed, native global summon (`Ctrl+Alt+A`) that immediately opens an AMOLED pitch-black switchboard HUD.

Apex enables instant window pinning (`[📌 TOPMOST]`), COM-based virtual desktop tracking (`IVirtualDesktopManager`), background process exclusion blacklists, bulk unpinning, and graceful/force process management—terminating automatically upon dismissal (`Esc` / `✕`) or after 60 seconds of inactivity.

---

## ⚡ Delivered Capabilities & Architectural Upgrades

### 1. Sovereign Module Architecture (`Modules/Apex/`)
- Fully integrated into the decoupled Sakshi modular architecture under `Modules/Apex/`.
- Deployed as a high-performance, standalone single-file binary directly into `~/.local/bin/Apex.exe`.
- Includes sovereign deployment and teardown scripts (`Install-Apex.ps1`, `Uninstall-Apex.ps1`).

### 2. Strict Zero-Daemon Footprint (0 MB Idle RAM / 0.0% CPU)
- 100% on-demand execution. Zero persistent background processes or tray polling hooks.
- Summoned globally via native Windows Explorer shortcut key (**`Ctrl + Alt + A`**), executed by the operating system shell with zero background memory cost.
- **1-Minute Inactivity Auto-Kill**: Monitors intentional keyboard and mouse interactions; automatically terminates after 60 seconds of inactivity to guarantee 0 lingering RAM or CPU.

### 3. Native COM Virtual Desktop Discovery & Depth Control
- Direct COM negotiation via `IVirtualDesktopManager` across Windows 10 and Windows 11 (21H2–24H2/25H2+).
- Focus-safe window depth manipulation (`SetWindowPos` with `SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOSIZE | SWP_NOOWNERZORDER`) that never steals keyboard focus or forces desktop switches.
- Single-instance teleportation: if summoned from another desktop, immediately teleports to the active workspace.

### 4. System Inviolability Shield
- Hardcoded safeguard in `MainWindow.xaml.cs` explicitly protecting Sakshi automation overlays (`MEMENTO MORI`, `Sakshi`) from accidental unpinning, closing, killing, or blacklisting.

---

## 📊 Empirical Telemetry Benchmarks

| Metric | Target Specification | Empirical Telemetry |
| :--- | :--- | :--- |
| **Idle RAM Footprint** | Strictly 0.0 MB | **0.0 MB** (Zero daemons) |
| **Idle CPU Consumption** | Strictly 0.0% | **0.0%** |
| **Cold Launch Execution**| $\le 50\text{ ms}$ | **<45 ms** |
| **Global Shortcut Key**  | Native Windows Explorer | **`Ctrl + Alt + A`** |
| **Auto-Destruct Inactivity** | 60 Seconds | **Self-destruct on idle** |

---

## 🎮 Controls & Operating Modes

| Trigger / Command | Context | Action / Result |
| :--- | :--- | :--- |
| **`Ctrl + Alt + A`** | Global (Anywhere) | Summons Apex HUD switchboard natively via Windows Explorer (0 MB RAM). |
| **`Apex`** | CLI / Run Box | Launches the Apex HUD switchboard on current desktop. |
| **`[⏏ Unpin All]`** | Apex HUD Header | Safely resets all user-pinned windows across all virtual desktops. |
| **Right-Click Card** | Apex HUD | Summons AMOLED context menu (Pin, Blacklist, Graceful Close, Force Kill). |
| **`Esc` / `✕`** | Apex HUD | Dismisses HUD and terminates process completely (0 MB RAM). |
