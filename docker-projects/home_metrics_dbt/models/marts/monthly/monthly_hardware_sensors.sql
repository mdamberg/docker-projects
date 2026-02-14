{{ config(
    materialized='table',
    schema='marts'
)}}

with date_spine as (
    select distinct
        month_start_date,
        month_end_date
    from {{ ref('dim_date') }}
),

sensors as (
    select
        ds.month_start_date,
        fh.host_id,
        fh.hostname,
        fh.sensor_name || '_' || fh.sensor_type as sensor_full_name,
        fh.sensor_value
    from date_spine ds
    inner join {{ ref('fct_hardware_sensor') }} fh
        on fh.recorded_date between ds.month_start_date and ds.month_end_date
    where fh.sensor_name || '_' || fh.sensor_type in (
        'GPU Core_voltage',
        'GPU Package_power',
        'CPU Total_load',
        'GPU Core_load',
        'Temperature_temperature',
        'GPU Core_temperature',
        'GPU Core_clock',
        'Core (Tctl/Tdie)_temperature',
        'Memory_load',
        'GPU Memory_clock',
        'GPU Fan_fan',
        'Used Space_load',
        'Package_power'
    )
)

select
    month_start_date,
    host_id,
    hostname,
    sensor_full_name,
    round(avg(sensor_value)::numeric, 2) as avg_value,
    round(min(sensor_value)::numeric, 2) as min_value,
    round(max(sensor_value)::numeric, 2) as max_value
from sensors
group by
    month_start_date,
    host_id,
    hostname,
    sensor_full_name
