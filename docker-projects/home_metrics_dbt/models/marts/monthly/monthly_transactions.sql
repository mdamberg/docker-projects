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
),
transactions as (
	select
		ds.month_start_date,
		ds.month_end_date,
		transaction_skey,
		account_key,
		account_holder, 
		account_holder_key,
		account_name_friendly,
		last_four,
		account_type,
		account_subtype,
		teller_transaction_id,
		transaction_date,
		transaction_description,
		transaction_flow,
		transaction_type,
		transaction_amount_normalized
		category,
		sub_category,
		vendor_key,
		vendor_name,
		is_recurring,
		is_mapped,
		running_balance
	from date_spine ds 
	left join {{ ref('fct_transactions') }} ft
		on ft.transaction_date between ds.month_start_date and ds.month_end_date
		and transaction_status = 'posted'
)
select 
	account_key,
	account_holder,
	account_name_friendly,
	last_four,
	account_type,
	account_subtype,
	vendor_name,
	category,
	sub_category,
	sum(transaction_amount_normalized) as total_monthly_amount
from transactions
