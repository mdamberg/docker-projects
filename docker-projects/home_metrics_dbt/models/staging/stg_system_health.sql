{{ config(
    materialized='view',
    schema='staging'
) }}

with raw_system_health as (

    select
        id, 
        'server_desktop' as hostname,
        recorded_at::date as recorded_date,
        recoreded_at as recorded_at_ts,
        inserted_at::date as inserted_date,
        inserted_at_ts as inserted_at,
        memory_percent as memory_usage_percent,
        disk_percent as disk_usage_percent,
        temperature_c,
        windows_logical_disk_read_latency_seconds_total as disk_read_latency_seconds,
        windows_logical_disk_write_latency_seconds_total as disk_write_latency_seconds,
        windows_logical_disk_read_bytes_total as disk_read_bytes_total,
        windows_logical_disk_write_bytes_total as disk_write_bytes_total,
        windows_net_bytes_received_total as network_received_bytes_total,
        windows_net_bytes_sent_total as network_sent_bytes_total,
        windows_system_processor_queue_length as system_processor_queue_length,
        windows_os_paging_free_bytes as os_paging_free_bytes,
        windows_memory_commit_limit as memory_commit_limit,
        windows_memory_committed_bytes as memory_committed_bytes,
        metadata
    from
        {{ source('home_metrics_raw', 'raw_system_health') }}
)

select
    *
from raw_system_health