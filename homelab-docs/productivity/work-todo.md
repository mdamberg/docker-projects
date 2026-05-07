# Work Todo — Task List App

A work-focused fork of the Flash Todo app, built for tracking professional tasks with work-relevant categories and per-task notes.

## Access

| Item | Value |
|------|-------|
| Local URL | http://10.0.0.7:5071 |
| Remote URL (Tailscale) | http://100.82.35.70:5071 |
| Port | 5071 (mapped from container port 5000) |
| Container | `work_todo` |

## Compose Location

```
docker-projects/work_todo/docker-compose.yml
```

## Features

- **Categories**: Projects, Planning, Meetings/Follow-ups, Documentation, Research, General
- **Priorities**: High / Medium / Low (changeable inline)
- **Notes**: Per-task notes field — click 📝 on any task to expand
- **Sort views**: By category (default) or by urgency
- **Completed tasks sink**: Done items drop to the bottom of each group automatically
- **Persistent metrics**: Completion stats survive task deletion
- **REST API**: Full CRUD at `/api/todos` (supports `notes` field)

## Management

```powershell
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\work_todo"

docker compose up -d          # Start (builds image if not built)
docker compose up -d --build  # Rebuild after code changes
docker compose down           # Stop
docker compose logs -f        # Logs
```

Also startable via `start-all-services.ps1 -Services "work"`.

## Notes

- Built from local source (`build: .`) — not a pre-built image
- Data persisted via bind mount at `./data` (todos.json + stats.json)
- Templates are served from `./templates` (live-reload on template changes without rebuild)
- Runs on the `media_stack_default` network for Homarr dashboard integration
- No authentication — acceptable for personal homelab/Tailscale use; do not expose publicly

## Backup

Include `docker-projects/work_todo/data/` in your Duplicati backup source.
