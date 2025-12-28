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

**Notifications**: Get alerts via Telegram when movies are grabbed, downloaded, imported, or failed

**Calendar**: See upcoming movie releases you're monitoring

## Telegram Notifications

Get reliable, instant notifications for all movie-related events in Telegram.

### Prerequisites
- Complete the [Telegram Bot Setup](../notifications/telegram-setup.md) first
- You'll need your **Bot Token** and **Chat ID**

### Configuration Steps

1. **Open Radarr** at `http://localhost:7878`

2. **Go to Settings → Connect**
   - Click the **+** button
   - Select **Telegram**

3. **Configure Telegram Connection**:
   - **Name**: `Telegram` (or any name you want)
   - **Bot Token**: `8410328014:AAF4MnHVHr-EoJwno7uB4x9weC22HtJI9LU`
   - **Chat ID**: `8320862964`
   - **Send Silently**: `No` (you want sound/vibration for notifications)

4. **Choose Notification Triggers** (enable these):

   ✅ **On Grab** - Notifies when Radarr grabs a movie release from an indexer
   - Message: "Movie grabbed: The Matrix (1999) - 1080p BluRay"

   ✅ **On Import** - Notifies when movie is successfully downloaded and imported
   - Message: "Movie downloaded: The Matrix (1999) - 8.5 GB"

   ✅ **On Upgrade** - Notifies when movie is upgraded to better quality
   - Message: "Movie upgraded: Inception (2010) - 720p → 1080p"

   ✅ **On Rename** - Notifies when Radarr renames files (optional)

   ✅ **On Movie Added** - Notifies when a new movie is added to Radarr (optional)

   ✅ **On Movie Delete** - Notifies when a movie is deleted

   ✅ **On Movie File Delete** - Notifies when movie file is deleted

   ✅ **On Health Issue** - Critical! Notifies about problems
   - Examples: "Indexer unavailable", "Download client error", "Disk space low"

   ✅ **On Health Restored** - Notifies when issues are resolved

   ✅ **On Application Update** - Notifies when Radarr updates (optional)

   ⚠️ **On Download Failure** - This is handled by "On Import Complete" when it fails

5. **Test the Connection**
   - Click **Test** button
   - You should receive a test notification in Telegram
   - If it fails, verify your bot token and chat ID

6. **Save** the connection

### Notification Examples

**Movie Grabbed:**
```
[Movie Grabbed] The Matrix (1999)
Quality: Bluray-1080p
Release: The.Matrix.1999.1080p.BluRay.x264-GROUP
Indexer: 1337x
```

**Movie Downloaded:**
```
[Movie Downloaded] The Matrix (1999)
Quality: Bluray-1080p
Size: 8.5 GB
Time: 45 minutes
```

**Download Failed:**
```
[Download Warning] Inception (2010)
Download client reported an error
Release: Inception.2010.1080p.BluRay
Error: Indexer returned 404 - file not found
```

**Health Issue:**
```
[Health Check Failure]
Issue: Indexer 1337x is unavailable
Time: 2025-12-27 14:30
```

### Troubleshooting Notifications

**Not receiving notifications?**
- Verify bot token and chat ID are correct
- Make sure you started a conversation with your bot (send `/start`)
- Check Radarr → System → Logs for Telegram errors
- Test the connection again

**Receiving too many notifications?**
- Disable optional triggers (On Rename, On Movie Added, On Application Update)
- Use Telegram's mute feature for specific times
- Adjust notification settings in Telegram app

**Notifications are delayed?**
- Telegram is usually instant - check your internet connection
- Verify Radarr isn't rate-limited (System → Logs)
- Check if bot is blocked or restricted

### What You Should Monitor

**Essential Notifications** (keep these enabled):
- ✅ On Import (know when movies finish)
- ✅ On Health Issue (catch problems early)
- ✅ On Grab (know what's downloading)

**Optional Notifications** (can be noisy):
- On Movie Added (if you use Overseerr, you'll get duplicate notifications)
- On Rename (only useful if debugging)
- On Application Update (unless you care about updates)

## Security Best Practices

✅ **Enable Authentication**: Protect Web UI with username/password
✅ **Backup Config**: Regularly backup `C:\media\config\radarr`
✅ **API Key Security**: Keep your API key private - it grants full access

## Important Notes

- **Library Size**: Start small and add movies gradually to understand how the system works
- **Disk Space**: Monitor `C:\media\movies` - movies consume significant space
- **Release Timing**: New theatrical releases may take weeks/months to appear in your desired quality
