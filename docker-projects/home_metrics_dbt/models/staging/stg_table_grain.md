# Staging Table Grain Definitions

This file documents the granularity for each staging model. Staging models are 1:1 with their source tables with light transformations (renaming, type casting, filtering).

---

## System Monitoring

1. **stg_system_health**
   - Grain: 1 row per system health collection (every 15 minutes per hostname)
   - Primary key: `id`
   - Source: `raw_system_health`

2. **stg_hardware_sensors**
   - Grain: 1 row per 15-minute interval per hostname (pivoted from raw sensor readings)
   - Primary key: `hostname` + `recorded_at_ts`
   - Source: `raw_hardware_sensors`
   - Note: Raw table has 1 row per sensor reading; staging pivots to 1 row per collection interval

---

## Media Tracking

3. **stg_media_activity**
   - Grain: 1 row per media watch event
   - Primary key: `id`
   - Source: `raw_media_activity`

4. **stg_media_library**
   - Grain: 1 row per library snapshot (per source + media_type + library_name + recorded_at)
   - Primary key: `id`
   - Source: `raw_media_library`

---

## Network Monitoring

5. **stg_pihole_metrics**
   - Grain: 1 row per pihole metrics snapshot (per pihole_instance per recorded_at)
   - Primary key: `id`
   - Source: `raw_pihole_metrics`

---

## Power Monitoring

6. **stg_power_consumption**
   - Grain: 1 row per power reading (per entity_id per recorded_at)
   - Primary key: `id`
   - Source: `raw_power_consumption`

---

## Workflow Monitoring (n8n)

7. **stg_n8n_workflow_runs**
   - Grain: 1 row per workflow execution
   - Primary key: `id`
   - Source: `raw_n8n_workflow_runs`

8. **stg_n8n_alerts**
   - Grain: 1 row per alert triggered
   - Primary key: `id`
   - Source: `raw_n8n_alerts`
