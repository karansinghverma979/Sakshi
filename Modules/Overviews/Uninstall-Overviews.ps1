<#
    .SYNOPSIS
        OVERVIEWS MODULE - Uninstall & Teardown Script
        MODULE: Modules/Overviews/Uninstall-Overviews.ps1
        COMPATIBILITY: Windows PowerShell 5.1 & PowerShell 7+
#>

[CmdletBinding()]
param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   👁️ SAKSHI // OVERVIEWS - UNINSTALL INTERFACE" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# 1. Remove Start Menu Shortcut
$StartMenuDir = [Environment]::GetFolderPath('Programs')
$ShortcutPath = Join-Path $StartMenuDir "Overviews.lnk"
if (Test-Path $ShortcutPath) {
    Remove-Item $ShortcutPath -Force
    Write-Host " [REMOVED] Shortcut eradicated: $ShortcutPath" -ForegroundColor Green
}

# 2. Remove Legacy Startup Shortcut if Present
$StartupDir = [Environment]::GetFolderPath('Startup')
$LegacyShortcut = Join-Path $StartupDir "Sakshi-Overviews.lnk"
if (Test-Path $LegacyShortcut) {
    Remove-Item $LegacyShortcut -Force
    Write-Host " [REMOVED] Legacy startup link eradicated: $LegacyShortcut" -ForegroundColor Green
}

# 3. Remove Binary from ~/.local/bin
$BinExe = Join-Path $env:USERPROFILE ".local\bin\Overviews.exe"
if (Test-Path $BinExe) {
    Remove-Item $BinExe -Force
    Write-Host " [REMOVED] Binary deleted: $BinExe" -ForegroundColor Green
}

Write-Host "`n[OK] Overviews module successfully uninstalled." -ForegroundColor Green

if (-not $NonInteractive) {
    Write-Host ""
    $restart = Read-Host "Would you like to restart Windows Explorer now to clean up cached hotkeys? (y/N)"
    if ($restart -and ($restart.Trim() -eq "y" -or $restart.Trim() -eq "yes")) {
        Write-Host "Refreshing Windows Explorer shell..." -ForegroundColor Cyan
        Stop-Process -Name explorer -Force
        Write-Host "[OK] Explorer restarted." -ForegroundColor Green
    }
}
