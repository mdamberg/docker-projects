# Matt's Homelab

This documentation covers the full setup, configuration, and maintenance of my personal homelab.
It's divided by project stack and topic for easy navigation.

## Overview

- **Server**: Older gaming PC repurposed as a homelab server running Windows 11
- **Network Core**: Home router at `10.0.0.1` — see [Networking](networking/overview.md)
- **Remote Access**: Tailscale (bypasses ISP CGNAT) — see [Remote Access](remote-access/README.md)
- **Core Services**: Media stack, monitoring stack, analytics pipeline, VPN, backups, home automation
- **Goal**: Self-host everything cleanly, securely, and reproducibly

## Quick Links

- [Networking Overview](networking/overview.md)
- [Media Stack](media-stack/README.md)
- [Monitoring Stack](monitoring-stack/README.md)
- [Analytics Stack](analytics-stack/README.md)
- [VPN Stack](vpn-stack/README.md)
- [Remote Access (Tailscale)](remote-access/README.md)
- [Backups (Duplicati)](backups/README.md)
- [Pi-hole (DNS)](pi-hole/pi-home.md)
- [Hardware](hardware/inventory.md)
- [Troubleshooting Logs](troubleshooting/README.md)

## Stacks

### Media Stack
Full self-hosted media server. Plex, Sonarr, Radarr, qBittorrent (via Gluetun), Overseerr, Prowlarr, LazyLibrarian, Audiobookshelf, Homarr, Portainer, Watchtower.

### Monitoring Stack
Uptime Kuma (service uptime alerts) + Glances (real-time system resources).

### Analytics Stack
Personal data warehouse. n8n collects data from Home Assistant, Plex, and Pi-hole → PostgreSQL → dbt transformations → Metabase dashboards.

### Home Automation
Home Assistant running in Docker with integrations feeding the analytics pipeline.

### Backups
Duplicati backs up all Docker configs nightly with healthchecks.io dead man's switch monitoring.

### Remote Access
Tailscale mesh VPN for access from anywhere. Replaced self-hosted WireGuard due to ISP CGNAT limitations.

## Standards

- [Naming Conventions](standards/naming.md)
- [Secrets Handling](standards/secrets-handling.md)
- [Backup & Restore](standards/backups-restore.md)
- [Infrastructure Scripts](utilities/scripts.md)

## Hardware

- [Inventory](hardware/inventory.md)
- NAS: Planned for the future
- UPS: TBD
