# Backup & Restore Standards

## What Gets Backed Up

Duplicati backs up the Docker project configuration files on a nightly schedule. This covers:

- All `docker-compose.yml` files
- All `.env` files (credentials)
- Service-specific config directories (e.g., Pi-hole's `etc-pihole/`, n8n's `n8n_data/`)
- Uptime Kuma monitor config (`uptime-kuma-data/`)

**Not backed up by default:**
- Large media files (movies, TV shows, music) — these live on separate storage
- Plex metadata — Plex can re-scan the library; config is backed up
- Database dumps — PostgreSQL data is in a Docker volume, which may not be captured by file-level backup. See analytics-stack backup docs.

---

## Backup Location

| Item | Detail |
|------|--------|
| Tool | Duplicati (Docker container) |
| Schedule | Nightly at 1:00 AM |
| Source | `C:\docker-projects` |
| Destination | `C:\backups` |
| Web UI | http://10.0.0.7:8200 |
| Monitoring | Healthchecks.io dead man's switch |

See [Backups README](../backups/README.md) for full Duplicati details.

---

## Restore Process

### Scenario 1: Restore a single service config

1. Open Duplicati at http://10.0.0.7:8200
2. Select the backup job → Restore
3. Navigate to the service directory (e.g., `docker-projects/pie_hole/`)
4. Restore to original location
5. `cd` to the service directory and run `docker-compose up -d`

### Scenario 2: Full disaster recovery (new machine)

1. Install Docker Desktop on the new machine
2. Install Duplicati via Docker:
   ```powershell
   cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\backups"
   docker-compose up -d
   ```
3. Open http://localhost:8200 → Import existing backup job
4. Restore all Docker config files
5. Run `.\start-all-services.ps1` to bring everything back up

### Scenario 3: Emergency restore without Duplicati

If Duplicati itself is unavailable:
- Backups are stored in plain (but possibly encrypted) format at `C:\backups`
- Reinstall Duplicati and import the configuration
- Restore files from the existing backup sets

---

## Testing Backups

**Monthly**: Verify at least one service can be restored from backup.

```powershell
# Stop a low-risk service
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\linkding"
docker-compose down
Remove-Item -Recurse .\linkding-data  # Simulate data loss

# Restore from Duplicati backup
# ... restore via web UI ...

# Bring service back up
docker-compose up -d
```

---

## Retention Policy (Recommended)

Configure in Duplicati web UI:
- Last 30 days: keep all backups
- Last 6 months: keep weekly backups
- Older: keep monthly backups

---

## What to Do If Backup Fails

1. Check Duplicati web UI for error details
2. Check healthchecks.io — if the dead man's switch fired, a ping was missed
3. Common causes: source path missing, destination disk full, container not running
4. Fix the issue, then run the backup manually to restore the ping cadence
