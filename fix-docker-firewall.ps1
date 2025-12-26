# Run this script as Administrator to allow Docker container ports through Windows Firewall

$ports = @(
    @{Port=7575; Name="HOMARR Dashboard"},
    @{Port=3002; Name="Dashdot"},
    @{Port=5055; Name="Overseerr"},
    @{Port=7878; Name="Radarr"},
    @{Port=8989; Name="Sonarr"},
    @{Port=9696; Name="Prowlarr"},
    @{Port=8191; Name="Flaresolverr"},
    @{Port=32400; Name="Plex"},
    @{Port=8080; Name="qBittorrent"},
    @{Port=9443; Name="Portainer"},
    @{Port=5299; Name="LazyLibrarian"},
    @{Port=13378; Name="AudioBookShelf"},
    @{Port=8123; Name="Home Assistant"},
    @{Port=3001; Name="Uptime Kuma"},
    @{Port=61208; Name="Glances"},
    @{Port=8200; Name="Duplicati"},
    @{Port=5000; Name="Weather API"},
    @{Port=8282; Name="Linkding"},
    @{Port=8082; Name="Pi-hole HTTP"},
    @{Port=8443; Name="Pi-hole HTTPS"}
)

Write-Host "Creating Windows Firewall rules for Docker containers..." -ForegroundColor Cyan

foreach ($item in $ports) {
    $ruleName = "Docker - $($item.Name)"

    # Remove existing rule if it exists
    Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

    # Create new rule
    New-NetFirewallRule `
        -DisplayName $ruleName `
        -Direction Inbound `
        -Action Allow `
        -Protocol TCP `
        -LocalPort $item.Port `
        -Profile Any `
        -Description "Allow access to Docker container: $($item.Name)" | Out-Null

    Write-Host "✓ Created firewall rule for port $($item.Port) - $($item.Name)" -ForegroundColor Green
}

Write-Host "`nFirewall rules created successfully!" -ForegroundColor Green
Write-Host "You can now access your containers via your LAN IP (192.168.1.7)" -ForegroundColor Cyan
