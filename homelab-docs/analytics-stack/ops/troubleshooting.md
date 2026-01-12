# Troubleshooting

Common issues and solutions for the analytics stack.

## PostgreSQL Issues

### Container Won't Start

**Check logs**:
```bash
docker logs home-metrics-postgres
```

**Common causes**:

1. **Port 5432 already in use**:
   ```bash
   # Check what's using the port
   netstat -an | findstr :5432  # Windows
   lsof -i :5432  # Linux/Mac

   # Solution: Stop conflicting service or change port in docker-compose.yml
   ports:
     - "5433:5432"  # Use different external port
   ```

2. **Data directory corruption**:
   ```bash
   # Backup current data
   mv postgres/data postgres/data.backup

   # Restart with fresh database
   docker-compose up -d postgres

   # Restore from backup
   ```

3. **Permission issues**:
   ```bash
   # Fix permissions
   sudo chown -R 999:999 postgres/data
   ```

### Can't Connect to Database

**From host**:
```bash
# Test connection
docker exec home-metrics-postgres pg_isready -U metrics_user -d home_metrics

# If fails, check:
# 1. Container is running: docker ps | grep postgres
# 2. Port is mapped: docker port home-metrics-postgres
# 3. Password is correct in .env
```

**From n8n/Metabase**:
```bash
# Test network connectivity
docker exec n8n nc -zv postgres 5432
docker exec home-metrics-metabase nc -zv postgres 5432

# If fails:
# 1. Ensure containers are on same network
docker network inspect home-metrics

# 2. Connect n8n to network
docker network connect home-metrics n8n
```

### Slow Queries

**Identify slow queries**:
```sql
SELECT
    pid,
    now() - query_start AS duration,
    query,
    state
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;
```

**Solutions**:
1. Add indexes on frequently queried columns
2. Use EXPLAIN ANALYZE to find bottlenecks
3. Create materialized views for complex queries
4. Increase shared_buffers in postgresql.conf

### Out of Disk Space

**Check database size**:
```sql
SELECT
    pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database
ORDER BY pg_database_size(pg_database.datname) DESC;
```

**Solutions**:
```bash
# 1. Vacuum to reclaim space
docker exec home-metrics-postgres psql -U metrics_user -d home_metrics -c "VACUUM FULL;"

# 2. Delete old data
docker exec home-metrics-postgres psql -U metrics_user -d home_metrics -c "DELETE FROM raw_power_consumption WHERE recorded_at < NOW() - INTERVAL '90 days';"

# 3. Increase disk space or move to larger volume
```

## Metabase Issues

### Metabase Won't Start

**Check logs**:
```bash
docker logs home-metrics-metabase --tail 100
```

**Common issues**:

1. **Can't connect to metabase database**:
   ```
   Error: database "metabase" does not exist
   ```

   **Solution**:
   ```bash
   docker exec home-metrics-postgres psql -U metrics_user -d postgres -c "CREATE DATABASE metabase OWNER metrics_user;"
   docker restart home-metrics-metabase
   ```

2. **Out of memory**:
   ```
   Java heap space OutOfMemoryError
   ```

   **Solution**: Increase JVM heap in docker-compose.yml:
   ```yaml
   environment:
     JAVA_OPTS: "-Xmx2g"
   ```

3. **Port 3000 in use**:
   ```bash
   # Change port in docker-compose.yml
   ports:
     - "3001:3000"
   ```

### Can't Connect to home_metrics Database

**Verify connection details**:
1. Settings → Admin → Databases → Home Metrics
2. Click "Edit"
3. Verify:
   - Host: `postgres` (not localhost)
   - Port: `5432`
   - Database: `home_metrics` (not metabase)
   - User: `metrics_user`
   - Password: matches .env

**Test from container**:
```bash
docker exec home-metrics-metabase nc -zv postgres 5432
```

### Slow Dashboard Loading

**Solutions**:
1. **Enable caching**: Settings → Admin → Caching
2. **Optimize queries**: Use EXPLAIN to find slow queries
3. **Create materialized views**: Pre-aggregate data with dbt
4. **Limit data range**: Add date filters to dashboards

### Lost Admin Password

**Reset via database**:
```sql
-- Connect to metabase database
docker exec -it home-metrics-postgres psql -U metrics_user -d metabase

-- Reset password for admin user (requires bcrypt hash)
-- Or create new admin user
INSERT INTO core_user (email, first_name, last_name, password, date_joined, last_login, is_superuser, is_active)
VALUES ('new-admin@example.com', 'Admin', 'User', '$2a$10$...', NOW(), NOW(), true, true);
```

## n8n Issues

### Can't Connect to PostgreSQL

**Check network**:
```bash
docker network ls
docker network inspect home-metrics
```

**Verify n8n is on network**:
```bash
# If not, connect it
docker network connect home-metrics n8n
docker restart n8n
```

**Test connection**:
```bash
docker exec n8n nc -zv postgres 5432
```

**Alternative**: Use `host.docker.internal` as hostname

### Workflow Keeps Failing

**Check execution logs**:
1. In n8n, click "Executions"
2. Click on failed execution
3. Review error message

**Common errors**:

1. **Duplicate key violation**:
   ```
   duplicate key value violates unique constraint
   ```
   Solution: Add conflict handling in INSERT or use UPSERT

2. **Invalid data type**:
   ```
   invalid input syntax for type numeric
   ```
   Solution: Validate/transform data in Function node before INSERT

3. **Timeout**:
   ```
   ETIMEDOUT
   ```
   Solution: Increase timeout or batch smaller requests

### Credentials Not Working

1. Re-create PostgreSQL credentials in n8n
2. Verify password has no special characters that need escaping
3. Test connection in credential setup

## Data Collection Issues

### No Data Flowing

**Check workflow status**:
```bash
# In n8n UI
# 1. Verify workflow is "Active" (toggle at top)
# 2. Check execution history for errors
# 3. Run manual test execution
```

**Verify data reached database**:
```sql
SELECT COUNT(*), MAX(inserted_at) FROM raw_power_consumption;
```

**If no recent data**:
1. Check n8n logs: `docker logs n8n`
2. Verify Home Assistant is accessible
3. Check API credentials/tokens

### Data Has Gaps

**Find gaps**:
```sql
WITH expected_times AS (
    SELECT generate_series(
        date_trunc('hour', NOW() - INTERVAL '24 hours'),
        date_trunc('hour', NOW()),
        interval '5 minutes'
    ) AS expected_time
),
actual_times AS (
    SELECT DISTINCT date_trunc('minute', recorded_at) AS actual_time
    FROM raw_power_consumption
    WHERE recorded_at > NOW() - INTERVAL '24 hours'
)
SELECT e.expected_time
FROM expected_times e
LEFT JOIN actual_times a ON date_trunc('minute', e.expected_time) = a.actual_time
WHERE a.actual_time IS NULL
ORDER BY e.expected_time;
```

**Common causes**:
1. n8n container was stopped
2. Home Assistant was unavailable
3. Network issues
4. Workflow was deactivated

**Solutions**:
- Set up monitoring alerts
- Add retry logic to workflows
- Backfill missing data if source allows

### Duplicate Data

**Find duplicates**:
```sql
SELECT
    entity_id,
    recorded_at,
    COUNT(*)
FROM raw_power_consumption
GROUP BY entity_id, recorded_at
HAVING COUNT(*) > 1;
```

**Solutions**:
1. Add unique constraint:
   ```sql
   ALTER TABLE raw_power_consumption
   ADD CONSTRAINT unique_reading UNIQUE (entity_id, recorded_at);
   ```

2. Use UPSERT in n8n:
   ```sql
   INSERT INTO raw_power_consumption (...)
   VALUES (...)
   ON CONFLICT (entity_id, recorded_at)
   DO NOTHING;
   ```

3. Clean up existing duplicates:
   ```sql
   DELETE FROM raw_power_consumption a
   USING raw_power_consumption b
   WHERE a.id > b.id
     AND a.entity_id = b.entity_id
     AND a.recorded_at = b.recorded_at;
   ```

## Network Issues

### Containers Can't Communicate

**Check network**:
```bash
docker network inspect home-metrics
```

**Verify all containers are listed**. If not:
```bash
# Connect missing container
docker network connect home-metrics <container_name>
```

**Test connectivity**:
```bash
# From n8n to postgres
docker exec n8n ping postgres

# From Metabase to postgres
docker exec home-metrics-metabase ping postgres
```

### DNS Resolution Fails

**Use IP address instead**:
```bash
# Find PostgreSQL IP
docker inspect home-metrics-postgres | grep IPAddress

# Use IP in connection strings
# e.g., 172.20.0.2 instead of postgres
```

## Performance Issues

### High CPU Usage

**Identify culprit**:
```bash
docker stats
```

**If PostgreSQL**:
```sql
-- Find expensive queries
SELECT * FROM pg_stat_activity ORDER BY query_start;
```

**If Metabase**:
- Check for heavy dashboards
- Enable caching
- Limit concurrent users

### High Memory Usage

**Check container memory**:
```bash
docker stats --no-stream
```

**Solutions**:
1. Limit PostgreSQL memory in docker-compose:
   ```yaml
   deploy:
     resources:
       limits:
         memory: 2G
   ```

2. Reduce Metabase JVM heap
3. Optimize queries to use less memory

## Error Messages

### "relation does not exist"

**Error**:
```
ERROR: relation "raw_power_consumption" does not exist
```

**Cause**: Table not created or wrong schema

**Solution**:
```sql
-- Check current schema
SHOW search_path;

-- Set schema
SET search_path TO public, staging, intermediate, marts;

-- Or use fully qualified name
SELECT * FROM public.raw_power_consumption;
```

### "authentication failed"

**Error**:
```
FATAL: password authentication failed for user "metrics_user"
```

**Solutions**:
1. Verify password in .env matches credentials
2. Check for special characters in password
3. Recreate user:
   ```sql
   DROP USER metrics_user;
   CREATE USER metrics_user WITH PASSWORD 'new_password';
   GRANT ALL PRIVILEGES ON DATABASE home_metrics TO metrics_user;
   ```

### "too many connections"

**Error**:
```
FATAL: sorry, too many clients already
```

**Solution**:
```sql
-- Check current connections
SELECT COUNT(*) FROM pg_stat_activity;

-- Increase max_connections
ALTER SYSTEM SET max_connections = 200;

-- Restart PostgreSQL
```

## Getting Help

1. **Check logs**: Always start with `docker logs <container>`
2. **Search documentation**: PostgreSQL, Metabase, n8n docs
3. **GitHub issues**: Check if others had similar problems
4. **Community forums**: PostgreSQL, Metabase, n8n communities

## Related Documentation

- [Setup Guide](setup.md)
- [Backup & Restore](backup-restore.md)
- [PostgreSQL Service](../services/postgresql.md)
- [Metabase Service](../services/metabase.md)
- [n8n Workflows](../services/n8n.md)
