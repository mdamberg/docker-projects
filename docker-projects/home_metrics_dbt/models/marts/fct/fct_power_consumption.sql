{{ config(
    materialized='table',
    schema='marts'
) }}


with power_consumption as (
    select
        recorded_date,
        recorded_at_time,
        power_consumption_record_id,
        power_consumption_entity_id,
        entity_name,
        power_entity,
        device_state,
        unit_of_measurement,
        inserted_date,
        inserted_at_time 
    from {{ ref('intmdt_power_consumption') }}
)

select * from power_consumption