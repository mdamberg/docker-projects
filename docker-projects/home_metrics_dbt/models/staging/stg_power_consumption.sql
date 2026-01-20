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
        date_trunc('month', rc.recorded_at)::date as month_recorded_at,
        rc.recorded_at::date as recorded_date,
        rc.recorded_at as recorded_datetime,
        rc.id,
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
        rc.inserted_at::date as inserted_date,
        rc.inserted_at as inserted_datetime,
        rc.attributes
    from raw_power_consumption rc
    join {{ ref('map_power_entity') }} mpe
        on rc.entity_id = mpe.entity_id