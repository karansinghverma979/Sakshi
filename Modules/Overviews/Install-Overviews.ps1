<#
    .SYNOPSIS
        OVERVIEWS MODULE - Instant Google AI Overview Sentry
        MODULE: Modules/Overviews/Install-Overviews.ps1
        COMPATIBILITY: Windows PowerShell 5.1 & PowerShell 7+
        TARGET: Standalone Native .NET 9 Binary (~/.local/bin/Overviews.exe)
        HOTKEY: Ctrl + Alt + O (Native Windows Explorer Shortcut, 0 MB Idle RAM)
#>

[CmdletBinding()]
param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   👁️ SAKSHI // OVERVIEWS - DEPLOYMENT INTERFACE" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# 1. Dependency & Environment Verification
Write-Host "`n[1/5] Verifying System Dependencies..." -ForegroundColor Cyan
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

# 2. Publish Local Overviews.exe (Framework-Dependent, ~164 KB)
Write-Host "`n[2/5] Compiling Workstation Binary (164 KB)..." -ForegroundColor Cyan
$OverviewsProj = Join-Path $PSScriptRoot "Overviews.csproj"
$PublishDir = Join-Path $PSScriptRoot "publish"

& dotnet publish $OverviewsProj -c Release -r win-x64 --no-self-contained -p:PublishSingleFile=true -o $BinDir
if ($LASTEXITCODE -ne 0) {
    Write-Host " [ERROR] Workstation compilation failed." -ForegroundColor Red
    Exit 1
}
Write-Host " [OK] Local binary published: $BinDir\Overviews.exe" -ForegroundColor Green

# 3. Publish Self-Contained Payload for Setup Embedding & Standalone Release (~12 MB)
Write-Host "`n[3/5] Compiling Self-Contained Payload for Setup & Standalone..." -ForegroundColor Cyan
if (-not (Test-Path $PublishDir)) {
    New-Item -ItemType Directory -Path $PublishDir -Force | Out-Null
}

& dotnet publish $OverviewsProj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:PublishTrimmed=true -p:TrimMode=partial -o $PublishDir
if ($LASTEXITCODE -ne 0) {
    Write-Host " [ERROR] Self-contained payload compilation failed." -ForegroundColor Red
    Exit 1
}
Write-Host " [OK] Self-contained payload generated: $PublishDir\Overviews.exe" -ForegroundColor Green

$DistDir = Join-Path $PSScriptRoot "dist"
if (-not (Test-Path $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
}

# Export standalone self-contained release binary
Copy-Item -Path (Join-Path $PublishDir "Overviews.exe") -Destination (Join-Path $DistDir "Overviews_SelfContained.exe") -Force
Write-Host " [OK] Standalone release binary generated: $DistDir\Overviews_SelfContained.exe" -ForegroundColor Green

# 4. Build Universal Self-Contained Setup Wizard (~25 MB) & Copy Universal Script
Write-Host "`n[4/5] Building Universal Setup Wizard & Packaging Script..." -ForegroundColor Cyan
$SetupProj = Join-Path $PSScriptRoot "Setup\Setup.csproj"

& dotnet publish $SetupProj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:PublishTrimmed=true -p:TrimMode=partial -o $DistDir
if ($LASTEXITCODE -ne 0) {
    Write-Host " [ERROR] Universal setup compilation failed." -ForegroundColor Red
    Exit 1
}
Write-Host " [OK] Universal setup binary built: $DistDir\Overviews_SelfContained_Setup.exe" -ForegroundColor Green

# Package universal setup script
$SetupScriptSource = Join-Path $PSScriptRoot "Overviews_SelfContained_Setup.ps1"
if (Test-Path $SetupScriptSource) {
    Copy-Item -Path $SetupScriptSource -Destination (Join-Path $DistDir "Overviews_SelfContained_Setup.ps1") -Force
    Write-Host " [OK] Universal setup script packaged: $DistDir\Overviews_SelfContained_Setup.ps1" -ForegroundColor Green
}

# 5. Configure Native Windows Explorer Shortcut (Ctrl + Alt + O)
Write-Host "`n[5/5] Binding Native Explorer Shortcut [Ctrl + Alt + O]..." -ForegroundColor Cyan
$StartMenuDir = [Environment]::GetFolderPath('Programs')
$ShortcutPath = Join-Path $StartMenuDir "Overviews.lnk"
$TargetExe = Join-Path $BinDir "Overviews.exe"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $TargetExe
$Shortcut.Hotkey = "Ctrl+Alt+O"
$Shortcut.IconLocation = "$TargetExe,0"
$Shortcut.WorkingDirectory = $BinDir
$Shortcut.Description = "Sakshi // Overviews - Instant Google AI Overview"
$Shortcut.Save()
Write-Host " [OK] Native Explorer shortcut registered: $ShortcutPath" -ForegroundColor Green
Write-Host " [OK] Hotkey bound: [Ctrl + Alt + O]" -ForegroundColor Green

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   🎉 OVERVIEWS V2.0.0 SUCCESSFULLY DEPLOYED!" -ForegroundColor Green
Write-Host "   • Local Binary:         ~/.local/bin/Overviews.exe" -ForegroundColor Gray
Write-Host "   • Distribution Triad:   Modules/Overviews/dist/" -ForegroundColor Cyan
Write-Host "     1. Standalone Binary: Overviews_SelfContained.exe" -ForegroundColor Gray
Write-Host "     2. Offline Setup EXE: Overviews_SelfContained_Setup.exe" -ForegroundColor Gray
Write-Host "     3. Universal Script:  Overviews_SelfContained_Setup.ps1" -ForegroundColor Gray
Write-Host "   • Native Hotkey:        Ctrl + Alt + O (0 MB Idle RAM / 0% CPU)" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Cyan

# Explorer Refresh prompt for immediate hotkey activation
if (-not $NonInteractive) {
    Write-Host ""
    $restart = Read-Host "Would you like to restart Windows Explorer now to activate [Ctrl+Alt+O] immediately? (Y/n)"
    if ([string]::IsNullOrWhiteSpace($restart) -or $restart.Trim() -eq "y" -or $restart.Trim() -eq "yes") {
        Write-Host "Refreshing Windows Explorer shell..." -ForegroundColor Cyan
        Stop-Process -Name explorer -Force
        Write-Host "[OK] Explorer restarted. [Ctrl + Alt + O] is active right now!" -ForegroundColor Green
    } else {
        Write-Host "[i] Explorer restart skipped. The shortcut key will become active on next logon." -ForegroundColor Gray
    }
}
