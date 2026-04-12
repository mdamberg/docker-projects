# Lightdash — BI Tool (dbt-native)

Lightdash is a BI tool that reads directly from dbt project metrics, making it an alternative to Metabase for exploring the home metrics data.

## Access

| Item | Value |
|------|-------|
| Local URL | http://10.0.0.7:8090 |
| Remote URL (Tailscale) | http://100.82.35.70:8090 |
| Port | 8090 (mapped from container port 8080) |
| Container | `lightdash` |
| Image | `lightdash/lightdash:latest` |

## Compose Location

```
docker-projects/lightdash/docker-compose.yml
```

## Services

Four containers make up the Lightdash stack:

| Container | Role |
|-----------|------|
| `lightdash` | Main application |
| `lightdash-db` | PostgreSQL for Lightdash's own app state |
| `lightdash-browser` | Headless Chrome for PDF/image exports |
| `lightdash-minio` | MinIO S3-compatible storage for query results |

## Connection to dbt

Lightdash reads the `home_metrics_dbt` project directly:

```yaml
volumes:
  - ../home_metrics_dbt:/usr/app/dbt:ro
```

This means it picks up dbt model definitions, metrics, and descriptions automatically — no manual configuration per table.

## Networks

Lightdash connects to the `home-metrics` external network to reach the PostgreSQL data warehouse. Make sure that network exists before starting:

```powershell
docker network create home-metrics
```

## Important Configuration Notes

- `LIGHTDASH_SECRET` defaults to `changemeplease123456789` — set a real value in `.env`
- MinIO credentials (`lightdash`/`lightdash123`) are internal-only defaults — fine for local use but change if exposed
- The headless browser (`browserless/chrome`) is used only for exports; it's optional

## Management

```powershell
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\lightdash"

docker-compose up -d     # Start (waits for db and minio health checks)
docker-compose down      # Stop
docker-compose logs -f lightdash  # App logs
```

## Relationship to Metabase

Both Metabase and Lightdash visualize the same PostgreSQL data warehouse. Lightdash is dbt-native (reads metrics from dbt models directly), while Metabase is more flexible for ad-hoc SQL. Use whichever fits the task.

## Backup

- `lightdash_pgdata` volume: Lightdash dashboards and app state
- `minio_data` volume: Cached query results

These are Docker named volumes. Verify they are included in backups or export dashboards manually.
