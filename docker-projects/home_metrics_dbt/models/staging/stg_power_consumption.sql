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
        date_trunc('month', recorded_at) as month_recorded_at,
        id,
        entity_id,
        case
            when entity_id = 'sensor.basement_entertainment_center_current_consumption' then 'basement_entertainment_center'
            when entity_id = 'sensor.work_and_gaming_setup_current_consumption' then 'work_and_gaming_setup'
            else null
                end as power_entity,
        state as device_state,
        unit_of_measurement,
        device_class,
        recorded_at_ts,
        inserted_at_ts,
        attributes
    from raw_power_consumption