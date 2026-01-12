# n8n Workflows

Data collection orchestration for the analytics stack.

## Overview

n8n lives in the main `docker-projects` repo and handles:
- Scheduled API calls to data sources
- Data transformation before insertion
- Inserting data into PostgreSQL raw tables
- Generating and sending reports

## Workflows

### 1. Home Assistant Power Collection

**File**: `power_consumption_workflow_FIXED.json`

**Schedule**: Every 5 minutes

**Steps**:
1. Trigger: Manual or Schedule (cron: `*/5 * * * *`)
2. Get All HA States via HTTP Request
3. Filter for power/energy sensors
4. Generate report (text + HTML)
5. **NEW: Insert into PostgreSQL** `raw_power_consumption`

**Data Collected**:
- Entity ID
- Friendly name
- State (power value)
- Unit of measurement
- Device class
- Attributes (JSON)
- Recorded timestamp
- Insert timestamp

### 2. Plex Media Library Stats

**Schedule**: Daily at 2 AM

**Steps**:
1. Trigger: Schedule (cron: `0 2 * * *`)
2. HTTP Request to Plex API `/library/sections`
3. Parse library statistics
4. Insert into `raw_media_library`

**Data Collected**:
- Source: 'plex'
- Media type (movie, show, music)
- Library name
- Item count
- Total size in bytes
- Metadata (JSON)

### 3. Plex Watch History

**Schedule**: Every 15 minutes (or webhook-triggered)

**Steps**:
1. Get recently watched items from Plex
2. Parse watch history
3. Insert into `raw_media_activity`

**Data Collected**:
- User name
- Media type
- Title
- Series title (for episodes)
- Duration
- Watched timestamp

### 4. Pi-hole Metrics

**Schedule**: Every 15 minutes

**Steps**:
1. HTTP Request to Pi-hole API `/admin/api.php?summary`
2. Parse metrics
3. Insert into `raw_pihole_metrics`

**Data Collected**:
- Total queries
- Blocked queries
- Percent blocked
- Unique domains
- Unique clients
- Top blocked domains (JSON array)
- Top queries (JSON array)

### 5. Sonarr/Radarr Library Stats

**Schedule**: Daily at 3 AM

**Steps**:
1. HTTP Request to Sonarr API `/api/v3/series`
2. HTTP Request to Radarr API `/api/v3/movie`
3. Aggregate statistics
4. Insert into `raw_media_library`

**Data Collected**:
- Series/movie counts
- Total file sizes
- Quality profiles
- Monitored vs unmonitored

### 6. Weekly Report Generator

**Schedule**: Monday at 8 AM

**Steps**:
1. Trigger: Schedule (cron: `0 8 * * 1`)
2. Query PostgreSQL marts: `SELECT * FROM summary_home_metrics WHERE week = date_trunc('week', now() - interval '1 week')`
3. Format report with power totals, media stats, pihole summary
4. Send to Notifiarr webhook
5. Post to Discord

## PostgreSQL Node Configuration

### Add to Workflow

1. In n8n, add "Postgres" node after data processing
2. Click "Create New Credential"
3. Enter connection details:
   ```
   Host: postgres (if on same network)
      OR host.docker.internal (from n8n container)
   Database: home_metrics
   User: metrics_user
   Password: <from .env>
   Port: 5432
   SSL: Disabled (localhost)
   ```
4. Test connection
5. Save credential

### Insert Query Example

For power consumption workflow:

```javascript
// In Function node, format data for insertion
const items = $input.all();

const insertData = items.map(item => {
    const entity = item.json;
    return {
        entity_id: entity.entity_id,
        friendly_name: entity.attributes.friendly_name || entity.entity_id,
        state: parseFloat(entity.state),
        unit_of_measurement: entity.attributes.unit_of_measurement || null,
        device_class: entity.attributes.device_class || null,
        recorded_at: entity.last_updated || new Date().toISOString(),
        attributes: JSON.stringify(entity.attributes)
    };
});

return insertData.map(data => ({ json: data }));
```

Then in Postgres node:
- Operation: Insert
- Table: `raw_power_consumption`
- Columns: Specify all columns
- Map input fields to columns

## Network Configuration

### Connecting n8n to PostgreSQL

**Option 1: Same Docker Network** (Recommended)
```bash
docker network connect home-metrics n8n
docker restart n8n
```

Then use hostname: `postgres`

**Option 2: Host Networking**
Use hostname: `host.docker.internal`

**Option 3: Direct IP**
Find PostgreSQL container IP:
```bash
docker inspect home-metrics-postgres | grep IPAddress
```

## Error Handling

### Add Error Handling to Workflows

1. Add "IF" node after data collection
2. Check if data exists
3. If error, send alert via webhook/email
4. Log error to separate error tracking table

### Retry Logic

1. Add "Set" node for retry counter
2. Add "Error Trigger" node
3. Implement exponential backoff
4. Max 3 retries, then alert

## Monitoring Workflows

### Check Execution History

1. In n8n, click "Executions" tab
2. Filter by workflow
3. Check for errors
4. View input/output data

### Set Up Alerts

1. Create monitoring workflow
2. Query PostgreSQL for data freshness
3. If last insert > threshold, send alert
4. Schedule: Every hour

## Best Practices

1. **Use Credentials** - Never hardcode passwords
2. **Add Retry Logic** - APIs can fail
3. **Validate Data** - Check for nulls/invalid values before insertion
4. **Log Errors** - Send to separate error table or external service
5. **Rate Limiting** - Respect API rate limits
6. **Batch Inserts** - Insert multiple rows at once
7. **Use Transactions** - For multi-table inserts

## Workflow Templates

### Basic Data Collection Pattern

```
[Schedule Trigger]
    ↓
[HTTP Request] → Get data from API
    ↓
[Function] → Transform/validate data
    ↓
[IF] → Check for errors
    ↓
[Postgres] → Insert into raw table
    ↓
[Set] → Log success
```

### Report Generation Pattern

```
[Schedule Trigger]
    ↓
[Postgres] → Query marts table
    ↓
[Function] → Format report
    ↓
[HTTP Request] → Send to Notifiarr/Discord
    ↓
[Set] → Log completion
```

## Testing Workflows

1. Click "Execute Workflow" to run manually
2. Check each node's output
3. Verify data in PostgreSQL:
   ```sql
   SELECT * FROM raw_power_consumption ORDER BY inserted_at DESC LIMIT 10;
   ```
4. Check for errors in n8n execution log

## Troubleshooting

### Can't Connect to PostgreSQL
- Verify network connection
- Check credentials
- Test from n8n container:
  ```bash
  docker exec -it n8n nc -zv postgres 5432
  ```

### Data Not Inserting
- Check PostgreSQL logs
- Verify table structure matches data
- Check for constraint violations
- Review n8n error output

### Workflow Not Triggering
- Verify schedule trigger is active
- Check n8n logs:
  ```bash
  docker logs n8n
  ```
- Ensure workflow is activated (toggle at top)

## Related Documentation

- [PostgreSQL Service](postgresql.md)
- [Metabase Service](metabase.md)
- [Setup Guide](../ops/setup.md)
- [Troubleshooting](../ops/troubleshooting.md)
