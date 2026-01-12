# Analytics Stack Overview

Personal data warehouse for home infrastructure metrics collection, transformation, and visualization.

## Purpose

Consolidate and analyze metrics from across the homelab:
- **Power consumption** from Home Assistant sensors
- **Media usage** from Plex, Sonarr, Radarr
- **DNS blocking** stats from Pi-hole
- **System health** metrics from various sources

## Architecture

```
┌─────────────────┐
│  Data Sources   │
│  (HA, Plex,     │
│   Pi-hole, etc) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│      n8n        │ ← Orchestration & data collection
│   (Workflows)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   PostgreSQL    │ ← Raw data storage
│  (Data Warehouse)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│      dbt        │ ← Transformations
│ (Staging → Marts)│
└────────┬────────┘
         │
         ├────────────────┐
         ▼                ▼
┌─────────────┐   ┌──────────────┐
│  Metabase   │   │     n8n      │
│ (Dashboards)│   │  (Reporting) │
└─────────────┘   └──────────────┘
```

## Components

### Infrastructure Layer
- **PostgreSQL 16** - Time-series data warehouse with raw, staging, intermediate, and marts schemas
- **Metabase** - BI tool for ad-hoc queries and dashboard building

### Orchestration Layer
- **n8n** - Data collection workflows, API calls, and automated reporting

### Transformation Layer
- **dbt** - SQL-based transformations from raw → staging → intermediate → marts
- **Repo**: [home-metrics-dbt](https://github.com/YOUR_USERNAME/home-metrics-dbt)

## Repository Structure

This stack spans **three repositories**:

1. **docker-projects** (this repo)
   - n8n workflows for data collection
   - Located: `docker-projects/n8n/`

2. **home-metrics-infrastructure** (private)
   - PostgreSQL + Metabase docker-compose
   - Database initialization scripts
   - Located: separate GitHub repo

3. **home-metrics-dbt** (public/private)
   - dbt transformation models
   - SQL analytics logic
   - Located: separate GitHub repo

## Data Pipeline Flow

1. **Collection** (n8n)
   - Scheduled workflows fetch data from APIs
   - Every 5 min (power), daily (media), 15 min (pihole)

2. **Storage** (PostgreSQL raw tables)
   - `raw_power_consumption`
   - `raw_media_library`
   - `raw_media_activity`
   - `raw_pihole_metrics`
   - `raw_system_health`

3. **Transformation** (dbt)
   - Staging: Clean and standardize
   - Intermediate: Aggregate and enrich
   - Marts: Analytics-ready tables

4. **Visualization** (Metabase)
   - Query marts for dashboards
   - Ad-hoc SQL analysis

5. **Reporting** (n8n)
   - Weekly/monthly summaries
   - Send to Discord via Notifiarr

## Database Schema Structure

```
public schema
├── raw_power_consumption     (n8n inserts)
├── raw_media_library         (n8n inserts)
├── raw_media_activity        (n8n inserts)
├── raw_pihole_metrics        (n8n inserts)
└── raw_system_health         (n8n inserts)

staging schema
├── stg_power_consumption     (dbt model)
├── stg_media_library         (dbt model)
└── ...

intermediate schema
├── int_power_hourly          (dbt model)
├── int_power_daily           (dbt model)
└── ...

marts schema
├── fact_power_consumption    (dbt model)
├── fact_media_usage          (dbt model)
└── summary_home_metrics      (dbt model)
```

## Key Features

- **Time-series analysis** - Track trends over time
- **Cost estimation** - Power consumption × electricity rates
- **Media insights** - Watch patterns, library growth
- **Network monitoring** - DNS blocking effectiveness
- **Automated reports** - Weekly summaries via Discord
- **SQL-based** - Leverages existing dbt/SQL skills from work

## Service URLs

- **PostgreSQL**: `localhost:5432`
- **Metabase**: http://localhost:3000
- **n8n**: http://localhost:5678

## Quick Start

See [Setup Guide](ops/setup.md) for complete installation instructions.

## Related Documentation

- [PostgreSQL Service](services/postgresql.md)
- [Metabase Service](services/metabase.md)
- [n8n Workflows](services/n8n.md)
- [Setup & Deployment](ops/setup.md)
- [Backup & Restore](ops/backup-restore.md)
- [Troubleshooting](ops/troubleshooting.md)

## Monitoring

Check data freshness:
```sql
SELECT * FROM v_data_freshness;
```

View recent power data:
```sql
SELECT friendly_name, state, recorded_at
FROM raw_power_consumption
WHERE recorded_at > NOW() - INTERVAL '1 hour'
ORDER BY recorded_at DESC;
```

## Security Considerations

- PostgreSQL exposed only on localhost
- Metabase requires authentication
- Secrets stored in `.env` (gitignored)
- Regular automated backups
- Separate metabase database for app state

## Future Enhancements

- [ ] Add real-time Grafana dashboards
- [ ] Implement data retention policies
- [ ] Add more data sources (weather, ISP speeds)
- [ ] Machine learning for anomaly detection
- [ ] Cost optimization recommendations
