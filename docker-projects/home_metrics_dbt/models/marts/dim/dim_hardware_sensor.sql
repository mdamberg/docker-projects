{{ config(
    materialized='table',
    schema='marts'
)}}


with sensors as (
        select  
            distinct sensor_id,
            host_id,    -- foreign key
            hostname, 	-- foreign key
            sensor_type,
            sensor_name, 
            hardware_name,
            hardware_type
        from {{ ref('stg_hardware_sensors') }} shs
)

select 
    sensor_id,
    host_id,
    hostname,
    sensor_type,
    sensor_name, 
    hardware_name,
    hardware_type
from sensors