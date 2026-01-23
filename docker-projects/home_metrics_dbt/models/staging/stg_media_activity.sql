{{ config( 
        materialized='view',
        schema='staging'
    )   }}

    with raw_media_activity as (

        select
            source,
            user_name,
            media_type,
            title,
            series_title,
            duration_seconds:: int as duration_seconds,
            watched_at::timestamp as watched_at,
            inserted_at::timestamp as inserted_at,
            metadata
        from
            {{ source('home_metrics_raw', 'raw_media_activity') }}

    ),

    dedupe as (
        select
            *,
            row_number() over(partition by source, user_name, media_type, title, coalesce(series_title, '') order by inserted_at desc) as rn
        from raw_media_activity
    )

    select
        {{ dbt_utils.generate_surrogate_key(['source']) }} as media_source_key,
        {{ dbt_utils.generate_surrogate_key(['source', 'user_name']) }} as user_key,
        {{ dbt_utils.generate_surrogate_key(['source','user_name','watched_at', 'media_type', 'title',  "coalesce(series_title, '')"]) }} as media_activity_key,
        source,
        user_name,
        media_type,
        title,
        series_title,
        duration_seconds,
        watched_at,
        inserted_at,
        metadata
    from dedupe
    where rn = 1