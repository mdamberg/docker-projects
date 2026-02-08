{{ config(
    materialized='table',
    schema='marts'
)}}


with sensors as (
        select  
            distinct hostname, 	-- foreign key
            sensor_type,
            sensor_name, 
            sensor_id,
            hardware_name,
            hardware_type
        from staging.stg_hardware_sensors shs 

)