{{ config(
    materialized='view',
    schema='staging'
) }}

with raw_system_health as (

    select
        *
    from
        {{ source('home_metrics_raw', 'raw_system_health') }}
)

select
    id,
    hostname,
    cpu_percent as cpu_usage_percent,
    memory_percent as memory_usage_percent,
    disk_percent as disk_usage_percent,
    temperature_c,
    recorded_at,
    inserted_at,
    metadata
from raw_system_health