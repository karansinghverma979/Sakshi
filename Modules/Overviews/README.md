# 👁️ Overviews — Google AI Overview & Instant Search Sentry

> **Module**: `Modules/Overviews`  
> **Ecosystem**: Sakshi (साक्षी // The Witness) — Release 2 (`v2.0.0`)  
> **Role**: Pure on-demand, full-screen Google AI Overview summoner & desktop sentry  
> **Binary**: `~/.local/bin/Overviews.exe`  
> **Global Shortcut**: `Ctrl + Alt + O` (Native Windows Explorer, 0 MB Idle RAM)  

---

## 🏛️ System Philosophy

**Overviews** is engineered to eliminate cognitive friction when querying knowledge during deep work. Instead of opening a full browser window with dozens of distracting tabs, toolbars, and bookmarks, pressing **`Ctrl + Alt + O`** instantly summons a clean, maximized, standalone Google AI Overview webapp window.

- **Zero-Daemon Invariant**: Strictly **0 MB idle RAM** and **0% idle CPU**. No persistent background processes or tray watchers.
- **Full-Screen Immersion**: Natively enforced full-screen maximized window (`SW_MAXIMIZE`) for instant focus.
- **Current Desktop Isolation**: Bypasses Chromium workspace teleportation bugs; always opens on your active display.
- **Single Keystroke Dismissal**: When done reading, tap `Ctrl + W` or `Alt + F4` to close and return instantly to your code.

---

## ⚡ Controls & Usage

| Trigger | Context | Behavior |
| :--- | :--- | :--- |
| **`Ctrl + Alt + O`** | Global (Anywhere) | Summons the maximized Google AI Overview window natively with 0 background RAM. |
| **`Overviews`** | CLI / Terminal | Launches the maximized Google AI Overview home window. |
| **`Overviews "<query>"`** | CLI / Terminal | Directly opens the Google AI Overview for `<query>` in maximized webapp mode. |

---

## 🛠️ Installation & Deployment Options

Sakshi v2.0.0 provides three distinct distribution channels in `dist/`:

### 1. Universal PowerShell One-Liner (Bypasses SmartScreen Popups)
Direct `.exe` browser downloads often trigger Microsoft Defender SmartScreen blue warning banners. To bypass this, execute the universal PowerShell setup script directly in terminal (compatible with **both Windows PowerShell 5.1 and PowerShell 7+**):

```powershell
# Directly run the setup script
irm https://raw.githubusercontent.com/karansinghverma979/Sakshi/main/Modules/Overviews/Overviews_SelfContained_Setup.ps1 | iex
```
Or run the local file:
```powershell
powershell -ExecutionPolicy Bypass -File .\Overviews_SelfContained_Setup.ps1
```
* Pulls `Overviews_SelfContained.exe` directly from GitHub releases via TLS 1.2/1.3 without browser MOTW tagging.
* Configures User `PATH` and registers native `Ctrl+Alt+O` shortcut in Start Menu.
* Provides clean interactive update and complete uninstallation/vanish options.

### 2. Universal Offline Setup Wizard (`Overviews_SelfContained_Setup.exe`)
For air-gapped or offline installations without PowerShell:
* Run `Overviews_SelfContained_Setup.exe`.
* Self-contained binary embedding the complete payload—no .NET SDK or runtime required.
* Includes interactive install, update, and complete teardown menus.

### 3. Portable Standalone Binary (`Overviews_SelfContained.exe`)
* Standalone executable (~12.3 MB) that can be placed anywhere or deployed via custom scripts.

### 4. Local Workstation Developer Fast-Path
```powershell
.\Install-Overviews.ps1
```
* Compiles `Overviews.exe` framework-dependent binary (~164 KB) directly to `~/.local/bin/Overviews.exe`.
* Generates all three release artifacts in `dist/`.
* Registers the native Windows Explorer shortcut (`Ctrl+Alt+O`) in Start Menu.

---

## 🧹 Complete Uninstallation & Vanish

To completely vanish Overviews from your machine (0 background services, 0 residue):
```powershell
# Via universal PowerShell script:
powershell -ExecutionPolicy Bypass -File .\Overviews_SelfContained_Setup.ps1 -Uninstall

# Or via the standalone executable wizard:
Overviews_SelfContained_Setup.exe --uninstall
```
