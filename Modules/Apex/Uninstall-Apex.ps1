<#
    .SYNOPSIS
        SAKSHI // APEX - Uninstall and Teardown Script
        MODULE: Modules/Apex/Uninstall-Apex.ps1
        COMPATIBILITY: Windows PowerShell 5.1 & PowerShell 7+
#>

[CmdletBinding()]
param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   ⚡ SAKSHI // APEX - UNINSTALL INTERFACE" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# 1. Remove Start Menu Shortcut
$StartMenuDir = [Environment]::GetFolderPath('Programs')
$ShortcutPath = Join-Path $StartMenuDir "Apex.lnk"
if (Test-Path $ShortcutPath) {
    Remove-Item $ShortcutPath -Force
    Write-Host " [REMOVED] Shortcut eradicated: $ShortcutPath" -ForegroundColor Green
}

# 2. Remove Binary from ~/.local/bin
$BinExe = Join-Path $env:USERPROFILE ".local\bin\Apex.exe"
if (Test-Path $BinExe) {
    Remove-Item $BinExe -Force
    Write-Host " [REMOVED] Binary deleted: $BinExe" -ForegroundColor Green
}

Write-Host "`n[OK] Apex module successfully uninstalled." -ForegroundColor Green

if (-not $NonInteractive) {
    Write-Host ""
    $restart = Read-Host "Would you like to restart Windows Explorer now to clean up cached hotkeys? (y/N)"
    if ($restart -and ($restart.Trim() -eq "y" -or $restart.Trim() -eq "yes")) {
        Write-Host "Refreshing Windows Explorer shell..." -ForegroundColor Cyan
        Stop-Process -Name explorer -Force
        Write-Host "[OK] Explorer restarted." -ForegroundColor Green
    }
}
