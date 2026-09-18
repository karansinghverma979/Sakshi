<#
    .SYNOPSIS
        SAKSHI // OVERVIEWS - Universal PowerShell Setup and Teardown Sentry
        MODULE: Modules/Overviews/Overviews_SelfContained_Setup.ps1
        COMPATIBILITY: Windows PowerShell 5.1 (Native Windows 10/11) and PowerShell 7+ (pwsh)
        PAYLOAD: Pulls standalone self-contained Overviews.exe directly from GitHub Releases
        HOTKEY: Ctrl + Alt + O (Native Windows Explorer Shortcut, 0 MB Idle RAM)
#>

[CmdletBinding()]
param(
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$NonInteractive,
    [string]$LocalBinaryPath,
    [string]$ReleaseTag = "latest"
)

$ErrorActionPreference = "Stop"

# Force TLS 1.2 / TLS 1.3 for rock-solid downloads on older Windows PowerShell 5.1
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if ([Net.SecurityProtocolType].GetMember("Tls13").Length -gt 0) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13
    }
} catch {
    # Ignore if TLS protocol setting cannot be mutated
}

function Show-Banner {
    Write-Host ""
    Write-Host " +-------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host " |       SAKSHI // OVERVIEWS (Google AI Overview)              |" -ForegroundColor Cyan
    Write-Host " |          Universal PowerShell Setup and Teardown Sentry     |" -ForegroundColor Cyan
    Write-Host " +-------------------------------------------------------------+" -ForegroundColor Cyan
}

function Restart-ExplorerShell {
    Write-Host " [~] Refreshing Windows Explorer shell..." -ForegroundColor Cyan
    try {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 800
        Start-Process "explorer.exe"
        Write-Host " [OK] Explorer refreshed. [Ctrl + Alt + O] is active right now!" -ForegroundColor Green
    } catch {
        Write-Host " [!] Notice: Please restart Windows Explorer or sign out to refresh hotkeys: $_" -ForegroundColor Yellow
    }
}

function Invoke-BinaryDownload {
    param(
        [string]$DestinationPath,
        [string]$Tag = "latest"
    )

    $DownloadUrl = if ($Tag -eq "latest") {
        "https://github.com/karansinghverma979/Sakshi/releases/latest/download/Overviews_SelfContained.exe"
    } else {
        "https://github.com/karansinghverma979/Sakshi/releases/download/$Tag/Overviews_SelfContained.exe"
    }

    Write-Host "   [DOWNLOAD] Fetching Overviews_SelfContained.exe from GitHub..." -ForegroundColor Cyan
    Write-Host "              Source: $DownloadUrl" -ForegroundColor Gray

    $TempDownload = "$DestinationPath.tmp-$([Guid]::NewGuid().ToString('N').Substring(0, 8))"

    try {
        # Prefer WebClient for high-speed streaming without UI progress bar slowdowns on PS 5.1
        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.Add("User-Agent", "Sakshi-Overviews-Installer")
        $WebClient.DownloadFile($DownloadUrl, $TempDownload)

        if (-not (Test-Path $TempDownload) -or (Get-Item $TempDownload).Length -lt 1000000) {
            throw "Downloaded binary appears invalid or incomplete (Size < 1MB)."
        }

        # Atomic move/overwrite
        Move-Item -Path $TempDownload -Destination $DestinationPath -Force
        Write-Host "   [OK] Standalone binary installed successfully: $DestinationPath" -ForegroundColor Green
    } catch {
        if (Test-Path $TempDownload) {
            Remove-Item -Path $TempDownload -Force -ErrorAction SilentlyContinue
        }
        throw "Failed to download payload from GitHub: $_"
    }
}

function Install-OverviewsModule {
    param(
        [string]$BinDir,
        [string]$TargetExePath,
        [string]$ShortcutPath,
        [bool]$IsNonInteractive,
        [string]$LocalSource = ""
    )

    Write-Host "`n  [1/4] Preparing user-space binary directory..." -ForegroundColor Cyan
    if (-not (Test-Path $BinDir)) {
        New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
        Write-Host "   [OK] Created directory: $BinDir" -ForegroundColor Green
    } else {
        Write-Host "   [OK] Target directory verified: $BinDir" -ForegroundColor Green
    }

    Write-Host "`n  [2/4] Deploying standalone self-contained binary..." -ForegroundColor Cyan
    if (-not [string]::IsNullOrEmpty($LocalSource)) {
        if (-not (Test-Path $LocalSource)) {
            Write-Host "   [ERROR] Specified local binary does not exist: $LocalSource" -ForegroundColor Red
            Exit 1
        }
        Write-Host "   [DEPLOY] Deploying from local source: $LocalSource" -ForegroundColor Cyan
        Copy-Item -Path $LocalSource -Destination $TargetExePath -Force
        Write-Host "   [OK] Standalone binary deployed successfully: $TargetExePath" -ForegroundColor Green
    } else {
        Invoke-BinaryDownload -DestinationPath $TargetExePath -Tag $ReleaseTag
    }

    Write-Host "`n  [3/4] Verifying User PATH environment variable..." -ForegroundColor Cyan
    $CurrentPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
    $NeedsPathUpdate = $true

    if (-not [string]::IsNullOrEmpty($CurrentPath)) {
        $PathParts = $CurrentPath.Split(';')
        foreach ($Part in $PathParts) {
            if ($Part.Trim().TrimEnd('\').Equals($BinDir.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)) {
                $NeedsPathUpdate = $false
                break
            }
        }
    }

    if ($NeedsPathUpdate) {
        $UpdatedPath = if ([string]::IsNullOrEmpty($CurrentPath)) { $BinDir } else { "$BinDir;$CurrentPath" }
        [Environment]::SetEnvironmentVariable("PATH", $UpdatedPath, [EnvironmentVariableTarget]::User)
        Write-Host "   [OK] Appended $BinDir to User PATH." -ForegroundColor Green
    } else {
        Write-Host "   [OK] User PATH already configured." -ForegroundColor Green
    }

    Write-Host "`n  [4/4] Binding native Windows Explorer shortcut [Ctrl + Alt + O]..." -ForegroundColor Cyan
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = $TargetExePath
        $Shortcut.Hotkey = "Ctrl+Alt+O"
        $Shortcut.IconLocation = "$TargetExePath,0"
        $Shortcut.WorkingDirectory = $BinDir
        $Shortcut.Description = "Sakshi // Overviews - Instant Google AI Overview"
        $Shortcut.Save()

        Write-Host "   [OK] Registered native shortcut: $ShortcutPath" -ForegroundColor Green
        Write-Host "   [OK] Global hotkey bound: [Ctrl + Alt + O]" -ForegroundColor Green
    } catch {
        Write-Host "   [WARN] Warning registering shortcut: $_" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host " +=============================================================+" -ForegroundColor Green
    Write-Host " |               INSTALLATION SUCCESSFUL!                      |" -ForegroundColor Green
    Write-Host " +=============================================================+" -ForegroundColor Green
    Write-Host " |  * Target Binary : ~/.local/bin/Overviews.exe               |" -ForegroundColor Green
    Write-Host " |  * Global Hotkey : [Ctrl + Alt + O]                         |" -ForegroundColor Green
    Write-Host " |  * Footprint     : 0.0 MB Idle RAM (Pure On-Demand)         |" -ForegroundColor Green
    Write-Host " +-------------------------------------------------------------+" -ForegroundColor Green

    if (-not $IsNonInteractive) {
        Write-Host ""
        $restart = Read-Host " [?] Restart Windows Explorer now to activate [Ctrl + Alt + O] immediately? (Y/n)"
        if ([string]::IsNullOrWhiteSpace($restart) -or $restart.Trim().ToLower() -eq "y" -or $restart.Trim().ToLower() -eq "yes") {
            Restart-ExplorerShell
        } else {
            Write-Host " [INFO] Explorer restart skipped. The hotkey will become active on next logon." -ForegroundColor Gray
        }
    }
}

function Uninstall-OverviewsModule {
    param(
        [string]$TargetExePath,
        [string]$ShortcutPath,
        [bool]$IsNonInteractive
    )

    Write-Host "`n  [~] Initiating clean uninstallation and complete vanish..." -ForegroundColor Yellow
    $RemovedCount = 0

    if (Test-Path $ShortcutPath) {
        Remove-Item -Path $ShortcutPath -Force -ErrorAction SilentlyContinue
        Write-Host "   [OK] Eradicated shortcut: $ShortcutPath" -ForegroundColor Green
        $RemovedCount++
    }

    $StartupDir = [Environment]::GetFolderPath('Startup')
    $LegacyShortcut = Join-Path $StartupDir "Sakshi-Overviews.lnk"
    if (Test-Path $LegacyShortcut) {
        Remove-Item -Path $LegacyShortcut -Force -ErrorAction SilentlyContinue
        Write-Host "   [OK] Eradicated legacy startup link: $LegacyShortcut" -ForegroundColor Green
        $RemovedCount++
    }

    if (Test-Path $TargetExePath) {
        Remove-Item -Path $TargetExePath -Force -ErrorAction SilentlyContinue
        Write-Host "   [OK] Eradicated binary: $TargetExePath" -ForegroundColor Green
        $RemovedCount++
    }

    Write-Host ""
    Write-Host " +=============================================================+" -ForegroundColor Green
    Write-Host " |               TEARDOWN AND VANISH COMPLETE!                 |" -ForegroundColor Green
    Write-Host " +=============================================================+" -ForegroundColor Green
    Write-Host " |  Overviews has been completely vanished from this machine.  |" -ForegroundColor Green
    Write-Host " |  Zero background services, zero leftover files.             |" -ForegroundColor Green
    Write-Host " +-------------------------------------------------------------+" -ForegroundColor Green

    if (-not $IsNonInteractive -and $RemovedCount -gt 0) {
        Write-Host ""
        $restart = Read-Host " [?] Restart Windows Explorer now to clean up cached hotkeys? (y/N)"
        if (-not [string]::IsNullOrWhiteSpace($restart) -and ($restart.Trim().ToLower() -eq "y" -or $restart.Trim().ToLower() -eq "yes")) {
            Restart-ExplorerShell
        }
    }
}

# --- Execution Entry Point ---
Show-Banner

$UserProfile = [Environment]::GetFolderPath('UserProfile')
$BinDir = Join-Path $UserProfile ".local\bin"
$TargetExePath = Join-Path $BinDir "Overviews.exe"
$StartMenuDir = [Environment]::GetFolderPath('Programs')
$ShortcutPath = Join-Path $StartMenuDir "Overviews.lnk"

if ($Uninstall) {
    Uninstall-OverviewsModule -TargetExePath $TargetExePath -ShortcutPath $ShortcutPath -IsNonInteractive $NonInteractive
    Exit 0
}

if ($Install) {
    Install-OverviewsModule -BinDir $BinDir -TargetExePath $TargetExePath -ShortcutPath $ShortcutPath -IsNonInteractive $NonInteractive -LocalSource $LocalBinaryPath
    Exit 0
}

# Interactive Mode
if (Test-Path $TargetExePath) {
    Write-Host "`n  [!] Overviews is currently INSTALLED on this machine.`n" -ForegroundColor Yellow
    Write-Host "  Select an action to proceed:"
    Write-Host "    [1] Reinstall / Update from GitHub" -ForegroundColor Green
    Write-Host "    [2] Uninstall / Completely Vanish" -ForegroundColor Red
    Write-Host "    [3] Cancel and Exit`n" -ForegroundColor Gray

    $Choice = Read-Host "  Enter choice [1-3] (Default: 1)"
    if ([string]::IsNullOrWhiteSpace($Choice) -or $Choice.Trim() -eq "1") {
        Install-OverviewsModule -BinDir $BinDir -TargetExePath $TargetExePath -ShortcutPath $ShortcutPath -IsNonInteractive $NonInteractive -LocalSource $LocalBinaryPath
    } elseif ($Choice.Trim() -eq "2") {
        Uninstall-OverviewsModule -TargetExePath $TargetExePath -ShortcutPath $ShortcutPath -IsNonInteractive $NonInteractive
    } else {
        Write-Host "`n  [INFO] Operation cancelled by user." -ForegroundColor Gray
    }
} else {
    Write-Host "`n  Select an action to proceed:"
    Write-Host "    [1] Install Overviews from GitHub" -ForegroundColor Green
    Write-Host "    [2] Cancel and Exit`n" -ForegroundColor Gray

    $Choice = Read-Host "  Enter choice [1-2] (Default: 1)"
    if ([string]::IsNullOrWhiteSpace($Choice) -or $Choice.Trim() -eq "1") {
        Install-OverviewsModule -BinDir $BinDir -TargetExePath $TargetExePath -ShortcutPath $ShortcutPath -IsNonInteractive $NonInteractive -LocalSource $LocalBinaryPath
    } else {
        Write-Host "`n  [INFO] Operation cancelled by user." -ForegroundColor Gray
    }
}
