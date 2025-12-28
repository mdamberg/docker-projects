# Overseerr

## Overview

Overseerr is a request management and discovery platform for your media server. It provides a beautiful, user-friendly interface where you and your friends/family can browse, discover, and request movies and TV shows. When someone requests content, Overseerr automatically sends the request to Radarr or Sonarr, which handles the rest.

**What it does**:
- Provides a Netflix-like interface for discovering content
- Allows users to request movies and TV shows
- Automatically sends approved requests to Sonarr/Radarr
- Manages user permissions and quotas
- Shows request status and notifications
- Integrates with Plex to see what's already available

**Why you need it**: Without Overseerr, users would need to access Sonarr/Radarr directly (complex and powerful tools that can be overwhelming). Overseerr provides a simple "click to request" interface that anyone can use.

## Ports

| Port | Purpose |
|------|---------|
| `5055` | Overseerr Web UI |

## How It Works

1. **User browses Overseerr** (sees trending movies/shows, search, recommendations)
2. **User finds content they want** (e.g., "The Matrix")
3. **User clicks "Request"**
4. **Overseerr checks**:
   - Is it already in Plex? (Shows "Available" instead of "Request")
   - Is there a pending request?
   - Does user have permissions/quota?
5. **If approved, Overseerr sends to Radarr/Sonarr**
6. **Radarr/Sonarr searches and downloads** via Prowlarr and qBittorrent
7. **Content appears in Plex**
8. **Overseerr notifies the requester** that it's available

Think of Overseerr as the "front desk" for your media server.

## Service Interactions

**Connects To**:
- **Plex** (syncs existing library, checks what's available)
- **Radarr** (sends movie requests)
- **Sonarr** (sends TV show requests)

**Used By**:
- You and your Plex users (web interface)

**Workflow**:
```
User discovers content in Overseerr → Clicks "Request"
                                           ↓
                            Overseerr checks if already in Plex
                                           ↓
                        If not available, sends to Radarr/Sonarr
                                           ↓
                      Radarr/Sonarr → Prowlarr → qBittorrent
                                           ↓
                            Content downloads and imports
                                           ↓
                                Appears in Plex library
                                           ↓
                        Overseerr notifies user "Now Available"
```

## Environment Variables

| Variable | Description | Value in Your Setup |
|----------|-------------|---------------------|
| `PUID` | User ID for file permissions | Loaded from `.env` |
| `PGID` | Group ID for file permissions | Loaded from `.env` |
| `TZ` | Timezone for request timestamps | Loaded from `.env` |

## Mounts & Volumes

| Mount | Purpose | Notes |
|-------|---------|-------|
| `C:\media\config\overseerr:/config` | Overseerr database and settings | Contains user accounts, request history, API keys |

**Important**: This folder contains all your Overseerr data - back it up regularly.

## Compose File Breakdown

```yaml
overseerr:
  image: linuxserver/overseerr:latest
  container_name: overseerr
  environment:
    - PUID=${PUID}              # File ownership
    - PGID=${PGID}
    - TZ=${TZ}                  # Timezone for logging
  volumes:
    - C:\media\config\overseerr:/config    # Settings and database
  ports:
    - "5055:5055"               # Web interface
  restart: unless-stopped
```

## Common Use Cases

- **Family Requests**: Family members can request shows without bothering you
- **Friend Access**: Give friends access to request content for shared Plex server
- **Content Discovery**: Browse trending/popular content to find things to watch
- **Request Management**: Approve/deny requests, set quotas per user
- **Status Tracking**: Users can see if their request is downloading, approved, or available

## Troubleshooting Tips

**Can't connect to Plex/Sonarr/Radarr?**
- Verify services are running
- Check API keys are correct (Settings → Services)
- Use container names as hostnames (e.g., `http://plex:32400`)
- Test connection in Overseerr settings

**Requests not sending to Sonarr/Radarr?**
- Check that Default Server is set (Settings → Radarr/Sonarr → Default Server toggle)
- Verify root folder is configured
- Check quality profile is selected
- View logs: `docker logs overseerr`

**Users can't see content that's already in Plex?**
- Trigger a Plex library sync (Settings → Plex → Sync Libraries)
- Verify Plex libraries are mapped correctly in Overseerr

**4K requests not working?**
- Set up separate 4K Radarr/Sonarr instances (recommended)
- Configure 4K server in Overseerr (Settings → Radarr/Sonarr → Add 4K Server)

**Notifications not sending?**
- Configure notification agents (Settings → Notifications)
- Test each agent after configuration
- Check user notification preferences

## Initial Configuration Steps

### 1. First Launch
- Access: `http://localhost:5055`
- Create admin account
- Sign in with Plex account (required for Plex integration)

### 2. Connect to Plex
- Settings → Plex → Add Plex Server
- Overseerr will auto-detect your local Plex server
- Select libraries to sync (Movies and TV Shows)
- Trigger initial sync

### 3. Connect to Radarr
- Settings → Services → Radarr → Add Radarr Server
- Server Name: "Radarr" (or custom name)
- Hostname: `radarr` (container name)
- Port: `7878`
- API Key: Copy from Radarr → Settings → General → API Key
- Test connection
- Select Root Folder: `/movies`
- Select Quality Profile
- **Enable "Default Server"** toggle
- Save

### 4. Connect to Sonarr
- Settings → Services → Sonarr → Add Sonarr Server
- Server Name: "Sonarr" (or custom name)
- Hostname: `sonarr`
- Port: `8989`
- API Key: Copy from Sonarr → Settings → General → API Key
- Test connection
- Select Root Folder: `/tv`
- Select Quality Profile
- Season Folders: Enabled
- **Enable "Default Server"** toggle
- Save

### 5. Configure User Settings
- Settings → Users → User Permissions
- Set default permissions for new users
- Configure request limits (optional)

### 6. Set Up Notifications (Optional)
- Settings → Notifications
- Add Email, Discord, Telegram, etc.
- Test notifications
- Users can customize their notification preferences

## Understanding User Permissions

**Admin**: Full access to all settings and requests

**Manage Requests**: Can approve/deny requests from other users

**Request**: Can request content (standard user permission)

**Auto-Approve**: Requests automatically approved without admin review

**Request 4K**: Separate permission for 4K content

**Advanced Permissions**:
- Request Limits (movies/shows per day/week/month)
- Request limits can be set per user or globally

## Request Workflow Options

**Auto-Approve**: All requests automatically sent to Sonarr/Radarr
- Good for personal use or trusted users
- No manual approval needed

**Manual Approval**: Admin must approve each request
- Good for shared servers with many users
- Control over what gets downloaded
- Manage bandwidth and storage

## Content Discovery Features

**Trending**: See what's popular on TMDB (The Movie Database)

**Popular**: Most popular content currently

**Upcoming**: See what's coming soon to theaters/streaming

**Recommendations**: Based on what's in your Plex library

**Search**: Find specific titles

**Collections**: Browse Marvel, DC, Star Wars, etc.

## Performance Notes

- **CPU**: Very light - only active during requests and syncs
- **RAM**: ~100-200MB
- **Plex Sync**: Runs periodically to update library status
- **Network**: Minimal - mostly API calls to other services

## Notifications

Overseerr can notify via:
- **Email**: Gmail, custom SMTP
- **Discord**: Webhooks for Discord servers
- **Telegram**: Telegram bot messages
- **Slack**: Workspace notifications
- **Pushbullet/Pushover**: Mobile push notifications
- **Webhook**: Custom webhook for integrations

**Notification Types**:
- Request received (admins)
- Request approved/denied (requester)
- Content available (requester)
- Failed requests
- Issue reports

### Telegram Notifications

Overseerr has excellent Telegram support for notifying users about request status.

#### Prerequisites
- Complete the [Telegram Bot Setup](../notifications/telegram-setup.md) first
- You'll need your **Bot Token** and **Chat ID**

#### Configuration Steps

1. **Open Overseerr** at `http://localhost:5055`

2. **Go to Settings → Notifications → Telegram**

3. **Configure Telegram**:
   - **Enable Agent**: Toggle ON
   - **Bot API Token**: `8410328014:AAF4MnHVHr-EoJwno7uB4x9weC22HtJI9LU`
   - **Chat ID**: `8320862964`
   - **Send Silently**: OFF (you want notifications with sound)

4. **Choose Notification Types**:

   **For Admins** (your Chat ID):
   - ✅ **Media Requested** - When users submit requests
   - ✅ **Media Auto-Approved** - When requests auto-approve
   - ✅ **Media Failed** - When downloads fail
   - ⚠️ **Media Approved** - Skip if using auto-approve (duplicate)
   - ⚠️ **Media Declined** - Only if manually reviewing requests

   **For Users** (they need their own Chat ID):
   - Users can add their own Telegram Chat ID in User Settings
   - They'll receive notifications when their requests are approved/available

5. **Test the Connection**
   - Click **Test** button
   - You should receive a test notification in Telegram

6. **Save** settings

#### Notification Examples

**Request Received (Admin):**
```
[Overseerr] New Request
The Matrix (1999) - Movie
Requested by: John
Quality: 1080p
Status: Pending approval
```

**Request Auto-Approved (Admin):**
```
[Overseerr] Request Auto-Approved
Inception (2010) - Movie
Requested by: Sarah
Sent to Radarr for download
```

**Media Available (User):**
```
[Overseerr] Media Available
The Matrix (1999) is now available!
Watch it now on Plex
```

**Download Failed (Admin):**
```
[Overseerr] Media Failed
Breaking Bad - Season 1
Requested by: Mike
Error: Download client returned error
```

#### User-Specific Notifications

Each Overseerr user can add their own Telegram Chat ID:

1. User logs into Overseerr
2. Goes to **User Settings → Notifications**
3. Adds their Telegram Chat ID
4. They receive notifications for their own requests:
   - Request approved
   - Content available
   - Request denied

**Pro Tip**: Send this guide to your Plex users so they can set up their own Telegram notifications!

#### What You Should Enable

**Essential (Admins)**:
- ✅ Media Requested (know what people want)
- ✅ Media Failed (catch download issues)
- ✅ Media Auto-Approved (track what's being downloaded)

**Optional (Admins)**:
- Media Approved (only if manually approving)
- Media Declined (only if manually declining)

**Essential (Users)**:
- Users should enable all notification types for their requests

## User Quotas

Limit how much users can request:
- Movies per day/week/month
- TV shows per day/week/month
- Episode limits for TV shows

**Why use quotas?**
- Prevent abuse on shared servers
- Manage bandwidth and storage
- Encourage thoughtful requests

## Issue Reporting

Users can report issues with content:
- "Video Problems" (buffering, quality issues)
- "Audio Problems"
- "Subtitle Problems"
- "Other Issues"

Issues alert admins to check the quality of downloaded content.

## 4K Management

**Separate 4K Server Recommended**:
- Set up separate Radarr/Sonarr instances for 4K
- Configure in Overseerr as "4K Server"
- Users request 4K separately (requires permission)
- Prevents mixing 4K and 1080p in same library

**Why separate?**
- 4K files are much larger (storage management)
- Not all users can stream 4K
- Different quality profiles needed

## Security Best Practices

✅ **Secure Authentication**: Use strong passwords
✅ **Limited Permissions**: Don't give all users admin access
✅ **Request Quotas**: Prevent abuse with limits
✅ **API Key Security**: Keep API keys private
✅ **Plex Integration**: Only trusted users should access

## Advanced Features

**Webhook Notifications**: Integrate with custom scripts/automations

**Request Lists**: Auto-add content from lists (Plex Watchlist, IMDB, etc.)

**Multi-Server Support**: Multiple Radarr/Sonarr instances (e.g., 4K, remux, anime)

**Issue Tracking**: Built-in issue reporting and management

**Request History**: Full audit trail of all requests

## Integration Tips

**Plex Integration**:
- Sync libraries regularly (Settings → Plex → Manual Sync button)
- Map Overseerr to same Plex account structure
- Users sign in with Plex accounts (automatic permission sync)

**Mobile Access**:
- Overseerr is mobile-responsive
- Can add as web app to home screen
- No dedicated mobile app needed

## Important Notes

- **Plex Account Required**: Users must have Plex accounts to use Overseerr
- **Discovery Data**: Content metadata from TMDB (The Movie Database)
- **No Streaming**: Overseerr doesn't stream - it only manages requests (use Plex for streaming)
- **Request ≠ Immediate**: Downloads take time; set user expectations
