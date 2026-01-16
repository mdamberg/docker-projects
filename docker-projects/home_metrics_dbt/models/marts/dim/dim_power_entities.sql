{{ config(
    materialized='table',
    schema='marts'
) }}

with power_consumption_entities as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['entity_id', 'power_entity']) }} as id,
        entity_id,
        power_entity,
        device_class
    from {{ ref('stg_power_consumption') }}

)

select *
from power_consumption_entities
