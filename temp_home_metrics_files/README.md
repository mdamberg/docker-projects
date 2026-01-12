# Home Metrics Infrastructure

PostgreSQL data warehouse and Metabase visualization platform for home infrastructure metrics collection and analysis.

## Overview

This repository contains the infrastructure layer for a personal data warehouse that consolidates metrics from:
- **Home Assistant** - Power consumption, IoT sensors
- **Plex** - Media library and watch history
- **Sonarr/Radarr** - Media automation stats
- **Pi-hole** - DNS blocking metrics

## Architecture

```
Data Sources → n8n → PostgreSQL (raw) → dbt → PostgreSQL (marts) → Metabase
                                                                   ↓
                                                            n8n (reports)
```

## Components

- **PostgreSQL 16** - Time-series data warehouse
- **Metabase** - Business intelligence and visualization
- **n8n** - Data collection orchestration (separate repo)
- **dbt** - Data transformation (separate repo)

## Quick Start

### 1. Prerequisites

- Docker and Docker Compose
- Git

### 2. Clone and Configure

```bash
git clone https://github.com/YOUR_USERNAME/home-metrics-infrastructure.git
cd home-metrics-infrastructure

# Copy environment template
cp .env.example .env

# Edit .env and set secure passwords
nano .env
```

### 3. Start Services

```bash
docker-compose up -d
```

### 4. Verify Services

- **PostgreSQL**: `localhost:5432`
  ```bash
  docker exec -it home-metrics-postgres psql -U metrics_user -d home_metrics
  ```

- **Metabase**: http://localhost:3000
  - Initial setup wizard will guide you
  - Connect to PostgreSQL using credentials from `.env`

## Database Structure

### Schemas

- **public** - Raw data tables (populated by n8n)
- **staging** - Cleaned/standardized data (dbt models)
- **intermediate** - Aggregated data (dbt models)
- **marts** - Analytics-ready tables (dbt models)

### Raw Tables

| Table | Description | Update Frequency |
|-------|-------------|------------------|
| `raw_power_consumption` | Power readings from HA sensors | Every 5 minutes |
| `raw_media_library` | Library stats from Plex/*arr | Daily |
| `raw_media_activity` | Watch history from Plex | Real-time |
| `raw_pihole_metrics` | DNS blocking statistics | Every 15 minutes |

## Data Pipeline

1. **Collection** - n8n workflows fetch data from APIs
2. **Storage** - Raw data inserted into PostgreSQL
3. **Transformation** - dbt models process raw → staging → intermediate → marts
4. **Visualization** - Metabase queries mart tables
5. **Reporting** - n8n generates and delivers reports

## Monitoring

### Check Data Freshness

```sql
SELECT * FROM v_data_freshness;
```

Shows last update time for each raw table.

### View Recent Power Data

```sql
SELECT
    friendly_name,
    state,
    unit_of_measurement,
    recorded_at
FROM raw_power_consumption
WHERE recorded_at > NOW() - INTERVAL '1 hour'
ORDER BY recorded_at DESC;
```

## Backup and Restore

### Backup

```bash
docker exec home-metrics-postgres pg_dump -U metrics_user home_metrics > backup_$(date +%Y%m%d).sql
```

### Restore

```bash
docker exec -i home-metrics-postgres psql -U metrics_user -d home_metrics < backup_20260111.sql
```

## Related Repositories

- **home-metrics-dbt** - dbt transformation models
- **docker-projects** - n8n workflows and other Docker services

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_DB` | Database name | `home_metrics` |
| `POSTGRES_USER` | Database user | `metrics_user` |
| `POSTGRES_PASSWORD` | Database password | _required_ |
| `POSTGRES_PORT` | PostgreSQL port | `5432` |
| `METABASE_PORT` | Metabase web UI port | `3000` |

### Ports

- `5432` - PostgreSQL
- `3000` - Metabase

## Troubleshooting

### Can't connect to PostgreSQL

```bash
docker logs home-metrics-postgres
```

### Metabase won't start

Check if it can reach PostgreSQL:
```bash
docker exec home-metrics-metabase nc -zv postgres 5432
```

### Check table sizes

```sql
SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Development

### Connect to Database

```bash
# From command line
docker exec -it home-metrics-postgres psql -U metrics_user -d home_metrics

# From external tool (DBeaver, pgAdmin, etc.)
Host: localhost
Port: 5432
Database: home_metrics
User: metrics_user
Password: (from .env file)
```

### Useful SQL Queries

See [docs/queries.md](docs/queries.md) for common queries and examples.

## Security Notes

- **Never commit `.env`** - Contains passwords
- **Use strong passwords** - Generate secure random passwords
- **Restrict network access** - Consider firewall rules for production
- **Regular backups** - Automate database backups
- **Update images** - Keep PostgreSQL and Metabase up to date

## License

MIT

## Contributing

This is a personal project, but feel free to fork and adapt for your own use!
