# FlareSolverr

## Overview

FlareSolverr is a proxy server that solves Cloudflare and DDoS-GUARD protection challenges that many torrent indexers use. When Prowlarr tries to search torrent sites, it often encounters Cloudflare's "I'm not a robot" checks. FlareSolverr handles these challenges automatically, allowing Prowlarr to access protected indexers.

**What it does**: Acts as a middleware that bypasses Cloudflare protection so Prowlarr can search torrent indexers without being blocked.

**Why you need it**: Many popular torrent indexers use Cloudflare protection. Without FlareSolverr, Prowlarr would fail to search these sites, severely limiting your ability to find content.

## Ports

| Port | Purpose |
|------|---------|
| `8191` | FlareSolverr API endpoint (used by Prowlarr to send requests) |

## How It Works

1. **Prowlarr makes a request** to search an indexer (like 1337x, RARBG alternatives, etc.)
2. **Indexer returns Cloudflare challenge** instead of search results
3. **Prowlarr forwards the request to FlareSolverr** (via port 8191)
4. **FlareSolverr solves the challenge** using browser automation
5. **FlareSolverr returns the solved page** to Prowlarr
6. **Prowlarr extracts search results** and passes them to Sonarr/Radarr

Think of it as a translator that speaks "Cloudflare" so Prowlarr doesn't have to.

## Service Interactions

**Primary User**: Prowlarr

**Workflow**:
```
Prowlarr → FlareSolverr (port 8191) → Protected Indexer → Results back to Prowlarr
```

**Configuration in Prowlarr**:
- You'll configure FlareSolverr in Prowlarr under Settings → Indexers
- Set FlareSolverr URL to: `http://flaresolverr:8191`

## Environment Variables

| Variable | Description | Value in Your Setup |
|----------|-------------|---------------------|
| `LOG_LEVEL` | Controls logging verbosity | `info` (shows important events) |
| `TZ` | Timezone for logs | Loaded from `.env` file |

### Log Levels Explained
- `error`: Only critical issues
- `info`: General operational information (your setting)
- `debug`: Detailed troubleshooting information

## Mounts & Volumes

FlareSolverr doesn't require any persistent volumes - it runs entirely in memory and doesn't store data between restarts.

## Compose File Breakdown

```yaml
flaresolverr:
  image: ghcr.io/flaresolverr/flaresolverr:latest
  container_name: flaresolverr
  environment:
    - LOG_LEVEL=info    # Moderate logging for monitoring
    - TZ=${TZ}          # Timezone for log timestamps
  ports:
    - "8191:8191"       # API endpoint for Prowlarr
  restart: unless-stopped
```

## Common Use Cases

- **Bypassing Cloudflare**: Main purpose - allows access to protected torrent indexers
- **Avoiding Rate Limits**: Some indexers use Cloudflare to prevent scraping; FlareSolverr helps maintain access
- **Indexer Reliability**: Keeps your indexers working even when they add/change protection

## Troubleshooting Tips

**Prowlarr shows "FlareSolverr error" or timeout?**
- Check if FlareSolverr is running: `docker ps | grep flaresolverr`
- View FlareSolverr logs: `docker logs flaresolverr`
- Test the service: Open `http://localhost:8191` in a browser (should show FlareSolverr info)

**Indexer still failing with FlareSolverr enabled?**
- The indexer might be down or using different protection
- Try disabling and re-enabling FlareSolverr in Prowlarr's indexer settings
- Check if the indexer is tagged to use FlareSolverr in Prowlarr

**High CPU usage?**
- Normal when solving challenges (uses browser automation)
- If persistent, check logs for errors or restart the container

## Performance Notes

- **Resource Usage**: Moderate - uses Chromium browser in headless mode
- **Response Time**: Adds 5-15 seconds to indexer queries (solving challenges takes time)
- **Memory**: Can use 200-500MB RAM when actively solving challenges

## Integration Setup

To configure FlareSolverr in Prowlarr:
1. Go to Prowlarr → Settings → Indexers
2. Scroll to FlareSolverr section
3. Add Tag (e.g., "flaresolverr")
4. Set URL: `http://flaresolverr:8191`
5. Tag indexers that need FlareSolverr with this tag

**Tip**: Only enable FlareSolverr for indexers that actually need it, as it adds latency to searches.
