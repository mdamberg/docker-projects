{{ config(
    materialized='table',
    schema='marts'
) }}

-- Fact table for desktop health metrics
-- Grain: one row per 15-minute interval

with desktop_metrics as (
    select * from {{ ref('int_desktop_metrics') }}
),

date_dim as (
    select * from {{ ref('dim_date') }}
)

select
    -- Surrogate key
    {{ dbt_utils.generate_surrogate_key(['dm.system_health_id', 'dm.interval_ts']) }} as desktop_health_sk,

    -- Foreign keys
    dd.date_id,
    dm.system_health_id,

    -- Dimensions
    dm.hostname,
    dm.hostname_id,
    dm.recorded_date,
    dm.recorded_at_ts,
    dm.interval_ts,

    -- CPU metrics
    dm.cpu_percent,
    dm.cpu_core_temp,
    dm.cpu_clock_speed,
    dm.cpu_load,

    -- Memory metrics
    dm.memory_usage_percent,

    -- Disk metrics
    dm.disk_usage_percent,
    dm.disk_read_latency_seconds,
    dm.disk_write_latency_seconds,
    dm.disk_read_bytes_total,
    dm.disk_write_bytes_total,

    -- GPU metrics
    dm.gpu_clock_speed,
    dm.gpu_usage,

    -- Metadata
    dm.inserted_date,
    dm.inserted_at_ts
from desktop_metrics dm
left join date_dim dd
    on dm.recorded_date = dd.date_day