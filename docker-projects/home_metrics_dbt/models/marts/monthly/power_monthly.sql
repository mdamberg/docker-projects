{{ config(
    materialized='table',
    schema='marts'
) }} 


with power_data as (
    select
        month_recorded_at,
        entity_name,
        power_entity,
        device_state
    from {{ ref('stg_power_consumption') }}
),
power_aggregated as (
    select
        month_recorded_at as month_recorded,
        entity_name,
        power_entity,
        sum(device_state::float) as total_monthly_draw_watts,
        max(device_state) as max_monthly_draw_watts,  
        round(cast(avg(device_state) as numeric), 2) as avg_monthly_draw_watts,
        min(device_state) as min_monthly_draw_watts
    from power_data
    group by month_recorded_at, entity_name, power_entity
)

select 
    month_recorded,
    entity_name,
    power_entity,
    total_monthly_draw_watts,
    max_monthly_draw_watts,
    avg_monthly_draw_watts,
    min_monthly_draw_watts
from power_aggregated
order by month_recorded