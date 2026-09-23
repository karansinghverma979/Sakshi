# 👁️ SAKSHI: Repository Architecture & Engineering Invariants

## 🏛️ System Identity & Philosophy
**Sakshi (साक्षी // The Witness)** is an architectural blueprint, concept incubator, and umbrella registry for Windows 11 cognitive governance and distraction-free desktop computing.

### Ecosystem State
All active disciplinary intervention modules have graduated from this incubator and are maintained in dedicated sovereign repositories:
1. **Death** (`karansinghverma979/Death`): AMOLED countdown lockdown (.NET 9 WPF).
2. **Overviews** (`karansinghverma979/Overviews`): Instant AI Overview sentry (.NET 9 WinExe).
3. **Apex** (`karansinghverma979/Apex`): DirectX GPU-accelerated Virtual Desktop & Z-Order switchboard (.NET 9 WPF).
4. **Spark** (`karansinghverma979/Spark`): Sub-10ms native Rust thought capture HUD & Markdown stream (Rust LLVM).

This repository is reserved as a template, umbrella index, and naming anchor for future system-wide platform synthesis.

---

## ⚡ Core Engineering Invariants

### 1. 🛑 Zero-Daemon Footprint Invariant (0 MB RAM / 0% CPU)
- Never create or permit persistent 24/7 background daemon loops or idle tray polling watchdogs that sit in memory.
- All scheduled time-based triggers must leverage native **Windows Task Scheduler** with **Sleep-Skip** enabled (`StartWhenAvailable = $false`).
- Idle resource consumption must remain strictly **0 MB RAM** and **0.0% CPU**. Processes spin up instantly on trigger, enforce their intervention, and terminate completely upon acknowledgment.

### 2. 🚀 Standalone Single-File Binary Invariant (`~/.local/bin`)
- All compiled executable modules in this ecosystem deploy as standalone, self-contained single-file binaries directly into `~/.local/bin/` (e.g., `Death.exe`, `Spark.exe`).
- Do not rely on intermediate wrapper scripts (`.cmd`, `.bat`) when direct binary execution via `%PATH%` is available.
- Disable debug symbols in release builds (`<DebugType>none</DebugType>` in .NET, `strip = true` in Rust) to ensure zero `.pdb` residue.

### 3. 🌐 Universal Relative & Portable Paths
- Never hardcode absolute user directory paths (e.g. `C:\Users\<username>\...`) into source code, scripts, configurations, or documentation.
- Always use relative paths (`./`, `../`) or dynamic environment variables (`~/.local/bin`, `%USERPROFILE%`, `[Environment]::GetFolderPath(...)`).

### 4. 🧹 Pristine Repository Discipline
- Keep this index repository clean of temporary build artifacts, scratch scripts, or uncommitted files.
- All future sub-modules or experimental prototypes must follow the sovereign decoupling pattern before reaching production.
