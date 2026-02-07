#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Starts all Docker infrastructure services

.DESCRIPTION
    This script navigates to each infrastructure service directory and runs docker-compose up -d
    Maintains separation of services while providing one-command startup.
    Also checks docker-users group membership and can optionally start DBeaver.

.PARAMETER Services
    Optional. Specify which services to start (comma-separated). If not provided, starts all.
    Valid values: pihole, homeassistant, mediastack, linkding, monitoring, flash, weather,
                  wireguard, n8n, backups, phpipam, homemetrics, all
    Example: .\start-all-services.ps1 -Services "pihole,homeassistant"

.PARAMETER StartDBeaver
    Optional switch. If specified, starts DBeaver database tool after Docker services.

.PARAMETER StartLibreHardwareMonitor
    Optional switch. If specified, starts LibreHardwareMonitor for hardware sensor collection.
    Required for the Hardware Sensors n8n workflow.

.EXAMPLE
    .\start-all-services.ps1
    Starts all infrastructure services

.EXAMPLE
    .\start-all-services.ps1 -Services "pihole,phpipam"
    Starts only Pi-hole and phpIPAM

.EXAMPLE
    .\start-all-services.ps1 -StartDBeaver
    Starts all services and launches DBeaver

.EXAMPLE
    .\start-all-services.ps1 -StartLibreHardwareMonitor
    Starts all services and launches LibreHardwareMonitor for hardware sensor collection

.EXAMPLE
    .\start-all-services.ps1 -StartDBeaver -StartLibreHardwareMonitor
    Starts all services plus both DBeaver and LibreHardwareMonitor
#>

param(
    [string]$Services = "all",
    [switch]$StartDBeaver,
    [switch]$StartLibreHardwareMonitor
)

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define infrastructure services (add/remove as needed)
$InfraServices = @{
    'pihole' = 'pie_hole'
    'homeassistant' = 'home_assist'
    'mediastack' = 'media_stack'
    'linkding' = 'linkding'
    'monitoring' = 'monitoring'
    'flash' = 'flash_todo'
    'weather' = 'weather_api_project'
    'wireguard' = 'wireguard'
    'n8n' = 'n8n'
    'backups' = 'backups'
    'phpipam' = 'phpipam'
    'homemetrics' = '..\temp_home_metrics_files'
    'lightdash' = 'lightdash'
}

# Parse which services to start
$ServicesToStart = @()
if ($Services -eq "all") {
    $ServicesToStart = $InfraServices.Keys
} else {
    $ServicesToStart = $Services -split ',' | ForEach-Object { $_.Trim().ToLower() }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Docker Infrastructure Startup Script  " -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check docker-users group membership
function Test-DockerUsersGroup {
    try {
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
        $dockerUsersGroup = Get-LocalGroupMember -Group "docker-users" -ErrorAction SilentlyContinue
        return ($dockerUsersGroup | Where-Object { $_.Name -like "*$currentUser" }) -ne $null
    } catch {
        return $false
    }
}

if (-not (Test-DockerUsersGroup)) {
    Write-Host "[WARNING] Current user is not in the 'docker-users' group!" -ForegroundColor Yellow
    Write-Host "          This may cause authentication issues with Docker Desktop." -ForegroundColor Yellow
    Write-Host "          To fix permanently, run as Admin:" -ForegroundColor Cyan
    Write-Host '          Add-LocalGroupMember -Group "docker-users" -Member "$env:USERNAME"' -ForegroundColor Cyan
    Write-Host "          Then log out and back in.`n" -ForegroundColor Cyan
}

# Check if Docker is running, start it if not
Write-Host "[CHECK] Verifying Docker Desktop is running..." -ForegroundColor Yellow

$DockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
$MaxWaitSeconds = 120  # Wait up to 2 minutes for Docker to start

function Test-DockerRunning {
    try {
        $null = docker version --format '{{.Server.Version}}' 2>&1
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

if (-not (Test-DockerRunning)) {
    Write-Host "[INFO] Docker Desktop is not running. Starting it now..." -ForegroundColor Yellow

    # Check if Docker Desktop executable exists
    if (-not (Test-Path $DockerDesktopPath)) {
        Write-Host "[ERROR] Docker Desktop not found at: $DockerDesktopPath" -ForegroundColor Red
        Write-Host "Please install Docker Desktop or update the path in this script.`n" -ForegroundColor Yellow
        exit 1
    }

    # Start Docker Desktop
    try {
        Start-Process -FilePath $DockerDesktopPath -WindowStyle Hidden
        Write-Host "[INFO] Docker Desktop starting..." -ForegroundColor Cyan
    } catch {
        Write-Host "[ERROR] Failed to start Docker Desktop: $_" -ForegroundColor Red
        exit 1
    }

    # Wait for Docker to be ready
    Write-Host "[WAIT] Waiting for Docker to initialize (max $MaxWaitSeconds seconds)..." -ForegroundColor Yellow
    $WaitedSeconds = 0
    $ReadyMessageShown = $false

    while (-not (Test-DockerRunning) -and $WaitedSeconds -lt $MaxWaitSeconds) {
        Start-Sleep -Seconds 2
        $WaitedSeconds += 2

        if ($WaitedSeconds % 10 -eq 0 -and -not $ReadyMessageShown) {
            Write-Host "[WAIT] Still waiting... ($WaitedSeconds seconds elapsed)" -ForegroundColor Yellow
        }
    }

    if (Test-DockerRunning) {
        $DockerVersion = docker version --format '{{.Server.Version}}' 2>&1
        Write-Host "[OK] Docker Desktop is ready (version: $DockerVersion)" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Docker Desktop failed to start within $MaxWaitSeconds seconds!" -ForegroundColor Red
        Write-Host "Please check Docker Desktop manually and ensure it can start properly.`n" -ForegroundColor Yellow
        exit 1
    }
} else {
    $DockerVersion = docker version --format '{{.Server.Version}}' 2>&1
    Write-Host "[OK] Docker Desktop is already running (version: $DockerVersion)" -ForegroundColor Green
}

$SuccessCount = 0
$FailCount = 0
$Results = @()

foreach ($ServiceKey in $ServicesToStart) {
    if (-not $InfraServices.ContainsKey($ServiceKey)) {
        Write-Host "[SKIP] Unknown service: $ServiceKey" -ForegroundColor Yellow
        continue
    }

    $ServiceDir = $InfraServices[$ServiceKey]
    $FullPath = Join-Path $ScriptDir $ServiceDir

    if (-not (Test-Path $FullPath)) {
        Write-Host "[ERROR] Directory not found: $ServiceDir" -ForegroundColor Red
        $FailCount++
        $Results += [PSCustomObject]@{
            Service = $ServiceKey
            Status = "FAILED"
            Message = "Directory not found"
        }
        continue
    }

    if (-not (Test-Path (Join-Path $FullPath "docker-compose.yml"))) {
        Write-Host "[SKIP] No docker-compose.yml found in: $ServiceDir" -ForegroundColor Yellow
        $Results += [PSCustomObject]@{
            Service = $ServiceKey
            Status = "SKIPPED"
            Message = "No docker-compose.yml"
        }
        continue
    }

    Write-Host "[STARTING] $ServiceKey ($ServiceDir)..." -ForegroundColor Yellow

    Push-Location $FullPath
    try {
        $Output = docker-compose up -d 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] $ServiceKey is running" -ForegroundColor Green
            $SuccessCount++
            $Results += [PSCustomObject]@{
                Service = $ServiceKey
                Status = "SUCCESS"
                Message = "Running"
            }
        } else {
            Write-Host "[ERROR] Failed to start $ServiceKey" -ForegroundColor Red
            Write-Host "Error: $Output" -ForegroundColor Red
            $FailCount++
            $Results += [PSCustomObject]@{
                Service = $ServiceKey
                Status = "FAILED"
                Message = "docker-compose failed"
            }
        }
    } catch {
        Write-Host "[ERROR] Exception starting $ServiceKey : $_" -ForegroundColor Red
        $FailCount++
        $Results += [PSCustomObject]@{
            Service = $ServiceKey
            Status = "FAILED"
            Message = $_.Exception.Message
        }
    } finally {
        Pop-Location
    }

    Start-Sleep -Milliseconds 500
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$Results | Format-Table -AutoSize

Write-Host "Total: $($Results.Count) | " -NoNewline
Write-Host "Success: $SuccessCount " -ForegroundColor Green -NoNewline
if ($FailCount -gt 0) {
    Write-Host "| Failed: $FailCount" -ForegroundColor Red
} else {
    Write-Host ""
}

Write-Host "`nAll services have restart policies set to 'unless-stopped'." -ForegroundColor Cyan
Write-Host "They will automatically restart on system reboot once started.`n" -ForegroundColor Cyan

# Start LibreHardwareMonitor if requested (required for hardware sensors workflow)
if ($StartLibreHardwareMonitor) {
    # Common installation paths for LibreHardwareMonitor
    $LHMPaths = @(
        "C:\Program Files\LibreHardwareMonitor\LibreHardwareMonitor.exe",
        "C:\Program Files (x86)\LibreHardwareMonitor\LibreHardwareMonitor.exe",
        "$env:LOCALAPPDATA\Programs\LibreHardwareMonitor\LibreHardwareMonitor.exe",
        "$env:USERPROFILE\Downloads\LibreHardwareMonitor\LibreHardwareMonitor.exe"
    )

    $LHMPath = $null
    foreach ($Path in $LHMPaths) {
        if (Test-Path $Path) {
            $LHMPath = $Path
            break
        }
    }

    if ($LHMPath) {
        # Check if already running
        $LHMProcess = Get-Process -Name "LibreHardwareMonitor" -ErrorAction SilentlyContinue
        if ($LHMProcess) {
            Write-Host "[OK] LibreHardwareMonitor is already running" -ForegroundColor Green
        } else {
            Write-Host "[STARTING] LibreHardwareMonitor..." -ForegroundColor Yellow
            try {
                # Start with elevated privileges (required for hardware access)
                Start-Process -FilePath $LHMPath -WindowStyle Minimized
                Start-Sleep -Seconds 2
                Write-Host "[SUCCESS] LibreHardwareMonitor started" -ForegroundColor Green
                Write-Host "          HTTP server should be available at http://localhost:8085" -ForegroundColor Cyan
                Write-Host "          (Ensure 'Remote Web Server' is enabled in LHM options)" -ForegroundColor Cyan
            } catch {
                Write-Host "[ERROR] Failed to start LibreHardwareMonitor: $_" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "[WARNING] LibreHardwareMonitor not found. Checked paths:" -ForegroundColor Yellow
        foreach ($Path in $LHMPaths) {
            Write-Host "          - $Path" -ForegroundColor Yellow
        }
        Write-Host "          Download from: https://github.com/LibreHardwareMonitor/LibreHardwareMonitor" -ForegroundColor Cyan
    }
}

# Start DBeaver if requested
if ($StartDBeaver) {
    $DBeaverPath = "$env:LOCALAPPDATA\DBeaver\dbeaver.exe"
    if (Test-Path $DBeaverPath) {
        Write-Host "[STARTING] DBeaver..." -ForegroundColor Yellow
        try {
            Start-Process -FilePath $DBeaverPath -WindowStyle Normal
            Write-Host "[SUCCESS] DBeaver started" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Failed to start DBeaver: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "[WARNING] DBeaver not found at: $DBeaverPath" -ForegroundColor Yellow
    }
}

# Return exit code based on results
if ($FailCount -gt 0) {
    exit 1
} else {
    exit 0
}
