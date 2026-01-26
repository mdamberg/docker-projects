{{ config( 
        materialized='view',
        schema='staging'
    )   }}


with sensors as (
    select
        hostname,
        sensor_type,
        sensor_name,
        sensor_id,
        hardware_name,
        hardware_type,
        value::float as sensor_value,
        value_min::float as sensor_value_min,
        value_max::float as sensor_value_max,
        unit,
        recorded_at,
        recorded_at::date as recorded_date,
        inserted_at as inserted_at_ts,
        metadata
    from {{ source('home_metrics_raw', 'raw_hardware_sensors') }}
),

deduplication as (
    select
        *,
        row_number()over(partition by hostname, sensor_id, recorded_at order by inserted_at_ts desc) as rn
    from sensors
)

select
    -- host row key
    {{ dbt_utils.generate_surrogate_key(['hostname']) }} as host_key,
    -- sensor row key
    {{ dbt_utils.generate_surrogate_key(['hostname','sensor_id']) }} as sensor_key,
    -- table grain key
    {{ dbt_utils.generate_surrogate_key(['hostname','sensor_id','recorded_at']) }} as reading_key,

    hostname,
    sensor_type,
    sensor_name,
    sensor_id,
    hardware_name,
    hardware_type,
    sensor_value,
    sensor_value_min,
    sensor_value_max,
    unit,
    cast({{ to_local_time('recorded_at') }} as timestamp) as recorded_at,
    recorded_date,
    cast({{ to_local_time('inserted_at_ts') }} as timestamp) as inserted_at_ts,
    metadata
from deduplication
where rn = 1