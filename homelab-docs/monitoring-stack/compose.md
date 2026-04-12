# Monitoring Stack — Compose Reference

Location: `docker-projects/monitoring/docker-compose.yml`

## Services

### uptime-kuma

```yaml
uptime-kuma:
  image: louislam/uptime-kuma:1
  container_name: uptime-kuma
  volumes:
    - ./uptime-kuma-data:/app/data
  ports:
    - 3001:3001
  restart: unless-stopped
```

**Notes:**
- Pinned to major version `1` (not `latest`) for stability
- Data volume at `./uptime-kuma-data` — back this up to preserve monitor configs and history

---

### glances

```yaml
glances:
  image: nicolargo/glances:latest
  container_name: glances
  restart: unless-stopped
  ports:
    - "61208:61208"
  environment:
    - GLANCES_OPT=-w --disable-plugin sensors
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
  pid: host
  privileged: true
```

**Notes:**
- `-w` flag enables web server mode (accessible via browser)
- `--disable-plugin sensors` avoids crashes on Windows where `/sys/class/thermal` doesn't exist
- `pid: host` and `privileged: true` are required for full system visibility
- Docker socket is mounted read-only — Glances reads container stats but cannot modify them

## Networks

No custom network — both services use the default bridge. They don't communicate with each other.

## Volumes

- `uptime-kuma-data` — persists monitors, alert configs, and history. Keep this backed up.

## Updating

```powershell
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\monitoring"
docker-compose pull
docker-compose up -d
```
