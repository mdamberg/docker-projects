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
        id,
        entity_id,
        friendly_name,
        state as device_state,
        unit_of_measurement,
        device_class,
        recorded_at,
        inserted_at,
        attributes
    from raw_power_consumption