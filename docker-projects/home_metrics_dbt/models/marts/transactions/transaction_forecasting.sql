with pay_dates as (                                                                                                                                                                      select distinct
          month_start_date,                                                                                                                                                          
          week_start_date,                                                                                                                                                           
          is_payweek,
          case when is_payweek = 1 then 4300 end as bi_weekly_income
      from {{ ref('dim_date') }}
      where month_start_date >= '2025-02-01'
  ),
  monthly_expenses as (
      select
          month_start_date,
          sum(case when transaction_type = 'Debit' then transaction_amount end) as total_expenses,
          sum(case when transaction_type = 'Credit' then transaction_amount end) as actual_income
      from {{ ref('monthly_transactions') }}
      group by month_start_date
  )
  select
      p.month_start_date,
      p.week_start_date,
      p.bi_weekly_income,
      sum(p.bi_weekly_income) over(order by p.week_start_date) as rolling_income,
      sum(p.bi_weekly_income) over(partition by p.month_start_date) as months_income,
      sum(p.bi_weekly_income) over(
          partition by extract(year from p.month_start_date)
          order by p.week_start_date
      ) as rolling_yearly_income,
      me.total_expenses,
      me.actual_income,
      sum(p.bi_weekly_income) over(partition by p.month_start_date) + coalesce(me.total_expenses, 0) as monthly_net,
      p.is_payweek
  from pay_dates p
  left join monthly_expenses me
      on p.month_start_date = me.month_start_date
  order by p.week_start_date