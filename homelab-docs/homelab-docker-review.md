# Homelab Docker Setup — Technical Review
*April 2026 | Stacks reviewed: media_stack, backups, monitoring, n8n, pie_hole, home_assist, linkding, phpipam, lightdash, flash_todo, mcp_server, wireguard, vpn*

---

## 1. Security Issues

### 1.1 Hardcoded Credentials (Critical)

**linkding/docker-compose.yml**
```
LD_SUPERUSER_PASSWORD=changeme
```
This is the literal default from the docs — it's hardcoded in the compose file, not pulled from an env var. Anyone who reads this file (which is committed to OneDrive and backed up via Duplicati) has your superuser password. Fix: use `LD_SUPERUSER_PASSWORD=${LINKDING_SUPERUSER_PASSWORD}` and set the value in a `.env` file.

**phpipam/docker-compose.yml**
```
MYSQL_ROOT_PASSWORD=phpipamadmin
MYSQL_PASSWORD=phpipampassword
IPAM_DATABASE_PASS=phpipampassword
```
All three are hardcoded plaintext, including the MariaDB root password. These values appear in three places and are identical across `phpipam-web` and `phpipam-cron`, meaning any change requires editing four fields. Move to `.env` vars.

**lightdash/docker-compose.yml**
```
PGPASSWORD: lightdash
S3_ACCESS_KEY: lightdash
S3_SECRET_KEY: lightdash123
MINIO_ROOT_USER: lightdash
MINIO_ROOT_PASSWORD: lightdash123
LIGHTDASH_SECRET: ${LIGHTDASH_SECRET:-changemeplease123456789}
```
Five hardcoded secrets plus a fallback default for `LIGHTDASH_SECRET` that is the literal string "changemeplease123456789". The `:-default` syntax means if `LIGHTDASH_SECRET` is not set in your environment at all, Lightdash will silently use the default. Since Lightdash uses this secret to sign session tokens, a known default value completely breaks session security. Remove the fallback: `LIGHTDASH_SECRET: ${LIGHTDASH_SECRET}` — this will fail loudly if not set, which is the correct behavior.

**media_stack/docker-compose.yml (Homarr)**
```
SECRET_ENCRYPTION_KEY=af6eadbe6729ee364ae16f4a99a0ce7e47ef12b9c4bda6db4001753d6f32d480
```
This encryption key for Homarr is hardcoded as a literal hex string. It's now in your OneDrive and your Duplicati backups. It should be in a `.env` file. Since it's already been committed, you should regenerate it and update.

**backups/docker-compose.yml (Duplicati)**
```
CLI_ARGS=--webservice-password=admin
```
The Duplicati web UI password is "admin" — set as a literal command-line argument. Duplicati has access to your Docker configs and your `C:\backups` directory. This needs a strong password via env var or the Duplicati settings file.

**wireguard/docker-compose.yml**
```
# Required: Bcrypt hashed password (password is: WireGuardAdmin2024!)
- PASSWORD_HASH=$$2a$$12$$WjOAt27j1vft0qusjKguW...
```
The plaintext WireGuard admin password is documented in a comment directly in the compose file. Even though the hash itself is bcrypt, anyone reading this file knows the password. Remove the comment; store only the hash.

---

### 1.2 No Password on Pi-hole Admin

**pie_hole/docker-compose.yml** — There is no `WEBPASSWORD` environment variable. Pi-hole defaults to no password when this is omitted, meaning the admin panel at port 8082 is completely open to anyone on the LAN. Add:
```yaml
- WEBPASSWORD=${PIHOLE_WEBPASSWORD}
```

---

### 1.3 Ports Exposed That Should Not Be

**flaresolverr (media_stack) — port 8191**
FlareSolverr exists solely so Prowlarr can bypass Cloudflare challenges. It should never be reachable from the host or the broader network — only Prowlarr needs to talk to it. Remove the port mapping entirely:
```yaml
# Remove this:
ports:
  - "8191:8191"
```
Since both services are in the same compose file (same default network), Prowlarr can reach `http://flaresolverr:8191` with no port mapping.

**Glances (monitoring) — port 61208**
Glances with `pid: host` and `privileged: true` exposes system-level metrics (CPU, memory, network, processes) on the LAN. There is no authentication on the Glances web server. This is information-rich for any attacker on the network. Either bind to loopback (`127.0.0.1:61208:61208`) or put it behind a reverse proxy with auth.

**MCP servers (mcp_server) — ports 8001 and 8002**
`mcp-docker-server` exposes port 8001 with access to `/var/run/docker.sock`. `mcp-filesystem-server` exposes port 8002 with filesystem access. Both are exposed on all interfaces with no auth. Anyone who can reach these ports has full Docker daemon control (server 1) or filesystem access (server 2). These should either be loopback-only or have auth added.

**WireGuard Web UI — port 51821**
The wg-easy web UI is exposed on all interfaces. The only protection is the bcrypt password. Fine for LAN-only access, but consider binding to `127.0.0.1:51821:51821` and accessing it via Tailscale when remote.

---

### 1.4 Privilege Escalation Risks

**dashdot (media_stack)**
```yaml
privileged: true
volumes:
  - /:/mnt/host:ro
```
`privileged: true` gives the container nearly full access to the host kernel. Mounting the entire root filesystem is also unnecessary — dashdot only needs `/proc`, `/sys`, and specific mount points. The combination is the highest-risk configuration in your entire setup. Switch to the minimal set:
```yaml
privileged: false
volumes:
  - /proc:/mnt/host/proc:ro
  - /sys:/mnt/host/sys:ro
  - /mnt:/mnt/host/mnt:ro
```

**Glances (monitoring)**
```yaml
privileged: true
pid: host
```
`pid: host` means Glances can see every process on the host. With `privileged: true` on top, this container can do almost anything. Use capabilities instead — Glances only needs `SYS_PTRACE` for process monitoring.

**Home Assistant (home_assist)**
```yaml
privileged: true
```
Home Assistant's docs recommend `privileged: true` only when doing USB device passthrough (Zigbee sticks, Z-Wave, etc.). If you're not using USB devices, remove this. If you are, use `devices:` to pass only the specific device instead.

**Docker socket mounts** — Four separate services mount `/var/run/docker.sock`: Watchtower, Homarr, Portainer, and mcp-docker-server. Any container with the Docker socket has root-equivalent access to the host. This is unavoidable for Portainer and Watchtower, but Homarr only needs it for container status widgets — consider whether that feature is worth the risk.

---

### 1.5 WireGuard Under CGNAT

Your ISP uses CGNAT, and WireGuard UDP port 51820 is mapped on the compose file. WireGuard connections from outside the home network to `damattberghome.duckdns.org` will silently fail — CGNAT means you don't have a public IP that forwards to your machine. Since you already use Tailscale for remote access, this WireGuard setup is likely not functional for external connections. It works fine for LAN clients. If you want external WireGuard, you'd need a VPS relay or to use the Tailscale subnet router feature instead.

---

## 2. Configuration Problems

### 2.1 Deprecated `version:` Key

**wireguard/docker-compose.yml** uses `version: "3.8"` at the top. This key has been deprecated since Docker Compose v2 (2022) and is now ignored — but its presence causes a warning on every `docker compose up`. The media_stack correctly has it commented out. Remove it from wireguard.

---

### 2.2 Missing Restart Policies

**flash_todo/docker-compose.yml** — No `restart:` policy at all. If the Flask app crashes, the container stays dead until manually restarted. Add `restart: unless-stopped`.

**mcp_server/docker-compose.yml** — Both MCP servers have no restart policy. The comment says "stdio servers run on-demand" but both have port mappings suggesting they're meant to be long-running HTTP servers, not stdio. Clarify the intent; if they're HTTP servers, add `restart: unless-stopped`.

---

### 2.3 n8n Configuration Problems

```yaml
N8N_BASIC_AUTH_ACTIVE=true
N8N_HOST=localhost
N8N_PROTOCOL=http
N8N_SECURE_COOKIE=false
```

**N8N_BASIC_AUTH_ACTIVE** — Basic auth was deprecated in n8n v1.0 (released mid-2023). If you're running a recent n8n image, this variable is silently ignored and n8n uses its own user account system instead. Verify you actually have a user account configured in n8n's own UI; you may have no effective authentication at all.

**N8N_HOST=localhost** — This means n8n generates webhook URLs like `http://localhost:5678/webhook/...`. Any webhook that an external service tries to call (e.g., a GitHub webhook, a Home Assistant notification) will have an unresolvable URL. Set this to your Tailscale machine name or local IP.

**N8N_SECURE_COOKIE=false** — Session cookies aren't marked `Secure`, meaning they'd be sent over plain HTTP. Acceptable for LAN, but if you ever put n8n behind a proper reverse proxy with HTTPS, change this.

**No network defined** — n8n is isolated on its own default bridge network. The POWER_CONSUMPTION_WORKFLOW_GUIDE.md recommends connecting to `http://homeassistant:8123`, but since n8n and Home Assistant are in different compose stacks with different default networks, this hostname won't resolve. You must use the host IP (e.g., `http://10.0.0.7:8123`) or create a shared external network.

**No PostgreSQL configured** — n8n stores all workflow data in the local SQLite file at `./n8n_data`. For your n8n → PostgreSQL → dbt → Lightdash pipeline, this means n8n itself is not using Postgres for its own internal data. This is fine, but it means n8n workflows are backed only by the bind-mounted `./n8n_data` directory, which Duplicati does not currently back up (see Section 5).

---

### 2.4 Timezone Inconsistencies

- Most services use `TZ=${TZ}` from env — good.
- `pie_hole`: `TZ=America/Chicago` — hardcoded.
- `phpipam-web`, `phpipam-cron`: `TZ=America/New_York` — hardcoded and different from Chicago.
- `linkding`: `TZ=America/Chicago` — hardcoded.
- `lightdash-db` (postgres): No TZ set.

Pick one, use `${TZ}` everywhere.

---

### 2.5 phpipam Depends_on Without Healthcheck

```yaml
phpipam-web:
  depends_on:
    - phpipam-db
```

This only waits for `phpipam-db` to *start*, not for MariaDB to be *ready*. On first run, MariaDB takes 10–30 seconds to initialize. phpipam-web will start, fail to connect, and crash. Add a healthcheck to the db and use `condition: service_healthy`:

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

---

### 2.6 MCP Filesystem Server Has Placeholder Path

```yaml
mcp-filesystem-server:
  volumes:
    - /home/your-user:/host
```

This is a template placeholder that was never filled in. The container will either fail to start (if the path doesn't exist) or mount the wrong directory. On Windows with Docker Desktop, this path needs to be a valid WSL2 or bind-mount path.

---

### 2.7 Watchtower Scope Is Too Broad

Watchtower updates every container it can see, every night at 4 AM. This includes your n8n, which is connected to an active data pipeline, and your phpipam database. A major version bump to any of these can silently break things overnight. At minimum, label critical containers to be excluded:

```yaml
# On containers you don't want auto-updated:
labels:
  - "com.centurylinklabs.watchtower.enable=false"
```

And configure Watchtower with `WATCHTOWER_LABEL_ENABLE=true` to opt-in rather than opt-out.

Also, Watchtower lives inside `media_stack`. If media_stack is down, nothing gets updated. Move Watchtower to its own compose file or to the monitoring stack.

---

### 2.8 Lightdash SITE_URL Set to Localhost

```yaml
SITE_URL: http://localhost:8090
```

This means any share links, export URLs, and OAuth redirects Lightdash generates will point to `localhost`. These won't work if you're accessing Lightdash from another device or via Tailscale. Set this to your LAN IP or Tailscale hostname: `http://100.82.35.70:8090`.

---

### 2.9 start-all-services.ps1 Uses Legacy docker-compose

The script calls `docker-compose` (with hyphen) throughout. Docker Compose v2 uses `docker compose` (space, no hyphen). Docker Desktop ships v2 by default; the hyphenated version is a legacy binary that may not be present. Update to `docker compose up -d` and `docker compose down`.

Also, the script iterates over a PowerShell hashtable (`$InfraServices.Keys`), which has no guaranteed ordering. Pi-hole (DNS) and the home-metrics network should start before services that depend on them.

---

### 2.10 stop-all-services.ps1 Missing lightdash

`stop-all-services.ps1` does not include `lightdash` in its `$InfraServices` table, but `start-all-services.ps1` does. Running "stop all" will leave Lightdash running.

---

## 3. Network Architecture

### 3.1 Overview of What Exists

| Stack | Network | How others connect |
|---|---|---|
| media_stack | `media_stack_default` (auto) | flash_todo joins this externally |
| phpipam | `phpipam_net` (explicit bridge) | Isolated — good |
| lightdash | `lightdash` (explicit) + `home-metrics` (external) | home-metrics must be pre-created |
| monitoring | default bridge (auto) | Nothing else joins |
| n8n | default bridge (auto) | Nothing else joins |
| pihole | default bridge (auto) | Nothing else joins |
| homeassistant | default bridge (auto) | Nothing else joins |
| flash_todo | joins `media_stack_default` | Shares network with all media services |
| mcp_server | `mcp-network` (explicit) | Isolated from everything else |

---

### 3.2 Cross-Stack Communication Is Broken

n8n's power consumption workflow references `http://homeassistant:8123`. n8n and Home Assistant are on different default networks (different compose projects). Container name DNS only works within the same network. This call will fail with a DNS resolution error. Solutions in order of preference:

1. Create a shared `home-automation` external network and add both services to it.
2. Use the host's LAN IP directly (`http://10.0.0.7:8123`).
3. On Docker Desktop for Windows, you can use `host.docker.internal` to reach the host, then port-forward from there.

The same problem applies to any n8n workflow that tries to reach Lightdash, phpipam, or any other service by container name.

---

### 3.3 The `home-metrics` External Network

Lightdash references `home-metrics` as an external network:
```yaml
networks:
  home-metrics:
    external: true
```

This network must be created manually before `docker compose up` for lightdash will work:
```
docker network create home-metrics
```

There's no documentation or automation for this. If someone does a fresh deploy or the network gets deleted, Lightdash will fail to start with a cryptic "network not found" error. Add this to the startup script or document it.

---

### 3.4 All Ports Bind to 0.0.0.0

Every exposed port binds to all interfaces by default. While CGNAT prevents external access, anything on your LAN can reach every service. For services that should only be accessed locally (Glances metrics, FlareSolverr, Duplicati config), bind to loopback:

```yaml
ports:
  - "127.0.0.1:61208:61208"  # Only accessible from the host itself
```

---

### 3.5 flash_todo on media_stack Network

flash_todo explicitly joins `media_stack_default`. This means the Flash app can directly talk to Plex, Sonarr, Radarr, qBittorrent, and every other media service by container name — and vice versa. This is likely unintentional. Flash Todo is a simple Flask app and doesn't need media stack access. Give it its own network or remove the network config so it uses its own isolated default.

---

## 4. Resilience / Reliability

### 4.1 Missing Restart Policies

- `flash_todo` — no restart policy, dies and stays dead.
- `mcp-docker-server` and `mcp-filesystem-server` — no restart policy.
- `lightdash-minio-init` — init container, correctly has no restart policy (runs once, exits 0).

### 4.2 Startup Order Is Non-Deterministic

`start-all-services.ps1` iterates over `$InfraServices.Keys`. PowerShell hashtables don't have a defined key order. Pi-hole (DNS) might start last even though everything else depends on working DNS. Use an ordered array for startup:

```powershell
$StartOrder = @('pihole', 'homeassistant', 'monitoring', 'wireguard', 'n8n', 'backups', 'phpipam', 'mediastack', 'linkding', 'flash', 'lightdash')
```

### 4.3 Watchtower Is a Single Point of Failure for Updates

As mentioned, Watchtower lives in media_stack. If you stop media_stack for maintenance, you lose automatic updates for all other stacks. Move it to a standalone compose file.

### 4.4 phpipam-web Can Fail on First Boot

Without a healthcheck-based depends_on (see 2.5), phpipam-web races against MariaDB initialization and often loses on first boot, requiring a manual `docker compose restart phpipam-web`.

### 4.5 n8n Has No Crash Recovery for Active Workflows

n8n stores execution state in its SQLite database (`./n8n_data`). If n8n crashes mid-workflow (e.g., during a power data collection job), workflows may fail silently. Since you have a data pipeline, consider enabling n8n's execution retry settings in the UI, or migrating n8n's own database to PostgreSQL for better crash recovery.

---

## 5. Storage / Volumes

### 5.1 What Is and Isn't Persisted

| Service | Storage Type | Location | Backed Up? |
|---|---|---|---|
| Plex config | Bind mount | `C:/media/config/plex` | ❌ No |
| Radarr/Sonarr/Prowlarr configs | Bind mounts | `C:/media/config/*` | ❌ No |
| qBittorrent config | Bind mount | `C:/media/config/qbittorrent` | ❌ No |
| Homarr config | Bind mount | `C:/media/config/homarr` | ❌ No |
| n8n workflows | Bind mount | `./n8n_data` | ❌ No |
| Pi-hole config | Bind mount | `./etc-pihole` | ❌ No |
| Home Assistant config | Bind mount | `./configuration/config` | ❌ No |
| Uptime Kuma data | Bind mount | `./uptime-kuma-data` | ❌ No |
| phpipam DB | Bind mount | `./mysql_data` | ❌ No |
| flash_todo data | Bind mount | `./data` | ❌ No |
| linkding bookmarks | Named volume | `linkding-data` | ❌ No |
| Lightdash DB | Named volume | `lightdash_pgdata` | ❌ No |
| MinIO data | Named volume | `minio_data` | ❌ No |
| Docker configs | Bind mount | `C:\docker-projects` | ✅ Duplicati |

**Duplicati only backs up your compose configuration files, not the actual data volumes.** This means if your machine dies and you restore from backup, you'll have all your compose files but empty databases, no Plex library metadata, no n8n workflows, no Home Assistant config, no Pi-hole blocklists. Add the data directories to Duplicati's source paths.

### 5.2 Named Volumes vs Bind Mounts

There's an inconsistency in approach:
- Media stack services all use Windows bind mounts (`C:/media/config/...`) — easy to browse in Explorer, but Docker Desktop performance on Windows bind mounts is noticeably slower than named volumes.
- Lightdash, linkding use named volumes — better performance, but harder to inspect manually.

Neither is wrong, but the inconsistency makes backup configuration harder. Consider either fully normalizing to bind mounts (easy to include in Duplicati) or using named volumes with periodic `docker run --rm -v volume:/data alpine tar` snapshots.

### 5.3 Backups Source Path May Be Wrong

```yaml
volumes:
  - C:\docker-projects:/source/docker-configs:ro
  - C:\backups:/backups
```

The `C:\docker-projects` path points to the root of your Docker projects on C:\, but your actual files are in `C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects`. Verify the Duplicati source actually captures your real files, not an empty or different directory.

---

## 6. Performance and Resource Management

### 6.1 No Resource Limits on Any Container

Not a single container in any of your 13 compose files has CPU or memory limits. On Docker Desktop for Windows, all containers share the WSL2 VM's resources. The most likely culprits to cause resource starvation:

- **Plex** during transcoding — can peg CPU at 100% indefinitely.
- **browserless/chrome** (Lightdash headless browser) — Chrome is notorious for memory leaks; no limit means it can consume all available RAM.
- **Glances** with `pid: host` — polling all processes on an interval adds CPU load.
- **n8n** during complex workflow runs — JavaScript execution can be CPU-intensive.

On Docker Desktop for Windows, use `mem_limit` and `cpus` directly under the service (not `deploy.resources` which requires Swarm):
```yaml
mem_limit: 2g
cpus: '2.0'
```

### 6.2 All Images Use :latest Tags

Every service (except `uptime-kuma:1` and `postgres:15-alpine`) uses `:latest`. Combined with Watchtower updating nightly, this means breaking changes can appear automatically. Services most at risk:

- `n8nio/n8n:latest` — n8n has had breaking auth changes across major versions.
- `lightdash/lightdash:latest` — Lightdash has aggressive version progression.
- `browserless/chrome:latest` — Chrome images can be very large; an update could cause a multi-GB pull at 4 AM.
- `linuxserver/plex:latest` — Plex major versions sometimes require library re-scans.

Recommend pinning to specific version tags for your pipeline-critical services (n8n, lightdash, phpipam) and continuing to use latest only for purely stateless utilities.

### 6.3 dbt Intermediate Layer Materialization

In `home_metrics_dbt/dbt_project.yml`, the `intmdt` layer has no `+materialized` setting, meaning it inherits the project default (likely view). If your intermediate models are computationally expensive and run on every Lightdash query, consider materializing them as tables. The `staging` layer is correctly views; marts are tables. The intermediate layer should probably be tables too.

---

## 7. Specific Actionable Improvements

**Priority 1 — Fix Immediately (Security)**

1. **linkding**: Change `LD_SUPERUSER_PASSWORD=changeme` to `LD_SUPERUSER_PASSWORD=${LINKDING_PASS}` and set a real password in `.env`.
2. **phpipam**: Move all three passwords to `.env` vars. Add a healthcheck to `phpipam-db`.
3. **lightdash**: Remove the `:-changemeplease123456789` fallback from `LIGHTDASH_SECRET`. Move `PGPASSWORD`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `MINIO_ROOT_PASSWORD` to `.env`.
4. **pihole**: Add `WEBPASSWORD=${PIHOLE_WEBPASSWORD}` to the environment block.
5. **backups/duplicati**: Change `CLI_ARGS=--webservice-password=admin` to `CLI_ARGS=--webservice-password=${DUPLICATI_WEBPASS}`.
6. **media_stack/homarr**: Move `SECRET_ENCRYPTION_KEY` to `.env`. Generate a new key since the current one is exposed.
7. **wireguard**: Delete the comment revealing the plaintext password.

**Priority 2 — Fix Soon (Configuration & Reliability)**

8. **Remove FlareSolverr port mapping**: Delete `- "8191:8191"`. Prowlarr reaches it on the internal network.
9. **flash_todo**: Add `restart: unless-stopped`. Remove it from `media_stack_default` network.
10. **n8n**: Verify auth is actually active. Set `N8N_HOST` to `10.0.0.7`. Create a proper `.env` file for all n8n variables.
11. **Update start-all-services.ps1**: Change `docker-compose` → `docker compose` (v2). Fix startup order. Add `lightdash` to `stop-all-services.ps1`. Add `docker network create home-metrics` call.
12. **phpipam healthcheck**: Add `healthcheck` to `phpipam-db` and change `depends_on` to `condition: service_healthy`.
13. **Timezone consistency**: Replace all hardcoded `TZ=America/Chicago` and `TZ=America/New_York` with `TZ=${TZ}`.
14. **wireguard**: Remove deprecated `version: "3.8"` line.
15. **Lightdash SITE_URL**: Change from `localhost` to `http://100.82.35.70:8090`.

**Priority 3 — Medium Term (Backup & Monitoring)**

16. **Expand Duplicati backup sources** to include at minimum:
    - `C:/media/config` (all *arr configs, Plex metadata)
    - `./n8n_data` (n8n workflows and credentials)
    - `./configuration/config` (Home Assistant config)
    - `./etc-pihole` (Pi-hole blocklists, custom DNS)
    - phpipam's `./mysql_data` directory
    - linkding and lightdash named volumes (via volume backup scripts)
17. **Verify Duplicati source path**: Confirm `C:\docker-projects` in Duplicati actually matches your real path `C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects`.
18. **Watchtower scope control**: Add `WATCHTOWER_LABEL_ENABLE=true` and label critical containers with `com.centurylinklabs.watchtower.enable=false` — especially n8n, phpipam-db, lightdash-db.
19. **Move Watchtower to its own compose file** so it runs independently of media_stack.
20. **dashdot**: Replace `privileged: true` and `/:mnt/host:ro` with specific mounts for `/proc`, `/sys`, and your actual mount points.
21. **Add resource limits** to at minimum: plex, browserless/chrome, n8n, and glances.
22. **dbt intermediate layer**: Add `+materialized: table` to the `intmdt:` block in `dbt_project.yml`.
23. **MCP filesystem server**: Replace `/home/your-user:/host` with your actual path.

---

## 8. Beneficial Additions

**Nginx Proxy Manager or Traefik**
You have 15+ services spread across 12 different ports. A reverse proxy would consolidate these behind a single point, enable proper HTTPS, and make Tailscale access much cleaner (one hostname per service rather than one port per service). Nginx Proxy Manager is the easier option; Traefik integrates more elegantly with Docker labels.

**Vaultwarden (Bitwarden-compatible)**
You have credentials scattered across `.env` files and hardcoded values. A self-hosted password manager reachable via Tailscale centralizes secrets management. Lightweight — runs in a single container with SQLite.

**Dedicated PostgreSQL Compose**
Your analytics pipeline (n8n → PostgreSQL → dbt → Lightdash) has no shared Postgres compose file visible. If n8n is writing data to Postgres, that database needs its own compose file with healthchecks, a named volume, and Duplicati coverage.

**Authentik or Authelia (SSO)**
With 10+ web UIs, you're managing separate credentials for each. Authentik provides SSO via OIDC/SAML and a forward-auth middleware that can protect services with no built-in auth (Glances, FlareSolverr, Duplicati). Pairs well with Traefik.

**ntfy (Push Notifications)**
A self-hosted push notification server. Lets n8n, Uptime Kuma, Duplicati, and Home Assistant all send push notifications to a single app on your phone. Lightweight single container.

**Grafana + Prometheus**
You have Glances and Uptime Kuma but no historical metrics. Adding Prometheus (scraping Glances, cAdvisor for per-container stats) with Grafana would give you historical CPU/RAM/disk trends, per-container resource usage over time, and alerts when containers exceed thresholds. Complements your existing Lightdash analytics pipeline.

**Actual Budget (Financial Tracking)**
Given you're already running a data pipeline with Lightdash for analytics, a self-hosted budgeting tool like Actual Budget would let you add financial data to the same pipeline — n8n can pull transactions, dbt can model them, Lightdash can visualize alongside home metrics.

---

## Summary Table

| Area | Severity | Count of Issues |
|---|---|---|
| Hardcoded credentials | 🔴 Critical | 7 |
| Missing/weak auth | 🔴 Critical | 2 (pihole, duplicati) |
| Privilege escalation | 🟠 High | 4 services |
| Exposed unnecessary ports | 🟠 High | 3 (flaresolverr, glances, mcp) |
| Backup coverage gaps | 🟠 High | 10+ data directories |
| Network communication broken | 🟠 High | n8n ↔ homeassistant |
| Missing restart policies | 🟡 Medium | 3 services |
| Deprecated config | 🟡 Medium | version key, docker-compose CLI |
| No resource limits | 🟡 Medium | All 13 stacks |
| No healthchecks | 🟡 Medium | Most services |
| Timezone inconsistencies | 🟢 Low | 3 stacks |
| Script service list sync | 🟢 Low | lightdash missing from stop script |
