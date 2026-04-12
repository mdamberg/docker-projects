# MCP Server — Model Context Protocol Servers

Custom MCP (Model Context Protocol) servers that allow AI assistants to interact with the homelab.

## Compose Location

```
docker-projects/mcp_server/docker-compose.yml
```

## Services

### mcp-docker-server

Exposes Docker management capabilities as an MCP tool.

| Item | Value |
|------|-------|
| Port | 8001 |
| Container | `mcp-docker-server` |
| Build | `./mcp_servers/server1` |

- Mounts Docker socket (`/var/run/docker.sock`) to allow container inspection and management
- Named `docker-manager` via `SERVER_NAME` environment variable

### mcp-filesystem-server

Exposes filesystem access as an MCP tool.

| Item | Value |
|------|-------|
| Port | 8002 |
| Container | `mcp-filesystem-server` |
| Build | `./mcp_servers/server2` |

- Mounts a host directory to `/host` inside the container
- Named `filesystem-manager` via `SERVER_NAME` environment variable

## Notes

- These servers run **on-demand** (no `restart` policy) — they are not persistent services
- Start them manually when needed, then shut them down
- Both servers are custom-built — source code is in `mcp_servers/server1` and `mcp_servers/server2`

## Starting On-Demand

```powershell
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\mcp_server"

# Start servers
docker-compose up -d

# Stop when done
docker-compose down
```
