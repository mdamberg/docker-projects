# Audiobookshelf

## Overview

Audiobookshelf is a self-hosted audiobook and podcast server with a beautiful, user-friendly interface for organizing, streaming, and managing your audiobook collection. Think of it as "Plex for audiobooks" - it provides a polished experience for listening to audiobooks on any device.

**What it does**:
- Organizes your audiobook library with cover art and metadata
- Streams audiobooks to any device (web, iOS, Android)
- Tracks listening progress and syncs across devices
- Manages podcast subscriptions and downloads
- Supports multiple users with individual libraries and progress
- Provides a mobile-friendly web interface and native mobile apps
- Remembers playback position, playback speed, and sleep timer

**Why you need it**: While LazyLibrarian gets your audiobooks, Audiobookshelf makes them enjoyable to listen to with progress tracking, beautiful UI, and multi-device sync.

## Ports

| Port | Purpose |
|------|---------|
| `13378` (host) → `80` (container) | Audiobookshelf Web UI and API |

Access via: `http://localhost:13378`

## How It Works

1. **LazyLibrarian downloads audiobooks** to your library folder
2. **Audiobookshelf scans the folder** and discovers audiobooks
3. **Audiobookshelf fetches metadata** (cover art, descriptions, author info)
4. **You access Audiobookshelf** via web browser or mobile app
5. **Start listening** - playback position syncs across devices
6. **Progress is tracked** - pick up where you left off on any device

Think of it as your personal audiobook streaming service.

## Service Interactions

**Reads Audiobooks From**:
- **LazyLibrarian's organized library** (`C:\media\audiobooks`)

**Can Also Access**:
- **Podcasts** (`C:\media\podcasts`)

**Used By**:
- You and your users via web browser or mobile apps

**Workflow**:
```
LazyLibrarian downloads → Audiobook saved to C:\media\audiobooks
                                       ↓
                        Audiobookshelf scans and indexes
                                       ↓
                           Fetches metadata and covers
                                       ↓
                         Appears in Audiobookshelf library
                                       ↓
                      Users listen via web or mobile app
                                       ↓
                        Progress syncs across devices
```

## Environment Variables

| Variable | Description | Value in Your Setup |
|----------|-------------|---------------------|
| `TZ` | Timezone for scheduling and logs | Loaded from `.env` |

**Note**: Audiobookshelf doesn't require PUID/PGID since it only reads files (doesn't modify).

## Mounts & Volumes

| Mount | Purpose | Notes |
|-------|---------|-------|
| `C:/media/config/audiobookshelf:/config` | Audiobookshelf database and settings | Contains user accounts, progress data, library metadata |
| `C:/media/audiobooks:/audiobooks` | Audiobook library | **Read-only access** - Audiobookshelf doesn't modify files |
| `C:/media/podcasts:/podcasts` | Podcast storage | Optional - for podcast feature |
| `C:/media/abs-metadata:/metadata` | Cached metadata and covers | Stores downloaded cover images and metadata |

**Important**: The audiobooks folder should contain your audiobook files organized by author or title.

## Compose File Breakdown

```yaml
audiobookshelf:
  image: ghcr.io/advplyr/audiobookshelf:latest
  container_name: audiobookshelf
  environment:
    - TZ=${TZ}                                  # Timezone
  ports:
    - "13378:80"                                # Maps host 13378 to container 80
  volumes:
    - "C:/media/config/audiobookshelf:/config"  # App data and database
    - "C:/media/audiobooks:/audiobooks"         # Audiobook library
    - "C:/media/podcasts:/podcasts"             # Podcast library
    - "C:/media/abs-metadata:/metadata"         # Metadata cache
  restart: unless-stopped
```

## Common Use Cases

- **Audiobook Streaming**: Listen to audiobooks from any device
- **Progress Tracking**: Resume where you left off, even on different devices
- **Family Sharing**: Multiple user accounts with separate libraries and progress
- **Podcast Management**: Subscribe to and listen to podcasts
- **Offline Listening**: Mobile apps support downloading for offline use
- **Reading Statistics**: Track listening time, completed books, etc.

## Troubleshooting Tips

**Can't access Audiobookshelf?**
- Access via `http://localhost:13378` (note the custom port)
- Check if container is running: `docker ps | grep audiobookshelf`
- View logs: `docker logs audiobookshelf`

**Audiobooks not showing up?**
- Verify files exist in `C:\media\audiobooks`
- Trigger manual scan: Settings → Libraries → Scan
- Check supported formats: M4B, M4A, MP3, MP4, OGG, OGA, OPUS, AAC, FLAC, WMA
- Ensure files aren't corrupted

**Playback issues?**
- Check file format compatibility
- Try re-encoding problematic files to M4B
- Clear browser cache
- Check network speed (streaming requires bandwidth)

**Progress not syncing?**
- Ensure you're logged into same account on all devices
- Check internet connection
- Manually sync: Pull down to refresh on mobile app

**Metadata not fetching?**
- Check internet connection
- Manually match: Select book → Edit → Match
- Metadata sources: Audiobookshelf, Google Books, iTunes

## Initial Configuration Steps

### 1. First Launch
- Access: `http://localhost:13378`
- Create admin account (first user is admin)
- Set strong password

### 2. Create Library
- Settings → Libraries → Add Library
- **Name**: Audiobooks (or custom name)
- **Folder Path**: `/audiobooks` (this is the container path, maps to `C:\media\audiobooks`)
- **Library Type**: Audiobooks
- **Save**

### 3. Add Podcast Library (Optional)
- Settings → Libraries → Add Library
- **Name**: Podcasts
- **Folder Path**: `/podcasts`
- **Library Type**: Podcasts
- **Save**

### 4. Scan Library
- Settings → Libraries → [Your Library] → Scan
- Wait for scan to complete
- Audiobookshelf will discover audiobooks and fetch metadata

### 5. Configure Metadata Fetching
- Settings → Library Settings
- Enable "Fetch covers from metadata providers"
- Enable "Prefer matched metadata"
- Choose providers (Audiobookshelf, Google Books)

### 6. Set Up Users (Optional)
- Settings → Users → Add User
- Create accounts for family members
- Set permissions (can delete, can download, etc.)
- Each user gets separate progress tracking

## Audiobook Organization

Audiobookshelf works best with organized files:

**Option 1 - By Author**:
```
C:\media\audiobooks\
  ├── Stephen King/
  │   └── The Shining/
  │       ├── Chapter 01.mp3
  │       ├── Chapter 02.mp3
  │       └── ...
```

**Option 2 - Single File (Preferred)**:
```
C:\media\audiobooks\
  ├── Stephen King/
  │   └── The Shining.m4b       # Single file with chapters
```

**Best Format**: M4B (single file with embedded chapters and metadata)

## Supported Audio Formats

- **M4B**: Best for audiobooks (single file, chapters, metadata) - **Recommended**
- **M4A**: Apple audio format
- **MP3**: Universal but requires multiple files
- **MP4**: Video container, but works for audio
- **OGG/OPUS**: Open formats, good quality
- **FLAC**: Lossless (large files)
- **AAC**: Advanced audio codec
- **WMA**: Windows Media Audio

## Mobile Apps

**iOS**: Available on App Store (search "Audiobookshelf")

**Android**: Available on Google Play and F-Droid

**Features**:
- Download audiobooks for offline listening
- Background playback
- Sleep timer
- Playback speed control
- Progress syncing
- Cast to smart speakers

**Setup**:
1. Install app
2. Enter server URL: `http://your-server-ip:13378`
3. Login with your Audiobookshelf account
4. Start listening!

## Features Explained

### Playback Controls
- **Playback Speed**: 0.5x to 3x (great for fast/slow listening)
- **Sleep Timer**: Auto-stop after X minutes
- **Chapter Navigation**: Jump between chapters
- **Skip Buttons**: Customizable skip forward/back (15s, 30s, etc.)

### Progress Tracking
- Syncs across all devices
- Shows % completed
- Tracks listening time
- "Continue Listening" section

### Collections
- Create custom collections (e.g., "Favorites", "To Read")
- Group related audiobooks
- Share collections with other users

### User Accounts
- **Admin**: Full control (can delete, edit, manage users)
- **User**: Can listen, track progress, download
- **Guest**: Limited access
- Each user has separate:
  - Progress tracking
  - Collections
  - Listening history

### Library Management
- **Multiple Libraries**: Separate audiobooks, podcasts, etc.
- **Folder Watching**: Auto-scan for new files
- **Metadata Editing**: Manually edit titles, authors, covers
- **Backup/Restore**: Export and import database

### Statistics
- **Listening Time**: Total hours listened
- **Books Completed**: Count of finished audiobooks
- **Listening Activity**: Daily/weekly listening patterns
- **Per-User Stats**: See individual user statistics (admin only)

## Performance Notes

- **CPU**: Light - only during playback and scans
- **RAM**: ~100-300MB depending on library size
- **Disk**: Metadata cache can grow (covers, metadata)
- **Network**: Streaming quality depends on network speed

**Transcoding**: Audiobookshelf can transcode audio on-the-fly for compatibility, which increases CPU usage during playback.

## Podcast Features

If you use the podcast feature:
- Subscribe to podcast RSS feeds
- Auto-download new episodes
- Manage episode queue
- Same progress tracking as audiobooks

**Configuration**:
- Settings → Podcasts
- Set download schedule
- Configure storage limits

## Integration with LazyLibrarian

**Perfect Workflow**:
1. LazyLibrarian finds and downloads audiobooks
2. Saves to `C:\media\audiobooks`
3. Audiobookshelf auto-scans and adds to library
4. You listen via Audiobookshelf

**Tip**: Configure LazyLibrarian to prefer M4B format for best Audiobookshelf experience.

## Advanced Features

**Embedded Metadata**: Audiobookshelf reads metadata from audio files (ID3 tags, m4b metadata)

**Cover Art**: Auto-fetches from online sources or uses embedded covers

**Series Support**: Groups books in series together

**RSS Feed**: Generate RSS feed of your library (for legacy podcast apps)

**OpenID Connect**: SSO authentication (advanced users)

**Notifications**: Webhook support for automations

## Backup & Restore

**What to Backup**:
- `C:/media/config/audiobookshelf` - Database, user accounts, progress
- `C:/media/abs-metadata` - Metadata cache (optional, can be re-downloaded)
- `C:/media/audiobooks` - Your actual audiobook files (most important!)

**Restore**:
- Restore config folder
- Restart Audiobookshelf
- Scan library to rebuild if needed

**Export/Import**:
- Settings → Backups → Create Backup (exports database)
- Can import backup on new installation

## Security Best Practices

✅ **Strong Passwords**: Use secure passwords for all accounts
✅ **Limited Permissions**: Don't give all users admin access
✅ **HTTPS**: Use reverse proxy for secure access if exposing to internet
✅ **Regular Backups**: Backup database regularly (contains progress)
✅ **API Key Security**: Protect API tokens (Settings → API)

## Comparison to Alternatives

**Audiobookshelf vs. Plex**:
- Audiobookshelf: Better audiobook experience, progress tracking, mobile apps
- Plex: Can handle audiobooks but interface not optimized

**Audiobookshelf vs. Booksonic**:
- Audiobookshelf: Modern UI, active development, better mobile apps
- Booksonic: Older, less development

**Why Audiobookshelf?** Best-in-class audiobook experience, active development, great mobile apps.

## Listening Tips

**Playback Speed**: Experiment with 1.2x or 1.5x for faster listening

**Sleep Timer**: Use at night to avoid losing your place

**Bookmarks**: Create bookmarks for important parts

**Notes**: Add notes to remember thoughts about books

## Sharing with Family

- Create separate user accounts for each family member
- Each gets their own progress tracking
- Share collections of recommended audiobooks
- Admin can see family listening statistics

## Remote Access

To access outside your home:
- Set up port forwarding (13378)
- Use a reverse proxy (Nginx, Traefik) for HTTPS
- Or use VPN for secure remote access

**Mobile apps** need server URL:
- Local: `http://192.168.x.x:13378`
- Remote: `https://yourdomain.com` (if reverse proxy configured)

## Important Notes

- **Audiobook Formats**: M4B is best - single file with chapters
- **Library Organization**: Keep audiobooks organized by author for best results
- **Metadata**: May need manual matching for obscure titles
- **Updates**: Watchtower keeps Audiobookshelf updated automatically
- **Storage**: Audiobooks can be large (100MB - 1GB+ each) - monitor disk space
