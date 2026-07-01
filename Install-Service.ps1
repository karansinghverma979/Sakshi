# SCRIPT: INSTALL-SERVICE (DAEMON REGISTRATION)
# IDENTITY: SAKSHI
# RUN AS: ADMIN (Mandatory)

# 1. VERIFY PRIVILEGES
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Host " [ERROR] This script must be run as Administrator." -ForegroundColor Red
    Write-Host " Please open PowerShell as Administrator and run the script again." -ForegroundColor Yellow
    Exit
}

# 2. PROMPT FOR CONFIGURATION
$DefaultTaskName = "Sakshi"
$DefaultQuote = "KEEP CALM AND STUDY HARD."

Write-Host "--- SAKSHI DEPLOYMENT INTERFACE ---" -ForegroundColor Cyan
$NewTaskName = Read-Host "Enter Scheduled Task Name [Default: $DefaultTaskName]"
if ([string]::IsNullOrWhiteSpace($NewTaskName)) {
    $NewTaskName = $DefaultTaskName
}

$CustomQuoteInput = Read-Host "Enter acknowledgment button quote [Default: $DefaultQuote]"
if ([string]::IsNullOrWhiteSpace($CustomQuoteInput)) {
    $CustomQuoteInput = $DefaultQuote
}

# 3. SET RELATIVE PATHS AND WRITE CONFIG
$BrainPath = Join-Path $PSScriptRoot "Sakshi.ps1"
$QuoteDir = Join-Path $PSScriptRoot "Modules\Death"
$QuotePath = Join-Path $QuoteDir "quote.txt"

# Write custom quote to file
try {
    if (-not (Test-Path $QuoteDir)) {
        New-Item -ItemType Directory -Path $QuoteDir -Force | Out-Null
    }
    $CustomQuoteInput | Out-File -FilePath $QuotePath -Encoding UTF8 -Force
    Write-Host " [CONFIG] Saved acknowledgment quote: '$CustomQuoteInput'" -ForegroundColor Cyan
}
catch {
    Write-Host " [WARNING] Failed to save custom quote: $_" -ForegroundColor Yellow
}

Write-Host " [SYSTEM] Initializing Sakshi Daemon Registration for task: '$NewTaskName'..." -ForegroundColor Cyan

# 4. PURGE DUPLICATES / PREVIOUS INSTANCES & PROCESSES
Write-Host " [CLEANUP] Stopping running background instances..." -ForegroundColor Yellow
Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*Sakshi.ps1*" -or $_.CommandLine -like "*Death.ps1*"
} | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}

if (Get-ScheduledTask -TaskName $NewTaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $NewTaskName -Confirm:$false
    Write-Host " [CLEANUP] Unregistered existing instance of task: $NewTaskName" -ForegroundColor Yellow
}

# 5. DEFINE TRIGGER (At Logon of the current user)
$Trigger = New-ScheduledTaskTrigger -AtLogon

# 6. DEFINE ACTION (Run Sakshi Hidden)
$Action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$BrainPath`""

# 7. DEFINE SETTINGS (Resilience)
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Days 365) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)

# 8. REGISTER NEW SERVICE
try {
    # Register the task to run under the current user's session with highest privileges (so WPF can interact with the desktop)
    $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    
    Register-ScheduledTask -TaskName $NewTaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Settings $Settings `
        -User $CurrentUser `
        -RunLevel Highest `
        -Description "The Witness (Sakshi) Overwatch System. Monitors discipline protocols." `
        -Force

    Write-Host " [SUCCESS] Daemon Registered: $NewTaskName" -ForegroundColor Green
    
    # Start it immediately
    Start-ScheduledTask -TaskName $NewTaskName
    Write-Host " [ACTIVE] Sakshi is now watching." -ForegroundColor Green
}
catch {
    Write-Host " [ERROR] Registration failed." -ForegroundColor Red
    Write-Host $_
}
