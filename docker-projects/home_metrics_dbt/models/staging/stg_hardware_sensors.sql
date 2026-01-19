{{ config(
    materialized='view',
    schema='staging'
) }}

with hardware_sensors as (
    select
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
),
-- pivot table to match table grain of stg_system health and make join for intmd model easier. 

hardware_pivot as (
	select
		hostname,
		recorded_date,
		recorded_at_ts,
		inserted_date,
		inserted_at_ts,
		max(case when hs.sensor_type = 'temperature' and hs.sensor_name = 'Core (Tctl/Tdie)' then hs.sensor_value end) as cpu_core_temp,
		max(case when hs.sensor_type = 'clock' and hs.sensor_name = 'Cores (Average)' then hs.sensor_value end) as cpu_clock_speed,
		max(case when hs.sensor_type = 'load' and hs.sensor_name = 'CPU Total' then hs.sensor_value end) as cpu_load,
		max(case when hs.sensor_type = 'clock' and hs.sensor_name = 'GPU Core' then hs.sensor_value end) as gpu_clock_speed,
		max(case when hs.sensor_type = 'load' and hs.sensor_name = 'GPU Core' then hs.sensor_value end) as gpu_usage
	from hardware_sensors hs
	group by hostname, recorded_date, recorded_at_ts, inserted_date, inserted_at_ts
)
select * from hardware_pivot
