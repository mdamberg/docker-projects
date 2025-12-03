#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Stops all Docker infrastructure services

.DESCRIPTION
    This script navigates to each infrastructure service directory and runs docker-compose down

.PARAMETER Services
    Optional. Specify which services to stop (comma-separated). If not provided, stops all.
    Valid values: pihole, homeassistant, mediastack, linkding, monitoring, vpn, flash, weather, all
    Example: .\stop-all-services.ps1 -Services "pihole,homeassistant"

.EXAMPLE
    .\stop-all-services.ps1
    Stops all infrastructure services

.EXAMPLE
    .\stop-all-services.ps1 -Services "mediastack"
    Stops only the media stack
#>

param(
    [string]$Services = "all"
)

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define infrastructure services (keep in sync with start-all-services.ps1)
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

# Parse which services to stop
$ServicesToStop = @()
if ($Services -eq "all") {
    $ServicesToStop = $InfraServices.Keys
} else {
    $ServicesToStop = $Services -split ',' | ForEach-Object { $_.Trim().ToLower() }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Docker Infrastructure Shutdown Script " -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$SuccessCount = 0
$FailCount = 0
$Results = @()

foreach ($ServiceKey in $ServicesToStop) {
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

    Write-Host "[STOPPING] $ServiceKey ($ServiceDir)..." -ForegroundColor Yellow

    Push-Location $FullPath
    try {
        $Output = docker-compose down 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] $ServiceKey stopped" -ForegroundColor Green
            $SuccessCount++
            $Results += [PSCustomObject]@{
                Service = $ServiceKey
                Status = "SUCCESS"
                Message = "Stopped"
            }
        } else {
            Write-Host "[ERROR] Failed to stop $ServiceKey" -ForegroundColor Red
            Write-Host "Error: $Output" -ForegroundColor Red
            $FailCount++
            $Results += [PSCustomObject]@{
                Service = $ServiceKey
                Status = "FAILED"
                Message = "docker-compose failed"
            }
        }
    } catch {
        Write-Host "[ERROR] Exception stopping $ServiceKey : $_" -ForegroundColor Red
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
    Write-Host "| Failed: $FailCount`n" -ForegroundColor Red
} else {
    Write-Host "`n"
}

# Return exit code based on results
if ($FailCount -gt 0) {
    exit 1
} else {
    exit 0
}
