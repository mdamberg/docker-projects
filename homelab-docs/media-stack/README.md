# Media Stack

Automated media management system for movies, TV shows, books, and audiobooks.

## Quick Links

| Service | URL | Purpose |
|---------|-----|---------|
| Overseerr | `http://localhost:5055` | Request movies/TV shows |
| Radarr | `http://localhost:7878` | Movie management |
| Sonarr | `http://localhost:8989` | TV show management |
| Prowlarr | `http://localhost:9696` | Indexer management |
| qBittorrent | `http://localhost:8080` | Download client |
| Plex | `http://localhost:32400` | Media streaming |
| Tautulli | `http://localhost:8181` | Plex statistics |
| Homarr | `http://localhost:7575` | Dashboard |

## Operations

- [Deployment](ops/deploy.md)
- [Upgrading](ops/upgrade.md)
- [Backup & Restore](ops/backup-restore.md)
- [Deleting Media](ops/deleting-media.md) - How to properly delete content without re-downloads
- [Troubleshooting](ops/troubleshooting.md)

## Services

- [Radarr](services/radarr.md) - Movie automation
- [Sonarr](services/sonarr.md) - TV show automation
- [Prowlarr](services/prowlarr.md) - Indexer management
- [Overseerr](services/overseerr.md) - Request management
- [qBittorrent](services/qbittorrent.md) - Download client
- [Plex](services/plex.md) - Media server
- [Gluetun](services/gluetun.md) - VPN container
- [FlareSolverr](services/flaresolverr.md) - Cloudflare bypass
- [Homarr](services/homarr.md) - Dashboard
- [AudioBookShelf](services/audiobookshelf.md) - Audiobooks & podcasts
- [Lazy Librarian](services/lazylibrarian.md) - Book automation
- [Watchtower](services/watchtower.md) - Auto-updates
- [Portainer](services/portainer.md) - Docker management
- [Dashdot](services/dashdot.md) - System monitoring

## Notifications

- [Telegram Setup](notifications/telegram-setup.md)
- [qBittorrent Telegram](notifications/qbittorrent-telegram.md)

## Architecture

```
User Request Flow:
Overseerr → Radarr/Sonarr → Prowlarr → qBittorrent (via Gluetun VPN) → Plex

Storage:
C:\media\
├── config\      # Service configurations
├── downloads\   # Active downloads
├── movies\      # Radarr-organized movies
├── tv\          # Sonarr-organized TV shows
├── books\       # Lazy Librarian books
├── audiobooks\  # AudioBookShelf content
└── podcasts\    # AudioBookShelf podcasts
```

## Compose File

See [compose.md](compose.md) for the full docker-compose configuration.
