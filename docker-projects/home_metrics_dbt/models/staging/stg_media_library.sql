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
    id,
    source,
    media_type,
    library_name,
    item_count,
    total_size_bytes,
    recorded_at,
    inserted_at,
    metadata
from raw_media_library