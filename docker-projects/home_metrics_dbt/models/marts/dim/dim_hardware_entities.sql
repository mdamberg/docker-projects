{{ config(
    materialized='table',
    schema='marts'
) }}

with hardware_objects as (

    select
        distinct {{ dbt_utils.generate_surrogate_key(['hostname', 'sensor_name', 'sensor_id',]) }} as id,
        case when hostname = 'DESKTOP-QGA3DvB' then 'server_desktop' else hostname end as hostname,
        sensor_type,
        sensor_name,
        sensor_id,
        hardware_name,
        hardware_type
    from {{ ref('stg_hardware_sensors_detail') }}
)   
select
    *
from hardware_objects