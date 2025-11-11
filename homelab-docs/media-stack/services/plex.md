# Plex

## Overview

Plex is a media server that organizes, manages, and streams your movies and TV shows to any device. It's the **end result** of your entire media stack - all the work done by Sonarr, Radarr, and qBittorrent culminates in Plex, where you actually watch your content.

**What it does**:
- Scans your media folders and organizes content into beautiful libraries
- Fetches metadata, posters, descriptions, and cast info from online databases
- Streams media to any device (smart TVs, phones, tablets, web browsers)
- Transcodes video on-the-fly if your device can't play the original format
- Provides a Netflix-like interface for your personal media collection

**Why you need it**: Plex is your personal streaming service - it makes all your downloaded content accessible and beautiful, just like Netflix or Disney+.

## Ports

| Port | Purpose |
|------|---------|
| `32400` | Main Plex Web UI and streaming port (the only one you typically need) |

**Note**: Plex uses additional ports for various features (DLNA, network discovery, etc.), but 32400 is the primary port for accessing your server.

## How It Works

1. **Sonarr/Radarr organize media** into `C:\media\movies` and `C:\media\tv`
2. **Plex scans these folders** periodically or when triggered
3. **Plex matches files** to online databases (TheMovieDB, TVDB) using file names
4. **Plex downloads metadata**: Posters, descriptions, cast info, ratings
5. **You access Plex** via web browser, app, or smart TV
6. **Plex streams content** to your device, transcoding if needed

## Service Interactions

**Reads Media From**:
- **Radarr's organized movies** (`C:\media\movies`)
- **Sonarr's organized TV shows** (`C:\media\tv`)

**Receives Requests From**:
- **Overseerr** (users can request content, which Overseerr sends to Sonarr/Radarr, which eventually appears in Plex)

**Accessed By**:
- You and your users via Plex apps on any device

**Workflow**:
```
Sonarr/Radarr organize files ’ C:\media\movies & C:\media\tv
                                         “
                              Plex scans and indexes files
                                         “
                        Plex fetches metadata and artwork
                                         “
                          Content appears in Plex library
                                         “
                            Users stream via Plex apps
```

## Environment Variables

| Variable | Description | Value in Your Setup |
|----------|-------------|---------------------|
| `PUID` | User ID for file permissions | Loaded from `.env` (ensures Plex can read media files) |
| `PGID` | Group ID for file permissions | Loaded from `.env` |
| `TZ` | Timezone for library scans and logs | Loaded from `.env` |
| `VERSION` | Plex version management | `docker` (uses latest stable version) |

## Mounts & Volumes

| Mount | Purpose | Notes |
|-------|---------|-------|
| `C:\media\config\plex:/config` | Plex database, settings, metadata cache | Contains your entire Plex library metadata - **VERY IMPORTANT TO BACKUP** |
| `C:\media\movies:/movies` | Movie library | **Read-only** - Plex only reads, doesn't modify |
| `C:\media\tv:/tv` | TV show library | **Read-only** - Plex only reads, doesn't modify |

**Critical**:
- Config folder can grow large (metadata, thumbnails, etc.) - can reach tens of GB
- Movies and TV mounts must exactly match where Sonarr/Radarr place organized files

## Compose File Breakdown

```yaml
plex:
  image: linuxserver/plex:latest
  container_name: plex
  environment:
    - PUID=${PUID}              # File ownership for reading media
    - PGID=${PGID}
    - TZ=${TZ}                  # Timezone for scheduled tasks
    - VERSION=docker            # Use latest Docker-optimized Plex version
  volumes:
    - C:\media\config\plex:/config      # Plex database and metadata
    - C:\media\movies:/movies           # Movie library (from Radarr)
    - C:\media\tv:/tv                   # TV library (from Sonarr)
  ports:
    - "32400:32400"             # Main Plex port
  restart: unless-stopped
```

## Common Use Cases

- **Personal Netflix**: Stream your collection from anywhere
- **Family Sharing**: Give family/friends access to your library
- **Device Compatibility**: Watch on any device (smart TV, Roku, iOS, Android, etc.)
- **Offline Sync**: Download content to mobile devices for offline viewing
- **Watch Together**: Plex supports synchronized watching across devices

## Troubleshooting Tips

**Can't access Plex?**
- Access via `http://localhost:32400/web`
- Or visit `https://app.plex.tv` and select your server
- Check if container is running: `docker ps | grep plex`
- View logs: `docker logs plex`

**New content isn't showing up?**
- Verify file is in `/movies` or `/tv` folder
- Check file naming matches Plex expectations (use Sonarr/Radarr naming)
- Manually scan library: Library ’ ... ’ Scan Library Files
- Check Plex logs for scanner errors

**Buffering/playback issues?**
- Check transcoding: Dashboard shows if server is transcoding
- Reduce quality in player settings if your device can't handle the original
- Verify network speed (4K needs 25+ Mbps)
- Check CPU usage - transcoding is CPU-intensive

**Metadata is wrong?**
- Edit the item manually (select item ’ Edit ’ Match)
- Use Plex's "Fix Match" feature to re-match to correct entry
- Ensure file naming follows Plex conventions

**Can't access remotely?**
- Check port forwarding (router must forward 32400 to your Plex server)
- Verify Plex account is signed in
- Check Settings ’ Network ’ Remote Access

## Initial Configuration Steps

### 1. First Launch & Claim Server
- Access: `http://localhost:32400/web`
- Sign in with your Plex account (create one if needed)
- **Claim your server** (this links the server to your Plex account)

### 2. Create Libraries
- Add Library ’ Movies ’ Browse for folder ’ Select `/movies`
- Add Library ’ TV Shows ’ Browse for folder ’ Select `/tv`
- Let Plex scan and match your existing content

### 3. Configure Settings

**Settings ’ Library**:
- Enable "Scan my library automatically"
- Enable "Run a partial scan when changes are detected"

**Settings ’ Network**:
- Set up Remote Access if you want to stream outside your home
- Configure port forwarding on your router (32400 ’ your server)

**Settings ’ Transcoder**:
- Set Transcoder quality (Higher = better quality, more CPU usage)
- Enable hardware transcoding if you have compatible GPU (massive performance boost)

### 4. Customize Experience
- Add posters/artwork for collections
- Create playlists
- Set up user accounts for family members (Settings ’ Users & Sharing)

## Understanding Transcoding

**Direct Play**: Device plays file as-is (no server CPU usage) - **Best scenario**

**Direct Stream**: Remuxes container but doesn't re-encode video (low CPU usage)

**Transcode**: Re-encodes video to compatible format (high CPU usage)

**When transcoding happens**:
- Device doesn't support video codec (e.g., 4K HEVC on older device)
- Network too slow for original bitrate
- User manually selects lower quality
- Audio codec incompatible with device

**Performance Impact**:
- 1080p transcode: ~2000-4000 CPU PassMark per stream
- 4K transcode: ~17000+ CPU PassMark per stream

**Pro Tip**: Use hardware transcoding (Settings ’ Transcoder) if your server has a compatible GPU (Intel Quick Sync, NVIDIA, AMD).

## File Naming Requirements

Plex requires specific naming for accurate matching:

**Movies**:
```
Movie Name (Year).ext
The Matrix (1999).mkv
```

**TV Shows**:
```
Show Name (Year)/Season 01/Show Name - S01E01 - Episode Title.mkv
Breaking Bad (2008)/Season 01/Breaking Bad - S01E01 - Pilot.mkv
```

**Good news**: Sonarr and Radarr handle this automatically!

## Performance Notes

- **CPU**: Idle when not streaming; high during transcoding
- **RAM**: ~500MB base, increases with number of active streams and library size
- **Disk**: Config folder can grow to 10-50GB+ (metadata, thumbnails)
- **Network**: Streaming quality determines bandwidth (1080p ~10-20 Mbps, 4K ~40-100 Mbps)

## Plex Pass (Optional Subscription)

Plex offers a premium "Plex Pass" subscription with features:
- Hardware transcoding (GPU acceleration)
- Mobile sync (offline downloads)
- Live TV & DVR
- Lyrics and early access to features
- User restrictions and parental controls

**Do you need it?** Not required, but hardware transcoding alone can be worth it for multiple concurrent users.

## Library Optimization

**Settings ’ Library ’ Optimize**:
- Plex can create optimized versions (lower quality copies) for specific devices
- Useful for mobile devices or slow connections
- Consumes additional disk space

## Collections & Organization

Create Collections to group related content:
- "Marvel Cinematic Universe"
- "Star Wars Saga"
- "Christopher Nolan Films"

Plex can auto-create collections based on franchises.

## User Management & Sharing

**Managed Users** (Plex Pass): Local accounts for family (no separate Plex account needed)

**Shared Users**: Invite friends with existing Plex accounts

**Restrictions**:
- Limit libraries (e.g., only share Movies, not TV)
- Set ratings restrictions (no R-rated for kids)
- Limit concurrent streams

## Security Best Practices

 **Strong Password**: Secure your Plex account (it controls server access)
 **Limited Sharing**: Only share with trusted users
 **Regular Backups**: Backup `C:\media\config\plex` regularly
 **Network Security**: Use VPN or secure network if accessing remotely
 **Update Regularly**: Keep Plex updated (Watchtower handles this)

## Advanced Features

**Watch Together**: Synchronized playback across multiple devices

**Playlists**: Create custom playlists from your library

**Discover**: Recommendations based on watching habits

**Live TV & DVR** (Plex Pass): Connect antenna for over-the-air TV

**Music & Photos**: Plex also manages music and photo libraries

## Important Notes

- **Legal Responsibility**: Ensure you have legal rights to any content you stream
- **Bandwidth**: Multiple concurrent streams can saturate your internet upload speed
- **Storage**: Large libraries require significant disk space (Blu-ray movies can be 20-50GB each)
- **Metadata Privacy**: Plex sends anonymous metadata to improve matching (can be disabled in settings)
