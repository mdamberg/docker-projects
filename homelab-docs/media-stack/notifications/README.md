# Media Stack Notifications

Complete guide to setting up reliable notifications for your media server.

## Overview

Get instant notifications for all important events in your media stack:
- Movie/TV downloads complete
- Download failures with reasons
- New requests from users
- Health issues (indexers down, disk space low, etc.)
- Content available for watching

## Why Telegram?

We use **Telegram** instead of Discord because:
- ✅ **More reliable** - Better rate limits, won't miss notifications
- ✅ **Instant delivery** - Notifications appear immediately
- ✅ **Free forever** - No costs or subscriptions
- ✅ **Easy to control** - Mute/unmute specific bots
- ✅ **Purpose-built** - Designed for bot notifications

## Quick Start

### Step 1: Set Up Telegram Bot (5 minutes)
[Follow the Telegram Bot Setup Guide](telegram-setup.md)

You'll get:
- Bot Token: Used to send notifications
- Chat ID: Your Telegram account identifier

### Step 2: Configure Services (15 minutes)

Configure Telegram in each service:

1. **Radarr** (Movies) - [Configuration Guide](../services/radarr.md#telegram-notifications)
2. **Sonarr** (TV Shows) - [Configuration Guide](../services/sonarr.md#telegram-notifications)
3. **LazyLibrarian** (Books/Audiobooks) - [Configuration Guide](../services/lazylibrarian.md#telegram-notifications)
4. **Overseerr** (Requests) - [Configuration Guide](../services/overseerr.md#telegram-notifications)
5. **qBittorrent** (Optional, for non-media torrents) - [Configuration Guide](qbittorrent-telegram.md)

## What You'll Get

### Radarr Notifications
- ✅ Movie grabbed from indexer
- ✅ Movie downloaded and imported
- ✅ Movie upgraded (720p → 1080p)
- ✅ Download failed (with reason)
- ✅ Health issues (indexer down, disk space, etc.)

### Sonarr Notifications
- ✅ Episode grabbed from indexer
- ✅ Episode downloaded and imported
- ✅ Episode upgraded
- ✅ Download failed (with reason)
- ✅ Health issues
- ✅ Series added/removed

### LazyLibrarian Notifications
- ✅ Book/audiobook grabbed
- ✅ Book/audiobook downloaded and imported
- ✅ Magazine grabbed (if enabled)
- ✅ Magazine downloaded (if enabled)

### Overseerr Notifications
- ✅ New request received
- ✅ Request auto-approved
- ✅ Content available
- ✅ Download failed
- ✅ User can be notified about their own requests

## Complete Notification Flow

```
User requests movie in Overseerr
    ↓
[Overseerr] Telegram: "New Request: The Matrix (1999)"
    ↓
Request auto-approved, sent to Radarr
    ↓
[Overseerr] Telegram: "Request Auto-Approved"
    ↓
Radarr searches and finds release
    ↓
[Radarr] Telegram: "Movie Grabbed: The Matrix (1999) - 1080p BluRay"
    ↓
qBittorrent downloads file
    ↓
Radarr imports and organizes movie
    ↓
[Radarr] Telegram: "Movie Downloaded: The Matrix (1999) - 8.5 GB"
    ↓
Overseerr detects movie is available
    ↓
[Overseerr] Telegram to User: "The Matrix is now available!"
```

## Notification Examples

### Movie Downloaded
```
[Radarr] Movie Downloaded
The Matrix (1999)
Quality: Bluray-1080p
Size: 8.5 GB
Time: 45 minutes
```

### Download Failed
```
[Radarr] Download Failed
Movie: Inception (2010)
Release: Inception.2010.1080p.BluRay
Error: Indexer returned 404 - file not found
```

### Episode Downloaded
```
[Sonarr] Episode Downloaded
Breaking Bad - S01E01 - Pilot
Quality: WEBDL-1080p
Size: 2.3 GB
```

### Health Issue
```
[Radarr] Health Check Failure
Issue: Indexer 1337x is unavailable
Time: 2025-12-27 14:30
```

### New Request
```
[Overseerr] New Request
The Dark Knight (2008)
Requested by: John
Quality: 1080p
```

## Configuration Summary

### Your Bot Details

**Bot Token**: `8410328014:AAF4MnHVHr-EoJwno7uB4x9weC22HtJI9LU`
**Chat ID**: `8320862964`

> **Security Note**: These values are in your documentation for easy reference. Keep them private and don't share publicly.

### Service Configuration URLs

| Service | URL | Config Path |
|---------|-----|-------------|
| Radarr | `http://localhost:7878` | Settings → Connect → Add → Telegram |
| Sonarr | `http://localhost:8989` | Settings → Connect → Add → Telegram |
| LazyLibrarian | `http://localhost:5299` | Config → Notifications → Telegram |
| Overseerr | `http://localhost:5055` | Settings → Notifications → Telegram |
| qBittorrent | `http://localhost:8080` | See [qBittorrent guide](qbittorrent-telegram.md) |

## Recommended Notification Settings

### Radarr (Movies)
**Enable:**
- ✅ On Grab
- ✅ On Import
- ✅ On Health Issue
- ✅ On Upgrade

**Optional:**
- On Movie Added (can be noisy if using Overseerr)
- On Rename (only for debugging)

### Sonarr (TV Shows)
**Enable:**
- ✅ On Grab
- ✅ On Import
- ✅ On Health Issue
- ✅ On Upgrade

**Optional:**
- On Series Add (can be noisy if using Overseerr)
- On Rename (only for debugging)

### LazyLibrarian (Books/Audiobooks)
**Enable:**
- ✅ On Book Download
- ✅ On Book Snatch

**Optional:**
- On Magazine notifications (only if using magazines)

### Overseerr (Requests)
**Enable:**
- ✅ Media Requested
- ✅ Media Auto-Approved
- ✅ Media Failed

**Optional:**
- Media Approved (if manually approving)
- Media Declined (if manually declining)

## Troubleshooting

### Not receiving notifications?

1. **Test the bot manually**:
   ```powershell
   $botToken = "8410328014:AAF4MnHVHr-EoJwno7uB4x9weC22HtJI9LU"
   $chatId = "8320862964"
   $message = "Test from homelab"
   Invoke-RestMethod -Uri "https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=$message"
   ```

2. **Check service configuration**:
   - Verify bot token and chat ID are correct
   - Make sure notification triggers are enabled
   - Test the connection in service settings

3. **Check service logs**:
   - Radarr: System → Logs
   - Sonarr: System → Logs
   - Overseerr: Settings → Logs
   - Look for Telegram errors

4. **Verify Telegram setup**:
   - Make sure you sent `/start` to your bot
   - Check that bot isn't blocked

### Too many notifications?

**Reduce noise:**
- Disable optional triggers (On Rename, On Add)
- Use Telegram's mute feature for specific hours
- Only enable essential: On Import, On Health Issue, On Grab

**Manage by priority:**
- Keep health notifications (critical)
- Keep import notifications (know when downloads finish)
- Disable add/rename notifications (not essential)

### Notifications delayed?

- Telegram is instant - check your internet connection
- Verify services aren't rate-limited (check logs)
- Restart the service container if needed

## Advanced Features

### Custom Notification Sounds

Set different sounds per notification type in Telegram:

1. Open Telegram settings
2. Notifications and Sounds
3. Find your bot
4. Customize sound, vibration, LED color

### Quiet Hours

Mute notifications during specific times:

1. Open chat with your bot in Telegram
2. Tap bot name → Notifications
3. Set custom notification settings
4. Enable "Mute for..." during sleep hours

### Group Notifications

Send notifications to a Telegram group instead of DMs:

1. Create Telegram group
2. Add bot to group
3. Make bot admin
4. Get group Chat ID (negative number)
5. Use group Chat ID instead of your personal Chat ID

[See detailed instructions](telegram-setup.md#advanced-group-notifications)

## Additional Notifications (Future)

### qBittorrent
- Currently handled by Radarr/Sonarr monitoring
- For standalone qBittorrent notifications, consider:
  - Custom scripts on torrent completion
  - Apprise integration
  - qBit Management tool

### Plex
- For "now watching" notifications
- Consider: Tautulli (Plex monitoring tool)
- Can send Telegram notifications for streams

### System Monitoring
- **Uptime Kuma** (Port 3001) - Service health monitoring
- **Duplicati** (Port 8200) - Backup completion notifications
- Both support Telegram webhooks

## Resources

- [Telegram Bot Setup Guide](telegram-setup.md)
- [Radarr Telegram Configuration](../services/radarr.md#telegram-notifications)
- [Sonarr Telegram Configuration](../services/sonarr.md#telegram-notifications)
- [LazyLibrarian Telegram Configuration](../services/lazylibrarian.md#telegram-notifications)
- [Overseerr Telegram Configuration](../services/overseerr.md#telegram-notifications)
- [qBittorrent Telegram Setup](qbittorrent-telegram.md)
- [Telegram Bot API Docs](https://core.telegram.org/bots/api)

## Support

If you have issues:
1. Check the troubleshooting section above
2. Review service logs for errors
3. Test the bot manually to verify it works
4. Check Telegram app settings

---

**Last Updated**: 2025-12-27
**Status**: Active and working
