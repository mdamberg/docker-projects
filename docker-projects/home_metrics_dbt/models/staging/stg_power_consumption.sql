{{ config(
        materialized='view',
        schema='staging'
    ) }}


    with raw_power_consumption as (

        select
            *
        from
            {{ source('home_metrics_raw', 'raw_power_consumption') }}
    )

    select
    -- Generate a surrogate key for unique power consumption records
        {{ dbt_utils.generate_surrogate_key(['id']) }} as power_consumption_record_id,
    -- Generate a surrogate key for power_consumption_id using entity_id and power_entity
        {{ dbt_utils.generate_surrogate_key(['rc.entity_id', 'power_entity']) }} as power_consumption_entity_id,
    -- Generate a surrogate key for power_consumption_record_id using entity_id    
        {{ dbt_utils.generate_surrogate_key(['rc.entity_id']) }} as power_consumption_record_entity,
        rc.entity_id,

        -- this method is not scalable and needs to be amended in the future
        case
            when rc.entity_id = 'sensor.basement_entertainment_center_current_consumption' then mpe.power_entity
            when rc.entity_id = 'sensor.work_and_gaming_setup_current_consumption' then mpe.power_entity
             when rc.entity_id = 'sensor.living_room_entertainment_wall_current_consumption' then mpe.power_entity
                else null
                    end as power_entity,
        rc.state::float as device_state,
        rc.unit_of_measurement,
        rc.device_class,
        date_trunc('month', rc.recorded_at)::date as month_recorded_at,
        rc.recorded_at::date as recorded_date,
        cast({{ to_local_time('rc.recorded_at') }} as timestamp) as recorded_datetime,
        rc.inserted_at::date as inserted_date,
        cast({{ to_local_time('rc.inserted_at') }} as timestamp) as inserted_datetime,
        rc.attributes
    from raw_power_consumption rc
    join {{ ref('map_power_entity') }} mpe
        on rc.entity_id = mpe.entity_id