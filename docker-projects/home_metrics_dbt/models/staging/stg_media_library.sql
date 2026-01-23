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
    {{ dbt_utils.generate_surrogate_key(['source']) }} as media_source_key,
    {{ dbt_utils.generate_surrogate_key(['source', 'media_type']) }} as media_type_key,
    source,
    media_type,
    case 
        when library_name = 'Unknown' and media_type = 'movie'  then 'radarr'
        when library_name = 'Unknown' and media_type = 'tv_show' then 'sonarr'
            end as library_name,
    total_size_bytes,
    recorded_at::date as date_recorded,
    recorded_at as recorded_at_ts,
    inserted_at::date as date_inserted,
    inserted_at as inserted_at_ts,
    metadata
from raw_media_library