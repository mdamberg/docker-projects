#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Starts all Docker infrastructure services

.DESCRIPTION
    This script navigates to each infrastructure service directory and runs docker-compose up -d
    Maintains separation of services while providing one-command startup

.PARAMETER Services
    Optional. Specify which services to start (comma-separated). If not provided, starts all.
    Valid values: pihole, homeassistant, mediastack, linkding, monitoring, vpn, flash, weather, all
    Example: .\start-all-services.ps1 -Services "pihole,homeassistant"

.EXAMPLE
    .\start-all-services.ps1
    Starts all infrastructure services

.EXAMPLE
    .\start-all-services.ps1 -Services "pihole,linkace"
    Starts only Pi-hole and LinkAce
#>

param(
    [string]$Services = "all"
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
    'vpn' = 'vpn'
    'flash' = 'flash_todo'
    'weather' = 'weather_api_project'
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

# Return exit code based on results
if ($FailCount -gt 0) {
    exit 1
} else {
    exit 0
}
