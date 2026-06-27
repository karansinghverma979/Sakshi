<#
    .SYNOPSIS
        SYSTEM: SAKSHI (THE WITNESS) - v2.0 OPTIMIZED
        SECTOR: AUTOMATION
        STATUS: ACTIVE OBSERVER
#>

# --- CONFIGURATION (PORTABLE) ---
# Hide the Console Window immediately (Stealth Mode)
$window = Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);' -Name "Win32ShowWindow" -Namespace Win32Functions -PassThru
$window::ShowWindow((Get-Process -Id $PID).MainWindowHandle, 0) 

$HomeBase   = $PSScriptRoot
$ModuleDir  = "$HomeBase\Modules"
$LogPath    = "$HomeBase\Witness.log"

# --- CORE FUNCTIONS ---

function Write-Log {
    param ( [string]$Message )
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$TimeStamp] | SAKSHI | $Message" | Out-File $LogPath -Append -Encoding UTF8
}

function Invoke-Module {
    param ( 
        [string]$Name,
        [switch]$Background # New switch to run without waiting
    )
    
    $TargetScript = "$ModuleDir\$Name\$Name.ps1"
    
    if (Test-Path $TargetScript) {
        try {
            # Pass strict arguments to the child process
            $processArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$TargetScript`""
            $modulePath = "$ModuleDir\$Name"

            if ($Background) {
                # Fire and Forget (Good for non-critical visual checks)
                Start-Process powershell.exe -ArgumentList $processArgs -WorkingDirectory $modulePath -WindowStyle Hidden
                if ($Name -ne "Drift") { Write-Log "Module Dispatched (Background): $Name" }
            }
            else {
                # Wait for completion (Enforces discipline - User cannot ignore)
                Start-Process powershell.exe -ArgumentList $processArgs -WorkingDirectory $modulePath -Wait -WindowStyle Hidden
                if ($Name -ne "Drift") { Write-Log "Module Executed (Blocking): $Name" }
            }
        }
        catch {
            Write-Log "CRITICAL ERROR: Module $Name failed. Details: $_"
        }
    }
    else {
        Write-Log "WARNING: Module $Name not found at $TargetScript"
    }
}

# --- THE ETERNAL WITNESS ---

Write-Log "SYSTEM ONLINE. SAKSHI is watching. Cycle Time: 5s."

# State Memory (To avoid sleep-based timing)
$LastMortalityCheck = -1

while ($true) {
    try {
        $Now = Get-Date
        $Minute = $Now.Minute

        # -----------------------------------------------------------
        # MORTALITY CHECK (Every 30 mins: 00, 30)
        # -----------------------------------------------------------
        # Logic: If current minute is a target AND we haven't run it this minute yet.
        if ($Minute -in 0, 30 -and $Minute -ne $LastMortalityCheck) {
            Invoke-Module "Death"
            $LastMortalityCheck = $Minute # Update memory so we don't fire again this minute
        }

        # -----------------------------------------------------------
        # HEARTBEAT (High Frequency)
        # -----------------------------------------------------------
        # We sleep only 5 seconds. This makes the system responsive.
        # It won't miss the :00 / :30 mark, and it can react to interruptions.
        Start-Sleep -Seconds 5
    }
    catch {
        Write-Log "SYSTEM FAILURE: Main Loop Crashed. Restarting... Error: $_"
        Start-Sleep -Seconds 10
    }
}

