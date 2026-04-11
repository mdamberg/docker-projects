# dbt Models Documentation

## Overview

dbt (data build tool) transforms raw data into analytics-ready models. Models are organized in layers, each with a specific purpose.

**Project Location**: `docker-projects/home_metrics_dbt/`

## Model Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    RAW TABLES (PostgreSQL)                  │
│  raw_media_library, raw_system_health, raw_n8n_alerts, etc. │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    STAGING LAYER (Views)                    │
│  stg_media_library, stg_system_health, stg_n8n_alerts, etc. │
│  Purpose: Clean, rename, cast - no joins                    │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 INTERMEDIATE LAYER (Views)                  │
│  intmdt_media_library, etc.                                 │
│  Purpose: Joins, aggregations, calculations                 │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    MARTS LAYER (Tables)                     │
│  (coming soon)                                              │
│  Purpose: Business-ready, denormalized for dashboards       │
└─────────────────────────────────────────────────────────────┘
```

---

## Staging Models

Location: `models/staging/`

### stg_media_library

**Source**: `raw_media_library`
**File**: `stg_media_library.sql`

Cleans and standardizes media library data from Plex, Sonarr, Radarr, and Prowlarr.

| Column            | Type      | Description                                   |
|-------------------|-----------|-----------------------------------------------|
| id                | integer   | Primary key                                   |
| source            | string    | Service name (plex, sonarr, radarr, prowlarr) |
| media_type        | string    | Type (movie, tv_show, indexer)                |
| library_name      | string    | Library or service name                       |
| item_count        | integer   | Number of items                               |
| total_size_bytes  | bigint    | Storage used                                  |
| total_size_gb     | numeric   | Storage in GB (calculated)                    |
| recorded_at       | timestamp | When captured                                 |
| date_recorded     | date      | Date portion                                  |
| time_recorded     | time      | Time portion                                  |
| inserted_at       | timestamp | When inserted to DB                           |
| metadata          | jsonb     | Additional details                            |


---

### stg_system_health

**Source**: `raw_system_health`
**File**: `stg_system_health.sql`

Cleans and standardizes system health metrics from Windows Exporter.

| Column                       | Type      | Description                          |
|------------------------------|-----------|--------------------------------------|
| id                           | integer   | Primary key                          |
| hostname                     | string    | System hostname                      |
| cpu_percent                  | numeric   | CPU usage %                          |
| memory_percent               | numeric   | RAM usage %                          |
| disk_percent                 | numeric   | C: drive usage %                     |
| disk_read_latency_seconds    | numeric   | Disk read latency                    |
| disk_write_latency_seconds   | numeric   | Disk write latency                   |
| disk_read_bytes_total        | bigint    | Cumulative disk reads                |
| disk_write_bytes_total       | bigint    | Cumulative disk writes               |
| net_bytes_received_total     | bigint    | Cumulative network received          |
| net_bytes_sent_total         | bigint    | Cumulative network sent              |
| processor_queue_length       | numeric   | CPU queue depth                      |
| paging_free_bytes            | bigint    | Page file free                       |
| memory_commit_limit          | bigint    | Max virtual memory                   |
| memory_committed_bytes       | bigint    | Used virtual memory                  |
| recorded_at                  | timestamp | When captured                        |
| date_recorded                | date      | Date portion                         |
| time_recorded                | time      | Time portion                         |
| inserted_at                  | timestamp | When inserted to DB                  |
| metadata                     | jsonb     | Additional details                   |


---

### stg_n8n_alerts

**Source**: `raw_n8n_alerts`
**File**: `stg_n8n_alerts.sql`

Cleans and standardizes workflow alerts and failures.

| Column          | Type      | Description                                   |
|-----------------|-----------|-----------------------------------------------|
| id              | integer   | Primary key                                   |
| alert_type      | string    | workflow_failure, stale_data, no_data         |
| severity        | string    | warning, error, critical                      |
| alert_source    | string    | Workflow or table name                        |
| title           | string    | Short description                             |
| message         | text      | Full details                                  |
| triggered_at    | timestamp | When alert fired                              |
| date_triggered  | date      | Date portion                                  |
| time_triggered  | time      | Time portion                                  |
| resolved_at     | timestamp | When resolved (NULL if active)                |
| is_active       | boolean   | TRUE if unresolved                            |
| inserted_at     | timestamp | When inserted to DB                           |
| metadata        | jsonb     | Extra context                                 |
| execution_id    | string    | n8n execution ID (from metadata)              |
| workflow_id     | string    | Workflow ID (from metadata)                   |
| failed_node     | string    | Node that failed (from metadata)              |


---

### stg_n8n_workflow_runs

**Source**: `raw_n8n_workflow_runs`
**File**: `stg_n8n_workflow_runs.sql`

Tracks workflow execution history.

| Column             | Type      | Description                          |
|--------------------|-----------|--------------------------------------|
| id                 | integer   | Primary key                          |
| workflow_id        | string    | Workflow identifier                  |
| workflow_name      | string    | Workflow name                        |
| source             | string    | Trigger source                       |
| status             | string    | Execution status                     |
| started_at         | timestamp | Start time                           |
| finished_at        | timestamp | End time                             |
| duration_seconds   | numeric   | Execution duration (calculated)      |
| inserted_at        | timestamp | When inserted                        |
| metadata           | jsonb     | Additional details                   |


---

### stg_pihole_metrics

**Source**: `raw_pihole_metrics`
**File**: `stg_pihole_metrics.sql`

Pi-hole DNS blocking statistics.

| Column               | Type      | Description                     |
|----------------------|-----------|---------------------------------|
| id                   | integer   | Primary key                     |
| pihole_instance      | string    | Instance identifier             |
| total_queries        | integer   | Total DNS queries               |
| blocked_queries      | integer   | Queries blocked                 |
| percent_blocked      | numeric   | Block percentage                |
| unique_domains       | integer   | Unique domains queried          |
| unique_clients       | integer   | Unique clients                  |
| recorded_at          | timestamp | When captured                   |
| inserted_at          | timestamp | When inserted                   |
| top_blocked_domains  | jsonb     | Most blocked domains            |
| top_queries          | jsonb     | Most queried domains            |


---

## Intermediate Models

Location: `models/intmdt/`

### intmdt_media_library

**File**: `intmdt_media_library.sql`

Aggregates and enriches media library data.

| Transformation | Description |
|----------------|-------------|
| Daily aggregation | Groups by date for trend analysis |
| Size calculations | Converts bytes to human-readable |
| Growth metrics | Calculates changes over time |

---

## Sources Configuration

**File**: `models/staging/sources.yml`

Defines connections from dbt to raw PostgreSQL tables.

```yaml
sources:
  - name: home_metrics_raw
    schema: public
    tables:
      - name: raw_media_library
      - name: raw_media_activity
      - name: raw_pihole_metrics
      - name: raw_power_consumption
      - name: raw_system_health
      - name: raw_n8n_alerts
      - name: raw_n8n_workflow_runs
```

### Referencing Sources in Models
```sql
SELECT * FROM {{ source('home_metrics_raw', 'raw_media_library') }}
```

---

## Common Commands

### Development
```bash
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\home_metrics_dbt"

# Test connection
dbt debug

# Install packages
dbt deps

# Run all models
dbt run

# Run specific model
dbt run --select stg_media_library

# Run model and all downstream
dbt run --select stg_media_library+

# Test all models
dbt test

# Build everything (run + test)
dbt build

# Build specific model with tests
dbt build --select stg_n8n_alerts
```

### Targeting
```bash
# Run all staging models
dbt run --select staging

# Run all models for a source
dbt run --select source:home_metrics_raw.raw_system_health+

# Run modified models only
dbt run --select state:modified+
```

### Documentation
```bash
# Generate docs
dbt docs generate

# Serve docs locally
dbt docs serve
```

---

## Model Configuration

### In dbt_project.yml
```yaml
models:
  home_metrics_dbt:
    staging:
      +materialized: view
      +schema: staging
    intmdt:
      +materialized: view
      +schema: intmdt
    marts:
      +materialized: table
      +schema: marts
```

### In Individual Models
```sql
{{ config(
    materialized='view',
    schema='staging'
) }}

SELECT ...
```

---

## Testing

### Generic Tests (in .yml files)
```yaml
models:
  - name: stg_media_library
    columns:
      - name: id
        tests:
          - unique
          - not_null
      - name: source
        tests:
          - accepted_values:
              values: ['plex', 'sonarr', 'radarr', 'prowlarr']
```

### Custom Tests (in tests/ folder)
```sql
-- tests/assert_no_negative_counts.sql
SELECT *
FROM {{ ref('stg_media_library') }}
WHERE item_count < 0
```

---

## Adding a New Model

1. **Create the SQL file**
   ```bash
   # models/staging/stg_new_source.sql
   ```

2. **Add the model pattern**
   ```sql
   {{ config(materialized='view', schema='staging') }}

   with source_data as (
       select * from {{ source('home_metrics_raw', 'raw_new_source') }}
   )

   select
       id,
       -- renamed/transformed columns
       recorded_at,
       inserted_at
   from source_data
   ```

3. **Create the YAML file**
   ```yaml
   # models/staging/stg_new_source.yml
   version: 2

   models:
     - name: stg_new_source
       description: "Description of the model"
       columns:
         - name: id
           tests:
             - unique
             - not_null
   ```

4. **Add source to sources.yml** (if new raw table)

5. **Test the model**
   ```bash
   dbt build --select stg_new_source
   ```

---

## Troubleshooting

### Source Not Found
```
Compilation Error: Model depends on source 'xxx' which was not found
```
**Fix**: Add the source to `models/staging/sources.yml`

### Column Does Not Exist
```
Database Error: column "xxx" does not exist
```
**Fix**: The raw table schema doesn't match. Either:
- Run ALTER TABLE to add the column
- Update the model to remove the column reference

### Connection Failed
```bash
# Test connection
dbt debug

# Check PostgreSQL is running
docker ps | grep postgres
```

### View Compiled SQL
```bash
dbt compile --select stg_media_library
cat target/compiled/home_metrics_dbt/models/staging/stg_media_library.sql
```
