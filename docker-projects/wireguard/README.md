# WireGuard Remote Access VPN (wg-easy)

## Purpose
Provides secure remote access to home network from anywhere in the world.

## Web Interface
- **URL:** http://10.0.0.7:51821
- **Password:** WireGuardAdmin2024!

## Configuration
- **DDNS Hostname:** damattberghome.duckdns.org
- **Port:** 51820/udp (forwarded in router)
- **VPN Network:** 10.8.0.0/24
- **Home Network Access:** 10.0.0.0/24
- **DNS:** 10.0.0.1 (router)

## Active Clients
1. **Remote_access** - Initial test client
2. **Phone** - Mobile device
3. **Laptop** - Personal laptop
4. **Tablet** - Tablet device

## Client Config Storage
**DO NOT store actual .conf files here!**

Client configurations contain private keys and should be stored securely:
- On your personal devices in a password-protected location
- NOT in this git repository
- Accessible via web UI when needed

## How to Add New Clients
1. Access web UI at http://10.0.0.7:51821
2. Click the "+" button
3. Enter client name
4. Download config or scan QR code
5. Import into WireGuard client app

## Accessing Services via VPN
Once connected to VPN, access services using local IPs:
- **Plex:** http://10.0.0.7:32400
- **Homarr:** http://10.0.0.7:8181
- **Home Assistant:** http://10.0.0.7:8123
- **Portainer:** https://10.0.0.7:9443
- All other services use their local addresses

## Container Info
- **Image:** ghcr.io/wg-easy/wg-easy:latest
- **Container:** wireguard
- **Config Volume:** ./config:/etc/wireguard

## Important Notes
- This replaced the old `homevpn` (linuxserver/wireguard) setup
- Completely separate from `gluetun` (used for torrenting privacy)
- Do not install WireGuard client on this server (10.0.0.7)
