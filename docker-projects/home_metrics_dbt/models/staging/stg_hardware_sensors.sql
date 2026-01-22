{{ config( 
        materialized='view',
        schema='staging'
    )   }}


with src as (
    select
        hostname,
        sensor_type,
        sensor_name,
        sensor_id,
        hardware_name,
        hardware_type,
        value::float as sensor_value,
        unit,
        recorded_at,                               -- keep full precision
        date_trunc('second', recorded_at) as recorded_at_ts,  -- optional convenience
        inserted_at
    from {{ source('home_metrics_raw', 'raw_hardware_sensors') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['hostname']) }} as host_key,
    {{ dbt_utils.generate_surrogate_key(['hostname','sensor_id']) }} as sensor_key,

    -- pick ONE of these depending on your desired grain:
    {{ dbt_utils.generate_surrogate_key(['hostname','sensor_id','recorded_at']) }} as reading_key,
    hostname,
    sensor_type,
    sensor_name,
    sensor_id,
    sensor_value,
    hardware_name,
    hardware_type
from src
