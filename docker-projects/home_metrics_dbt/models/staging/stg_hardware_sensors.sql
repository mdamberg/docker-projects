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
        case
            when sensor_name like '%D3D%' then 'GeForce 3070Ti'
            when sensor_name like 'GPU%' then 'GeForce 3070Ti'
            when sensor_name like 'Network Utilization' then 'Network Adapter'
                else hardware_name end as hardware_name,
        case 
            when sensor_name like 'GPU%' then 'GPU' 
            when sensor_name like '%D3D%' then 'GPU' 
                else sensor_name end as hardware_type,
        value::float as sensor_value,
        unit,
        recorded_at,                               -- keep full precision
        date_trunc('second', recorded_at) as recorded_at_ts,  -- optional convenience
        inserted_at
    from {{ source('home_metrics_raw', 'raw_hardware_sensors') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['hostname']) }} as host_id,
    {{ dbt_utils.generate_surrogate_key(['hostname','sensor_id']) }} as sensor_key,

    -- pick ONE of these depending on your desired grain:
    {{ dbt_utils.generate_surrogate_key(['hostname','sensor_id','recorded_at']) }} as host_record_id,
    recorded_at::date as recorded_date,
    cast({{ to_local_time('recorded_at') }} as time) as recorded_time,
    inserted_at::date as inserted_date,
    cast({{ to_local_time('inserted_at') }} as time) as inserted_time,
    hostname,
    sensor_type,
    sensor_name,
    sensor_id,
    sensor_value,
    hardware_name,
    hardware_type
from src
