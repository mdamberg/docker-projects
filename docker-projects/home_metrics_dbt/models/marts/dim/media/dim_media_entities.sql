{{ config(
    materialized='table',
    schema='marts'
) }}

-- media entities

with media_entities as (

    select
        distinct 
        {{ dbt_utils.generate_surrogate_key(['source', 'media_type', 'library_name']) }} as id,
        source,
        media_type,
        library_name
    from {{ ref('stg_media_library') }}
)

select 
    id,
    source,
    media_type,
    library_name
from media_entities