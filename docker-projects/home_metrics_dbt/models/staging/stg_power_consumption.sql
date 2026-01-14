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
        date_trunc('month', recorded_at)::date as month_recorded_at,
        recorded_at::date as recorded_date,
        recorded_at as recorded_datetime,
        id,
        entity_id,
        case
            when entity_id = 'sensor.basement_entertainment_center_current_consumption' then 'basement_entertainment_center'
            when entity_id = 'sensor.work_and_gaming_setup_current_consumption' then 'work_and_gaming_setup'
            else null
                end as power_entity,
        state::float as device_state,
        unit_of_measurement,
        device_class,
        inserted_at::date as inserted_date,
        inserted_at as inserted_datetime,
        attributes
    from raw_power_consumption