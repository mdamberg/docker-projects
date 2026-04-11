# n8n Workflows Documentation

## Overview

n8n workflows are responsible for extracting data from various sources and loading it into PostgreSQL raw tables. Workflows are organized by domain in the `docker-projects/n8n/` folder.

## Workflow Inventory

| Workflow | Schedule | Source | Target Table |
|----------|----------|--------|--------------|
| Media Library Data Collection | Every 6 hours | Tautulli, Sonarr, Radarr, Prowlarr | raw_media_library |
| System Health Metrics Collection | Every 15 minutes | Windows Exporter | raw_system_health |
| Workflow Health Monitor | Every 1 hour | PostgreSQL (self-check) | raw_n8n_alerts |
| Global Error Catcher | On error | Any failing workflow | raw_n8n_alerts |

---

## Media Library Data Collection

**File**: `plex_media_workflows/media_library_workflow.json`

### Purpose
Collects library statistics from media management services.

### Schedule
Every 6 hours

### Data Sources
| Service | Endpoint | Data Collected |
|---------|----------|----------------|
| Tautulli | `http://host.docker.internal:8181/api/v2` | Plex library counts per section |
| Sonarr | `http://host.docker.internal:8989/api/v3/series` | TV series count, episodes, disk size |
| Radarr | `http://host.docker.internal:7878/api/v3/movie` | Movie count, downloaded/missing, disk size |
| Prowlarr | `http://host.docker.internal:9696/api/v1/indexer` | Indexer count, enabled/disabled |

### Output Schema (raw_media_library)
```sql
source          -- 'plex', 'sonarr', 'radarr', 'prowlarr'
media_type      -- 'movie', 'tv_show', 'indexer', etc.
library_name    -- Library or service name
item_count      -- Number of items
total_size_bytes -- Storage used (where applicable)
recorded_at     -- When data was captured
metadata        -- Additional details (JSONB)
```

### Workflow Nodes
```
Schedule Trigger (6h) ──┬── Get Plex Libraries ── Transform ── Insert
                        ├── Get Sonarr Series ── Transform ── Insert
Manual Trigger ─────────┼── Get Radarr Movies ── Transform ── Insert
                        └── Get Prowlarr Indexers ── Transform ── Insert
```

---

## System Health Metrics Collection

**File**: `system_health_workflows/system_health_workflow.json`

### Purpose
Collects system performance metrics from Windows desktop via windows_exporter.

### Prerequisites
- **Windows Exporter** must be installed and running on port 9182
- Download from: https://github.com/prometheus-community/windows_exporter/releases

### Schedule
Every 15 minutes

### Data Source
| Service | Endpoint | Format |
|---------|----------|--------|
| Windows Exporter | `http://host.docker.internal:9182/metrics` | Prometheus text format |

### Metrics Collected
| Metric | Description |
|--------|-------------|
| cpu_percent | CPU usage percentage (calculated from idle time) |
| memory_percent | RAM usage percentage |
| disk_percent | C: drive usage percentage |
| disk_read/write_latency | Disk I/O latency (seconds) |
| disk_read/write_bytes_total | Cumulative disk I/O |
| net_bytes_received/sent_total | Cumulative network I/O |
| processor_queue_length | CPU saturation indicator |
| paging_free_bytes | Page file free space |
| memory_commit_limit/committed | Virtual memory stats |

### Output Schema (raw_system_health)
```sql
hostname                                    -- System hostname
cpu_percent, memory_percent, disk_percent   -- Usage percentages
temperature_c                               -- (null - requires special hardware)
windows_logical_disk_*                      -- Disk metrics
windows_net_*                               -- Network metrics
windows_system_processor_queue_length       -- CPU queue
windows_os_paging_free_bytes               -- Page file
windows_memory_*                            -- Memory details
recorded_at, inserted_at                    -- Timestamps
metadata                                    -- Core count, GB values, uptime, etc.
```

### Workflow Nodes
```
Schedule Trigger (15m) ──┬── Get Windows Metrics ── Transform Metrics ── Insert
Manual Trigger ──────────┘
```

### Notes
- Disk/network `_bytes_total` are cumulative counters since boot
- To calculate rates, compare consecutive readings: `(current - previous) / time_diff`
- CPU percentage is a lifetime average; for real-time, compare idle time between readings

---

## Workflow Health Monitor

**File**: `workflow_alerts/workflow_health_monitor.json`

### Purpose
Monitors data freshness across all raw tables and alerts if data stops flowing.

### Schedule
Every 1 hour

### Tables Monitored
| Table | Threshold | Expected Schedule |
|-------|-----------|-------------------|
| raw_system_health | 20 minutes | Every 15 minutes |
| raw_media_library | 7 hours (420 min) | Every 6 hours |
| raw_pihole_metrics | 7 hours (420 min) | Every 6 hours |

### Alert Types Generated
| Type | Severity | Condition |
|------|----------|-----------|
| `stale_data` | warning | Data older than threshold |
| `no_data` | warning | No data in last 24 hours |

### Output
- **Discord notification** - Immediate alert with details
- **raw_n8n_alerts** - Historical log of all alerts

### Workflow Nodes
```
Schedule Trigger (1h) ──┬── Check Data Freshness (SQL) ── Analyze ── If Issues? ──┬── Split Alerts ── Log to DB
Manual Trigger ─────────┘                                                          └── Send Discord Alert
```

### SQL Query (simplified)
```sql
SELECT
  'raw_system_health' AS table_name,
  MAX(recorded_at) AS last_recorded,
  EXTRACT(EPOCH FROM (NOW() - MAX(recorded_at)))/60 AS minutes_since_last,
  20 AS threshold_minutes,
  CASE WHEN minutes > 20 THEN true ELSE false END AS is_stale
FROM raw_system_health
WHERE recorded_at > NOW() - INTERVAL '24 hours'
-- UNION ALL for each table...
```

---

## Global Error Catcher

**File**: `workflow_alerts/global_error_catcher.json`

### Purpose
Automatically catches and logs errors from ANY workflow in n8n.

### Trigger
Uses n8n's `errorTrigger` node - fires whenever any workflow fails.

### Setup Required
1. Import the workflow
2. Configure PostgreSQL credential
3. Configure Discord webhook URL
4. **Activate the workflow**
5. **Set as default error workflow**: Settings → Workflows → Error Workflow

### Data Captured
| Field | Description |
|-------|-------------|
| alert_type | Always `workflow_failure` |
| severity | Always `error` |
| source | Name of the failed workflow |
| title | Short description |
| message | Error message with node name |
| metadata | execution_id, execution_url, error_stack, last_node_executed |

### Output
- **Discord notification** - Immediate alert
- **raw_n8n_alerts** - Database log

### Workflow Nodes
```
On Workflow Error ── Transform Error Data ──┬── Log to Database
                                            └── Send Discord Alert
```

---

## Unified Alerts Table (raw_n8n_alerts)

Both alerting workflows write to the same table for unified monitoring.

### Schema
```sql
CREATE TABLE raw_n8n_alerts (
    id BIGSERIAL PRIMARY KEY,
    alert_type VARCHAR(50) NOT NULL,    -- 'workflow_failure', 'stale_data', 'no_data'
    severity VARCHAR(20),               -- 'warning', 'error', 'critical'
    source VARCHAR(100),                -- workflow name or table name
    title VARCHAR(500),                 -- short description
    message TEXT,                       -- detailed message
    triggered_at TIMESTAMP NOT NULL,
    resolved_at TIMESTAMP,              -- NULL if still active
    inserted_at TIMESTAMP DEFAULT NOW(),
    metadata JSONB
);
```

### Useful Queries
```sql
-- All recent alerts
SELECT * FROM raw_n8n_alerts ORDER BY triggered_at DESC LIMIT 20;

-- Unresolved alerts
SELECT * FROM raw_n8n_alerts WHERE resolved_at IS NULL;

-- Alerts by type
SELECT alert_type, COUNT(*) FROM raw_n8n_alerts GROUP BY alert_type;

-- Workflow failures only
SELECT * FROM raw_n8n_alerts WHERE alert_type = 'workflow_failure';
```

---

## Discord Webhook Setup

Both alerting workflows can send notifications to Discord.

### Create Webhook
1. Open Discord server
2. Server Settings → Integrations → Webhooks
3. New Webhook → Copy URL
4. Paste URL in workflow's "Send Discord Alert" node

### Alert Format
```json
{
  "content": "🚨 Workflow Failed: Media Library Collection",
  "embeds": [{
    "title": "Workflow Failure Details",
    "description": "**Error:** Connection refused\n**Node:** Get Sonarr Series",
    "color": 15158332,
    "timestamp": "2026-01-15T22:00:00Z"
  }]
}
```

---

## Adding New Data Sources

To add a new data collection workflow:

1. **Create the workflow** in n8n
   - Add Schedule Trigger and Manual Trigger
   - Add HTTP Request node(s) to fetch data
   - Add Code node to transform data
   - Add PostgreSQL node to insert

2. **Create the raw table** in PostgreSQL
   - Add to `02-create-raw-tables.sql`
   - Run ALTER TABLE or recreate container

3. **Add to sources.yml** in dbt
   - Define source in `models/staging/sources.yml`

4. **Create staging model** in dbt
   - Create `stg_<name>.sql` and `stg_<name>.yml`

5. **Add to Workflow Health Monitor**
   - Add UNION ALL clause to check freshness
   - Set appropriate threshold

6. **Test end-to-end**
   - Run workflow manually
   - Run `dbt build --select stg_<name>`
   - Verify data in Metabase
