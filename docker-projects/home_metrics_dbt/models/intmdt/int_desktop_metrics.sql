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
            (floor(extract(minute from recorded_at_ts) / 15) * interval '15 minutes') as interval_ts,       -- rounds to 15 min intervals
        cpu_percent,
        memory_usage_percent,
        disk_usage_percent,
        disk_read_latency_seconds,
        disk_write_latency_seconds,
        disk_read_bytes_total,
        disk_write_bytes_total
    from {{ ref('stg_system_health') }}
),

hardware_sensors_raw as (
    select
        hostname,
        recorded_date,
        recorded_at_ts,
        inserted_date,
        inserted_at_ts,
        date_trunc('hour', recorded_at_ts) +
            (floor(extract(minute from recorded_at_ts) / 15) * interval '15 minutes') as interval_ts,       -- rounds to 15 min intervals
        cpu_core_temp,
        cpu_clock_speed,
        cpu_load,
        gpu_clock_speed,
        gpu_usage
    from {{ ref('stg_hardware_sensors') }}
),

-- Aggregate to ensure one row per interval_ts
hardware_sensors as (
    select
        {{ dbt_utils.generate_surrogate_key(['hostname', 'interval_ts']) }} as hardware_sensors_id,
        hostname,
        interval_ts,
        max(recorded_date) as recorded_date,
        max(recorded_at_ts) as recorded_at_ts,
        max(inserted_date) as inserted_date,
        max(inserted_at_ts) as inserted_at_ts,
        avg(cpu_core_temp) as cpu_core_temp,
        avg(cpu_clock_speed) as cpu_clock_speed,
        avg(cpu_load) as cpu_load,
        avg(gpu_clock_speed) as gpu_clock_speed,
        avg(gpu_usage) as gpu_usage
    from hardware_sensors_raw
    group by hostname, interval_ts
)

select
    sh.system_health_id,
    hs.hardware_sensors_id,
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
