{{ config( 
        materialized='view',
        schema='staging'
    )   }}


with hardware_sensors as (
    select
        hostname,
        sensor_type,
        sensor_name,
        value::float as sensor_value,
        recorded_at::date as recorded_date,
        date_trunc('second', recorded_at) as recorded_at_ts,
        inserted_at::date as inserted_date,
        inserted_at as inserted_at_ts
    from {{ source('home_metrics_raw', 'raw_hardware_sensors') }}
),
hardware_pivot as (
    select
        hostname,
        recorded_date,
        recorded_at_ts,
        inserted_date,
        max(inserted_at_ts) as inserted_at_ts,

        max(case when sensor_type = 'temperature' and sensor_name = 'Core (Tctl/Tdie)' then sensor_value end) as cpu_core_temp,
        max(case when sensor_type = 'clock'       and sensor_name = 'Cores (Average)'  then sensor_value end) as cpu_clock_speed,
        max(case when sensor_type = 'load'        and sensor_name = 'CPU Total'        then sensor_value end) as cpu_load,
        max(case when sensor_type = 'clock'       and sensor_name = 'GPU Core'         then sensor_value end) as gpu_clock_speed,
        max(case when sensor_type = 'load'        and sensor_name = 'GPU Core'         then sensor_value end) as gpu_usage

    from hardware_sensors
    group by
        hostname,
        recorded_date,
        recorded_at_ts, 
        inserted_date

)
select *
from hardware_pivot
order by recorded_at_ts desc
