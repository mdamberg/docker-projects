# qBittorrent

## Overview

qBittorrent is a free, open-source BitTorrent client that downloads media files from torrent indexers. It's the download engine of your media stack - when Sonarr, Radarr, or LazyLibrarian find content you want, they send download requests to qBittorrent, which handles the actual file transfer.

**What it does**: Downloads files via the BitTorrent protocol based on .torrent files or magnet links sent by Sonarr, Radarr, and LazyLibrarian.

**Why you need it**: Your *arr applications find content, but they need a download client to actually retrieve the files. qBittorrent is that download client.

## Ports

| Port | Purpose |
|------|---------|
| `8080` | Web UI (accessed via Gluetun since qBittorrent uses Gluetun's network) |
| `6881` (TCP & UDP) | BitTorrent protocol port for peer connections |

**Important**: These ports are exposed on **Gluetun**, not directly on qBittorrent, because qBittorrent routes all traffic through the VPN.

## How It Works

1. **Sonarr/Radarr/LazyLibrarian find content** you want (e.g., a TV episode)
2. **They send a download request** to qBittorrent with a torrent file or magnet link
3. **qBittorrent connects to peers** through the BitTorrent network (via Gluetun VPN)
4. **Downloads the file** to your configured downloads folder (`C:\media\downloads`)
5. **Notifies the requesting app** when the download completes
6. **The *arr app moves/renames the file** to its final location (movies, TV, books)

## Service Interactions

**Receives Downloads From**:
- **Sonarr** (TV shows)
- **Radarr** (Movies)
- **LazyLibrarian** (Books/Audiobooks)

**Routed Through**:
- **Gluetun** (VPN tunnel for privacy and security)

**Saves Files To**:
- `C:\media\downloads` (shared with Sonarr, Radarr, LazyLibrarian for file access)

**Workflow**:
```
Sonarr/Radarr/LazyLibrarian → qBittorrent API → Gluetun VPN → BitTorrent Network
                                                     ↓
                                          C:\media\downloads
                                                     ↓
                                    Sonarr/Radarr/LazyLibrarian picks up completed file
```

## Environment Variables

| Variable | Description | Value in Your Setup |
|----------|-------------|---------------------|
| `PUID` | User ID for file permissions | Loaded from `.env` (ensures you can access downloaded files) |
| `PGID` | Group ID for file permissions | Loaded from `.env` |
| `TZ` | Timezone | Loaded from `.env` |
| `WEBUI_PORT` | Internal Web UI port | `8080` (matches Gluetun's exposed port) |

### Why PUID/PGID Matter
These ensure downloaded files have the correct ownership so Windows (or your user account) can read, write, and delete them without permission issues.

## Mounts & Volumes

| Mount | Purpose | Notes |
|-------|---------|-------|
| `C:\media\config\qbittorrent:/config` | Stores qBittorrent settings, state files, and session data | Preserves settings across container restarts |
| `C:\media\downloads:/downloads` | Where completed and in-progress downloads are stored | **Shared with Sonarr, Radarr, and LazyLibrarian** for file handoff |

**Critical**: The `/downloads` mount must be identical across qBittorrent and all *arr apps for them to find completed files.

## Compose File Breakdown

```yaml
qbittorrent:
  image: linuxserver/qbittorrent:latest
  container_name: qbittorrent
  network_mode: "service:gluetun"        # Routes ALL traffic through Gluetun VPN
  environment:
    - PUID=${PUID}                       # File ownership
    - PGID=${PGID}
    - TZ=${TZ}
    - WEBUI_PORT=8080                    # Web interface port
  volumes:
    - C:\media\config\qbittorrent:/config   # Settings storage
    - C:\media\downloads:/downloads         # Download destination (shared with *arr apps)
  depends_on:
    - gluetun                            # Ensures Gluetun starts first
  restart: unless-stopped
```

### Network Mode Explained
`network_mode: "service:gluetun"` means:
- qBittorrent doesn't have its own network interface
- All network traffic goes through Gluetun's VPN tunnel
- If Gluetun stops, qBittorrent loses internet access (by design - prevents leaks)
- You access qBittorrent's Web UI via Gluetun's IP address

## Common Use Cases

- **Automated Downloads**: Receives and processes downloads from Sonarr/Radarr/LazyLibrarian
- **Manual Downloads**: You can also manually add torrents via the Web UI
- **Seeding**: Continues to upload (seed) files after download to maintain torrent health

## Troubleshooting Tips

**Can't access qBittorrent Web UI?**
- Remember: Access via `http://localhost:8080` (Gluetun's port, not qBittorrent's)
- Check if Gluetun is running: `docker ps | grep gluetun`
- If Gluetun is down, qBittorrent has no network access

**Downloads failing or stalled?**
- Check Gluetun VPN connection: `docker logs gluetun`
- Verify port forwarding is working (some VPNs require this)
- Check disk space on `C:\media\downloads`

**Sonarr/Radarr can't see completed downloads?**
- Verify the downloads path is **exactly the same** in qBittorrent and the *arr app
- Check file permissions (PUID/PGID match)
- Look in qBittorrent settings → Downloads → ensure "Keep incomplete torrents" is in a subfolder

**VPN leak concerns?**
- qBittorrent ONLY works through Gluetun - if VPN drops, downloads stop
- Verify at the Web UI level: check your IP via a browser in qBittorrent's search plugins

## Security & Privacy Features

✅ **VPN-Only Operation**: All traffic forced through Gluetun VPN
✅ **No Direct Internet Access**: Network isolation prevents IP leaks
✅ **Automatic Kill Switch**: If Gluetun stops, qBittorrent loses connectivity

## Performance Notes

- **Disk Usage**: Downloads can consume significant space; monitor `C:\media\downloads`
- **CPU**: Light during normal operation, higher during active downloads
- **RAM**: ~100-300MB depending on number of active torrents

## Configuration Tips

**In qBittorrent Settings**:
- Set download path to `/downloads` (this maps to `C:\media\downloads` via volume mount)
- Enable "Automatically add torrents from" if you want to drop .torrent files in a folder
- Configure speed limits if needed (Settings → Speed)
- Set seeding goals (e.g., seed until ratio of 2.0 or for 7 days)

**In Sonarr/Radarr/LazyLibrarian**:
- Add qBittorrent as download client
- Host: `gluetun` (or `localhost` if same machine)
- Port: `8080`
- Category: Set different categories for each app (optional but helpful for organization)
