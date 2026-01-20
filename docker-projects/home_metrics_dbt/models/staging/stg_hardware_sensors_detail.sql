{{ config( 
        materialized='view',
        schema='staging'
    )   }}


with detailed_sensors as (
    select
        id,
        hostname, 
        sensor_type,
        sensor_name,
        sensor_id,
        value,
        value_min,
        value_max, 
        unit,
        hardware_name,
        hardware_type,
        recorded_at ,
        inserted_at,
        metadata
    from {{ source('home_metrics_raw', 'raw_hardware_sensors') }}
)

select
    *
from detailed_sensors 