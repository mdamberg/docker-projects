# LazyLibrarian

## Overview

LazyLibrarian is an automated book and audiobook collection manager, similar to Sonarr/Radarr but for literature. It tracks authors and books you want, automatically searches for them, downloads via qBittorrent, and organizes them into your library for consumption via Audiobookshelf or other ebook readers.

**What it does**:
- Tracks authors and their books/audiobooks
- Monitors for new releases from followed authors
- Automatically searches for books and audiobooks via Prowlarr
- Sends downloads to qBittorrent
- Organizes completed downloads into your books library
- Can grab both ebooks (EPUB, MOBI) and audiobooks
- Manages metadata and covers

**Why you need it**: Just like you automate TV and movies, LazyLibrarian automates building your digital library of books and audiobooks.

## Ports

| Port | Purpose |
|------|---------|
| `5299` | LazyLibrarian Web UI and API endpoint |

## How It Works

1. **You add an author or book** to LazyLibrarian
2. **LazyLibrarian monitors** for new releases from that author
3. **When a new book is available, LazyLibrarian searches Prowlarr**
4. **LazyLibrarian evaluates releases** and sends the best match to qBittorrent
5. **qBittorrent downloads** to `C:\media\downloads`
6. **LazyLibrarian monitors the download** and waits for completion
7. **When complete, LazyLibrarian**:
   - Processes the file (extracts if needed)
   - Renames following a consistent format
   - Moves to `C:\media\books` (for ebooks) or keeps in downloads for audiobooks
8. **Audiobookshelf or your ebook reader** picks up the new content

## Service Interactions

**Searches Via**:
- **Prowlarr** (queries configured book/audiobook indexers)

**Downloads Via**:
- **qBittorrent** (sends torrent files for download)

**Organizes Files For**:
- **Audiobookshelf** (audiobooks)
- **Ebook readers** (Calibre, ebook apps)

**Workflow**:
```
Add author/book ’ LazyLibrarian ’ Searches Prowlarr ’ Finds release
                                                           “
                                           Sends to qBittorrent to download
                                                           “
                                            Download completes
                                                           “
                                  LazyLibrarian organizes into C:\media\books
                                                           “
                                     Audiobookshelf or ebook reader picks it up
```

## Environment Variables

| Variable | Description | Value in Your Setup |
|----------|-------------|---------------------|
| `PUID` | User ID for file permissions | Loaded from `.env` |
| `PGID` | Group ID for file permissions | Loaded from `.env` |
| `TZ` | Timezone | Loaded from `.env` |

## Mounts & Volumes

| Mount | Purpose | Notes |
|-------|---------|-------|
| `C:/media/config/lazylibrarian:/config` | LazyLibrarian settings, database | Contains your library metadata and configurations |
| `C:/media/downloads:/downloads` | Reads completed downloads from qBittorrent | **Must match qBittorrent's download path** |
| `C:/media/books:/books` | Final destination for organized books/audiobooks | Where your digital library lives |

**Important**: LazyLibrarian needs access to both downloads (to find completed files) and books (to move/organize them).

## Compose File Breakdown

```yaml
lazylibrarian:
  image: linuxserver/lazylibrarian:latest
  container_name: lazylibrarian
  environment:
    - PUID=${PUID}                  # File ownership
    - PGID=${PGID}
    - TZ=${TZ}                      # Timezone
  volumes:
    - "C:/media/config/lazylibrarian:/config"    # Settings and database
    - "C:/media/downloads:/downloads"            # Completed downloads (shared with qBittorrent)
    - "C:/media/books:/books"                    # Book library
  ports:
    - "5299:5299"                   # Web UI and API
  restart: unless-stopped
```

## Common Use Cases

- **Author Following**: Add your favorite authors, get their new books automatically
- **Book Requests**: Manually search and grab specific books
- **Audiobook Collection**: Build an audiobook library for Audiobookshelf
- **Ebook Library**: Maintain organized ebook collection
- **Series Tracking**: Follow book series and get new installments

## Troubleshooting Tips

**Book won't download?**
- Check if Prowlarr has working book indexers
- Verify qBittorrent connection (Settings ’ Downloaders)
- Check search providers (Settings ’ Search Providers)
- Look at LazyLibrarian logs (Config ’ Logs)

**Download completed but LazyLibrarian didn't import?**
- Verify `/downloads` path matches qBittorrent's path
- Check file permissions (PUID/PGID)
- Look for processing errors in logs
- Try manual processing (Books ’ Process Folder)

**Book imported but wrong format?**
- Configure preferred formats (Settings ’ Processing ’ Preferred ebook/audiobook type)
- LazyLibrarian tries to get format you prefer (EPUB, MOBI, M4B, etc.)

**Searches return no results?**
- Book indexers are less common than movie/TV indexers
- Make sure Prowlarr has book-specific indexers configured
- Try alternative search providers (GoodReads, GoogleBooks API)

**Can't connect to qBittorrent?**
- qBittorrent uses Gluetun's network
- Host: `gluetun` or `localhost`
- Port: `8080`
- Verify category is set correctly in LazyLibrarian

## Initial Configuration Steps

### 1. First Launch
- Access: `http://localhost:5299`
- Complete initial setup wizard
- Set timezone and basic settings

### 2. Connect to Prowlarr
- Config ’ Indexers ’ Add Prowlarr
- **OR** add from Prowlarr side (Settings ’ Apps ’ Add ’ LazyLibrarian)
  - URL: `http://lazylibrarian:5299`
  - API Key: Found in LazyLibrarian ’ Config ’ Interface

### 3. Add Download Client (qBittorrent)
- Config ’ Downloaders ’ Add qBittorrent
- Host: `gluetun` (or `localhost`)
- Port: `8080`
- Category: `books` (optional but helpful)
- Test connection

### 4. Configure Search Providers
- Config ’ Search Providers
- Add GoodReads API key (optional, for metadata)
- Add GoogleBooks API key (optional, for metadata)
- Configure preferred ebook/audiobook format

### 5. Set Processing Options
- Config ’ Processing
- **Ebook Type**: EPUB, MOBI, AZW3 (choose your preferred format)
- **Audiobook Type**: M4B, MP3 (M4B recommended for audiobooks)
- **Destination**: `/books` (already configured via volume mount)

### 6. Add Your First Author
- Authors ’ Add Author
- Search for author name
- Select author
- Choose which books to monitor
- LazyLibrarian will search for monitored books

## Book Formats Explained

### Ebooks
- **EPUB**: Universal format, works on most devices (recommended)
- **MOBI**: Amazon Kindle format (older)
- **AZW3**: Kindle format (newer, better than MOBI)
- **PDF**: Less ideal for ebooks (fixed layout)

### Audiobooks
- **M4B**: Single file with chapters (best for audiobooks) - **Recommended**
- **MP3**: Multiple files (less convenient)
- **OPUS**: High quality, smaller size (less compatible)

**Tip**: Configure LazyLibrarian to prefer M4B for audiobooks and EPUB for ebooks.

## Understanding Book Sources

**Torrent Indexers** (via Prowlarr):
- Book-specific torrent sites
- Less common than movie/TV indexers
- Configure in Prowlarr with "Books" category

**Direct Search**:
- GoodReads API
- GoogleBooks API
- LibGen (manual searches)

**Usenet** (if configured):
- Some Usenet indexers carry books
- Requires Usenet account and newsreader

## Working with Audiobookshelf

LazyLibrarian and Audiobookshelf work together:

1. **LazyLibrarian downloads** and organizes audiobooks to `C:\media\books` (or separate audiobook folder)
2. **Audiobookshelf scans** that folder and makes audiobooks playable
3. **You listen** via Audiobookshelf's interface

**Configuration Tip**: You can organize ebooks and audiobooks separately:
- `/books/ebooks` for ebooks
- `/books/audiobooks` for audiobooks
- Configure paths in LazyLibrarian accordingly

## Performance Notes

- **CPU**: Light - only active during searches and processing
- **RAM**: ~100-200MB
- **Disk**: Database grows with library size
- **Processing**: Extracting audiobook archives can be CPU-intensive temporarily

## Library Organization

LazyLibrarian can organize books in several ways:

**By Author**:
```
C:\media\books\
     Stephen King/
        The Shining.epub
        It.epub
     J.K. Rowling/
         Harry Potter and the Sorcerer's Stone.epub
```

**By Series** (optional):
```
C:\media\books\
     Harry Potter Series/
        Book 1 - Philosopher's Stone.epub
        Book 2 - Chamber of Secrets.epub
```

Configure this in Settings ’ Processing ’ Folder Format

## Metadata and Covers

LazyLibrarian fetches:
- **Book metadata**: Title, author, description, ISBN
- **Cover art**: Book covers for library display
- **Series information**: Which book in a series
- **Publication data**: Release dates, publishers

Sources:
- GoodReads
- GoogleBooks
- LazyLibrarian's own database

## Advanced Features

**Want List**: Add books without authors - LazyLibrarian searches for them

**Magazine Support**: LazyLibrarian can also grab magazines (if you configure sources)

**Calibre Integration**: Can integrate with Calibre library management

**Alternative Sources**: Can search multiple sources beyond torrents

**Notifications**: Configure Discord, Telegram, etc. for new book alerts

## Book Indexers for Prowlarr

Popular book indexers to add in Prowlarr:
- **MyAnonamouse** (private, excellent for books/audiobooks - requires interview)
- **Bibliotik** (private, great selection - invite only)
- **MAM** (MyAnonamouse - same as above)
- **Public indexers**: Available but less reliable

**Note**: Book torrenting is less popular than movies/TV, so private trackers are more important.

## Security & Legal Considerations

- **Public Domain**: Many classics are public domain and freely available
- **Library Access**: Check if your local library offers ebook lending (Libby, Overdrive)
- **Purchase**: Support authors by purchasing books when possible
- **Personal Backups**: LazyLibrarian is useful for managing books you own

## Common Workflows

**Following an Author**:
1. Authors ’ Add Author
2. Select author
3. Monitor all future books
4. LazyLibrarian auto-downloads new releases

**One-Time Book Request**:
1. Books ’ Add Book
2. Search for specific title
3. Add and search
4. LazyLibrarian finds and downloads

**Building a Series**:
1. Search for first book in series
2. Add author
3. Mark all series books as wanted
4. LazyLibrarian grabs them all

## Integration with Reading Apps

**Ebook Readers**:
- Point Calibre to `C:\media\books`
- Use Calibre Web for web-based access
- Copy EPUBs to Kindle/Kobo

**Audiobooks**:
- Use Audiobookshelf (recommended - see audiobookshelf.md)
- Or use Plex (also supports audiobooks)
- Or copy M4B files to phone

## Backup Considerations

**What to Backup**:
- `C:/media/config/lazylibrarian` - Your database and settings
- `C:/media/books` - Your actual book library (most important!)

**Frequency**:
- Config: After major changes
- Books: Regularly (these are large files)

## Important Notes

- **Book Availability**: Books are less available on torrents than movies/TV - be patient
- **Format Preference**: Set your preferred formats early to avoid re-downloading
- **Audiobook Size**: Audiobooks are large (100MB - 1GB per book)
- **Metadata Quality**: Book metadata can be inconsistent - you may need to manually correct some entries
- **Author Updates**: Check occasionally that author tracking is working - release dates can be wrong
