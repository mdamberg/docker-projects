{{ config( 
    materialized='table',
    schema='marts'
)}}

with hardware_sensors as (
        select  
            recorded_date,
            recorded_time,
            sensor_id,
            host_id,    -- foreign key
            hostname, 	-- foreign key
            sensor_type,
            sensor_name, 
            hardware_name,
            hardware_type,
            sensor_value
        from {{ ref('stg_hardware_sensors') }} shs
)
select 
    recorded_date,
    recorded_time,
    sensor_id,
    host_id,
    hostname,
    sensor_type,
    sensor_name, 
    hardware_name,
    hardware_type,
    sensor_value
from hardware_sensors