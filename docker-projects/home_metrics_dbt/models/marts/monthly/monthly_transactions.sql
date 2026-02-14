with months as (
    select  
        dd.month_start_date ,
        dd.month_end_date ,
    	transaction_date,
        account_type,
        account_name,
        account_number,
        transaction_name,
        transaction_category,
        transaction_amount
    from {{ ref('dim_date') }} dd 
    left join {{ ref('fct_transactions') }} ft
    	on ft.transaction_date between dd.month_start_date and dd.month_end_date 
)
select * 
from months
