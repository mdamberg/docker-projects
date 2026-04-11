# Home Metrics Quick Reference

## File Locations

| What | Where |
|------|-------|
| Raw table definitions | `temp_home_metrics_files/postgres/init/02-create-raw-tables.sql` |
| n8n workflows | `docker-projects/n8n/` |
| dbt project | `docker-projects/home_metrics_dbt/` |
| dbt sources | `docker-projects/home_metrics_dbt/models/staging/sources.yml` |
| dbt profiles | `~/.dbt/profiles.yml` |

## Tables

| Raw Table | Staging Model | Source |
|-----------|---------------|--------|
| raw_media_library | stg_media_library | Plex, Sonarr, Radarr, Prowlarr |
| raw_media_activity | stg_media_activity | Plex watch history |
| raw_system_health | stg_system_health | Windows Exporter |
| raw_pihole_metrics | stg_pihole_metrics | Pi-hole |
| raw_power_consumption | stg_power_consumption | Home Assistant |
| raw_n8n_alerts | stg_n8n_alerts | n8n (self-monitoring) |
| raw_n8n_workflow_runs | stg_n8n_workflow_runs | n8n (execution logs) |

## n8n Workflows

| Workflow | Schedule | Folder |
|----------|----------|--------|
| Media Library Collection | 6 hours | plex_media_workflows/ |
| System Health Metrics | 15 minutes | system_health_workflows/ |
| Workflow Health Monitor | 1 hour | workflow_alerts/ |
| Global Error Catcher | On error | workflow_alerts/ |

## Common Commands

### dbt
```bash
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\home_metrics_dbt"

dbt debug              # Test connection
dbt deps               # Install packages
dbt build              # Run + test all
dbt build --select stg_media_library  # Build specific model
dbt docs generate && dbt docs serve   # Generate and view docs
```

### PostgreSQL
```bash
# Connect via docker
docker exec -it home-metrics-postgres psql -U metrics_user -d home_metrics

# Quick queries
SELECT * FROM v_data_freshness;                    # Check data freshness
SELECT * FROM raw_n8n_alerts ORDER BY triggered_at DESC LIMIT 10;  # Recent alerts
```

### Useful SQL
```sql
-- Data freshness
SELECT * FROM v_data_freshness;

-- Recent alerts
SELECT * FROM raw_n8n_alerts WHERE resolved_at IS NULL;

-- System health latest
SELECT * FROM raw_system_health ORDER BY recorded_at DESC LIMIT 1;

-- Media library summary
SELECT source, SUM(item_count) as items, SUM(total_size_bytes)/1e9 as gb
FROM raw_media_library
WHERE recorded_at > NOW() - INTERVAL '1 day'
GROUP BY source;
```

## Ports

| Service | Port |
|---------|------|
| PostgreSQL | 5432 |
| n8n | 5678 |
| Metabase | 3000 |
| Windows Exporter | 9182 |
| Tautulli | 8181 |
| Sonarr | 8989 |
| Radarr | 7878 |
| Prowlarr | 9696 |

## Alert Types

| alert_type | severity | Source |
|------------|----------|--------|
| workflow_failure | error | Global Error Catcher |
| stale_data | warning | Workflow Health Monitor |
| no_data | warning | Workflow Health Monitor |

## Adding New Data Source Checklist

- [ ] Create n8n workflow to collect data
- [ ] Add raw table to `02-create-raw-tables.sql`
- [ ] Create table in database (ALTER or recreate)
- [ ] Add source to `sources.yml`
- [ ] Create `stg_*.sql` model
- [ ] Create `stg_*.yml` with tests
- [ ] Add to Workflow Health Monitor (if needed)
- [ ] Test: `dbt build --select stg_*`

## Documentation

| Doc | Path |
|-----|------|
| Architecture Overview | `homelab-docs/home_metrics_dbt/data-pipeline-architecture.md` |
| n8n Workflows | `homelab-docs/home_metrics_dbt/workflows/n8n-workflows.md` |
| dbt Models | `homelab-docs/home_metrics_dbt/models/dbt-models.md` |
| Troubleshooting | `homelab-docs/home_metrics_dbt/troubleshooting.md` |
