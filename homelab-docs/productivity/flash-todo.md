# Flash Todo — Task List App

A simple Flask-based todo application, custom-built and running as a Docker container.

## Access

| Item | Value |
|------|-------|
| Local URL | http://10.0.0.7:5070 |
| Remote URL (Tailscale) | http://100.82.35.70:5070 |
| Port | 5070 (mapped from container port 5000) |
| Container | `flash_todo` |

## Compose Location

```
docker-projects/flash_todo/docker-compose.yml
```

## Notes

- Built from local source (`build: .`) — not a pre-built image
- Data is persisted via a bind mount at `./data`
- Templates are served from `./templates`
- Runs on the `media_stack_default` network (joins Homarr's network for dashboard integration)
- No authentication — accessible to anyone on the local network or via Tailscale

## Management

```powershell
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\flash_todo"

docker-compose up -d        # Start (builds image if not built)
docker-compose up -d --build  # Rebuild after code changes
docker-compose down         # Stop
docker-compose logs -f      # Logs
```

> This service is not in the `start-all-services.ps1` script by default — check if it needs to be added.

## Backup

The `./data` directory contains todo items. Include `docker-projects/flash_todo/data/` in your Duplicati backup source.
