# Prowlarr

## Overview

Prowlarr is a centralized indexer manager for your *arr stack. Instead of configuring torrent indexers (like 1337x, The Pirate Bay, RARBG alternatives, etc.) separately in Sonarr, Radarr, and LazyLibrarian, you configure them once in Prowlarr, and it automatically syncs them to all your apps.

**What it does**:
- Manages torrent and Usenet indexers in one place
- Searches indexers when your *arr apps need to find content
- Automatically syncs indexer configurations to Sonarr, Radarr, and LazyLibrarian

**Why you need it**: Without Prowlarr, you'd have to manually add and maintain indexers in each *arr app separately. Prowlarr makes this a one-time configuration that automatically propagates everywhere.

## Ports

| Port | Purpose |
|------|---------|
| `9696` | Prowlarr Web UI and API endpoint |

## How It Works

1. **You configure indexers in Prowlarr** (e.g., add 1337x, YTS, Nyaa)
2. **Prowlarr connects to your *arr apps** (Sonarr, Radarr, LazyLibrarian)
3. **Prowlarr syncs indexers** to those apps automatically
4. **When Sonarr/Radarr/LazyLibrarian need to search**:
   - They send a search query to Prowlarr
   - Prowlarr queries all configured indexers
   - Prowlarr returns combined results
   - The *arr app picks the best release and sends it to qBittorrent

Think of Prowlarr as the "phone book" that knows where to find content.

## Service Interactions

**Provides Indexers To**:
- **Sonarr** (searches for TV shows)
- **Radarr** (searches for movies)
- **LazyLibrarian** (searches for books/audiobooks)

**Uses**:
- **FlareSolverr** (to bypass Cloudflare protection on some indexers)

**Workflow**:
```
Sonarr/Radarr/LazyLibrarian ’ Search Request ’ Prowlarr
                                                   “
                                    Queries All Configured Indexers
                                    (via FlareSolverr if needed)
                                                   “
                                    Returns Combined Results
                                                   “
                            Sonarr/Radarr/LazyLibrarian picks best match
                                                   “
                                    Sends to qBittorrent to download
```

## Environment Variables

| Variable | Description | Value in Your Setup |
|----------|-------------|---------------------|
| `PUID` | User ID for file permissions | Loaded from `.env` |
| `PGID` | Group ID for file permissions | Loaded from `.env` |
| `TZ` | Timezone for scheduled tasks and logs | Loaded from `.env` |

## Mounts & Volumes

| Mount | Purpose | Notes |
|-------|---------|-------|
| `C:\media\config\prowlarr:/config` | Stores Prowlarr settings, indexer configs, and app sync settings | Contains database and API keys |

**Important**: Back up this directory regularly - it contains all your indexer configurations and API keys for your *arr apps.

## Compose File Breakdown

```yaml
prowlarr:
  image: linuxserver/prowlarr:latest
  container_name: prowlarr
  environment:
    - PUID=${PUID}        # File ownership
    - PGID=${PGID}
    - TZ=${TZ}            # Timezone for scheduling
  volumes:
    - C:\media\config\prowlarr:/config    # Settings and database
  ports:
    - "9696:9696"         # Web UI and API
  restart: unless-stopped
```

## Common Use Cases

- **Centralized Indexer Management**: Add/remove/update indexers in one place
- **Automatic Syncing**: Changes in Prowlarr instantly reflect in all *arr apps
- **Search Aggregation**: Prowlarr searches multiple indexers simultaneously for better results
- **Indexer Health Monitoring**: See which indexers are working or down

## Troubleshooting Tips

**Indexers not syncing to Sonarr/Radarr?**
- Check that you've added the apps in Prowlarr ’ Settings ’ Apps
- Verify API keys are correct
- Look at Prowlarr logs: `docker logs prowlarr`

**Search results are empty?**
- Check indexer status in Prowlarr (some may be down)
- Verify FlareSolverr is working for Cloudflare-protected indexers
- Test individual indexers manually in Prowlarr

**Can't add certain indexers?**
- Some require FlareSolverr (add FlareSolverr tag to those indexers)
- Some require VIP/premium accounts
- Check indexer-specific notes in Prowlarr

**App sync failed error?**
- Verify the target app (Sonarr/Radarr) is running
- Check that the app URL and API key are correct in Prowlarr
- Ensure there are no firewall/network issues between containers

## Initial Configuration Steps

1. **Access Web UI**: `http://localhost:9696`
2. **Set Authentication**: Settings ’ General ’ Authentication (recommended: Forms with username/password)
3. **Add Indexers**: Indexers ’ Add Indexer ’ Search for your preferred sites
4. **Configure FlareSolverr** (if needed): Settings ’ Indexers ’ FlareSolverr Tags
   - FlareSolverr URL: `http://flaresolverr:8191`
5. **Add Apps**: Settings ’ Apps ’ Add Application
   - Add Sonarr, Radarr, LazyLibrarian with their API keys
6. **Sync**: Click "Sync App Indexers" to push configurations

## Indexer Categories Explained

Prowlarr categorizes indexers to help apps find the right content:

- **Movies**: Radarr searches these
- **TV**: Sonarr searches these
- **Books**: LazyLibrarian searches these
- **General**: Searched by all apps (usually general torrent sites)

## Performance Notes

- **CPU**: Very light - only active during searches
- **RAM**: ~100-200MB
- **Network**: Minimal - only queries indexers when apps request searches
- **Response Time**: Searches typically complete in 1-5 seconds (longer with FlareSolverr)

## Security Best Practices

 **Enable Authentication**: Protect the Web UI with a password
 **Use HTTPS** (optional): Can be configured with a reverse proxy
 **API Key Protection**: Keep API keys secure - they give full access to Prowlarr
 **Regular Updates**: Prowlarr frequently adds support for new indexers

## Advanced Features

**Health Checks**: Prowlarr monitors indexer availability and alerts you to issues

**Statistics**: Track which indexers provide the most results

**Tags**: Organize indexers with tags (e.g., "public", "private", "4k-content")

**Custom Filters**: Create advanced search filters for specific content needs

## Important Notes

- **Indexer Legality**: Torrent indexers may link to copyrighted content. Use responsibly and legally in your jurisdiction.
- **Indexer Reliability**: Public indexers often go down or change URLs. Prowlarr's community updates these regularly.
- **Private Indexers**: Some users prefer private trackers for better quality and speed (require invitations).
