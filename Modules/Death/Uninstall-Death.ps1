<#
    .SYNOPSIS
        DEATH MODULE - System Purge & Deregistration Engine
        MODULE: Modules/Death/Uninstall-Death.ps1
        ROLE: Clean Deregistration, Process Eradication & Binary Purge
        TARGET: Standalone Native .NET 9 Binary (~/.local/bin/Death.exe) & Scheduled Task

    .DESCRIPTION
        Self-contained uninstaller strictly dedicated to the Death module.
        Halts running Death instances, unregisters the Death scheduled task,
        and purges installed binaries from ~/.local/bin/.
#>

[CmdletBinding()]
param(
    [Parameter()][string]$TaskName,
    [switch]$KeepBinary,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Continue"

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   🧹 DEATH MODULE - UNINSTALL & PURGE INTERFACE" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# --- 1. IDENTIFY TARGET TASK ---
$DefaultTaskName = "Death"
if ([string]::IsNullOrWhiteSpace($TaskName)) {
    if ($NonInteractive) {
        $TaskName = $DefaultTaskName
    } else {
        # Check existing death-related tasks
        $FoundTasks = @()
        foreach ($name in @("Death", "DeathModule", "MementoMori")) {
            if (Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue) {
                $FoundTasks += $name
            }
        }

        if ($FoundTasks.Count -gt 0) {
            Write-Host "`n Detected active Death tasks: $($FoundTasks -join ', ')" -ForegroundColor Yellow
        }

        $InputName = Read-Host "Enter Scheduled Task Name to unregister [Default: $DefaultTaskName]"
        $TaskName = if ([string]::IsNullOrWhiteSpace($InputName)) { $DefaultTaskName } else { $InputName.Trim() }
    }
}

# --- 2. TERMINATE ACTIVE DEATH PROCESSES ---
Write-Host "`n[1/3] Halting active Death processes..." -ForegroundColor Cyan

Get-Process -Name "Death" -ErrorAction SilentlyContinue | ForEach-Object {
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    Write-Host " [TERMINATED] Active Death.exe process (PID: $($_.Id))" -ForegroundColor Yellow
}

# --- 3. DEREGISTER DEATH SCHEDULED TASKS ---
Write-Host "`n[2/3] Deregistering Scheduled Task '$TaskName'..." -ForegroundColor Cyan

$TasksToClean = @($TaskName, "Death", "MementoMori") | Select-Object -Unique

foreach ($tName in $TasksToClean) {
    $task = Get-ScheduledTask -TaskName $tName -ErrorAction SilentlyContinue
    if ($task) {
        try {
            Stop-ScheduledTask -TaskName $tName -ErrorAction SilentlyContinue
            Unregister-ScheduledTask -TaskName $tName -Confirm:$false -ErrorAction Stop
            Write-Host " [UNREGISTERED] Task '$tName' successfully removed from Task Scheduler." -ForegroundColor Green
        }
        catch {
            Write-Host " [ACCESS DENIED] Task '$tName' was created with elevated rights." -ForegroundColor Red
            Write-Host "   To force-remove '$tName', open an Administrator PowerShell and run:" -ForegroundColor Yellow
            Write-Host "   schtasks /Delete /TN `"$tName`" /F" -ForegroundColor White
        }
    }
}

# --- 4. FILESYSTEM & BINARY PURGE ---
Write-Host "`n[3/3] Purging Death binaries and artifacts..." -ForegroundColor Cyan

$BinDir = Join-Path $env:USERPROFILE ".local\bin"
$TargetExe = Join-Path $BinDir "Death.exe"
$TargetCmd = Join-Path $BinDir "Death.cmd"
$LegacyExe = Join-Path $BinDir "death.exe"
$ResidualQuote = Join-Path $BinDir "quote.txt"

if (-not $KeepBinary) {
    foreach ($file in @($TargetExe, $TargetCmd, $LegacyExe, $ResidualQuote)) {
        if (Test-Path $file) {
            try {
                Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
                Write-Host " [PURGED] Artifact removed: $file" -ForegroundColor Green
            } catch {
                Write-Host " [WARN] Could not delete $file : $_" -ForegroundColor Yellow
            }
        }
    }
} else {
    Write-Host " [PRESERVED] Binary kept in $BinDir (-KeepBinary specified)." -ForegroundColor DarkGray
}

# Clean any project legacy log remnants
$ProjectDeathLog = Join-Path $PSScriptRoot "Death.log"
if (Test-Path $ProjectDeathLog) {
    Remove-Item -Path $ProjectDeathLog -Force -ErrorAction SilentlyContinue
    Write-Host " [PURGED] Removed log: $ProjectDeathLog" -ForegroundColor DarkGray
}

# --- 5. POST-ACTION AUDIT REPORT ---
$RemainingProcesses = Get-Process -Name "Death" -ErrorAction SilentlyContinue
$RemainingTasks = Get-ScheduledTask | Where-Object { $_.TaskName -match "^Death$|^DeathModule$|^MementoMori$" } -ErrorAction SilentlyContinue
$BinaryExists = Test-Path $TargetExe

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   📋 DEATH MODULE PURGE AUDIT" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "   • Running Processes : $(if ($RemainingProcesses) { 'Active (' + $RemainingProcesses.Count + ')' } else { 'Clean (0)' })" -ForegroundColor $(if ($RemainingProcesses) { 'Yellow' } else { 'Green' })
Write-Host "   • Scheduled Tasks   : $(if ($RemainingTasks) { 'Present: ' + ($RemainingTasks.TaskName -join ', ') } else { 'Clean (0)' })" -ForegroundColor $(if ($RemainingTasks) { 'Yellow' } else { 'Green' })
Write-Host "   • Installed Binary  : $(if ($BinaryExists) { 'Preserved' } else { 'Completely Erased' })" -ForegroundColor $(if ($BinaryExists) { 'White' } else { 'Green' })
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host " [COMPLETE] Death module eradication finished.`n" -ForegroundColor Green
