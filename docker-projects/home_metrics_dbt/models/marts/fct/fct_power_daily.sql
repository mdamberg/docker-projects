-- This model serves to aggregate power consumption data on a daily basis.
{{ config(
    materialized='table',
    schema='marts'
) }}

with power_data as (
    select
        recorded_date,
        entity_name,
        power_entity,
        device_state
    from {{ ref('stg_power_consumption') }}
),
power_aggregated as (
    select
        recorded_date as date_recorded,
        entity_name,
        power_entity,
        sum(device_state) as total_daily_draw_watts,
        max(device_state) as max_daily_draw_watts,  
        round(cast(avg(device_state) as numeric), 2) as avg_daily_draw_watts,
        min(device_state) as min_daily_draw_watts
    from power_data
    group by recorded_date, entity_name, power_entity
)
select *
from power_aggregated
order by date_recorded
