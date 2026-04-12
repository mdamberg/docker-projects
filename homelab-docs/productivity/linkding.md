# Linkding — Bookmark Manager

Self-hosted bookmark manager for saving and organizing links.

## Access

| Item | Value |
|------|-------|
| Local URL | http://10.0.0.7:8282 |
| Remote URL (Tailscale) | http://100.82.35.70:8282 |
| Port | 8282 (mapped from container port 9090) |
| Container | `linkding` |
| Image | `sissbruecker/linkding:latest` |

## Compose Location

```
docker-projects/linkding/docker-compose.yml
```

## Configuration

- **Superuser**: set via `LD_SUPERUSER_NAME` in compose
- **Password**: set via `LD_SUPERUSER_PASSWORD` in `.env` — the compose default is `changeme`, which must be changed
- **Data**: persisted in named volume `linkding-data`

> ⚠️ If you haven't changed the default password yet, do it now: Settings → Change Password inside the Linkding UI, or update the `.env` and recreate the container.

## Management

```powershell
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\linkding"

docker-compose up -d     # Start
docker-compose down      # Stop
docker-compose logs -f   # Logs
```

## Backup & Restore

Linkding stores its data in a named Docker volume (`linkding-data`). The volume may not be captured by file-level Duplicati backups — verify this.

To manually export bookmarks:
1. Log in → Settings → General
2. Click "Export bookmarks" (HTML format, importable in any browser)

To backup the volume directly:
```powershell
docker run --rm -v linkding-data:/data -v C:\backups:/backup alpine tar czf /backup/linkding-backup.tar.gz /data
```

## Updating

```powershell
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\linkding"
docker-compose pull
docker-compose up -d
```
