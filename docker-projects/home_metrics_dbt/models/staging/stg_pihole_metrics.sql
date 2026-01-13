{{ config(
    materialized='view',
    schema='staging'
) }}

with raw_pihole_metrics as (

    select
        *
    from
        {{ source('home_metrics_raw', 'raw_pihole_metrics') }}
)

select  
    id,
    pihole_instance,
    blocked_queries,
    percent_blocked,
    unique_domains,
    unique_clients,
    recorded_at,
    inserted_at,
    top_blocked_domains,
    top_queries,
    metadata
from raw_pihole_metrics