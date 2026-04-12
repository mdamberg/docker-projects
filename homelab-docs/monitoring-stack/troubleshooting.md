# Monitoring Stack — Troubleshooting

## Uptime Kuma

### Service shows as down but it's actually up

- Check if the monitored URL or port is correct
- If monitoring by hostname, confirm DNS resolution is working from inside the container:
  ```powershell
  docker exec uptime-kuma nslookup <hostname>
  ```
- If using `host.docker.internal` for local services, verify Docker Desktop has that resolved

### Can't access Uptime Kuma web UI

```powershell
# Check if container is running
docker ps | findstr uptime-kuma

# Check logs
docker logs uptime-kuma

# Verify port is bound
netstat -ano | findstr ":3001"
```

### Lost monitors / config after container restart

- Config is stored in `./uptime-kuma-data` — if this folder is missing or was deleted, config is gone
- Restore from Duplicati backup if available
- Going forward: include `uptime-kuma-data` directory in Duplicati source

### Notifications not sending

- Go to Settings → Notifications in the Uptime Kuma UI
- Test the notification channel directly
- Check that outbound connections aren't blocked by Windows Firewall

---

## Glances

### Glances web UI not loading

```powershell
docker logs glances
netstat -ano | findstr ":61208"
```

### Glances shows incomplete stats (missing processes, disks, etc.)

- On Windows, some stats require `pid: host` and `privileged: true` — confirm those are set in compose
- `sensors` plugin is intentionally disabled — this is expected

### Container crash on startup

- Most commonly caused by the sensors plugin trying to read `/sys/class/thermal` on Windows
- Confirm `GLANCES_OPT=-w --disable-plugin sensors` is set in the environment

### Docker container list not showing

- Verify Docker socket is mounted: `- /var/run/docker.sock:/var/run/docker.sock:ro`
- Confirm Docker Desktop is running and the socket is accessible

---

## General

### Restart the whole stack

```powershell
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\monitoring"
docker-compose down
docker-compose up -d
```
