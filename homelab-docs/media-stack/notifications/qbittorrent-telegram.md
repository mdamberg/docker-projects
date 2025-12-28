# qBittorrent Telegram Notifications

Get Telegram notifications when torrents complete in qBittorrent.

## Important Note

**For media downloads** (movies, TV shows, books), you're already covered:
- Radarr monitors movie downloads and sends notifications
- Sonarr monitors TV downloads and sends notifications
- LazyLibrarian monitors book downloads and sends notifications

**This guide is for:**
- Standalone torrents (not managed by *arr apps)
- Manual torrent downloads
- Non-media downloads

If you're only downloading media via Radarr/Sonarr/LazyLibrarian, you **don't need this** - you already get notifications from those apps!

---

## Overview

qBittorrent doesn't have native Telegram support, but we can use its "Run external program on torrent completion" feature with a simple PowerShell script.

## Prerequisites

- Telegram bot set up ([Telegram Bot Setup](telegram-setup.md))
- qBittorrent running on Windows host
- PowerShell available (already on Windows)

## Setup Steps

### Step 1: Create the Notification Script

1. **Create a scripts folder**:
   ```powershell
   mkdir "C:\Users\mattd\OneDrive\Matts Documents\Docker\scripts"
   ```

2. **Create the notification script**:
   Save this as `C:\Users\mattd\OneDrive\Matts Documents\Docker\scripts\telegram-notify.ps1`:

   ```powershell
   # qBittorrent Telegram Notification Script
   param(
       [string]$TorrentName,
       [string]$Category,
       [string]$Tags,
       [string]$ContentPath,
       [string]$RootPath,
       [string]$SavePath,
       [string]$NumberOfFiles,
       [string]$TorrentSize,
       [string]$CurrentTracker
   )

   # Your Telegram credentials
   $botToken = "8410328014:AAF4MnHVHr-EoJwno7uB4x9weC22HtJI9LU"
   $chatId = "8320862964"

   # Convert size from bytes to readable format
   $sizeGB = [math]::Round([double]$TorrentSize / 1GB, 2)
   $sizeMB = [math]::Round([double]$TorrentSize / 1MB, 2)

   if ($sizeGB -gt 1) {
       $sizeFormatted = "$sizeGB GB"
   } else {
       $sizeFormatted = "$sizeMB MB"
   }

   # Build notification message
   $message = @"
   [qBittorrent] Download Complete

   Name: $TorrentName
   Size: $sizeFormatted
   Files: $NumberOfFiles
   Category: $Category
   Path: $SavePath
   "@

   # Send to Telegram
   try {
       $uri = "https://api.telegram.org/bot$botToken/sendMessage"
       $body = @{
           chat_id = $chatId
           text = $message
           parse_mode = "HTML"
       }

       Invoke-RestMethod -Uri $uri -Method Post -Body $body -ErrorAction Stop
       Write-Host "Notification sent successfully"
   } catch {
       Write-Host "Failed to send notification: $_"
   }
   ```

### Step 2: Configure qBittorrent

**Note**: Since qBittorrent is running in Docker via Gluetun, this is tricky. Here are your options:

#### Option A: Run Script on Host (Recommended)

1. **Enable qBittorrent Web API** (already enabled at `http://localhost:8080`)

2. **Create a Windows scheduled task** that polls for completed torrents:

   Save this as `C:\Users\mattd\OneDrive\Matts Documents\Docker\scripts\qbit-monitor.ps1`:

   ```powershell
   # qBittorrent Monitor Script
   $botToken = "8410328014:AAF4MnHVHr-EoJwno7uB4x9weC22HtJI9LU"
   $chatId = "8320862964"
   $qbitUrl = "http://localhost:8080"

   # Track completed torrents (store in file to avoid duplicates)
   $trackedFile = "C:\Users\mattd\OneDrive\Matts Documents\Docker\scripts\qbit-tracked.txt"

   if (!(Test-Path $trackedFile)) {
       New-Item -Path $trackedFile -ItemType File
   }

   $tracked = Get-Content $trackedFile -ErrorAction SilentlyContinue

   # Get completed torrents from qBittorrent API
   try {
       $torrents = Invoke-RestMethod -Uri "$qbitUrl/api/v2/torrents/info?filter=completed" -Method Get

       foreach ($torrent in $torrents) {
           $hash = $torrent.hash

           # Skip if already notified
           if ($tracked -contains $hash) {
               continue
           }

           # Format size
           $sizeGB = [math]::Round($torrent.size / 1GB, 2)
           $sizeMB = [math]::Round($torrent.size / 1MB, 2)

           if ($sizeGB -gt 1) {
               $sizeFormatted = "$sizeGB GB"
           } else {
               $sizeFormatted = "$sizeMB MB"
           }

           # Build message
           $message = @"
   [qBittorrent] Download Complete

   Name: $($torrent.name)
   Size: $sizeFormatted
   Category: $($torrent.category)
   Ratio: $([math]::Round($torrent.ratio, 2))
   "@

           # Send notification
           $uri = "https://api.telegram.org/bot$botToken/sendMessage"
           $body = @{
               chat_id = $chatId
               text = $message
           }

           Invoke-RestMethod -Uri $uri -Method Post -Body $body

           # Mark as notified
           Add-Content -Path $trackedFile -Value $hash
       }
   } catch {
       Write-Host "Error: $_"
   }
   ```

3. **Create Windows Scheduled Task**:

   ```powershell
   # Run this in PowerShell as Administrator
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File 'C:\Users\mattd\OneDrive\Matts Documents\Docker\scripts\qbit-monitor.ps1'"
   $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
   $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U
   $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

   Register-ScheduledTask -TaskName "qBittorrent Telegram Notifications" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Sends Telegram notifications for completed torrents"
   ```

   This creates a task that runs every 5 minutes and checks for completed torrents.

#### Option B: Docker Container Monitoring (Advanced)

Use a tool like **qBit Management** or **qbittorrent-exporter** to monitor qBittorrent and send notifications.

---

## What You'll Get

### Download Complete
```
[qBittorrent] Download Complete

Name: ubuntu-22.04.iso
Size: 3.2 GB
Category: software
Ratio: 0.5
```

### For Media Files
```
[qBittorrent] Download Complete

Name: Movie.Name.2024.1080p.BluRay
Size: 8.5 GB
Category: movies
Ratio: 0.0
```

---

## Testing

1. **Test the monitor script manually**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "C:\Users\mattd\OneDrive\Matts Documents\Docker\scripts\qbit-monitor.ps1"
   ```

2. **Add a small test torrent** in qBittorrent

3. **Wait for completion** - you should get a notification within 5 minutes

---

## Recommended Approach

**If you only download media via Radarr/Sonarr:**
- ✅ Skip qBittorrent notifications entirely
- ✅ Use Radarr/Sonarr notifications (already set up)
- ✅ Those apps give you better context (movie name, quality, etc.)

**If you download non-media torrents:**
- ✅ Use Option A (monitoring script with scheduled task)
- ✅ Run every 5-10 minutes
- ✅ Simple and reliable

**If you want real-time notifications:**
- Consider using qBittorrent's Web UI and checking manually
- Or set up a more advanced solution with Docker event monitoring

---

## Troubleshooting

### Script not running?
- Check Windows Task Scheduler to verify task is enabled
- Run the script manually to test
- Check PowerShell execution policy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Not receiving notifications?
- Test the Telegram bot manually
- Check script logs in Task Scheduler (History tab)
- Verify qBittorrent Web API is accessible at `http://localhost:8080`

### Duplicate notifications?
- The script tracks completed torrents in `qbit-tracked.txt`
- Delete this file to reset tracking
- Notifications should only send once per torrent

### Task won't create?
- Run PowerShell as Administrator
- Verify the script path is correct
- Check Windows Event Viewer for errors

---

## Alternative: Just Use Radarr/Sonarr

**Honestly, for most users:**

The best approach is to **only get notifications from Radarr/Sonarr** because:
- ✅ They already monitor qBittorrent
- ✅ They give better context ("Movie Name" vs "Movie.Name.2024.x264.mkv")
- ✅ They notify on grab AND import (two notifications per download)
- ✅ They include failure notifications with reasons

qBittorrent notifications are only useful for standalone/manual torrents.

---

## Summary

- **Media downloads**: Already covered by Radarr/Sonarr/LazyLibrarian ✅
- **Standalone torrents**: Use the monitoring script with scheduled task
- **Real-time needs**: Consider alternative tools or manual checking

For most users, the Radarr/Sonarr notifications you already set up are sufficient!
