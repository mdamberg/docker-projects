# Intermediate Table Grain Definitions

This file documents the granularity for each intermediate model. Intermediate models join and transform staging models before loading into marts.

---

## System Monitoring

1. **int_desktop_metrics**
   - Grain: 1 row per 15-minute interval per hostname
   - Primary key: `system_health_id` + `interval_ts`
   - Joins: `stg_system_health` + `stg_hardware_sensors` (on 15-min interval)
   - Purpose: Aligns system health and hardware sensor data to same time grain for downstream fact table
