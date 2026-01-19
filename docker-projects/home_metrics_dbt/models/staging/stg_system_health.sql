{{ config(
    materialized='view',
    schema='staging'
) }}

with raw_system_health as (

    select
        id,
        'server_desktop' as hostname,
        hostname as hostname_id,
        recorded_at::date as recorded_date,
        recorded_at as recorded_at_ts,
        inserted_at::date as inserted_date,
        inserted_at as inserted_at_ts,
        cpu_percent,
        memory_percent as memory_usage_percent,
        disk_percent as disk_usage_percent,
        windows_logical_disk_read_latency_seconds_total as disk_read_latency_seconds,
        windows_logical_disk_write_latency_seconds_total as disk_write_latency_seconds,
        windows_logical_disk_read_bytes_total as disk_read_bytes_total,
        windows_logical_disk_write_bytes_total as disk_write_bytes_total
    from
        {{ source('home_metrics_raw', 'raw_system_health') }}
)

select
    *
from raw_system_health