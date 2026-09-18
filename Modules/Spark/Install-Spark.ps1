<#
    .SYNOPSIS
        SAKSHI // SPARK - Ephemeral Thought Capture HUD
        MODULE: Modules/Spark/Install-Spark.ps1
        COMPATIBILITY: Windows PowerShell 5.1 & PowerShell 7+
        TARGET: Standalone Native Rust Binary (~/.local/bin/Spark.exe)
        HOTKEY: Ctrl + Alt + S (Native Windows Explorer Shortcut, 0 MB Idle RAM)
#>

[CmdletBinding()]
param(
    [string]$Hotkey = "Ctrl+Alt+S",
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   ⚡ SAKSHI // SPARK - DEPLOYMENT INTERFACE" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# 1. Dependency & Environment Verification
Write-Host "`n[1/4] Verifying Toolchain Dependencies..." -ForegroundColor Cyan
$CargoCmd = Get-Command "cargo" -ErrorAction SilentlyContinue
if (-not $CargoCmd) {
    Write-Host " [CRITICAL ERROR] cargo not found in PATH." -ForegroundColor Red
    Write-Host " Please install Rust toolchain from https://rustup.rs" -ForegroundColor Yellow
    Exit 1
}
$RustVer = & rustc --version
Write-Host " [OK] Rust Toolchain Detected: $RustVer" -ForegroundColor Green

$BinDir = Join-Path $env:USERPROFILE ".local\bin"
if (-not (Test-Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

# 2. Build Optimized Release Binary
Write-Host "`n[2/4] Compiling Standalone Native Rust Binary..." -ForegroundColor Cyan
Push-Location $PSScriptRoot
try {
    & cargo build --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host " [ERROR] Spark compilation failed." -ForegroundColor Red
        Exit 1
    }
} finally {
    Pop-Location
}

$CompiledExe = Join-Path $PSScriptRoot "target\release\spark.exe"
$TargetExe = Join-Path $BinDir "Spark.exe"

if (-not (Test-Path $CompiledExe)) {
    Write-Host " [ERROR] Compiled binary not found at $CompiledExe" -ForegroundColor Red
    Exit 1
}

Copy-Item $CompiledExe $TargetExe -Force
Write-Host " [OK] Standalone binary deployed: $TargetExe" -ForegroundColor Green

# 3. Verify User PATH Environment Variable
Write-Host "`n[3/4] Verifying User PATH..." -ForegroundColor Cyan
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
    Write-Host " [OK] Appended $BinDir to User PATH." -ForegroundColor Green
} else {
    Write-Host " [OK] User PATH already configured." -ForegroundColor Green
}

# 4. Configure Native Windows Explorer Shortcut
Write-Host "`n[4/4] Binding Native Explorer Shortcut [$Hotkey]..." -ForegroundColor Cyan
$StartMenuDir = [Environment]::GetFolderPath('Programs')
$ShortcutPath = Join-Path $StartMenuDir "Spark.lnk"

try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetExe
    $Shortcut.Hotkey = $Hotkey
    $Shortcut.IconLocation = "$TargetExe,0"
    $Shortcut.WorkingDirectory = $BinDir
    $Shortcut.Description = "Sakshi // Spark - Ephemeral Thought Capture HUD"
    $Shortcut.Save()

    Write-Host " [OK] Native Explorer shortcut registered: $ShortcutPath" -ForegroundColor Green
    Write-Host " [OK] Hotkey bound: [$Hotkey]" -ForegroundColor Green
} catch {
    Write-Host " [!] Warning creating shortcut: $_" -ForegroundColor Yellow
}

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   🎉 SPARK SUCCESSFULLY DEPLOYED!" -ForegroundColor Green
Write-Host "   • Local Binary: ~/.local/bin/Spark.exe" -ForegroundColor Gray
Write-Host "   • Native Hotkey: $Hotkey (0 MB Idle RAM / 0% CPU)" -ForegroundColor Gray
Write-Host "   • Storage Sink: ~/.gemini/Spark.md" -ForegroundColor Gray
Write-Host "=======================================================" -ForegroundColor Cyan

if (-not $NonInteractive) {
    Write-Host ""
    $restart = Read-Host "Would you like to restart Windows Explorer now to activate [$Hotkey] immediately? (Y/n)"
    if ([string]::IsNullOrWhiteSpace($restart) -or $restart.Trim() -eq "y" -or $restart.Trim() -eq "yes") {
        Write-Host "Refreshing Windows Explorer shell..." -ForegroundColor Cyan
        Stop-Process -Name explorer -Force
        Write-Host "[OK] Explorer restarted. [$Hotkey] is active right now!" -ForegroundColor Green
    } else {
        Write-Host "[i] Explorer restart skipped. The shortcut key will become active on next logon." -ForegroundColor Gray
    }
}
