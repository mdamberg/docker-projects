{{ config(
    materialized='table',
    schema='marts'
)}}

WITH date_spine AS (
      SELECT generate_series(
          '2020-01-01'::date,
          '2030-12-31'::date,
          '1 day'::interval
      )::date AS date_day
  ),
  dim_date_cte as (
    SELECT
        to_char(date_day, 'YYYYMMDD')::int AS date_id,
        date_day,
        to_char(date_day, 'Day') AS day_of_week,
        (extract(ISODOW FROM date_day))::smallint AS day_of_week_num,
        date_trunc('month', date_day)::date AS month_start_date,
        (date_trunc('month', date_day) + interval '1 month' - interval '1 day')::date AS month_end_date,
        to_char(date_day, 'Month') AS month_name,
        extract(MONTH FROM date_day)::smallint AS month_number,
        date_trunc('year', date_day)::date AS year_start_date,
        extract(YEAR FROM date_day)::int AS year_num,
        extract(DOW FROM date_day) IN (0, 6) AS is_weekend,
        date_day = date_trunc('month', date_day)::date as is_bom
    from date_spine
  )

SELECT
    date_id,
    date_day,
    day_of_week,
    day_of_week_num,
    month_start_date,
    month_end_date,
    month_name,
    month_number,
    year_start_date,
    year_num,
    case when is_weekend = true then 1 else 0 end as is_weekend_flag,
    case when is_bom = true then 1 else 0 end as is_bom_flag
FROM dim_date_cte