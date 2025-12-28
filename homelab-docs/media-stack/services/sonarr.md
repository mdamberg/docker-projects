# Sonarr

## Overview

Sonarr is a TV show collection manager that automates finding, downloading, organizing, and upgrading your TV library. It monitors TV series you're watching, automatically searches for new episodes when they air, sends downloads to qBittorrent, and then organizes the completed files into your Plex library.

**What it does**:
- Tracks TV shows and monitors for new episodes
- Automatically searches for episodes as they air
- Sends downloads to qBittorrent
- Renames and organizes completed episodes into your Plex library
- Can upgrade existing episodes to better quality (e.g., 720p → 1080p)

**Why you need it**: Sonarr is the brain of your TV automation - it knows what shows you watch, finds new episodes automatically, gets them, and puts them where Plex can stream them.

## Ports

| Port | Purpose |
|------|---------|
| `8989` | Sonarr Web UI and API endpoint |

## How It Works

1. **You add a TV series** to Sonarr (manually or via Overseerr)
2. **Sonarr monitors the series** and knows when new episodes air
3. **When an episode airs, Sonarr searches Prowlarr** for available releases
4. **Sonarr evaluates releases** based on your quality profile
5. **Sonarr sends the best match** to qBittorrent to download
6. **qBittorrent downloads the file** to `C:\media\downloads`
7. **Sonarr monitors the download** and waits for completion
8. **When complete, Sonarr**:
   - Renames the file to a standard format (e.g., `Series - S01E01 - Episode Title.mkv`)
   - Moves it to `C:\media\tv/Series Name/Season 01/`
   - Updates your library
9. **Plex detects the new episode** and adds it to your library

## Service Interactions

**Receives Requests From**:
- **Overseerr** (users request TV shows via Overseerr's interface)
- **Manual additions** (you add shows directly in Sonarr)

**Searches Via**:
- **Prowlarr** (queries all configured indexers for TV releases)

**Downloads Via**:
- **qBittorrent** (sends torrent files for download)

**Organizes Files For**:
- **Plex** (moves completed episodes to Plex's TV directory)

**Workflow**:
```
User adds TV show → Sonarr monitors air dates → Episode airs → Sonarr searches Prowlarr
                                                                         ↓
                                                         Sends to qBittorrent to download
                                                                         ↓
                                                         Monitors download progress
                                                                         ↓
                                                Download completes in C:\media\downloads
                                                                         ↓
                                    Sonarr renames and moves to C:\media\tv\ShowName\Season XX\
                                                                         ↓
                                                         Plex finds and adds episode
```

## Environment Variables

| Variable | Description | Value in Your Setup |
|----------|-------------|---------------------|
| `PUID` | User ID for file permissions | Loaded from `.env` (ensures file access) |
| `PGID` | Group ID for file permissions | Loaded from `.env` |
| `TZ` | Timezone for air date tracking | Loaded from `.env` (critical for knowing when episodes air!) |

### Why TZ (Timezone) is Critical
Sonarr needs your timezone to know when episodes air in your local time. If this is wrong, it might search too early or too late.

## Mounts & Volumes

| Mount | Purpose | Notes |
|-------|---------|-------|
| `C:\media\config\sonarr:/config` | Sonarr settings, database, and logs | Contains your TV series library metadata |
| `C:\media\tv:/tv` | Final destination for organized TV shows | **Shared with Plex** for streaming |
| `C:\media\downloads:/downloads` | Reads completed downloads from qBittorrent | **Must match qBittorrent's download path** |

**Critical Path Matching**:
- Sonarr's `/downloads` mount must point to the same location as qBittorrent's downloads
- Sonarr's `/tv` mount must match Plex's TV library path

## Compose File Breakdown

```yaml
sonarr:
  image: linuxserver/sonarr:latest
  container_name: sonarr
  environment:
    - PUID=${PUID}              # File ownership
    - PGID=${PGID}
    - TZ=${TZ}                  # Critical for episode air times!
  volumes:
    - C:\media\config\sonarr:/config        # Settings and database
    - C:\media\tv:/tv                       # Organized TV library (shared with Plex)
    - C:\media\downloads:/downloads         # Completed downloads (shared with qBittorrent)
  ports:
    - "8989:8989"               # Web UI and API
  restart: unless-stopped
```

## Common Use Cases

- **Automated TV Downloads**: Add a series once, Sonarr gets every episode as it airs
- **Binge-Watching**: Add a completed series and grab all seasons at once
- **Quality Upgrades**: Automatically replace 720p with 1080p when better versions appear
- **Season Monitoring**: Choose which seasons to monitor (e.g., only future episodes, not old seasons)
- **Library Management**: Keep your TV collection organized by show/season/episode

## Troubleshooting Tips

**Episode won't download?**
- Check if Prowlarr has working TV indexers (Settings → Indexers)
- Verify qBittorrent is connected (Settings → Download Clients)
- Look at Sonarr → Activity → Queue to see if there are errors
- Verify episode is monitored (Sonarr → Series → [Show] → check episode monitoring)

**Download completed but Sonarr didn't import it?**
- Verify paths match: qBittorrent's `/downloads` = Sonarr's `/downloads`
- Check file permissions (PUID/PGID)
- Look at Sonarr → System → Logs for import errors
- Manual import: Activity → Manual Import

**Episode imported but Plex doesn't see it?**
- Check that Sonarr moved it to `/tv` (Sonarr → Series → [Show] → Files)
- Verify Plex's TV library points to `C:\media\tv`
- Check naming format matches Plex expectations
- Manually refresh Plex library

**Sonarr missed an episode?**
- Check if the episode is marked as "monitored" (blue icon)
- Verify timezone is correct (Settings → General)
- Look at Series → [Show] → History to see if it searched
- Manually search: Series → [Show] → Episode → Manual Search

**Episode keeps downloading the wrong version?**
- Check your quality profile (Settings → Profiles)
- Review release profiles to prefer/reject certain release groups
- Use manual search to select the specific release you want

## Initial Configuration Steps

### 1. First Launch
- Access: `http://localhost:8989`
- Set authentication (Settings → General → Security)

### 2. Add Download Client (qBittorrent)
- Settings → Download Clients → Add → qBittorrent
- Host: `gluetun` (or `localhost`)
- Port: `8080`
- Category: `tv` (optional but helpful)
- Test connection

### 3. Connect to Prowlarr
- Settings → Indexers → Add → Prowlarr
- **OR** add from Prowlarr side (Settings → Apps → Add → Sonarr)
  - Sonarr URL: `http://sonarr:8989`
  - API Key: Found in Sonarr → Settings → General

### 4. Set Root Folder
- Settings → Media Management → Root Folders → Add
- Path: `/tv`

### 5. Create Quality Profile
- Settings → Profiles → Add
- Choose qualities (e.g., 720p WEBDL, 1080p WEBDL)
- Set cutoff (quality at which upgrades stop)

### 6. Configure File Naming
- Settings → Media Management → Episode Naming
- Enable "Rename Episodes"
- Choose format (e.g., `{Series Title} - S{season:00}E{episode:00} - {Episode Title}`)

### 7. Add Your First Series
- Series → Add New
- Search for a show
- Choose quality profile
- Choose season monitoring (all, future, recent, etc.)
- Add + Search for episodes

## Understanding Season Monitoring

Sonarr offers flexible monitoring options:

- **All Episodes**: Grabs every episode from every season (great for new shows you want to binge)
- **Future Episodes**: Only monitors unaired episodes (good for ongoing series)
- **Missing Episodes**: Grabs episodes you don't have, including past ones
- **Existing Episodes**: Only monitors episodes already in your library for upgrades
- **First Season**: Only the first season (good for trying out a show)
- **Latest Season**: Only the most recent season
- **None**: Don't automatically grab any episodes (manual only)

**Pro Tip**: Use "Future Episodes" for ongoing series to avoid downloading 10+ seasons of old shows.

## Understanding Quality Profiles

Similar to Radarr, Sonarr uses quality profiles:

- **Qualities**: Which formats you accept (720p, 1080p, 4K, etc.)
- **Cutoff**: Stop upgrading once this quality is reached
- **Priority**: Order of preference

**Example Profile**:
- Allow: 720p WEBDL, 1080p WEBDL
- Cutoff: 1080p WEBDL
- Result: Downloads 720p quickly when episode airs, upgrades to 1080p later

**TV-Specific Consideration**: WEBDL releases typically appear first (hours after airing), Bluray months later. Most users prefer WEBDL for TV.

## Performance Notes

- **CPU**: Light - only active during searches and imports
- **RAM**: ~150-400MB depending on library size (more series = more data)
- **Disk**: Database grows with library size
- **Network**: Only uses bandwidth during searches (metadata, not downloads)

## File Organization

Sonarr organizes TV shows with customizable naming:

**Default format**:
```
Series Title (Year)/
  Season 01/
    Series Title - S01E01 - Episode Title.ext
    Series Title - S01E02 - Episode Title.ext
```

**Example**:
```
C:\media\tv\
  ├── Breaking Bad (2008)/
  │   ├── Season 01/
  │   │   ├── Breaking Bad - S01E01 - Pilot.mkv
  │   │   └── Breaking Bad - S01E02 - Cat's in the Bag....mkv
  │   └── Season 02/
  │       └── Breaking Bad - S02E01 - Seven Thirty-Seven.mkv
```

**Why this matters**: Plex expects this structure for proper season/episode organization and metadata fetching.

## Advanced Features

**Calendar**: Visual overview of upcoming episodes across all your shows

**Lists**: Auto-add shows from Trakt lists or IMDb lists

**Custom Formats**: Prefer specific release groups, codecs (e.g., x265 for space savings)

**Notifications**: Get alerts via Telegram when episodes are grabbed, downloaded, imported, or failed

**Anime Support**: Special naming and parsing for anime series

## Telegram Notifications

Get reliable, instant notifications for all TV show-related events in Telegram.

### Prerequisites
- Complete the [Telegram Bot Setup](../notifications/telegram-setup.md) first
- You'll need your **Bot Token** and **Chat ID**

### Configuration Steps

1. **Open Sonarr** at `http://localhost:8989`

2. **Go to Settings → Connect**
   - Click the **+** button
   - Select **Telegram**

3. **Configure Telegram Connection**:
   - **Name**: `Telegram` (or any name you want)
   - **Bot Token**: `8410328014:AAF4MnHVHr-EoJwno7uB4x9weC22HtJI9LU`
   - **Chat ID**: `8320862964`
   - **Send Silently**: `No` (you want sound/vibration for notifications)

4. **Choose Notification Triggers** (enable these):

   ✅ **On Grab** - Notifies when Sonarr grabs an episode release from an indexer
   - Message: "Episode grabbed: Breaking Bad - S01E01 - Pilot"

   ✅ **On Import** - Notifies when episode is successfully downloaded and imported
   - Message: "Episode downloaded: Breaking Bad - S01E01 - 2.3 GB"

   ✅ **On Upgrade** - Notifies when episode is upgraded to better quality
   - Message: "Episode upgraded: Breaking Bad - S01E01 - 720p → 1080p"

   ✅ **On Rename** - Notifies when Sonarr renames files (optional)

   ✅ **On Series Add** - Notifies when a new series is added to Sonarr (optional)

   ✅ **On Series Delete** - Notifies when a series is removed

   ✅ **On Episode File Delete** - Notifies when episode file is deleted

   ✅ **On Health Issue** - Critical! Notifies about problems
   - Examples: "Indexer unavailable", "Download client error", "Disk space low"

   ✅ **On Health Restored** - Notifies when issues are resolved

   ✅ **On Application Update** - Notifies when Sonarr updates (optional)

   ⚠️ **On Download Failure** - This is handled by "On Import Complete" when it fails

5. **Test the Connection**
   - Click **Test** button
   - You should receive a test notification in Telegram
   - If it fails, verify your bot token and chat ID

6. **Save** the connection

### Notification Examples

**Episode Grabbed:**
```
[Episode Grabbed] Breaking Bad - S01E01 - Pilot
Quality: WEBDL-1080p
Release: Breaking.Bad.S01E01.1080p.WEB-DL.x264-GROUP
Indexer: EZTV
```

**Episode Downloaded:**
```
[Episode Downloaded] Breaking Bad - S01E01 - Pilot
Quality: WEBDL-1080p
Size: 2.3 GB
Time: 15 minutes
```

**Download Failed:**
```
[Download Warning] The Office - S02E05
Download client reported an error
Release: The.Office.S02E05.1080p.WEB-DL
Error: Indexer returned 404 - file not found
```

**Health Issue:**
```
[Health Check Failure]
Issue: qBittorrent is unavailable
Time: 2025-12-27 20:00
```

**Series Added:**
```
[Series Added] The Mandalorian (2019)
Monitoring: Future episodes only
Quality Profile: HD-1080p
```

### Troubleshooting Notifications

**Not receiving notifications?**
- Verify bot token and chat ID are correct
- Make sure you started a conversation with your bot (send `/start`)
- Check Sonarr → System → Logs for Telegram errors
- Test the connection again

**Receiving too many notifications?**
- Disable optional triggers (On Rename, On Series Add, On Application Update)
- Use Telegram's mute feature during sleep hours
- Consider using "Future Episodes" monitoring to reduce noise

**Notifications are delayed?**
- Telegram is usually instant - check your internet connection
- Verify Sonarr isn't rate-limited (System → Logs)
- Check if bot is blocked or restricted

### What You Should Monitor

**Essential Notifications** (keep these enabled):
- ✅ On Import (know when episodes finish downloading)
- ✅ On Health Issue (catch problems early)
- ✅ On Grab (know what's downloading)

**Optional Notifications** (can be noisy):
- On Series Add (if you use Overseerr, you'll get duplicate notifications)
- On Rename (only useful if debugging)
- On Application Update (unless you care about updates)

**Pro Tip**: If you watch a lot of ongoing series (10+ shows), notifications can get frequent during peak TV nights (Sunday/Monday). Consider muting during those times or only enabling "On Import" and "On Health Issue".

## Episode Naming Tokens

Customize your episode naming with tokens:

- `{Series Title}` - Show name
- `{season:00}` - Season number (2 digits)
- `{episode:00}` - Episode number (2 digits)
- `{Episode Title}` - Episode name
- `{Quality Title}` - Quality (e.g., 1080p WEBDL)
- `{Release Group}` - Release group name

## Security Best Practices

✅ **Enable Authentication**: Protect Web UI with username/password
✅ **Backup Config**: Regularly backup `C:\media\config\sonarr`
✅ **API Key Security**: Keep your API key private - it grants full access

## Important Notes

- **Release Timing**: Episodes typically appear 30-60 minutes after airing (depends on release groups)
- **Disk Space**: TV shows accumulate quickly - a 10-season series can be 100+ GB
- **Anime**: If you watch anime, enable anime naming format in settings
- **Episode Packs**: Sonarr can grab season/series packs for faster bulk downloads
