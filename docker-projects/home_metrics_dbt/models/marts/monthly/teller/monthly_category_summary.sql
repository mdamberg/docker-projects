{{ config(
    materialized='table',
    schema='marts'
) }}
with date_spine as (
	select
		month_start_date,
		month_end_date,
		month_number
	from {{ ref('dim_date') }}
	where is_bom_flag = 1
	and month_start_date <= current_date
),
transactions as (
	select
		ds.month_start_date,
		ds.month_end_date,
		account_key,
		transaction_flow,
		transaction_amount_normalized,
		category,
		running_balance
	from date_spine ds 
	left join {{ ref('fct_transactions') }} ft
		on ft.transaction_date between ds.month_start_date and ds.month_end_date
	where 
		(transaction_status = 'posted' and ft.account_key is not null)
)
select 
	{{ dbt_utils.generate_surrogate_key(['month_start_date', 'month_end_date', 'account_key', 'category']) }} as monthly_transaction_skey,
	month_start_date,
	month_end_date,
	account_key,
	category,
	sum(case when transaction_flow = 'debit' then transaction_amount_normalized
		else 0 end) as total_expenses,
	sum(case when transaction_flow = 'credit' then transaction_amount_normalized
		else 0 end) as total_income,
	sum(transaction_amount_normalized) as net_income,
	max(running_balance) as max_monthly_balance,
	min(running_balance) as min_running_balance
from transactions
group by month_start_date, month_end_date, account_key, category