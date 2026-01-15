{{ config(
    materialized='view',
    schema='staging'
) }}

with raw_media_library as (
    select
        *
    from
        {{ source('home_metrics_raw', 'raw_media_library') }}
)
select
    recorded_at::date as date_recorded,
    recorded_at as recorded_at_ts,
    id,
    source,
    media_type,
    library_name,
    item_count,

    -- memory size conversions
    total_size_bytes,
    total_size_bytes / 1000000 as total_size_mb,
    total_size_bytes / 1000000000 as total_size_gb,

    inserted_at::date as date_inserted,
    inserted_at as inserted_at_ts,
    metadata
from raw_media_library