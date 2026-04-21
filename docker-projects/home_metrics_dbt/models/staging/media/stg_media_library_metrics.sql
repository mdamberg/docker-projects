{{
    config(materialized='view', 
    schema='staging')
}}



with raw_media_library_metrics as (

    select
        id,
        source,
        media_type,
        library_name,
        item_count,
        coalesce(total_size_bytes,0) as total_size_bytes,
        recorded_at::date as date_recorded,
        recorded_at as recorded_at_ts,
        inserted_at::date as date_inserted,
        inserted_at as inserted_at_ts,
        metadata
    from
        {{ source('home_metrics_raw', 'raw_media_library_metrics') }}

),

dedupe as (
    select
        *,
        row_number() over(partition by source, media_type, library_name, date_recorded order by date_inserted desc) as rn
    from raw_media_library_metrics
)

select
-- media source identifier
    {{ dbt_utils.generate_surrogate_key(['source']) }} as media_source_key,
-- Library identifier
    {{ dbt_utils.generate_surrogate_key(['source' ,'library_name']) }} as library_key,
-- Snapshot identifier
    {{ dbt_utils.generate_surrogate_key(['source', 'library_name', 'date_recorded']) }} as library_snapshot_key,
    source,
    media_type,
    library_name,
    item_count,
    total_size_bytes,
    date_recorded,
    cast({{ to_local_time('recorded_at_ts') }} as timestamp) as recorded_at_ts,
    date_inserted,
    cast({{ to_local_time('inserted_at_ts') }} as timestamp) as inserted_at_ts,
    metadata
from dedupe
where rn = 1