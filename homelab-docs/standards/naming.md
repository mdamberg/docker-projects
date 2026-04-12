# Naming Conventions

## Directory Names

Service directories under `docker-projects/` use `snake_case`:

```
docker-projects/
├── pie_hole/
├── home_assist/
├── media_stack/
├── flash_todo/
├── home_metrics_dbt/
├── mcp_server/
...
```

## Container Names

Container names use `kebab-case` or `snake_case` matching the service name, set explicitly in compose files via `container_name`:

```yaml
container_name: uptime-kuma
container_name: pihole
container_name: flash_todo
```

Setting `container_name` explicitly makes `docker logs <name>` and `docker exec <name>` predictable.

## Docker Compose Files

All compose files are named `docker-compose.yml` (not `compose.yml`). This ensures compatibility with both `docker-compose` (v1) and `docker compose` (v2) CLI.

## .env Files

Each service has a single `.env` file in its directory. Variable names use `SCREAMING_SNAKE_CASE`:

```
N8N_BASIC_AUTH_USER=admin
TZ=America/Chicago
SETTINGS_ENCRYPTION_KEY=abc123
```

## Volume Names

Named volumes follow `service-name_purpose` format where possible:

```
linkding-data
lightdash_pgdata
minio_data
```

Bind mounts use relative paths from the compose file directory:
```yaml
- ./uptime-kuma-data:/app/data
- ./n8n_data:/home/node/.n8n
```

## Network Names

Custom networks use `service_net` or `service-network` format:

```
phpipam_net
mcp-network
home-metrics
lightdash
```

The media stack uses the default network (`media_stack_default`) which other services (like Flash Todo) join as an external network.

## Documentation Files

- Stack-level docs: `homelab-docs/<stack-name>/README.md`
- Service-level docs: `homelab-docs/<stack-name>/services/<service>.md`
- Operations docs: `homelab-docs/<stack-name>/ops/<topic>.md`
- Troubleshooting logs: `homelab-docs/troubleshooting/YYYY-MM-DD-brief-description.md`
