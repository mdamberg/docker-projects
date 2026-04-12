# Home Assistant

Home automation platform running as a Docker container.

## Access

| Item | Value |
|------|-------|
| Local URL | http://10.0.0.7:8123 |
| Remote URL (Tailscale) | http://100.82.35.70:8123 |
| Port | 8123 |
| Container | `homeassistant` |
| Image | `ghcr.io/home-assistant/home-assistant:stable` |

## Compose Location

```
docker-projects/home_assist/docker-compose.yml
```

## Configuration

Configuration is persisted at `docker-projects/home_assist/configuration/config/`. This includes:

- `configuration.yaml` — main HA config
- `automations.yaml` — automations
- `scripts.yaml` — scripts
- Custom components (in `custom_components/`)
- HACS integrations

The config directory is backed up via Duplicati as part of the Docker projects backup.

## Role in the Homelab

Home Assistant is a data source for the analytics pipeline:

- **Power sensors** are read by n8n every 5 minutes and stored in PostgreSQL (`raw_power_consumption`)
- Power data feeds through dbt transformations into the `fact_power_consumption` mart
- See [Analytics Stack](../analytics-stack/README.md) and [n8n Workflows](../analytics-stack/services/n8n.md) for details

## Management

```powershell
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\home_assist"

docker-compose up -d     # Start
docker-compose down      # Stop
docker-compose logs -f   # View logs
```

Or via scripts:
```powershell
.\start-all-services.ps1 -Services "homeassistant"
```

## Updating

Home Assistant updates frequently. To update:

```powershell
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\home_assist"
docker-compose pull
docker-compose up -d
```

Check the [HA release notes](https://www.home-assistant.io/blog/) before updating — breaking changes do occur.

## Backup & Restore

The config directory (`./configuration/config`) is included in Duplicati backups. To restore:

1. Restore `docker-projects/home_assist/` from Duplicati
2. Run `docker-compose up -d`

For a full restore test, verify automations and integrations are still connected after restoring.

## Notes

- Runs with `privileged: true` to allow device access (required for some integrations)
- Timezone is set via `.env` file (`TZ` variable)
- HACS (Home Assistant Community Store) is installed for additional integrations
- See `MEDIA_DASHBOARD_SETUP.md` in the project folder for the media dashboard configuration

## Sections to Fill In

- [ ] List of active integrations
- [ ] List of key automations
- [ ] Devices connected (smart plugs with power monitoring, etc.)
- [ ] Notes on any integrations that required special setup
