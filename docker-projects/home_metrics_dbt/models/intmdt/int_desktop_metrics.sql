{{ config(
    materialized='view',
    schema='intermediate'
) }}

-- Joins hardware sensor data with system health data
-- Aligns timestamps to 15-minute intervals for consistent grain

with system_health as (
    select
        id as system_health_id,
        hostname,
        hostname_id,
        recorded_date,
        recorded_at_ts,
        inserted_date,
        inserted_at_ts,
        date_trunc('hour', recorded_at_ts) +
            (floor(extract(minute from recorded_at_ts) / 15) * interval '15 minutes') as interval_ts,
        cpu_percent,
        memory_usage_percent,
        disk_usage_percent,
        disk_read_latency_seconds,
        disk_write_latency_seconds,
        disk_read_bytes_total,
        disk_write_bytes_total
    from {{ ref('stg_system_health') }}
),

hardware_sensors as (
    select
        hostname,
        recorded_date,
        recorded_at_ts,
        inserted_date,
        inserted_at_ts,
        date_trunc('hour', recorded_at_ts) +
            (floor(extract(minute from recorded_at_ts) / 15) * interval '15 minutes') as interval_ts,
        cpu_core_temp,
        cpu_clock_speed,
        cpu_load,
        gpu_clock_speed,
        gpu_usage
    from {{ ref('stg_hardware_sensors') }}
)

select
    sh.system_health_id,
    sh.hostname,
    sh.hostname_id,
    sh.recorded_date,
    sh.recorded_at_ts,
    sh.interval_ts,
    sh.inserted_date,
    sh.inserted_at_ts,
    -- CPU metrics
    sh.cpu_percent,
    hs.cpu_core_temp,
    hs.cpu_clock_speed,
    hs.cpu_load,
    -- Memory metrics
    sh.memory_usage_percent,
    -- Disk metrics
    sh.disk_usage_percent,
    sh.disk_read_latency_seconds,
    sh.disk_write_latency_seconds,
    sh.disk_read_bytes_total,
    sh.disk_write_bytes_total,
    -- GPU metrics
    hs.gpu_clock_speed,
    hs.gpu_usage
from system_health sh
left join hardware_sensors hs
    on sh.interval_ts = hs.interval_ts
