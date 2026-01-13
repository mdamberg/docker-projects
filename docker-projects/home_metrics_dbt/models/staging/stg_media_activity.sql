{{ config( 
        materialized='view',
        schema='staging'
    )   }}

    with raw_media_activity as (

        select
            *
        from
            {{ source('home_metrics_raw', 'raw_media_activity') }}

    )

    select
        id,
        source,
        user_name,
        media_type,
        title,
        series_title,
        duration_seconds,
        watched_at,
        inserted_at,
        metadata
    from raw_media_activity