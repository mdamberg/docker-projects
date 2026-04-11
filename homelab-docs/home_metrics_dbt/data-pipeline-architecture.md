# Data Pipeline Architecture

## Overview

The Home Metrics data pipeline collects, transforms, and visualizes data from various homelab services. It follows a modern ELT (Extract, Load, Transform) pattern.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATA SOURCES                                       │
├─────────────┬─────────────┬─────────────┬─────────────┬─────────────────────┤
│   Plex/     │  Pi-hole    │  Windows    │    Home     │       n8n           │
│  Tautulli   │   DNS       │  Exporter   │  Assistant  │   (self-monitor)    │
│  Sonarr     │             │  (9182)     │             │                     │
│  Radarr     │             │             │             │                     │
└──────┬──────┴──────┬──────┴──────┬──────┴──────┬──────┴──────────┬──────────┘
       │             │             │             │                 │
       ▼             ▼             ▼             ▼                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         n8n WORKFLOWS (Extraction)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│  • Media Library Collection (every 6 hours)                                 │
│  • System Health Metrics (every 15 minutes)                                 │
│  • Pi-hole Metrics (every 6 hours)                                          │
│  • Power Consumption (continuous)                                           │
│  • Workflow Health Monitor (every 1 hour)                                   │
│  • Global Error Catcher (on any workflow failure)                           │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      PostgreSQL RAW TABLES (Loading)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│  • raw_media_library          • raw_system_health                           │
│  • raw_media_activity         • raw_pihole_metrics                          │
│  • raw_power_consumption      • raw_n8n_alerts                              │
│  • raw_n8n_workflow_runs                                                    │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      dbt STAGING MODELS (Transform)                         │
├─────────────────────────────────────────────────────────────────────────────┤
│  • stg_media_library          • stg_system_health                           │
│  • stg_media_activity         • stg_pihole_metrics                          │
│  • stg_power_consumption      • stg_n8n_alerts                              │
│  • stg_n8n_workflow_runs                                                    │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    dbt INTERMEDIATE MODELS (Transform)                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  • intmdt_media_library (aggregations, calculations)                        │
│  • (more to come...)                                                        │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       dbt MARTS MODELS (Transform)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│  • (coming soon - business-ready aggregated tables)                         │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         VISUALIZATION (Consume)                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  • Metabase Dashboards                                                      │
│  • Ad-hoc SQL Queries                                                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Components

### 1. Data Sources

| Source | What It Provides | Collection Method |
|--------|------------------|-------------------|
| Plex/Tautulli | Library stats, watch history | HTTP API |
| Sonarr | TV show library, episodes | HTTP API |
| Radarr | Movie library | HTTP API |
| Prowlarr | Indexer stats | HTTP API |
| Pi-hole | DNS queries, blocked domains | HTTP API |
| Windows Exporter | CPU, memory, disk, network metrics | Prometheus metrics (port 9182) |
| Home Assistant | Power consumption sensors | HTTP API |
| n8n | Workflow execution status, failures | Internal |

### 2. n8n Workflows

Workflows are stored in: `docker-projects/n8n/`

| Folder | Workflows |
|--------|-----------|
| `plex_media_workflows/` | Media Library Data Collection |
| `system_health_workflows/` | System Health Metrics Collection |
| `workflow_alerts/` | Global Error Catcher, Workflow Health Monitor |
| `power_consumption_workflows/` | Power Consumption Collection |
| `pi_hole_workflows/` | Pi-hole Metrics Collection |

### 3. PostgreSQL Raw Tables

Located in schema: `public`

All raw tables follow this pattern:
- `id` - Auto-incrementing primary key
- `*_at` timestamps - `recorded_at` (when data was captured), `inserted_at` (when inserted to DB)
- `metadata` - JSONB column for flexible additional data

### 4. dbt Models

Located in: `docker-projects/home_metrics_dbt/models/`

| Layer | Purpose | Materialization |
|-------|---------|-----------------|
| `staging/` | Clean, rename, cast raw data | View |
| `intmdt/` | Joins, aggregations, calculations | View/Table |
| `marts/` | Business-ready analytics tables | Table |

## Data Flow Example: System Health

```
1. Windows Exporter runs on desktop (port 9182)
         ↓
2. n8n "System Health Metrics Collection" workflow
   - Runs every 15 minutes
   - Fetches http://host.docker.internal:9182/metrics
   - Parses Prometheus format
   - Extracts CPU, memory, disk, network metrics
         ↓
3. Inserts into raw_system_health table
         ↓
4. dbt stg_system_health model
   - Cleans data
   - Casts types
   - Extracts metadata fields
         ↓
5. Metabase dashboard displays metrics
```

## Alerting Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    ALERT SOURCES                                 │
├────────────────────────┬────────────────────────────────────────┤
│  Workflow Failures     │  Stale/Missing Data                    │
│  (any workflow errors) │  (data not flowing)                    │
└───────────┬────────────┴───────────────┬────────────────────────┘
            │                            │
            ▼                            ▼
┌───────────────────────┐    ┌───────────────────────────────────┐
│  Global Error Catcher │    │  Workflow Health Monitor          │
│  (errorTrigger node)  │    │  (hourly schedule)                │
└───────────┬───────────┘    └───────────────┬───────────────────┘
            │                                │
            └────────────┬───────────────────┘
                         ▼
              ┌──────────────────────┐
              │   raw_n8n_alerts     │
              │   (unified table)    │
              └──────────┬───────────┘
                         │
            ┌────────────┴────────────┐
            ▼                         ▼
   ┌─────────────────┐       ┌─────────────────┐
   │  Discord Alert  │       │  Database Log   │
   │  (immediate)    │       │  (historical)   │
   └─────────────────┘       └─────────────────┘
```

## Key Files

| File | Purpose |
|------|---------|
| `temp_home_metrics_files/postgres/init/02-create-raw-tables.sql` | Raw table definitions |
| `docker-projects/home_metrics_dbt/models/staging/sources.yml` | dbt source definitions |
| `docker-projects/home_metrics_dbt/dbt_project.yml` | dbt project config |
| `~/.dbt/profiles.yml` | Database connection config |

## Common Operations

### Run all dbt models
```bash
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\home_metrics_dbt"
dbt build
```

### Check data freshness
```sql
SELECT * FROM v_data_freshness;
```

### View recent alerts
```sql
SELECT * FROM raw_n8n_alerts ORDER BY triggered_at DESC LIMIT 20;
```

### Check active alerts
```sql
SELECT * FROM raw_n8n_alerts WHERE resolved_at IS NULL;
```

## Ports Reference

| Service | Port | Purpose |
|---------|------|---------|
| PostgreSQL | 5432 | Database |
| n8n | 5678 | Workflow automation |
| Metabase | 3000 | Visualization |
| Windows Exporter | 9182 | System metrics |
| Tautulli | 8181 | Plex stats |
| Sonarr | 8989 | TV management |
| Radarr | 7878 | Movie management |
| Prowlarr | 9696 | Indexer management |
