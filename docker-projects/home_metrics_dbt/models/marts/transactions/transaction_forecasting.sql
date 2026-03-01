  with pay_dates as (                                                                                                                                                                      select distinct
          month_start_date,                                                                                                                                                          
          week_start_date,
          is_payweek,
          case when is_payweek = 1 then 4300 end as bi_weekly_income
      from dim_date
      where month_start_date >= '2025-02-01'
  )
  select
      month_start_date,
      week_start_date,
      bi_weekly_income,
      sum(bi_weekly_income) over(order by week_start_date) as rolling_income,
      sum(bi_weekly_income) over(partition by month_start_date) as months_income,
      sum(bi_weekly_income) over(
          partition by extract(year from month_start_date)
          order by week_start_date
      ) as rolling_yearly_income,
      is_payweek
  from pay_dates