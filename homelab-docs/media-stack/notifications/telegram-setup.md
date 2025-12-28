# Telegram Bot Setup for Media Stack Notifications

This guide walks through setting up a Telegram bot to receive notifications from your media stack services (Radarr, Sonarr, Overseerr, etc.).

## Why Telegram Over Discord?

- **More reliable** - Better rate limits, won't miss notifications
- **Instant delivery** - Notifications appear immediately on mobile and desktop
- **Rich formatting** - Supports images, links, formatting
- **Free forever** - No costs or subscriptions
- **Easy control** - Mute/unmute per-bot, custom sounds per bot
- **Better for automation** - Purpose-built for bots

## Your Bot Details

**Bot Token**: `8410328014:AAF4MnHVHr-EoJwno7uB4x9weC22HtJI9LU`
**Chat ID**: `8320862964`

**SECURITY**: Keep these values private. Treat the bot token like a password.

---

## Quick Start (Already Completed)

You've already completed the setup! Your bot is working. Here's what you did:

1. ✅ Created bot with @BotFather
2. ✅ Got bot token
3. ✅ Got your chat ID
4. ✅ Tested the bot successfully

---

## Next Steps: Configure Services

Now configure Telegram notifications in each service:

### 1. Radarr (Movies)
[Follow the Radarr Telegram guide](../services/radarr.md#telegram-notifications)

**Quick config:**
- Open: `http://localhost:7878`
- Go to: Settings → Connect → Add → Telegram
- Bot Token: `8410328014:AAF4MnHVHr-EoJwno7uB4x9weC22HtJI9LU`
- Chat ID: `8320862964`
- Enable: On Grab, On Import, On Health Issue
- Test and Save

### 2. Sonarr (TV Shows)
[Follow the Sonarr Telegram guide](../services/sonarr.md#telegram-notifications)

**Quick config:**
- Open: `http://localhost:8989`
- Go to: Settings → Connect → Add → Telegram
- Bot Token: `8410328014:AAF4MnHVHr-EoJwno7uB4x9weC22HtJI9LU`
- Chat ID: `8320862964`
- Enable: On Grab, On Import, On Health Issue
- Test and Save

### 3. Overseerr (Requests) - Optional
[Follow the Overseerr Telegram guide](../services/overseerr.md#telegram-notifications)

---

## What Notifications You'll Get

### From Radarr (Movies)
- ✅ Movie grabbed from indexer
- ✅ Movie download completed
- ✅ Movie imported to library
- ✅ Movie upgrade completed (720p → 1080p)
- ✅ Download failed with reason
- ✅ Health check warnings (indexer down, disk space low, etc.)

### From Sonarr (TV Shows)
- ✅ Episode grabbed from indexer
- ✅ Episode download completed
- ✅ Episode imported to library
- ✅ Episode upgrade completed
- ✅ Download failed with reason
- ✅ Health check warnings
- ✅ Series added/removed

### From Overseerr (Requests)
- ✅ New media request submitted
- ✅ Request approved/auto-approved
- ✅ Request denied
- ✅ Media available for watching
- ✅ Request failed
- ✅ Issue reported

---

## Notification Examples

**Movie Downloaded:**
```
[Radarr] Movie Downloaded
The Matrix (1999) [1080p BluRay]
Quality: Bluray-1080p
Size: 8.5 GB
Time: 45 minutes
```

**Download Failed:**
```
[Radarr] Download Failed
Movie: Inception (2010)
Reason: Indexer returned 404 - file not found
Release: Inception.2010.1080p.BluRay.x264
```

**TV Episode Imported:**
```
[Sonarr] Episode Downloaded
Breaking Bad - S01E01 - Pilot
Quality: WEBDL-1080p
Size: 2.3 GB
```

**Health Issue:**
```
[Radarr] Health Check Failure
Issue: Indexer 1337x is unavailable
Time: 2025-12-27 14:30
```

---

## Testing Your Bot

To test the bot manually (for debugging):

**PowerShell:**
```powershell
$botToken = "8410328014:AAF4MnHVHr-EoJwno7uB4x9weC22HtJI9LU"
$chatId = "8320862964"
$message = "Test notification from homelab!"

Invoke-RestMethod -Uri "https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=$message"
```

**Bash/WSL:**
```bash
curl -X POST "https://api.telegram.org/bot8410328014:AAF4MnHVHr-EoJwno7uB4x9weC22HtJI9LU/sendMessage" \
  -d "chat_id=8320862964" \
  -d "text=Test notification from homelab!"
```

---

## Troubleshooting

### "Chat not found" error
**Solution:** Send `/start` to your bot in Telegram first

### Not receiving notifications from Radarr/Sonarr?
**Check:**
1. Bot token and chat ID are correct in service settings
2. You've enabled the notification triggers (On Grab, On Import, etc.)
3. Test button works in the service
4. Check service logs (System → Logs) for Telegram errors

### Notifications delayed?
- Telegram is instant - check your internet connection
- Check if service is rate-limited (System → Logs)

### Too many notifications?
- Disable optional triggers (On Rename, On Movie/Series Add)
- Use Telegram's mute feature for specific times
- Only enable essential: On Import, On Health Issue, On Grab

---

## Advanced: Custom Notification Sounds

Set different sounds for different notification types:

1. Open Telegram settings
2. **Notifications and Sounds**
3. Find your bot in the list
4. Set custom sound, vibration, LED color
5. Set quiet hours if needed

---

## Advanced: Group Notifications

Want notifications in a Telegram group instead of DMs?

1. Create a Telegram group
2. Add your bot to the group
3. Make bot an admin (recommended)
4. Get group Chat ID:
   - Send a message in the group
   - Visit: `https://api.telegram.org/bot8410328014:AAF4MnHVHr-EoJwno7uB4x9weC22HtJI9LU/getUpdates`
   - Look for group chat ID (negative number, like `-123456789`)
5. Use the group Chat ID instead of `8320862964` in your service configurations

---

## Security Best Practices

✅ **Keep bot token secret** - Treat it like a password
✅ **Don't share your bot** - Others can spam you
✅ **Don't commit to git** - Use .env files
✅ **Regenerate if compromised** - Use @BotFather `/token` command

---

## Additional Resources

- [Telegram Bot API Documentation](https://core.telegram.org/bots/api)
- [BotFather Commands](https://core.telegram.org/bots#botfather)
- [Radarr Notification Settings](https://wiki.servarr.com/radarr/settings#connect)
- [Sonarr Notification Settings](https://wiki.servarr.com/sonarr/settings#connect)

---

## Summary

You now have:
- ✅ Working Telegram bot
- ✅ Bot token and Chat ID
- ✅ Tested successfully
- 📋 Ready to configure Radarr and Sonarr

**Next:** Go configure Radarr and Sonarr using the guides linked above!
