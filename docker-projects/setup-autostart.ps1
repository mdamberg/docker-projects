#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sets up automatic startup of Docker infrastructure services

.DESCRIPTION
    Creates a Windows Task Scheduler task to automatically start all Docker
    infrastructure services when the system boots, before user login.

.EXAMPLE
    .\setup-autostart.ps1
    Run as Administrator to set up auto-start
#>

# Require Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again." -ForegroundColor Yellow
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$StartScriptPath = Join-Path $ScriptDir "start-all-services.ps1"

if (-not (Test-Path $StartScriptPath)) {
    Write-Host "ERROR: Could not find start-all-services.ps1" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Docker Auto-Start Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Task details
$TaskName = "Docker Infrastructure Auto-Start"
$TaskDescription = "Automatically starts Docker infrastructure services on system boot"

# Check if task already exists
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($ExistingTask) {
    Write-Host "Task '$TaskName' already exists." -ForegroundColor Yellow
    $Response = Read-Host "Do you want to replace it? (y/n)"
    if ($Response -ne 'y') {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Removed existing task." -ForegroundColor Green
}

# Create the scheduled task action
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$StartScriptPath`""

# Create the trigger (at system startup)
$Trigger = New-ScheduledTaskTrigger -AtStartup

# Create the principal (run as SYSTEM with highest privileges)
$Principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

# Create the settings
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)

# Register the task
try {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Description $TaskDescription `
        -Action $Action `
        -Trigger $Trigger `
        -Principal $Principal `
        -Settings $Settings `
        -Force | Out-Null

    Write-Host "`nSUCCESS!" -ForegroundColor Green
    Write-Host "  Task Name: $TaskName" -ForegroundColor Cyan
    Write-Host "  Trigger: At system startup" -ForegroundColor Cyan
    Write-Host "  Script: $StartScriptPath" -ForegroundColor Cyan

    Write-Host "`nYour Docker infrastructure will now automatically start:" -ForegroundColor Green
    Write-Host "  • When the system boots" -ForegroundColor White
    Write-Host "  • Before user login" -ForegroundColor White
    Write-Host "  • Even after power loss" -ForegroundColor White

    Write-Host "`nTo verify, check Task Scheduler:" -ForegroundColor Yellow
    Write-Host "  1. Press Win+R, type 'taskschd.msc', press Enter" -ForegroundColor White
    Write-Host "  2. Look for '$TaskName' in Task Scheduler Library" -ForegroundColor White

    Write-Host "`nTo test without rebooting:" -ForegroundColor Yellow
    Write-Host "  Run-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White

} catch {
    Write-Host "`nFAILED to create scheduled task!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
