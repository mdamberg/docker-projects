{{ config(
    materialized='view',
    schema='staging'
) }}

with raw_system_health as (

    select
    -- Generate a surrogate key for system_health_id using hostname
        {{ dbt_utils.generate_surrogate_key(['hostname']) }} as system_health_id,
    -- Generate a surrogate key for system_health_record_id using hostname and recorded_at
        {{ dbt_utils.generate_surrogate_key(['hostname', 'recorded_at']) }} as system_health_record_id,
        'server_desktop' as hostname,
        hostname as hostname_id,
        recorded_at::date as recorded_date,
        cast({{ to_local_time('recorded_at') }} as timestamp) as recorded_at_ts,
        inserted_at::date as inserted_date,
        cast({{ to_local_time('inserted_at') }} as timestamp) as inserted_at_ts,
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