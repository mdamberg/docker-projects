#!/usr/bin/env pwsh
# Fix Docker Desktop named pipe access issue
# Run as Administrator

Write-Host "`n[1/4] Stopping all Docker processes..." -ForegroundColor Yellow
Get-Process -Name "Docker Desktop","com.docker.*","vpnkit","dockerd" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5

Write-Host "[2/4] Cleaning up Docker named pipes..." -ForegroundColor Yellow
Get-ChildItem "\\.\pipe\" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*docker*" } | ForEach-Object {
    try {
        Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
    } catch {
        # Ignore errors, pipe might be in use
    }
}

Write-Host "[3/4] Waiting for cleanup..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

Write-Host "[4/4] Starting Docker Desktop..." -ForegroundColor Yellow
$dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerPath) {
    Start-Process $dockerPath
    Write-Host "`nDone! Docker Desktop should start normally now." -ForegroundColor Green
    Write-Host "Wait 30 seconds for it to fully initialize." -ForegroundColor Cyan
} else {
    Write-Host "ERROR: Docker Desktop not found at $dockerPath" -ForegroundColor Red
}
