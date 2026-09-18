# 👁️ Sakshi: Master Release Roadmap & Engineering Index

This document serves as the living release index, engineering roadmap, and version ledger for the **Sakshi (साक्षी // The Witness)** ecosystem.

---

## 🏛️ System Invariants & Core Governance

1. **Zero-Daemon Footprint**:
   - Idle background polling loops are strictly prohibited.
   - Idle RAM must remain **0 MB**; idle CPU must remain **0.0%**.
   - Scheduling is handled natively by Windows Task Scheduler with Sleep-Skip (`StartWhenAvailable = $false`).
2. **Modular Architecture**:
   - Each module lives in `Modules/<ModuleName>/` with independent build files and sovereign documentation.
   - Modules must compile to standalone single-file executables in `~/.local/bin/`.
3. **Unescapable Disciplinary Focus**:
   - Fullscreen interventions use hardware acceleration, topmost z-order, taskbar icon suppression, and low-level keyboard hook interception.

---

## 📝 Release Changelog & Version Index

| Version | Status | Release Dossier | Primary Milestones Delivered |
| :--- | :--- | :--- | :--- |
| **`v1.0.0`** | **`Active / Production`** | [`Release-1.md`](Release-1.md) | Decoupled modular architecture; standalone .NET 9 Death engine deployed to `~/.local/bin/Death.exe`; 0-RAM Task Scheduler; low-level keyboard hook (`WH_KEYBOARD_LL`); taskbar icon suppression; 4-tier media freeze & WASAPI session isolation. |
| **`v2.0.0`** | **`Active / Production`** | [`Release-2.md`](Release-2.md) | **Overviews Module**: Instant full-screen Google AI Overview sentry; native `Ctrl+Alt+O` Windows Explorer shortcut (0 MB idle RAM / 0% CPU); Win32 `SW_MAXIMIZE` full-screen enforcement; complete eradication of legacy `g.cmd`; synchronized distribution triad (`Overviews_SelfContained_Setup.ps1`, `Overviews_SelfContained_Setup.exe`, `Overviews_SelfContained.exe`) with SmartScreen MOTW bypass. |
| **`v3.0.0`** | **`Active / Production`** | [`Release-3.md`](Release-3.md) | **Apex Module**: DirectX GPU-accelerated Virtual Desktop & Z-Order (Topmost) Controller; native `Ctrl+Alt+A` Windows Explorer shortcut (0 MB idle RAM / 0% CPU); native COM `IVirtualDesktopManager` discovery; 1-minute inactivity auto-destruct; System Inviolability Shield. |
| **`vNext`**  | `Future Roadmap`          | *Unscheduled*                 | Active-sensing orchestrator, Drift foreground task supervisor, and posture ergonomics. |

---

## 🤝 Module Development & Contribution Protocol

1. **Branching Model**:
   - Develop features on dedicated branches (`feature/<module-name>` or `fix/<issue>`).
2. **Compilation Standard**:
   ```powershell
   dotnet publish Modules/<ModuleName>/<ModuleName>.csproj -c Release -r win-x64 --no-self-contained -p:PublishSingleFile=true -o "$HOME\.local\bin"
   ```
3. **Release Dossier Standard**:
   - Every production milestone must have an immutable `Release-<N>.md` engineering specification.
   - The active development stage must be captured in `Release-<N+1>.md`.
   - `Release.md` must be synchronously maintained as the index.
