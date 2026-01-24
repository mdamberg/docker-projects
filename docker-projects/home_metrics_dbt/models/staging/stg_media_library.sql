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
-- Dimension Key
    {{ dbt_utils.generate_surrogate_key(['source']) }} as media_source_key,
-- Media Type Key
    {{ dbt_utils.generate_surrogate_key(['source', 'media_type']) }} as media_type_key,
    source,
    media_type,
    case 
        when media_type = 'movie'  then 'radarr'
        when media_type = 'tv_show' then 'sonarr'
            end as library_name,
    title,
    genre,
    cast(year as varchar(15)) as year,
    ratings,
    recorded_at::date as date_recorded,
    recorded_at as recorded_at_ts,
    inserted_at::date as date_inserted,
    inserted_at as inserted_at_ts,
    metadata
from raw_media_library