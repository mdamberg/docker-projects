# Deleting Media Without Re-Downloads

## The Problem

When you delete a movie or TV show incorrectly, it gets re-downloaded because:
1. **Radarr/Sonarr still has it monitored** - It keeps searching for the title
2. **Overseerr shows it as "available"** - Users can re-request it
3. **Multiple places to manage** - Files exist in qBittorrent, Radarr/Sonarr, Plex, and on disk

## The Solution: Delete from Radarr/Sonarr

**Always delete from Radarr (movies) or Sonarr (TV shows) - this is your single source of truth.**

Deleting from Radarr/Sonarr:
- Removes the files from disk
- Removes from your library database
- Plex automatically removes it on next scan
- Prevents re-downloading (if you choose "Delete" not just "Unmonitor")

---

## Quick Reference

| I Want To...                          | Action |      Clicks                              |
|--------------                         |--------| --------------------------------------|
| Delete movie permanently              | Radarr →  Movie → Delete (with "Delete files") | 3 |
| Delete TV show permanently            | Sonarr → Series → Delete (with "Delete files") | 3 |
| Keep in library but stop monitoring   | Radarr/Sonarr → Unmonitor | 2 |
| Delete and block re-requests          | Delete in Radarr/Sonarr, then decline in Overseerr | 4-5 |

---

## Deleting Movies (Radarr)

### Method 1: Single Movie Deletion (3 clicks)

1. **Open Radarr**: `http://localhost:7878`
2. **Find the movie**: Use search or browse
3. **Click the movie** to open details
4. **Click the trash icon** (or go to Edit → Delete)
5. **Check "Delete files from disk"**
6. **Confirm deletion**

```
Radarr → Movies → [Movie Name] → 🗑️ Delete → ✅ Delete files → Confirm
```

### Method 2: Bulk Deletion (multiple movies)

1. **Open Radarr**: `http://localhost:7878`
2. **Go to Movies → Movie Editor** (or press `Shift+E`)
3. **Select movies** using checkboxes
4. **Click "Delete" at the bottom**
5. **Check "Delete files from disk"**
6. **Confirm**

### What Happens After Deletion

- Files removed from `C:\media\movies\[Movie Name]\`
- Movie removed from Radarr database
- Plex removes it on next library scan (usually within 15 minutes)
- Overseerr will show it as "Not Available" (allowing re-requests if desired)

---

## Deleting TV Shows (Sonarr)

### Method 1: Delete Entire Series (3 clicks)

1. **Open Sonarr**: `http://localhost:8989`
2. **Find the series**: Use search or browse
3. **Click the series** to open details
4. **Click the trash icon** (or Edit → Delete)
5. **Check "Delete files from disk"**
6. **Confirm deletion**

```
Sonarr → Series → [Show Name] → 🗑️ Delete → ✅ Delete files → Confirm
```

### Method 2: Delete Specific Episodes/Seasons

If you only want to delete some episodes:

1. **Open Sonarr**: `http://localhost:8989`
2. **Navigate to series**
3. **Expand the season**
4. **Click the episode(s)** to select
5. **Click delete icon for selected episodes**
6. **Optional**: Unmonitor deleted episodes to prevent re-download

**Note**: Deleting individual episodes while keeping the show monitored may cause re-downloads. Either delete the whole series or unmonitor the deleted episodes.

### Method 3: Bulk Series Deletion

1. **Open Sonarr**: `http://localhost:8989`
2. **Go to Series → Series Editor** (or press `Shift+E`)
3. **Select series** using checkboxes
4. **Click "Delete" at the bottom**
5. **Check "Delete files from disk"**
6. **Confirm**

---

## Preventing Re-Downloads

### Option 1: Delete Completely (Recommended)

When you delete with "Delete files from disk" checked in Radarr/Sonarr, the item is:
- Removed from your library
- Removed from disk
- **Not monitored** - won't be searched for again

If someone requests it again via Overseerr, it will be treated as a new request (which you can decline).

### Option 2: Keep But Stop Monitoring

If you want to keep a record but stop downloads:

**Radarr:**
1. Open movie details
2. Click the **bookmark icon** to unmonitor (turns gray)
3. Movie stays in library but won't be searched for

**Sonarr:**
1. Open series details
2. Click the **bookmark icon** to unmonitor entire series
3. Or expand seasons/episodes and unmonitor specific ones

### Option 3: Block Re-Requests (Overseerr)

To completely prevent users from re-requesting deleted content:

1. **After deleting in Radarr/Sonarr**
2. **Open Overseerr**: `http://localhost:5055`
3. **Search for the title**
4. If there's an existing request, click it
5. **Decline the request** with a reason
6. The title will show as "Declined" and users can't easily re-request

---

## Do NOT Delete From These Locations

| Location | Why Not |
|----------|---------|
| **Plex** | Plex doesn't manage downloads - Radarr/Sonarr will still have it monitored and re-download |
| **File Explorer** | Same issue - Radarr/Sonarr still tracking it, will re-download |
| **qBittorrent** | Only deletes the torrent/download, not the imported file - and Radarr/Sonarr will re-grab it |
| **Overseerr** | Overseerr only manages requests, not files |

**Golden Rule**: The app that downloads it (Radarr/Sonarr) should be the app that deletes it.

---

## Handling Active Downloads

If something is currently downloading and you want to stop it:

### Step 1: Remove from Download Client

1. **Open qBittorrent**: `http://localhost:8080`
2. **Find the download**
3. **Right-click → Delete**
4. **Check "Also delete files"**

### Step 2: Remove from Radarr/Sonarr

1. **Open Radarr/Sonarr**
2. **Go to Activity → Queue**
3. **Find the item** and click the X to remove from queue
4. **Then delete the movie/series** as described above

---

## Workflow Comparison

### Wrong Way (5+ clicks, content re-downloads)

```
Delete in Plex → Radarr notices "missing" → Searches again → Re-downloads → 😤
```

### Wrong Way (4+ clicks, content re-downloads)

```
Delete files in Explorer → Plex removes → Radarr notices "missing" → Re-downloads → 😤
```

### Right Way (3 clicks, permanent)

```
Delete in Radarr with "Delete files" → Files gone → Plex syncs → Done → 😊
```

---

## Reclaiming Disk Space

After deleting content, verify space is reclaimed:

1. **Check Radarr/Sonarr** - deleted items shouldn't appear
2. **Check Plex** - should disappear after library scan
3. **Check disk** - verify `C:\media\movies` or `C:\media\tv` shows reduced size

If files still exist after Radarr/Sonarr deletion:
- Check for orphaned files in download folder (`C:\media\downloads`)
- Radarr/Sonarr may not have cleaned up incomplete downloads
- Manually delete orphans from `C:\media\downloads\complete` if needed

---

## Common Scenarios

### "I deleted a movie but it came back"

**Cause**: You deleted from Plex or file system, not Radarr
**Fix**: Delete properly from Radarr with "Delete files" checked

### "I deleted a show but some episodes re-downloaded"

**Cause**: You deleted files but the series is still monitored in Sonarr
**Fix**: Either delete the entire series from Sonarr, or unmonitor the episodes you deleted

### "Users keep re-requesting things I deleted"

**Cause**: Overseerr allows new requests for unavailable content
**Fix**: After deleting, decline the request in Overseerr with a note like "Not adding to library"

### "Deleted content still shows in Plex"

**Cause**: Plex hasn't scanned the library yet
**Fix**: Manually scan library: Plex → Libraries → Movies/TV → Scan Library Files

### "I want to delete but keep the request history"

**Action**: Delete in Radarr/Sonarr - Overseerr maintains its own request history separate from the actual files

---

## Automation Ideas

### Radarr: Auto-Delete After Watching (Not Recommended)

Radarr doesn't have auto-delete, but Tautulli + custom scripts can:
1. Tautulli detects movie watched to 90%
2. Webhook triggers script
3. Script calls Radarr API to delete

**Warning**: This can delete movies before all household members watch them.

### Sonarr: Delete Watched Episodes

Same concept with Tautulli for TV shows. Useful for daily shows you won't rewatch.

### Better Alternative: Unmonitor Instead

Instead of auto-deleting, auto-unmonitor completed shows:
- Keeps files for rewatching
- Stops upgrades and re-downloads
- Prevents accidental deletion

---

## Summary

| Task | Where | Action |
|------|-------|--------|
| Delete movie | Radarr | Delete with "Delete files" |
| Delete TV show | Sonarr | Delete with "Delete files" |
| Stop upgrades only | Radarr/Sonarr | Unmonitor |
| Block re-requests | Overseerr | Decline request |
| Delete active download | qBittorrent → then Radarr/Sonarr | Remove from both |

**Remember**: Radarr/Sonarr are your single source of truth. Always delete from there.
