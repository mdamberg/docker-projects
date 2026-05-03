{{ config(
    materialized='table',
    schema='marts'
) }}

with power_consumption_entities as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['entity_name', 'power_entity']) }} as id,
        entity_name,
        power_entity,
        device_class
    from {{ ref('stg_power_consumption') }}

)

select 
    id,
    entity_name,
    power_entity,
    device_class
from power_consumption_entities
