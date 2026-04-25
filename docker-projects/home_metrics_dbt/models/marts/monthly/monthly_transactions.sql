{{ config(
    materialized='table',
    schema='marts'
) }}

with months as (
    select  
        transaction_pk,
        account_key,
        category_key,
    
        dd.month_start_date,
        dd.month_end_date,
        dd.is_payweek,
    	transaction_date,
        account_type,
        account_name_friendly,
        last_four,
        transaction_description,
        category,
        transaction_type,
        transaction_amount,
        is_recurring
    from {{ ref('dim_date') }} dd 
    join {{ ref('fct_transactions') }} ft
    	on ft.transaction_date between dd.month_start_date and dd.month_end_date 
        and dd.month_start_date <= current_date
        and dd.is_bom_flag = 1
)
select * 
from months
