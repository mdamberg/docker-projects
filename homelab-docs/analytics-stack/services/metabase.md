# Metabase Service

Business intelligence and data visualization platform.

## Overview

- **Image**: `metabase/metabase:latest`
- **Container**: `home-metrics-metabase`
- **Port**: `3000`
- **URL**: http://localhost:3000

## Configuration

### Environment Variables
```bash
MB_DB_TYPE=postgres
MB_DB_DBNAME=metabase
MB_DB_PORT=5432
MB_DB_USER=metrics_user
MB_DB_PASS=<password>
MB_DB_HOST=postgres
```

### Storage
- **Application Database**: PostgreSQL `metabase` database
- **Configuration**: Stored in metabase database
- **Dashboards**: Stored in metabase database
- **User Data**: `./metabase/data:/metabase-data` (optional)

## Initial Setup

### First Time Access

1. Open http://localhost:3000
2. Complete setup wizard:
   - Create admin account (email/password)
   - Skip "Add your data" (we'll do it manually)
   - Click "Take me to Metabase"

### Connect to Home Metrics Database

1. Click Settings (gear icon) → Admin → Databases
2. Click "Add database"
3. Fill in connection details:
   ```
   Display name: Home Metrics
   Database type: PostgreSQL
   Host: postgres
   Port: 5432
   Database name: home_metrics
   Username: metrics_user
   Password: <from .env file>
   ```
4. Click "Save"
5. Wait for schema scan to complete

## Creating Your First Query

### Simple Query
1. Click "New" → "Question"
2. Select "Home Metrics" database
3. Choose table (e.g., `Raw Power Consumption`)
4. Add filters, grouping, visualization
5. Save query

### SQL Query
1. Click "New" → "Question"
2. Click "Native query"
3. Write SQL:
   ```sql
   SELECT
       DATE_TRUNC('hour', recorded_at) AS hour,
       friendly_name,
       AVG(state) AS avg_power_w
   FROM raw_power_consumption
   WHERE recorded_at > NOW() - INTERVAL '24 hours'
   GROUP BY hour, friendly_name
   ORDER BY hour DESC;
   ```
4. Visualize as line chart
5. Save and add to dashboard

## Dashboard Examples

### Power Consumption Dashboard

**Widgets to create:**

1. **Total Current Power** (Number)
   ```sql
   SELECT SUM(state) AS total_watts
   FROM raw_power_consumption
   WHERE recorded_at = (SELECT MAX(recorded_at) FROM raw_power_consumption);
   ```

2. **Power Over Time** (Line Chart)
   ```sql
   SELECT
       DATE_TRUNC('hour', recorded_at) AS time,
       SUM(state) AS total_watts
   FROM raw_power_consumption
   WHERE recorded_at > NOW() - INTERVAL '7 days'
   GROUP BY time
   ORDER BY time;
   ```

3. **Top Power Consumers** (Bar Chart)
   ```sql
   SELECT
       friendly_name,
       AVG(state) AS avg_watts
   FROM raw_power_consumption
   WHERE recorded_at > NOW() - INTERVAL '24 hours'
   GROUP BY friendly_name
   ORDER BY avg_watts DESC
   LIMIT 10;
   ```

4. **Power by Device** (Pie Chart)
   ```sql
   SELECT
       friendly_name AS device,
       AVG(state) AS avg_watts
   FROM raw_power_consumption
   WHERE recorded_at > NOW() - INTERVAL '24 hours'
   GROUP BY device;
   ```

### Media Usage Dashboard

1. **Watch Activity This Week**
2. **Library Growth Over Time**
3. **Most Watched Shows/Movies**
4. **Watch Time by User**

### Pi-hole Dashboard

1. **Total Queries Today**
2. **Block Percentage**
3. **Top Blocked Domains**
4. **Queries Over Time**

## Features

### Filters
Add dashboard filters to make dashboards interactive:
- Date range picker
- Device selector
- User filter

### Scheduled Reports
1. Create dashboard
2. Click sharing icon → "Subscriptions"
3. Set schedule (daily/weekly)
4. Choose delivery method (email)

### Alerts
1. Create question
2. Click bell icon
3. Set alert conditions
4. Configure notification (email/Slack)

### Collections
Organize dashboards and questions:
1. Create collection for each topic
2. Set permissions per collection
3. Share with team members

## User Management

### Add Users
1. Settings → Admin → People
2. Click "Invite someone"
3. Enter email and set permissions

### Permission Groups
- **Administrators** - Full access
- **Analysts** - Can create queries/dashboards
- **Viewers** - Read-only access

## Performance Optimization

### Query Caching
Metabase automatically caches query results. Configure:
1. Settings → Admin → Caching
2. Set cache duration (1-24 hours)

### Database Connection Pool
Adjust in docker-compose if needed:
```yaml
environment:
  MB_DB_CONNECTION_POOL_MAX: 10
```

## Backing Up Metabase

### Application Database Backup
Already included in PostgreSQL backups (metabase database)

### Export Dashboards
No built-in export feature. Dashboards stored in `metabase` database.

## Upgrading

```bash
# Stop container
docker-compose stop metabase

# Pull latest image
docker-compose pull metabase

# Start with new version
docker-compose up -d metabase

# Check logs
docker logs -f home-metrics-metabase
```

## Troubleshooting

### Metabase Won't Start
```bash
# Check logs
docker logs home-metrics-metabase

# Common issues:
# - Can't connect to metabase database
# - JVM out of memory
# - Port 3000 in use
```

### Can't Connect to home_metrics Database
1. Verify PostgreSQL is running
2. Check connection details match .env
3. Use hostname `postgres` not `localhost`
4. Test connection from Metabase container:
   ```bash
   docker exec -it home-metrics-metabase nc -zv postgres 5432
   ```

### Slow Queries
1. Add indexes to frequently queried columns
2. Use materialized views for complex aggregations (via dbt)
3. Enable query caching
4. Limit date ranges in queries

### Out of Memory
Increase JVM heap:
```yaml
environment:
  JAVA_OPTS: "-Xmx2g"
```

## Security

### Change Admin Password
1. Settings → Account Settings
2. Click "Password"
3. Enter new password

### Enable HTTPS
Add reverse proxy (nginx/traefik) in front of Metabase

### Session Timeout
1. Settings → Admin → Settings
2. Under "Security" set session timeout

## Useful SQL Queries

### Data Completeness Check
```sql
SELECT
    DATE(recorded_at) AS date,
    COUNT(*) AS readings,
    COUNT(DISTINCT entity_id) AS unique_sensors
FROM raw_power_consumption
WHERE recorded_at > NOW() - INTERVAL '7 days'
GROUP BY date
ORDER BY date DESC;
```

### Gap Detection
```sql
WITH time_series AS (
    SELECT
        entity_id,
        recorded_at,
        LAG(recorded_at) OVER (PARTITION BY entity_id ORDER BY recorded_at) AS prev_reading,
        recorded_at - LAG(recorded_at) OVER (PARTITION BY entity_id ORDER BY recorded_at) AS gap
    FROM raw_power_consumption
)
SELECT *
FROM time_series
WHERE gap > INTERVAL '10 minutes'
ORDER BY gap DESC;
```

## Best Practices

1. **Name Queries Clearly** - Include date range and metrics
2. **Use Collections** - Organize by topic
3. **Add Descriptions** - Help others understand queries
4. **Set Refresh Schedules** - Match data update frequency
5. **Use Parameters** - Make dashboards reusable
6. **Monitor Performance** - Check slow query log

## Related Documentation

- [PostgreSQL Service](postgresql.md)
- [n8n Workflows](n8n.md)
- [Setup Guide](../ops/setup.md)
- [Troubleshooting](../ops/troubleshooting.md)
