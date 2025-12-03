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

# Check if Docker is running
Write-Host "[CHECK] Verifying Docker Desktop is running..." -ForegroundColor Yellow
try {
    $DockerVersion = docker version --format '{{.Server.Version}}' 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker daemon not responding"
    }
    Write-Host "[OK] Docker Desktop is running (version: $DockerVersion)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Docker Desktop is not running!" -ForegroundColor Red
    Write-Host "`nPlease start Docker Desktop and wait for it to fully initialize," -ForegroundColor Yellow
    Write-Host "then run this script again.`n" -ForegroundColor Yellow
    Write-Host "You can start Docker Desktop from:" -ForegroundColor Cyan
    Write-Host "  - Start Menu: Search for 'Docker Desktop'" -ForegroundColor Cyan
    Write-Host "  - Or run: Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'`n" -ForegroundColor Cyan
    exit 1
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
