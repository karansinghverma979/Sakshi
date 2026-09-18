# 👁️ Sakshi v2.0.0 — Sovereign Engineering Specification

- **Product**: Sakshi (साक्षी // The Witness)
- **Milestone**: Version 2.0.0 (Production Release)
- **Date**: 2026-09-18
- **Architect**: Karan Singh Verma
- **Flagship Module**: Overviews (Google AI Overview & Instant Search Sentry) v1.0.0

---

## 🎯 Executive Overview

**Sakshi v2.0.0** introduces **Overviews**, a pure on-demand, hardware-accelerated cognitive query sentry and instant AI overview summoner engineered for Windows 11. Built strictly adhering to Sakshi's **Zero-Daemon Footprint Invariant (0 MB idle RAM / 0% CPU)**, Overviews provides a high-speed, native global summon (`Ctrl+Alt+O`) that instantly launches a clean, maximized Google AI Overview webapp window on the user's active desktop.

All background daemons, tray watchers, and polling loops are permanently eliminated. Execution is handled natively by Windows Explorer, cold-booting in **<15ms**, enforcing the full-screen maximized WebApp presentation via Win32 `SW_MAXIMIZE`, and terminating immediately.

---

## ⚡ Delivered Capabilities & Architectural Upgrades

### 1. Sovereign Module Architecture (`Modules/Overviews/`)
- Encapsulated within the decoupled Sakshi modular architecture under `Modules/Overviews/`.
- Deployed as a high-performance, standalone single-file binary directly into `~/.local/bin/Overviews.exe`.
- Completely eradicated legacy scripts (`g.cmd`) in favor of the unified, high-performance native desktop binary.

### 2. Strict Zero-Daemon Footprint (0 MB Idle RAM / 0.0% CPU)
- 100% on-demand execution. Zero persistent background processes or tray polling hooks.
- Triggered globally via native Windows Explorer shortcut key (**`Ctrl + Alt + O`**), executed by the operating system shell with zero background memory cost.

### 3. Enforced Full-Screen Immersion & Current Desktop Isolation
- Launches via Microsoft Edge's native standalone mode (`--app`).
- Enforces instant full-screen maximized state via Win32 `ShowWindow(hWnd, SW_MAXIMIZE)`.
- Guarantees clean immersion with cursor focused in Google's search box.
- Eliminates Chromium PWA single-instance workspace jumping; always opens on the user's current virtual desktop.

### 4. GitHub Distribution Triad & SmartScreen MOTW Bypass
To eliminate Windows Defender SmartScreen browser download friction (which triggers warning banners on unknown `.exe` downloads), Sakshi v2.0.0 ships with a synchronized distribution triad:
1. **`Overviews_SelfContained_Setup.ps1`** (~13 KB): Universal PowerShell setup and teardown script compatible with **both Windows PowerShell 5.1 and PowerShell 7+**. Pulls `Overviews_SelfContained.exe` directly from GitHub releases via TLS 1.2/1.3 without browser MOTW tagging, configures User `PATH`, registers `Ctrl+Alt+O`, and provides a 1-click vanish teardown.
2. **`Overviews_SelfContained_Setup.exe`** (~25.7 MB): Offline, single-file GUI/CLI wizard embedding the full payload for offline installations without .NET SDK requirements.
3. **`Overviews_SelfContained.exe`** (~12.3 MB): Direct portable single-file binary for manual installation or distribution.

---

## 📊 Empirical Telemetry Benchmarks

| Metric | Target Specification | Empirical Telemetry |
| :--- | :--- | :--- |
| **Idle RAM Footprint** | Strictly 0.0 MB | **0.0 MB** (Zero daemons) |
| **Idle CPU Consumption** | Strictly 0.0% | **0.0%** |
| **Cold Launch Execution**| $\le 25\text{ ms}$ | **<15 ms** |
| **Global Shortcut Key**  | Native Windows Explorer | **`Ctrl + Alt + O`** |
| **Window Presentation**  | Maximized Full Screen | **`SW_MAXIMIZE (3)`** |

---

## 🎮 Controls & Operating Modes

| Trigger / Command | Context | Action / Result |
| :--- | :--- | :--- |
| **`Ctrl + Alt + O`** | Global (Anywhere) | Summons maximized Google AI Overview natively via Windows Explorer (0 MB RAM). |
| **`Overviews`** | CLI / Run Box | Launches the maximized Google AI Overview home window. |
| **`Overviews "<query>"`** | CLI / Terminal | Directly opens the AI Overview for `<query>` in maximized webapp mode. |
| **`Overviews_SelfContained_Setup --uninstall`** | CLI / Terminal | Completely uninstalls and vanishes Overviews with 0 residue via executable wizard. |
| **`Overviews_SelfContained_Setup.ps1 -Uninstall`** | PowerShell 5.1 / 7+ | Completely uninstalls and vanishes Overviews with 0 residue via script. |
