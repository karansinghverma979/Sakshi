<#
    .SYNOPSIS
        DEATH MODULE - Autonomous Disciplinary Overwatch Engine
        MODULE: Modules/Death/Install-Death.ps1
        ROLE: Deployment, Single-File Compilation & Windows Task Scheduler Registration
        TARGET: Standalone Native .NET 9 Binary (~/.local/bin/Death.exe)
        SCHEDULE: Native Windows Task Scheduler (0 MB Idle RAM, Sleep-Skip)

    .DESCRIPTION
        Self-contained deployment engine for the Death module.
        Builds the .NET 9 WPF single-file executable directly to ~/.local/bin/Death.exe
        and registers an autonomous recurring trigger in Windows Task Scheduler
        with zero persistent background memory footprint.
#>

[CmdletBinding()]
param(
    [Parameter()][string]$TaskName,
    [Parameter()][string]$Quote,
    [Parameter()][string]$IntervalMinutes,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

# --- 1. DISPLAY HEADER ---
Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   💀 DEATH MODULE - DEPLOYMENT INTERFACE" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# --- 2. PRE-CHECKS & ENVIRONMENT VERIFICATION ---
Write-Host "`n[1/5] Running System Pre-checks & Dependency Verification..." -ForegroundColor Cyan

# A. Verify .NET SDK
$DotnetCmd = Get-Command "dotnet" -ErrorAction SilentlyContinue
if (-not $DotnetCmd) {
    Write-Host " [CRITICAL ERROR] .NET SDK ('dotnet') not found in PATH." -ForegroundColor Red
    Write-Host " Please install .NET 9 SDK (x64) from https://dotnet.microsoft.com/download" -ForegroundColor Yellow
    Exit 1
}

$DotnetVersion = & dotnet --version
Write-Host " [OK] .NET SDK Detected: $DotnetVersion" -ForegroundColor Green

# B. Verify Source Project
$CsprojPath = Join-Path $PSScriptRoot "Death.csproj"
if (-not (Test-Path $CsprojPath)) {
    Write-Host " [CRITICAL ERROR] Project source not found: $CsprojPath" -ForegroundColor Red
    Exit 1
}
Write-Host " [OK] Source Project Located: $CsprojPath" -ForegroundColor Green

# C. Verify & Ensure Output Directory (~/.local/bin)
$BinDir = Join-Path $env:USERPROFILE ".local\bin"
if (-not (Test-Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
    Write-Host " [CREATED] Directory initialized: $BinDir" -ForegroundColor Yellow
} else {
    Write-Host " [OK] Target Directory Exists: $BinDir" -ForegroundColor Green
}

# D. Verify PATH contains ~/.local/bin
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$BinDir*") {
    Write-Host " [INFO] Adding $BinDir to User PATH for global CLI access..." -ForegroundColor Yellow
    try {
        [Environment]::SetEnvironmentVariable("Path", "$UserPath;$BinDir", "User")
        $env:Path = "$env:Path;$BinDir"
        Write-Host " [OK] User PATH updated successfully." -ForegroundColor Green
    } catch {
        Write-Host " [WARN] Could not update User PATH: $_" -ForegroundColor DarkGray
    }
}

# --- 3. CONFIGURATION & INPUT VALIDATION ---
Write-Host "`n[2/5] Configuring Intervention Parameters..." -ForegroundColor Cyan

$DefaultTaskName = "Death"
$DefaultQuote = "KEEP CALM AND STUDY HARD."
$DefaultInterval = 30

# A. Task Name Validation
if ([string]::IsNullOrWhiteSpace($TaskName)) {
    if ($NonInteractive) {
        $TaskName = $DefaultTaskName
    } else {
        $InputName = Read-Host "Enter Scheduled Task Name [Default: $DefaultTaskName]"
        $TaskName = if ([string]::IsNullOrWhiteSpace($InputName)) { $DefaultTaskName } else { $InputName.Trim() }
    }
}
if ($TaskName -notmatch '^[a-zA-Z0-9_\-]+$') {
    Write-Host " [WARN] Task name '$TaskName' contained special characters. Sanitizing to alphanumeric/dashes." -ForegroundColor Yellow
    $TaskName = ($TaskName -replace '[^a-zA-Z0-9_\-]', '')
    if ([string]::IsNullOrWhiteSpace($TaskName)) { $TaskName = $DefaultTaskName }
}

# B. Acknowledgment Quote Validation
if ([string]::IsNullOrWhiteSpace($Quote)) {
    if ($NonInteractive) {
        $Quote = $DefaultQuote
    } else {
        $InputQuote = Read-Host "Enter acknowledgment button quote [Default: $DefaultQuote]"
        $Quote = if ([string]::IsNullOrWhiteSpace($InputQuote)) { $DefaultQuote } else { $InputQuote.Trim() }
    }
}
$Quote = $Quote.Trim('"').Trim("'")
if ($Quote.Length -gt 250) {
    Write-Host " [WARN] Quote exceeds 250 chars. Truncating to fit OLED button cleanly." -ForegroundColor Yellow
    $Quote = $Quote.Substring(0, 250).Trim()
}

# C. Interval Validation (Supports any arbitrary positive integer)
$FinalInterval = $null
if (-not [string]::IsNullOrWhiteSpace($IntervalMinutes)) {
    if ($IntervalMinutes -match '^\d+$' -and [int]$IntervalMinutes -gt 0) {
        $FinalInterval = [int]$IntervalMinutes
    }
}

if ($null -eq $FinalInterval) {
    if ($NonInteractive) {
        $FinalInterval = $DefaultInterval
    } else {
        while ($null -eq $FinalInterval) {
            $InputInterval = Read-Host "Enter interval in minutes (e.g. 15, 17, 25, 30, 45, 60) [Default: $DefaultInterval]"
            if ([string]::IsNullOrWhiteSpace($InputInterval)) {
                $FinalInterval = $DefaultInterval
            } elseif ($InputInterval -match '^\d+$' -and [int]$InputInterval -gt 0) {
                $FinalInterval = [int]$InputInterval
            } else {
                Write-Host " [!] Invalid interval '$InputInterval'. Must be a positive integer." -ForegroundColor Yellow
            }
        }
    }
}

Write-Host " [CONFIG LOCKED]" -ForegroundColor Green
Write-Host "   - Task Identifier : $TaskName" -ForegroundColor White
Write-Host "   - Interval Repeat : Every $FinalInterval minutes" -ForegroundColor White
Write-Host "   - Button Quote    : `"$Quote`"" -ForegroundColor White

# --- 4. PRE-ACTION PROCESS PURGE & LOCK RELEASE ---
Write-Host "`n[3/5] Pre-Action Process & File Sweep..." -ForegroundColor Cyan

# Terminate active Death instances to allow file overwriting
Get-Process -Name "Death" -ErrorAction SilentlyContinue | ForEach-Object {
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    Write-Host " [PREACTION] Terminated running Death.exe (PID: $($_.Id))" -ForegroundColor Yellow
}

# Purge legacy lowercase death.exe if present
$LegacyExe = Join-Path $BinDir "death.exe"
if (Test-Path $LegacyExe) {
    try {
        Remove-Item -Path $LegacyExe -Force -ErrorAction SilentlyContinue
        Write-Host " [PURGED] Removed legacy artifact: $LegacyExe" -ForegroundColor DarkGray
    } catch { }
}

# Clean old scheduled task with this name if exists
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host " [CLEANED] Unregistered existing scheduled task '$TaskName'." -ForegroundColor Yellow
    } catch {
        Write-Host " [WARN] Existing task '$TaskName' could not be unregistered: $_" -ForegroundColor DarkGray
    }
}

# --- 5. COMPILATION & PACKAGING ENGINE (0 DISK I/O) ---
Write-Host "`n[4/5] Compiling Standalone Native .NET 9 WPF Executable..." -ForegroundColor Cyan

$TargetExe = Join-Path $BinDir "Death.exe"

try {
    # Compile Single-File Release Executable directly to ~/.local/bin/Death.exe
    $BuildOutput = & dotnet publish $CsprojPath -c Release -r win-x64 --no-self-contained -p:PublishSingleFile=true -o $BinDir 2>&1
    
    if (-not (Test-Path $TargetExe)) {
        throw "Compilation completed, but $TargetExe was not found.`nBuild Log:`n$($BuildOutput -join "`n")"
    }

    $CmdWrapper = Join-Path $PSScriptRoot "Death.cmd"
    if (Test-Path $CmdWrapper) {
        Copy-Item -Path $CmdWrapper -Destination (Join-Path $BinDir "Death.cmd") -Force
    }

    $ExeSizeMB = [math]::Round(((Get-Item $TargetExe).Length / 1MB), 2)
    Write-Host " [SUCCESS] Compiled successfully: $TargetExe ($ExeSizeMB MB)" -ForegroundColor Green
}
catch {
    Write-Host " [CRITICAL ERROR] Compilation failed: $_" -ForegroundColor Red
    Exit 1
}

# --- 6. NATIVE TASK SCHEDULER REGISTRATION (0 MB IDLE RAM) ---
Write-Host "`n[5/5] Registering Native 0-RAM Windows Task Scheduler Trigger..." -ForegroundColor Cyan

try {
    # Repetition interval
    $Trigger = New-ScheduledTaskTrigger -Once -At "00:00" -RepetitionInterval (New-TimeSpan -Minutes $FinalInterval)

    # Action: Direct execution of standalone binary with manifested quote argument (Zero quote.txt file needed!)
    $Action = New-ScheduledTaskAction -Execute $TargetExe -Argument "--quote `"$Quote`""

    # Settings: Resilience on battery, non-overlapping, and Sleep-Skip
    $Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -MultipleInstances IgnoreNew `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
        -Priority 4 `
        -StartWhenAvailable:$false

    # Register under active interactive user
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $CurrentUser = $env:USERNAME

    if ($IsAdmin) {
        Register-ScheduledTask -TaskName $TaskName `
            -Action $Action `
            -Trigger $Trigger `
            -Settings $Settings `
            -User $CurrentUser `
            -RunLevel Highest `
            -Description "Death Disciplinary Overwatch. Interval: $FinalInterval mins." `
            -Force | Out-Null
        Write-Host " [OK] Registered with Highest Privileges (Administrator Mode)." -ForegroundColor Green
    } else {
        Register-ScheduledTask -TaskName $TaskName `
            -Action $Action `
            -Trigger $Trigger `
            -Settings $Settings `
            -User $CurrentUser `
            -Description "Death Disciplinary Overwatch. Interval: $FinalInterval mins." `
            -Force | Out-Null
        Write-Host " [OK] Registered under current user session (Standard Mode)." -ForegroundColor Green
    }
}
catch {
    Write-Host " [CRITICAL ERROR] Failed to register Scheduled Task: $_" -ForegroundColor Red
    Exit 1
}

# --- 7. POST-ACTION VERIFICATION & HEALTH AUDIT ---
$TaskVerification = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($TaskVerification -and $TaskVerification.State -eq "Ready") {
    Write-Host " [VERIFIED] Task '$TaskName' is ACTIVE and READY in Task Scheduler." -ForegroundColor Green
} else {
    Write-Host " [WARN] Task registered, but reported state is: $($TaskVerification.State)" -ForegroundColor Yellow
}

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   ✅ DEATH MODULE DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "   • Target Binary    : $TargetExe" -ForegroundColor White
Write-Host "   • Task Name        : $TaskName" -ForegroundColor White
Write-Host "   • Interval         : Every $FinalInterval minutes" -ForegroundColor White
Write-Host "   • Manifested Quote : `"$Quote`"" -ForegroundColor White
Write-Host "   • Idle RAM Impact  : 0.00 MB (Triggered natively by Windows kernel)" -ForegroundColor White
Write-Host "   • Sleep Skip Policy: Enabled (missed triggers during sleep are skipped)" -ForegroundColor White
Write-Host "   • Storage Hygiene  : Zero auxiliary text files (stateless single binary)" -ForegroundColor White
Write-Host "-------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " 💡 Quick Test: Run 'Death --test' from any terminal for a 3-second test run." -ForegroundColor Yellow
Write-Host " 💡 Manual Run: Run 'Death' anytime to trigger an immediate lockdown." -ForegroundColor Yellow
Write-Host "=======================================================`n" -ForegroundColor Cyan
