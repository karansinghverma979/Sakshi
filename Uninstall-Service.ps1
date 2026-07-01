# SCRIPT: UNINSTALL-SERVICE (DAEMON DE-REGISTRATION)
# IDENTITY: SAKSHI
# RUN AS: ADMIN (Mandatory)

# 1. VERIFY PRIVILEGES
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Host " [ERROR] This script must be run as Administrator." -ForegroundColor Red
    Write-Host " Please open PowerShell as Administrator and run the script again." -ForegroundColor Yellow
    Exit
}

# 2. PROMPT FOR TASK NAME
$DefaultTaskName = "Sakshi"
Write-Host "--- SAKSHI DE-REGISTRATION INTERFACE ---" -ForegroundColor Cyan
$NewTaskName = Read-Host "Enter Scheduled Task Name to remove [Default: $DefaultTaskName]"
if ([string]::IsNullOrWhiteSpace($NewTaskName)) {
    $NewTaskName = $DefaultTaskName
}

# 3. STOP AND UNREGISTER TASK
try {
    if (Get-ScheduledTask -TaskName $NewTaskName -ErrorAction SilentlyContinue) {
        # Stop task if running
        Stop-ScheduledTask -TaskName $NewTaskName -ErrorAction SilentlyContinue
        Write-Host " [STOPPED] Active daemon task stopped." -ForegroundColor Yellow

        # Terminate any running process instances
        Write-Host " [CLEANUP] Stopping running background instances..." -ForegroundColor Yellow
        Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue | Where-Object {
            $_.CommandLine -like "*Sakshi.ps1*" -or $_.CommandLine -like "*Death.ps1*"
        } | ForEach-Object {
            Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
        }

        # Unregister task
        Unregister-ScheduledTask -TaskName $NewTaskName -Confirm:$false
        Write-Host " [SUCCESS] Scheduled Task '$NewTaskName' unregistered successfully." -ForegroundColor Green
    }
    else {
        Write-Host " [INFO] Scheduled Task '$NewTaskName' not found on this system." -ForegroundColor Yellow
    }
}
catch {
    Write-Host " [ERROR] Failed to remove the Scheduled Task." -ForegroundColor Red
    Write-Host $_
}
