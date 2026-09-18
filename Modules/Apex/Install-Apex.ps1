<#
    .SYNOPSIS
        SAKSHI // APEX - DirectX GPU-Accelerated Virtual Desktop & Z-Order Controller
        MODULE: Modules/Apex/Install-Apex.ps1
        COMPATIBILITY: Windows PowerShell 5.1 & PowerShell 7+
        TARGET: Standalone Native .NET 9 Binary (~/.local/bin/Apex.exe)
        HOTKEY: Ctrl + Alt + A (Native Windows Explorer Shortcut, 0 MB Idle RAM)
#>

[CmdletBinding()]
param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   ⚡ SAKSHI // APEX - DEPLOYMENT INTERFACE" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# 1. Dependency & Environment Verification
Write-Host "`n[1/4] Verifying System Dependencies..." -ForegroundColor Cyan
$DotnetCmd = Get-Command "dotnet" -ErrorAction SilentlyContinue
if (-not $DotnetCmd) {
    Write-Host " [CRITICAL ERROR] .NET SDK not found in PATH." -ForegroundColor Red
    Write-Host " Please install .NET 9 SDK (x64) from https://dotnet.microsoft.com/download" -ForegroundColor Yellow
    Exit 1
}
$DotnetVer = & dotnet --version
Write-Host " [OK] .NET SDK Detected: $DotnetVer" -ForegroundColor Green

$BinDir = Join-Path $env:USERPROFILE ".local\bin"
if (-not (Test-Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

# 2. Publish Local Apex.exe (~335 KB)
Write-Host "`n[2/4] Compiling Workstation Binary..." -ForegroundColor Cyan
$ApexProj = Join-Path $PSScriptRoot "Apex.csproj"

& dotnet publish $ApexProj -c Release -r win-x64 --no-self-contained -p:PublishSingleFile=true -o $BinDir
if ($LASTEXITCODE -ne 0) {
    Write-Host " [ERROR] Apex compilation failed." -ForegroundColor Red
    Exit 1
}
Write-Host " [OK] Local binary published: $BinDir\Apex.exe" -ForegroundColor Green

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

# 4. Configure Native Windows Explorer Shortcut (Ctrl + Alt + A)
Write-Host "`n[4/4] Binding Native Explorer Shortcut [Ctrl + Alt + A]..." -ForegroundColor Cyan
$StartMenuDir = [Environment]::GetFolderPath('Programs')
$ShortcutPath = Join-Path $StartMenuDir "Apex.lnk"
$TargetExe = Join-Path $BinDir "Apex.exe"

try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetExe
    $Shortcut.Hotkey = "Ctrl+Alt+A"
    $Shortcut.IconLocation = "$TargetExe,0"
    $Shortcut.WorkingDirectory = $BinDir
    $Shortcut.Description = "Sakshi // Apex - Virtual Desktop & Z-Order Controller"
    $Shortcut.Save()

    Write-Host " [OK] Native Explorer shortcut registered: $ShortcutPath" -ForegroundColor Green
    Write-Host " [OK] Hotkey bound: [Ctrl + Alt + A]" -ForegroundColor Green
} catch {
    Write-Host " [!] Warning creating shortcut: $_" -ForegroundColor Yellow
}

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   🎉 APEX SUCCESSFULLY DEPLOYED!" -ForegroundColor Green
Write-Host "   • Local Binary: ~/.local/bin/Apex.exe" -ForegroundColor Gray
Write-Host "   • Native Hotkey: Ctrl + Alt + A (0 MB Idle RAM / 0% CPU)" -ForegroundColor Gray
Write-Host "=======================================================" -ForegroundColor Cyan

# Explorer Refresh prompt for immediate hotkey activation
if (-not $NonInteractive) {
    Write-Host ""
    $restart = Read-Host "Would you like to restart Windows Explorer now to activate [Ctrl+Alt+A] immediately? (Y/n)"
    if ([string]::IsNullOrWhiteSpace($restart) -or $restart.Trim() -eq "y" -or $restart.Trim() -eq "yes") {
        Write-Host "Refreshing Windows Explorer shell..." -ForegroundColor Cyan
        Stop-Process -Name explorer -Force
        Write-Host "[OK] Explorer restarted. [Ctrl + Alt + A] is active right now!" -ForegroundColor Green
    } else {
        Write-Host "[i] Explorer restart skipped. The shortcut key will become active on next logon." -ForegroundColor Gray
    }
}
