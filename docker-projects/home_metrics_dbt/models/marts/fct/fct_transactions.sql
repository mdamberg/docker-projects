{{ config(
    materialized='table',
    schema='marts'
) }}


with transactions as (
    select
        transaction_pk,
        account_key,
        category_key,
        transaction_date,
        transaction_time,
        account_type,
        account_name,
        account_number,
        account_holder,
        transaction_name,
        transaction_type,
        case    
            when transaction_category ilike '%STDNT LN%' then 'Student Loan'
                else transaction_category 
                    end as transaction_category,
        transaction_amount,
        row_number() over( )
    from {{ ref('stg_transactions') }}
    where transaction_category not in ('Savings Transfer', 'Internal Transfer')
)
select * from transactions