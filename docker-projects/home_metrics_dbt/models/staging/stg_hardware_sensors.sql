{{ config(
    materialized='view',
    schema='staging'
) }}

with hardware_sensors as (
    select
        id,
        hostname,
        sensor_type,
        sensor_name,
        sensor_id,
        value as sensor_value,
        value_min,
        value_max,
        unit,
        hardware_name,
        hardware_type,
        recorded_at::date as recorded_date,
        recorded_at as recorded_at_ts,
        inserted_at::date as inserted_date,
        inserted_at as inserted_at_ts,
        metadata
    from {{ source('home_metrics_raw', 'raw_hardware_sensors') }}
)

select
    id,
    hostname,
    sensor_type,
    sensor_name,
    sensor_id,
    sensor_value,
    value_min,
    value_max,
    unit,
    hardware_name,
    hardware_type,
    recorded_date,
    recorded_at_ts,
    inserted_date,
    inserted_at_ts,
    metadata
from hardware_sensors