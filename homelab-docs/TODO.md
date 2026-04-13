# HomeLab To-Do List
*Generated April 2026 — ordered by priority*

---

## 🔴 CRITICAL — Security (Fix First)

- [ ] **1. Set a password on Duplicati web UI**
  - `docker-projects/backups/docker-compose.yml` has `CLI_ARGS=--webservice-password=admin`
  - Change to `CLI_ARGS=--webservice-password=${DUPLICATI_WEBPASS}` and add `DUPLICATI_WEBPASS=<strong-password>` to `.env`
  - Duplicati has read access to all your config files — "admin" is not acceptable

- [ ] **2. Verify Duplicati backup source path is correct**
  - Compose has `C:\docker-projects:/source/docker-configs:ro`
  - Your actual files are at `C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects`
  - Open Duplicati at http://10.0.0.7:8200 → check the backup job source path is pointing to the right place
  - If wrong, this means backups have never captured your actual files

- [ ] **3. Expand Duplicati backup sources**
  - Currently only backs up compose YAML files — not the actual app data
  - Add these paths to Duplicati's backup job source:
    - `C:\media\config` — Plex, Sonarr, Radarr, qBittorrent configs
    - `docker-projects\n8n\n8n_data` — all your n8n workflows
    - `docker-projects\home_assist\configuration\config` — Home Assistant config
    - `docker-projects\monitoring\uptime-kuma-data` — Uptime Kuma monitors
    - `docker-projects\phpipam\mysql_data` — phpIPAM database
    - `docker-projects\flash_todo\data` — Flash Todo data
  - Named volumes (linkding-data, lightdash_pgdata, minio_data) need a separate volume backup strategy

- [ ] **4. Move hardcoded credentials out of compose files**
  - **linkding**: `LD_SUPERUSER_PASSWORD=changeme` → move to `.env` as `${LINKDING_PASS}`
  - **phpipam**: `MYSQL_ROOT_PASSWORD=phpipamadmin`, `MYSQL_PASSWORD=phpipampassword` → move all to `.env`
  - **lightdash**: Remove `:-changemeplease123456789` fallback from `LIGHTDASH_SECRET`; move `PGPASSWORD`, `S3_SECRET_KEY`, `MINIO_ROOT_PASSWORD` to `.env`
  - **media_stack/Homarr**: `SECRET_ENCRYPTION_KEY` hardcoded as hex literal → move to `.env`, generate a new key
  - **wireguard**: Delete the comment that says `password is: WireGuardAdmin2024!`

- [ ] **5. Remove FlareSolverr port exposure**
  - `media_stack/docker-compose.yml`: delete `- "8191:8191"` from flaresolverr
  - Prowlarr reaches it internally via `http://flaresolverr:8191` — no external port needed

---

## 🟠 HIGH — Fix Soon

- [ ] **6. Fix n8n ↔ Home Assistant network communication**
  - n8n and Home Assistant are on different Docker networks — `http://homeassistant:8123` in workflows fails silently
  - Quickest fix: change workflow URLs to use `http://10.0.0.7:8123` instead of the container name
  - Better fix: create a shared external Docker network both services join
  - Verify your power consumption workflow is actually collecting data

- [ ] **7. Verify n8n authentication is actually working**
  - `N8N_BASIC_AUTH_ACTIVE=true` was deprecated in n8n v1.0 (mid-2023) and is now silently ignored
  - Open n8n at http://10.0.0.7:5678 — if you can access it without entering credentials, you have no auth
  - If unprotected: go to Settings → Users in the n8n UI and create a user account

- [ ] **8. Create the `home-metrics` Docker network**
  - Lightdash requires this external network: `docker network create home-metrics`
  - Without it, Lightdash fails to start with a confusing error
  - Add to `start-all-services.ps1` so it's created automatically:
    ```powershell
    docker network create home-metrics 2>$null
    ```

- [ ] **9. Reduce dashdot privileges**
  - Currently: `privileged: true` + mounts entire root filesystem `/:/mnt/host:ro`
  - Replace with specific mounts only:
    ```yaml
    privileged: false
    volumes:
      - /proc:/mnt/host/proc:ro
      - /sys:/mnt/host/sys:ro
      - /mnt:/mnt/host/mnt:ro
    ```

- [ ] **10. Fix Home Assistant privilege setting**
  - `home_assist/docker-compose.yml` has `privileged: true`
  - Only needed for USB device passthrough (Zigbee sticks, Z-Wave dongles)
  - If you're not using USB devices with HA, remove `privileged: true`
  - If you are using USB, replace with `devices:` pointing to the specific device

---

## 🟡 MEDIUM — Improve When Possible

- [ ] **11. Update start-all-services.ps1**
  - Change all `docker-compose` → `docker compose` (v2, no hyphen)
  - Add `docker network create home-metrics 2>$null` near the top
  - Fix startup order so Pi-hole starts first (hashtables iterate randomly):
    ```powershell
    $StartOrder = @('pihole', 'homeassistant', 'monitoring', 'n8n', 'backups', 'phpipam', 'mediastack', 'linkding', 'flash', 'lightdash')
    ```
  - Add `lightdash` to `stop-all-services.ps1` (it's missing)

- [ ] **12. Fix Lightdash SITE_URL**
  - Change `SITE_URL: http://localhost:8090` → `SITE_URL: http://100.82.35.70:8090`
  - Without this, share links and exports don't work from other devices

- [ ] **13. Fix n8n hostname**
  - Change `N8N_HOST=localhost` → `N8N_HOST=10.0.0.7`
  - Without this, any webhook URLs n8n generates point to localhost and can't be reached externally

- [ ] **14. Add restart policy to flash_todo**
  - Add `restart: unless-stopped` to `flash_todo/docker-compose.yml`
  - Currently if it crashes, it stays dead

- [ ] **15. Fix phpipam startup race condition**
  - Add healthcheck to `phpipam-db` so `phpipam-web` waits for the database to be truly ready:
    ```yaml
    phpipam-db:
      healthcheck:
        test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
        interval: 10s
        timeout: 5s
        retries: 5
    phpipam-web:
      depends_on:
        phpipam-db:
          condition: service_healthy
    ```

- [ ] **16. Fix timezone inconsistencies**
  - `pie_hole`: change `TZ=America/Chicago` → `TZ=${TZ}`
  - `linkding`: change `TZ=America/Chicago` → `TZ=${TZ}`
  - `phpipam-web` and `phpipam-cron`: change `TZ=America/New_York` → `TZ=${TZ}`
  - Add `TZ=` to `lightdash-db`

- [ ] **17. Pin critical container versions, control Watchtower scope**
  - Add `WATCHTOWER_LABEL_ENABLE=true` to Watchtower environment
  - Add this label to containers you don't want auto-updated overnight:
    ```yaml
    labels:
      - "com.centurylinklabs.watchtower.enable=false"
    ```
  - Apply to: `n8n`, `lightdash`, `phpipam-db`, `phpipam-web`

- [ ] **18. Move Watchtower to its own compose file**
  - Currently lives in `media_stack` — if you stop media stack, nothing gets auto-updated
  - Create `docker-projects/watchtower/docker-compose.yml`

- [ ] **19. Remove deprecated `version:` key from wireguard compose**
  - Delete the `version: "3.8"` line from `docker-projects/wireguard/docker-compose.yml`

- [ ] **20. Fix MCP filesystem server placeholder path**
  - `mcp_server/docker-compose.yml` still has `/home/your-user:/host`
  - Replace with your actual path (e.g., `C:\Users\mattd:/host`)

- [ ] **21. Add resource limits to heavy containers**
  - On Docker Desktop for Windows, use `mem_limit` and `cpus` under the service:
    ```yaml
    mem_limit: 2g
    cpus: '2.0'
    ```
  - Apply to: Plex, Lightdash headless browser (`browserless/chrome`), n8n, Glances

- [ ] **22. Materialize dbt intermediate models**
  - Add to `home_metrics_dbt/dbt_project.yml` under `intmdt:`:
    ```yaml
    intmdt:
      +materialized: table
    ```
  - Without this, intermediate models run as views on every Lightdash query

---

## 🔵 ADDITIONS — After Fixes Are Done

- [ ] **A1. Nginx Proxy Manager**
  - Consolidate 15 ports into named URLs (e.g., `plex.local`, `ha.local`)
  - Enables proper HTTPS on all services
  - Makes Tailscale access cleaner

- [ ] **A2. Verify ntfy setup / add ntfy container**
  - You mentioned using ntfy for backup notifications — no ntfy container found in your compose files
  - ntfy may be running externally (ntfy.sh cloud) or configured as a Duplicati webhook — verify it's actually working by checking if you receive a test notification
  - If you want self-hosted: add `docker-projects/ntfy/docker-compose.yml` and point Duplicati, Uptime Kuma, n8n, and Home Assistant at it

- [ ] **A3. Dedicated PostgreSQL compose for analytics pipeline**
  - Your n8n → PostgreSQL → dbt → Lightdash pipeline needs a standalone compose file
  - Should include: healthcheck, named volume, coverage in Duplicati

- [ ] **A4. Grafana + Prometheus**
  - Historical resource metrics to complement Lightdash dashboards
  - cAdvisor for per-container stats, Node Exporter for host stats
  - Fills the gap between "current state" (Glances) and "trends over time"

- [ ] **A5. Vaultwarden (self-hosted Bitwarden)**
  - Centralize the credential sprawl across `.env` files
  - Accessible via Tailscale from any device

- [ ] **A6. Actual Budget (financial tracking)**
  - Fits naturally into your analytics pipeline
  - n8n can pull transactions → Postgres → dbt → Lightdash

---

## Notes

- **Pi-hole**: Skipped — not actively used
- **ntfy**: You have healthchecks.io for backup dead-man's-switch monitoring. Verify ntfy is receiving those alerts and working as expected
- **WireGuard external access**: Confirmed non-functional due to CGNAT — Tailscale handles remote access
- **ansible-notes.md**: Skipped — Ansible not in use
