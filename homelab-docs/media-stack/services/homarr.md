# Homarr

## Overview

Homarr is a customizable dashboard and homepage for your homelab. It provides a central location to access all your services (Plex, Sonarr, Radarr, Overseerr, etc.) with beautiful widgets, status monitoring, and quick links. Think of it as your homelab's mission control center.

**What it does**:
- Provides a unified dashboard with links to all your services
- Displays real-time status of your Docker containers
- Shows system metrics (CPU, RAM, disk usage)
- Integrates with your *arr apps to show statistics
- Customizable layout with drag-and-drop widgets
- Can display weather, calendar, RSS feeds, and more

**Why you need it**: Instead of bookmarking 10+ different URLs for each service, Homarr gives you one beautiful page to access everything.

## Ports

| Port | Purpose |
|------|---------|
| `7575` | Homarr Web UI |

## How It Works

1. **You access Homarr** via `http://localhost:7575`
2. **Dashboard displays** all your configured services with status indicators
3. **Click any service card** to open that service
4. **Homarr monitors services** via Docker socket or API integrations
5. **Widgets update in real-time** showing service health and statistics

## Service Interactions

**Monitors**:
- All your Docker containers (via Docker socket mount)
- Sonarr/Radarr/Overseerr (via API integrations for statistics)
- System resources (via dashdot integration, optional)

**Provides Access To**:
- Plex, Overseerr, Sonarr, Radarr, Prowlarr, Portainer, and any other services you add

**Workflow**:
```
User opens Homarr ’ Views dashboard with all services
                           “
                 Clicks service card ’ Opens service in new tab
                           “
          Homarr continuously monitors service status
```

## Environment Variables

| Variable | Description | Value in Your Setup |
|----------|-------------|---------------------|
| `TZ` | Timezone for logs and scheduling | Loaded from `.env` |
| `SECRET_ENCRYPTION_KEY` | Encryption key for sensitive data | A long random hex string (already configured in your compose) |

### Secret Encryption Key
This key encrypts sensitive information like API keys you add to Homarr. **Do not change this after initial setup** or you'll lose access to encrypted data.

## Mounts & Volumes

| Mount | Purpose | Notes |
|-------|---------|-------|
| `C:/media/config/homarr:/appdata` | Homarr configuration and database | Contains dashboard layouts, service configs, API keys |
| `/var/run/docker.sock:/var/run/docker.sock` | Docker socket access | Allows Homarr to monitor and manage Docker containers |

**Important**: The Docker socket mount gives Homarr visibility into all running containers.

## Compose File Breakdown

```yaml
homarr:
  image: ghcr.io/homarr-labs/homarr:latest
  container_name: homarr
  volumes:
    - "C:/media/config/homarr:/appdata"           # Config storage
    - /var/run/docker.sock:/var/run/docker.sock   # Docker monitoring
  ports:
    - "7575:7575"                                  # Web interface
  environment:
    - TZ=${TZ}                                     # Timezone
    - SECRET_ENCRYPTION_KEY=af6eadbe...            # Encryption for API keys
  restart: unless-stopped
```

## Common Use Cases

- **Centralized Access**: One page for all your services
- **Status Monitoring**: See which services are up/down at a glance
- **Quick Links**: Bookmark Homarr instead of individual services
- **Service Statistics**: See Sonarr/Radarr library counts, recent activity
- **System Health**: Monitor CPU, RAM, disk usage
- **New User Introduction**: Great landing page for family/friends accessing your server

## Troubleshooting Tips

**Can't see Docker containers?**
- Verify Docker socket is mounted correctly
- Check container permissions
- View Homarr logs: `docker logs homarr`

**Service integrations not working?**
- Add API keys in Homarr settings (Settings ’ Services)
- Verify service URLs are correct (use container names: `http://sonarr:8989`)
- Test connectivity from Homarr to each service

**Dashboard layout broken after update?**
- Check Homarr logs for errors
- May need to reset layout (Settings ’ Import/Export)
- Backup your config before major updates

**Can't access Homarr remotely?**
- Ensure port 7575 is accessible (port forwarding if needed)
- Consider using a reverse proxy (Nginx, Traefik) for HTTPS

## Initial Configuration Steps

### 1. First Launch
- Access: `http://localhost:7575`
- Complete initial setup wizard
- Choose dashboard layout style

### 2. Add Services
- Click "+ Add Service" or "+ Add a widget"
- Search for your services (Sonarr, Radarr, Plex, etc.)
- For each service:
  - Set URL: `http://servicename:port` (e.g., `http://sonarr:8989`)
  - Add API key (if applicable)
  - Choose icon and appearance
  - Save

### 3. Configure Integrations
- Settings ’ Integrations
- Add API keys for *arr apps to display statistics:
  - Sonarr API: Shows series count, upcoming episodes
  - Radarr API: Shows movie count, upcoming releases
  - Prowlarr API: Shows indexer health
  - Overseerr API: Shows pending requests

### 4. Customize Dashboard
- Drag and drop widgets to rearrange
- Resize widgets by dragging corners
- Add additional widgets:
  - Weather
  - Calendar
  - RSS feeds
  - System monitors
  - Bookmarks
  - iFrame embeds

### 5. Appearance Settings
- Settings ’ Appearance
- Choose theme (light/dark)
- Customize colors
- Set background image (optional)

## Widget Types

**Service Tiles**: Quick links to your applications

**Stat Widgets**: Display metrics from integrated services
- Sonarr: Series count, episodes monitored, recent grabs
- Radarr: Movie count, monitored movies, recent adds
- Download Client: Active downloads, queue size

**System Monitors**: Show CPU, RAM, disk usage (requires dashdot or similar)

**Media Widgets**: RSS feeds, calendars, bookmarks

**Docker Container Status**: Shows running/stopped containers

**Weather**: Local weather forecast

**Search Bar**: Quick search across services

## Dashboard Organization Ideas

**Example Layout 1 - By Function**:
- Top Row: Media (Plex, Overseerr)
- Middle Row: Management (*arr apps)
- Bottom Row: System (Portainer, Dashdot)

**Example Layout 2 - By Usage Frequency**:
- Most Used: Plex, Overseerr
- Management: Sonarr, Radarr, Prowlarr
- Maintenance: Portainer, qBittorrent

**Example Layout 3 - For Shared Users**:
- User-facing only: Plex, Overseerr
- Hide admin tools

## Performance Notes

- **CPU**: Very light - mostly idle
- **RAM**: ~50-150MB
- **Network**: Minimal - periodic API calls to integrated services
- **Load Time**: Dashboard loads quickly, <1 second typically

## Advanced Features

**Multiple Dashboards**: Create different boards for different purposes (admin, users, mobile)

**Background Jobs**: Schedule tasks (though your services handle most automation)

**User Authentication**: Protect dashboard with login (Settings ’ Auth)

**Reverse Proxy Integration**: Works well behind Nginx, Traefik, Caddy for HTTPS

**Custom CSS**: Advanced customization with custom CSS

**Ping Monitoring**: Monitor service availability

## Integration Examples

**Sonarr Integration**:
- Shows total series, monitored series
- Recent downloads
- Upcoming episodes
- Calendar of air dates

**Radarr Integration**:
- Total movies, monitored movies
- Recent additions
- Upcoming releases
- Missing movies count

**Download Client** (qBittorrent):
- Active downloads
- Download/upload speeds
- Queue size

**Plex Integration** (if configured):
- Now playing
- Recent additions
- Library statistics

## Mobile Access

- Homarr is fully responsive
- Works great on tablets and phones
- Can add to mobile home screen as PWA (Progressive Web App)
- Touch-friendly interface

## Backup & Restore

**Backup**:
- Export dashboard layout: Settings ’ Import/Export ’ Export
- Backup config folder: `C:/media/config/homarr`

**Restore**:
- Import dashboard layout: Settings ’ Import/Export ’ Import
- Restore config folder from backup

## Security Best Practices

 **Enable Authentication**: Set up login (Settings ’ Authentication)
 **HTTPS**: Use reverse proxy for secure access
 **API Key Protection**: Homarr encrypts stored API keys
 **Limited Exposure**: Don't expose Homarr to internet without authentication
 **Regular Backups**: Backup your dashboard configuration

## Alternatives to Homarr

Other dashboard options (if you want to explore):
- **Heimdall**: Simpler, fewer integrations
- **Homer**: Static configuration via YAML
- **Organizr**: More authentication features
- **Flame**: Minimal and fast
- **Dashy**: Highly customizable

**Why Homarr?** Modern interface, Docker integration, active development, good widget support.

## Important Notes

- **Docker Socket Access**: Homarr has privileged access to Docker - be cautious with permissions
- **API Keys**: Store API keys securely; Homarr encrypts them with your SECRET_ENCRYPTION_KEY
- **Updates**: Watchtower will auto-update Homarr; check release notes for breaking changes
- **Customization**: Homarr is very flexible - experiment with layouts to find what works for you
