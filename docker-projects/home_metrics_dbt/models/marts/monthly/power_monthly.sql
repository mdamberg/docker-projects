{{ config(
    materialized='table',
    schema='marts'
) }} 


with power_data as (
    select
        month_recorded_at,
        entity_id,
        power_entity,
        device_state
    from {{ ref('stg_power_consumption') }}
),
power_aggregated as (
    select
        month_recorded_at as month_recorded,
        entity_id,
        power_entity,
        sum(device_state) as total_monthly_draw_watts,
        max(device_state) as max_monthly_draw_watts,  
        round(cast(avg(device_state) as numeric), 2) as avg_monthly_draw_watts,
        min(device_state) as min_monthly_draw_watts
    from power_data
    group by month_recorded_at, entity_id, power_entity
)

select 
    *
from power_aggregated
order by month_recorded