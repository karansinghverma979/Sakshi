# 👁️ SAKSHI (साक्षी // The Witness)

<p align="center">
  <img src="https://img.shields.io/badge/STATUS-RESERVED%20%2F%20INDEX-inactive?style=for-the-badge" alt="Status"/>
  <img src="https://img.shields.io/badge/ECOSYSTEM-WINDOWS%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Platform"/>
  <img src="https://img.shields.io/badge/ARCHITECTURE-DECOUPLED%20MICRO--ENGINES-512BD4?style=for-the-badge" alt="Decoupled Micro-Engines"/>
  <img src="https://img.shields.io/badge/STANDALONE%20REPOS-4%20PRODUCTION-brightgreen?style=for-the-badge" alt="Production Repositories"/>
  <img src="https://img.shields.io/badge/LICENSE-MIT-blue?style=for-the-badge" alt="MIT License"/>
</p>

---

> [!NOTE]
> **Repository Status: Architectural Blueprint & Umbrella Registry**
>
> Sakshi originally served as the incubator for Windows 11 cognitive governance and behavioral intervention utilities. **All active production modules have been graduated and decoupled into their own dedicated, sovereign GitHub repositories.**
>
> This repository is maintained as an **Index, Architectural Template, and Concept Anchor** for the ecosystem. It is not currently deployed in production. Active development and binary releases occur directly within the dedicated module repositories listed below.

---

## 🏛️ Ecosystem Architecture

Sakshi defines the overarching philosophy of the **zero-daemon invariant**: 0 MB idle RAM, 0% idle CPU, and instant on-demand execution via native Windows hotkeys and Task Scheduler triggers.

```text
┌─────────────────────────────────────────────────────────────┐
│                 SAKSHI (साक्षी // THE WITNESS)              │
│       Cognitive Governance Blueprint & Umbrella Index       │
│              [Status: Reserved / Incubator]                 │
└──────────────────────────────┬──────────────────────────────┘
                               │ Decoupled into Sovereign Repositories
         ┌─────────────────────┼─────────────────────┐
         ▼                     ▼                     ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│   💀 Death       │  │   👁️ Overviews    │  │   ⚡ Apex        │
│ Memento Mori     │  │ AI Search Sentry │  │ Desktop Switcher │
│ (Active / .NET)  │  │ (Active / .NET)  │  │ (Active / .NET)  │
└──────────────────┘  └──────────────────┘  └──────────────────┘
                               │
                               ▼
                      ┌──────────────────┐
                      │   ⚡ Spark        │
                      │ Thought HUD      │
                      │ (Active / Rust)  │
                      └──────────────────┘
```

---

## 📦 Sovereign Production Repositories

Each disciplinary tool originated within Sakshi and now lives as an independent, fully maintained open-source project:

| Tool | Focus & Capabilities | Tech Stack | Production Repository |
| :--- | :--- | :--- | :--- |
| **💀 Death** | Unescapable AMOLED countdown lockdown, low-level Win32 keyboard hook (`WH_KEYBOARD_LL`), 4-tier media freeze, WASAPI audio ticks, 0-RAM Task Scheduler trigger. | .NET 9 WPF | [**karansinghverma979/Death ➔**](https://github.com/karansinghverma979/Death) |
| **👁️ Overviews** | Instant Google AI Overview summoner, distraction-free search sentry, `Ctrl+Alt+O` shell shortcut, Win32 `SW_MAXIMIZE` enforcement, 0 MB idle RAM. | .NET 9 WinExe | [**karansinghverma979/Overviews ➔**](https://github.com/karansinghverma979/Overviews) |
| **⚡ Apex** | DirectX GPU-accelerated Virtual Desktop & Z-Order (Topmost) switchboard HUD, `Ctrl+Alt+A` shortcut, COM `IVirtualDesktopManager` discovery, auto-destruct. | .NET 9 WPF | [**karansinghverma979/Apex ➔**](https://github.com/karansinghverma979/Apex) |
| **⚡ Spark** | Sub-10ms native Rust ephemeral thought capture HUD, `Ctrl+Alt+S` shortcut, Void Black card, auto-bullet engine, atomic append-only Markdown stream. | Rust (LLVM) | [**karansinghverma979/Spark ➔**](https://github.com/karansinghverma979/Spark) |

---

## 🧭 Future Roadmap (Incubator Concepts)

Concepts reserved for future platform exploration:

* **🧭 Drift**: Foreground application context-drift and tab-paralysis detection.
* **🧘 Posture**: Micro-break physical ergonomics and screen strain supervisor.
* **🛡️ Sentry**: Win32 AFK tracker and idle-aware intervention coordinator.

---

## 📁 Repository Structure

```text
Sakshi/
├── .github/                      # Issue & PR Templates, OpenSSF CI Workflow
├── .gitattributes                # LF/CRLF normalization firewall
├── .gitignore                    # Hardened Git exclusions
├── GEMINI.md                     # Architectural principles & system invariants
├── LICENSE                       # MIT License
├── README.md                     # Master Ecosystem Index & Architecture Blueprint
└── SECURITY.md                   # OpenSSF coordinated vulnerability disclosure
```

---

## 📄 License & Governance

* **License**: [MIT License](LICENSE)
* **Author & Architect**: [Karan Singh Verma](https://github.com/karansinghverma979)
