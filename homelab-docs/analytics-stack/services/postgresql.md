# PostgreSQL Service

Time-series data warehouse for home infrastructure metrics.

## Overview

- **Image**: `postgres:16-alpine`
- **Container**: `home-metrics-postgres`
- **Port**: `5432`
- **Database**: `home_metrics`
- **User**: `metrics_user`

## Configuration

### Environment Variables
```bash
POSTGRES_DB=home_metrics
POSTGRES_USER=metrics_user
POSTGRES_PASSWORD=<secure_password>
PGDATA=/var/lib/postgresql/data/pgdata
```

### Volumes
- `./postgres/data:/var/lib/postgresql/data` - Database files
- `./postgres/init:/docker-entrypoint-initdb.d:ro` - Init scripts

### Networks
- `home-metrics` - Internal bridge network

## Database Structure

### Schemas
1. **public** - Raw data tables (populated by n8n)
2. **staging** - Cleaned data (dbt models)
3. **intermediate** - Aggregations (dbt models)
4. **marts** - Analytics-ready tables (dbt models)

### Raw Tables
| Table | Description | Update Frequency |
|-------|-------------|------------------|
| `raw_power_consumption` | HA power sensor readings | Every 5 minutes |
| `raw_media_library` | Plex/Sonarr/Radarr library stats | Daily |
| `raw_media_activity` | Plex watch history | Real-time |
| `raw_pihole_metrics` | DNS blocking statistics | Every 15 minutes |
| `raw_system_health` | System metrics | Configurable |

### Views
- `v_data_freshness` - Monitors last update time for each raw table

## Common Operations

### Connect to Database
```bash
# From host
psql -h localhost -p 5432 -U metrics_user -d home_metrics

# From container
docker exec -it home-metrics-postgres psql -U metrics_user -d home_metrics
```

### List Schemas
```sql
\dn
```

### List Tables
```sql
-- All tables
\dt

-- Specific schema
\dt staging.*
\dt marts.*
```

### Check Data Freshness
```sql
SELECT * FROM v_data_freshness;
```

### View Recent Power Data
```sql
SELECT
    entity_id,
    friendly_name,
    state,
    unit_of_measurement,
    recorded_at
FROM raw_power_consumption
WHERE recorded_at > NOW() - INTERVAL '1 hour'
ORDER BY recorded_at DESC
LIMIT 20;
```

### Count Records by Table
```sql
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    (SELECT COUNT(*) FROM pg_tables t WHERE t.schemaname = p.schemaname AND t.tablename = p.tablename) AS row_count
FROM pg_tables p
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Backup

### Manual Backup
```bash
docker exec home-metrics-postgres pg_dump -U metrics_user home_metrics > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Automated Backup (Cron)
```bash
# Add to crontab
0 2 * * * docker exec home-metrics-postgres pg_dump -U metrics_user home_metrics | gzip > ~/backups/home_metrics_$(date +\%Y\%m\%d).sql.gz
```

## Restore

```bash
# From SQL dump
docker exec -i home-metrics-postgres psql -U metrics_user -d home_metrics < backup.sql

# From gzipped dump
gunzip -c backup.sql.gz | docker exec -i home-metrics-postgres psql -U metrics_user -d home_metrics
```

## Performance Tuning

### Check Index Usage
```sql
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

### Table Sizes
```sql
SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS index_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Vacuum Statistics
```sql
SELECT
    schemaname,
    tablename,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables;
```

## Monitoring

### Check Connection Count
```sql
SELECT COUNT(*) FROM pg_stat_activity;
```

### Active Queries
```sql
SELECT
    pid,
    usename,
    application_name,
    state,
    query,
    query_start
FROM pg_stat_activity
WHERE state != 'idle';
```

### Database Size
```sql
SELECT pg_size_pretty(pg_database_size('home_metrics'));
```

## Maintenance

### Manual Vacuum
```sql
VACUUM ANALYZE;
```

### Reindex
```sql
REINDEX DATABASE home_metrics;
```

### Update Statistics
```sql
ANALYZE;
```

## Security

### Change Password
```sql
ALTER USER metrics_user WITH PASSWORD 'new_secure_password';
```

### List Users and Permissions
```sql
\du
```

### Grant Permissions to New User
```sql
CREATE USER readonly_user WITH PASSWORD 'password';
GRANT CONNECT ON DATABASE home_metrics TO readonly_user;
GRANT USAGE ON SCHEMA public, staging, intermediate, marts TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public, staging, intermediate, marts TO readonly_user;
```

## Troubleshooting

### Can't Connect
```bash
# Check if container is running
docker ps | grep postgres

# Check logs
docker logs home-metrics-postgres

# Test connection from host
docker exec home-metrics-postgres pg_isready -U metrics_user
```

### Out of Disk Space
```bash
# Check disk usage
df -h

# Check database size
docker exec home-metrics-postgres psql -U metrics_user -d home_metrics -c "SELECT pg_size_pretty(pg_database_size('home_metrics'));"

# Vacuum to reclaim space
docker exec home-metrics-postgres psql -U metrics_user -d home_metrics -c "VACUUM FULL;"
```

### Slow Queries
```sql
-- Enable query logging
ALTER DATABASE home_metrics SET log_min_duration_statement = 1000; -- Log queries > 1 second

-- View slow queries
SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;
```

## Configuration Files

Located in container at `/var/lib/postgresql/data/postgresql.conf`

To modify:
```bash
docker exec -it home-metrics-postgres vi /var/lib/postgresql/data/postgresql.conf
docker restart home-metrics-postgres
```

## Logs

```bash
# View logs
docker logs home-metrics-postgres

# Follow logs
docker logs -f home-metrics-postgres

# Last 100 lines
docker logs --tail 100 home-metrics-postgres
```

## Related Documentation

- [Metabase Service](metabase.md)
- [n8n Workflows](n8n.md)
- [Backup & Restore](../ops/backup-restore.md)
- [Troubleshooting](../ops/troubleshooting.md)
