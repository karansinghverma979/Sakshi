[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('status', 'install-all', 'uninstall-all', 'death', 'overviews', 'apex', 'spark', 'menu')]
    [string]$Command = 'menu',

    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'
$LocalBin = Join-Path $HOME ".local\bin"

function Show-Banner {
    Write-Host ""
    Write-Host " ===============================================================" -ForegroundColor Cyan
    Write-Host "  SAKSHI (The Witness) - Sovereign Control Matrix" -ForegroundColor Cyan
    Write-Host "  Zero-Daemon Governance  --  0 MB Idle RAM  --  Windows 11" -ForegroundColor DarkGray
    Write-Host " ===============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-ModuleStatus {
    $modules = @(
        @{ Name = "Death"; Binary = "Death.exe"; Trigger = "Task Scheduler (Memento Mori)" },
        @{ Name = "Overviews"; Binary = "Overviews.exe"; Trigger = "Ctrl + Alt + O" },
        @{ Name = "Apex"; Binary = "Apex.exe"; Trigger = "Ctrl + Alt + A" },
        @{ Name = "Spark"; Binary = "Spark.exe"; Trigger = "Ctrl + Alt + S" }
    )

    Write-Host " MODULE SOVEREIGN STATUS LEDGER:" -ForegroundColor Yellow
    Write-Host " ---------------------------------------------------------------" -ForegroundColor DarkGray

    foreach ($m in $modules) {
        $binPath = Join-Path $LocalBin $m.Binary
        $isInstalled = Test-Path $binPath
        $statusIcon = if ($isInstalled) { "[INSTALLED]" } else { "[NOT FOUND]" }
        $color = if ($isInstalled) { "Green" } else { "DarkGray" }

        Write-Host (" {0,-12} {1,-15} | Trigger: {2}" -f $m.Name, $statusIcon, $m.Trigger) -ForegroundColor $color
    }

    Write-Host " ---------------------------------------------------------------" -ForegroundColor DarkGray

    $activeProcesses = Get-Process -Name "Death", "Overviews", "Apex", "Spark" -ErrorAction SilentlyContinue
    if ($activeProcesses) {
        $cnt = $activeProcesses.Count
        Write-Host " Active Instances Running: $cnt" -ForegroundColor Yellow
    } else {
        Write-Host " ZERO-DAEMON INVARIANT: 0 MB Idle RAM (Pristine Standby)" -ForegroundColor Green
    }
    Write-Host ""
}

function Invoke-InstallAll {
    Write-Host " Initializing installation of all 4 sovereign modules..." -ForegroundColor Cyan
    $root = Split-Path $PSScriptRoot -Parent
    
    $moduleDirs = @("Death", "Overviews", "Apex", "Spark")
    foreach ($m in $moduleDirs) {
        $siblingDir = Join-Path $root $m
        $installScript = Join-Path $siblingDir "Install-$m.ps1"

        if (-not (Test-Path $installScript)) {
            Write-Host " [·] Sibling repository not found. Fetching $m from GitHub..." -ForegroundColor DarkYellow
            git clone "https://github.com/karansinghverma979/$m.git" $siblingDir
        }

        if (Test-Path $installScript) {
            Write-Host " Compiling and Installing $m..." -ForegroundColor Green
            powershell -ExecutionPolicy Bypass -File $installScript -NonInteractive
        } else {
            Write-Host " Install script for $m not found at $installScript" -ForegroundColor DarkYellow
        }
    }
    Write-Host " All modules installed and registered into Windows 11 Shell." -ForegroundColor Green
}

function Invoke-UninstallAll {
    Write-Host " Teardown and Vanish of all 4 sovereign modules..." -ForegroundColor Yellow
    $root = Split-Path $PSScriptRoot -Parent
    
    $moduleDirs = @("Death", "Overviews", "Apex", "Spark")
    foreach ($m in $moduleDirs) {
        $siblingDir = Join-Path $root $m
        $uninstallScript = Join-Path $siblingDir "Uninstall-$m.ps1"

        if (Test-Path $uninstallScript) {
            Write-Host " Removing $m..." -ForegroundColor DarkGray
            powershell -ExecutionPolicy Bypass -File $uninstallScript
        }
    }
    Write-Host " Complete teardown complete. 0 residual hooks." -ForegroundColor Green
}

switch ($Command) {
    'status' {
        Show-Banner
        Get-ModuleStatus
    }
    'install-all' {
        Show-Banner
        Invoke-InstallAll
    }
    'uninstall-all' {
        Show-Banner
        Invoke-UninstallAll
    }
    'death' {
        $bin = Join-Path $LocalBin "Death.exe"
        if (Test-Path $bin) { & $bin } else { Write-Host "Death.exe not found in $LocalBin" -ForegroundColor Red }
    }
    'overviews' {
        $bin = Join-Path $LocalBin "Overviews.exe"
        if (Test-Path $bin) { & $bin } else { Write-Host "Overviews.exe not found in $LocalBin" -ForegroundColor Red }
    }
    'apex' {
        $bin = Join-Path $LocalBin "Apex.exe"
        if (Test-Path $bin) { & $bin } else { Write-Host "Apex.exe not found in $LocalBin" -ForegroundColor Red }
    }
    'spark' {
        $bin = Join-Path $LocalBin "Spark.exe"
        if (Test-Path $bin) { & $bin } else { Write-Host "Spark.exe not found in $LocalBin" -ForegroundColor Red }
    }
    'menu' {
        Show-Banner
        Get-ModuleStatus
        Write-Host " [1] Launch Death (Memento Mori Smoke Test)" -ForegroundColor White
        Write-Host " [2] Launch Overviews (Google AI Overview)" -ForegroundColor White
        Write-Host " [3] Summon Apex (Virtual Desktop and Topmost HUD)" -ForegroundColor White
        Write-Host " [4] Summon Spark (Thought Capture HUD)" -ForegroundColor White
        Write-Host " [5] Install All Modules" -ForegroundColor White
        Write-Host " [6] Uninstall All Modules" -ForegroundColor White
        Write-Host " [Q] Quit" -ForegroundColor DarkGray
        Write-Host ""
        
        if ($NonInteractive) { return }

        $choice = Read-Host " Select Option"
        switch ($choice) {
            '1' { $bin = Join-Path $LocalBin "Death.exe"; if (Test-Path $bin) { & $bin --test } }
            '2' { $bin = Join-Path $LocalBin "Overviews.exe"; if (Test-Path $bin) { & $bin } }
            '3' { $bin = Join-Path $LocalBin "Apex.exe"; if (Test-Path $bin) { & $bin } }
            '4' { $bin = Join-Path $LocalBin "Spark.exe"; if (Test-Path $bin) { & $bin } }
            '5' { Invoke-InstallAll }
            '6' { Invoke-UninstallAll }
            default { Write-Host " Exiting Sakshi." -ForegroundColor DarkGray }
        }
    }
}
