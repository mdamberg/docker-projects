{{ config(
    materialized='table',
    schema='intermediate'
) }}


with power_consumption as (
	select
		recorded_date,
		cast(recorded_datetime as time) as recorded_at_time,
		power_consumption_record_id,
		power_consumption_entity_id,
		entity_name ,
		power_entity,
		device_state,
		case when unit_of_measurement = 'W' then 'Watts' else 'unknown' end as unit_of_measurement,
		inserted_date,
		cast(inserted_datetime as time) as inserted_at_time 
	from {{ ref('stg_power_consumption') }}
)
select * from power_consumption