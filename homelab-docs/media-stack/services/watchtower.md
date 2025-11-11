# Watchtower

## Overview

Watchtower is an automated Docker container update service that monitors all running containers and automatically pulls new images and restarts containers when updates are available. Think of it as your homelab's automatic maintenance worker - it keeps all your services up-to-date without manual intervention.

**What it does**: Checks for new versions of your container images, downloads updates, and safely restarts containers with the new versions.

**Why you need it**: Keeps your services secure with the latest patches and features without requiring you to manually check and update each service.

## Ports

Watchtower doesn't expose any ports - it works entirely in the background by communicating with the Docker engine.

## How It Works

1. **Scheduled Checks**: Watchtower runs on a schedule (configured via `WATCHTOWER_SCHEDULE`)
2. **Image Comparison**: It checks Docker Hub (or your configured registry) for newer versions of each container's image
3. **Update Process**: If a new version is found:
   - Pulls the new image
   - Stops the old container
   - Starts a new container with the same configuration
   - Removes the old image (if `WATCHTOWER_CLEANUP` is enabled)

## Service Interactions

**Monitors**: All containers in your stack (qBittorrent, Sonarr, Radarr, Plex, etc.)

**Note**: Watchtower operates independently and doesn't interact directly with your services - it manages them at the Docker level.

## Environment Variables

| Variable | Description | Value in Your Setup |
|----------|-------------|---------------------|
| `TZ` | Timezone for scheduling | Loaded from `.env` file |
| `WATCHTOWER_CLEANUP` | Remove old images after update | `true` (saves disk space) |
| `WATCHTOWER_INCLUDE_RESTARTING` | Update containers even if restarting | `true` |
| `WATCHTOWER_SCHEDULE` | Cron schedule for checks | `0 0 4 * * *` (runs at 4 AM daily) |

### Understanding the Schedule
`0 0 4 * * *` is a cron expression meaning:
- Run at 4:00 AM
- Every day
- Every month

## Mounts & Volumes

| Mount | Purpose |
|-------|---------|
| `/var/run/docker.sock:/var/run/docker.sock` | Gives Watchtower access to the Docker engine to manage containers. **Critical**: This is a privileged mount that allows full Docker control. |

**Important**: The Docker socket mount gives Watchtower administrative control over all containers on your system.

## Compose File Breakdown

```yaml
watchtower:
  image: containrrr/watchtower:latest
  container_name: watchtower
  environment:
    - TZ=${TZ}
    - WATCHTOWER_CLEANUP=true              # Removes old images after updating
    - WATCHTOWER_INCLUDE_RESTARTING=true   # Updates containers in restart state
    - WATCHTOWER_SCHEDULE=0 0 4 * * *      # Checks for updates daily at 4 AM
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock  # Docker engine access
  restart: unless-stopped
```

## Common Use Cases

- **Automatic Security Patches**: Get security updates as soon as they're released
- **Feature Updates**: Always run the latest stable versions
- **Hands-off Maintenance**: No need to manually update 13+ containers

## Troubleshooting Tips

**Container keeps reverting after manual changes?**
- Watchtower may be overwriting your changes. Temporarily exclude that container from Watchtower monitoring.

**Want to exclude a specific container?**
- Add a label to that container: `com.centurylinklabs.watchtower.enable=false`

**Update caused issues?**
- Check container logs: `docker logs watchtower`
- Revert by manually pulling an older image version

## Safety Considerations

- Updates happen at 4 AM (low-traffic time) to minimize disruption
- Consider testing updates in a non-production environment first for critical services
- Watchtower respects your volume mounts - your data and configs are preserved during updates
