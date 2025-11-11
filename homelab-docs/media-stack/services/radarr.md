# Radarr

## Overview

Radarr is a movie collection manager that automates finding, downloading, organizing, and upgrading your movie library. It monitors for movies you want, automatically searches for them via Prowlarr, sends downloads to qBittorrent, and then organizes the completed files into your Plex library.

**What it does**:
- Tracks movies you want to download
- Automatically searches for releases when they become available
- Sends downloads to qBittorrent
- Renames and organizes completed movies into your Plex library
- Can upgrade existing movies to better quality (e.g., 720p → 1080p)

**Why you need it**: Radarr is the brain of your movie automation - it knows what movies you want, finds them, gets them, and puts them where Plex can stream them.

## Ports

| Port | Purpose |
|------|---------|
| `7878` | Radarr Web UI and API endpoint |

## How It Works

1. **You add a movie** to Radarr (manually or via Overseerr)
2. **Radarr searches Prowlarr** for available releases
3. **Radarr evaluates releases** based on your quality profile (1080p, 4K, etc.)
4. **Radarr sends the best match** to qBittorrent to download
5. **qBittorrent downloads the file** to `C:\media\downloads`
6. **Radarr monitors the download** and waits for completion
7. **When complete, Radarr**:
   - Renames the file to a standard format
   - Moves it to `C:\media\movies`
   - Updates your library
8. **Plex detects the new movie** and adds it to your library

## Service Interactions

**Receives Requests From**:
- **Overseerr** (users request movies via Overseerr's interface)
- **Manual additions** (you add movies directly in Radarr)

**Searches Via**:
- **Prowlarr** (queries all configured indexers for movie releases)

**Downloads Via**:
- **qBittorrent** (sends torrent files for download)

**Organizes Files For**:
- **Plex** (moves completed movies to Plex's movie directory)

**Workflow**:
```
User adds movie → Radarr → Searches Prowlarr → Finds release
                                                      ↓
                                      Sends to qBittorrent to download
                                                      ↓
                                      Monitors download progress
                                                      ↓
                             Download completes in C:\media\downloads
                                                      ↓
                          Radarr renames and moves to C:\media\movies
                                                      ↓
                                      Plex finds and adds movie
```

## Environment Variables

| Variable | Description | Value in Your Setup |
|----------|-------------|---------------------|
| `PUID` | User ID for file permissions | Loaded from `.env` (ensures file access) |
| `PGID` | Group ID for file permissions | Loaded from `.env` |
| `TZ` | Timezone for release monitoring | Loaded from `.env` |

### Why PUID/PGID Matter
Ensures Radarr can read downloads from qBittorrent and write organized files to your movies folder without permission errors.

## Mounts & Volumes

| Mount | Purpose | Notes |
|-------|---------|-------|
| `C:\media\config\radarr:/config` | Radarr settings, database, and logs | Contains your movie library metadata |
| `C:\media\movies:/movies` | Final destination for organized movies | **Shared with Plex** for streaming |
| `C:\media\downloads:/downloads` | Reads completed downloads from qBittorrent | **Must match qBittorrent's download path** |

**Critical Path Matching**:
- Radarr's `/downloads` mount must point to the same location as qBittorrent's downloads
- Radarr's `/movies` mount must match Plex's movie library path

## Compose File Breakdown

```yaml
radarr:
  image: linuxserver/radarr:latest
  container_name: radarr
  environment:
    - PUID=${PUID}              # File ownership
    - PGID=${PGID}
    - TZ=${TZ}                  # Timezone for release schedules
  volumes:
    - C:\media\config\radarr:/config        # Settings and database
    - C:\media\movies:/movies               # Organized movie library (shared with Plex)
    - C:\media\downloads:/downloads         # Completed downloads (shared with qBittorrent)
  ports:
    - "7878:7878"               # Web UI and API
  restart: unless-stopped
```

## Common Use Cases

- **Automated Movie Downloads**: Add a movie once, Radarr handles the rest
- **Quality Upgrades**: Automatically replace 720p with 1080p when available
- **Library Management**: Keep your movie collection organized and named consistently
- **Release Monitoring**: Get movies as soon as they're released in your preferred quality

## Troubleshooting Tips

**Movie won't download?**
- Check if Prowlarr has working indexers (Settings → Indexers)
- Verify qBittorrent is connected (Settings → Download Clients)
- Look at Radarr → Activity → Queue to see if there are errors
- Check if your quality profile matches available releases

**Download completed but Radarr didn't import it?**
- Verify paths match: qBittorrent's `/downloads` = Radarr's `/downloads`
- Check file permissions (PUID/PGID)
- Look at Radarr → System → Logs for import errors
- Manual import: Activity → Manual Import

**Movie imported but Plex doesn't see it?**
- Check that Radarr moved it to `/movies` (Radarr → Movies → Files)
- Verify Plex's movie library points to `C:\media\movies`
- Manually refresh Plex library

**Quality upgrade stuck?**
- Check your quality profile cutoff (Settings → Profiles)
- Verify "Upgrades Allowed" is enabled
- Look for better releases in Radarr → Movies → [Movie] → Search

**Radarr can't connect to qBittorrent?**
- qBittorrent uses Gluetun's network - set host to `gluetun` or `localhost:8080`
- Verify qBittorrent Web UI is accessible
- Check API key if authentication is enabled in qBittorrent

## Initial Configuration Steps

### 1. First Launch
- Access: `http://localhost:7878`
- Set authentication (Settings → General → Security)

### 2. Add Download Client (qBittorrent)
- Settings → Download Clients → Add → qBittorrent
- Host: `gluetun` (or `localhost`)
- Port: `8080`
- Test connection

### 3. Connect to Prowlarr
- Settings → Indexers → Add → Prowlarr
- **OR** add from Prowlarr side (Settings → Apps → Add → Radarr)
  - Radarr URL: `http://radarr:7878`
  - API Key: Found in Radarr → Settings → General

### 4. Set Root Folder
- Settings → Media Management → Root Folders → Add
- Path: `/movies`

### 5. Create Quality Profile
- Settings → Profiles → Add
- Choose qualities (e.g., 1080p Bluray, WEBDL)
- Set cutoff (quality at which upgrades stop)

### 6. Configure File Naming
- Settings → Media Management → Movie Naming
- Enable "Rename Movies"
- Choose format (e.g., `{Movie Title} ({Release Year})`)

## Understanding Quality Profiles

Radarr uses quality profiles to determine what to download:

- **Qualities**: Which formats you accept (720p, 1080p, 4K, etc.)
- **Cutoff**: Stop upgrading once this quality is reached
- **Priority**: Order of preference (e.g., prefer Bluray over WEBDL)

**Example Profile**:
- Allow: 720p WEBDL, 1080p WEBDL, 1080p Bluray
- Cutoff: 1080p Bluray
- Result: Downloads 720p if available, upgrades to 1080p WEBDL, then upgrades to 1080p Bluray and stops

## Performance Notes

- **CPU**: Light - only active during searches and imports
- **RAM**: ~100-300MB depending on library size
- **Disk**: Database grows with library size (typically <100MB for 1000 movies)
- **Network**: Only uses bandwidth during searches (metadata, not downloads)

## File Organization

Radarr organizes movies with customizable naming:

**Default format**: `Movie Title (Year)/Movie Title (Year).ext`

**Example**:
```
C:\media\movies\
  ├── The Matrix (1999)/
  │   └── The Matrix (1999).mkv
  ├── Inception (2010)/
  │   └── Inception (2010).mkv
```

**Why this matters**: Plex and other media servers rely on consistent naming to fetch metadata and artwork.

## Advanced Features

**Lists**: Auto-add movies from IMDb lists, Trakt lists, or Plex watchlists

**Custom Formats**: Prefer or avoid specific release groups, codecs, or sources

**Notifications**: Get alerts via Discord, Telegram, etc. when movies are added

**Calendar**: See upcoming movie releases you're monitoring

## Security Best Practices

✅ **Enable Authentication**: Protect Web UI with username/password
✅ **Backup Config**: Regularly backup `C:\media\config\radarr`
✅ **API Key Security**: Keep your API key private - it grants full access

## Important Notes

- **Library Size**: Start small and add movies gradually to understand how the system works
- **Disk Space**: Monitor `C:\media\movies` - movies consume significant space
- **Release Timing**: New theatrical releases may take weeks/months to appear in your desired quality
