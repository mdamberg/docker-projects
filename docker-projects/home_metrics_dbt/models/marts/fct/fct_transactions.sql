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
        case    
            when transaction_category ilike '%STDNT LN%' then 'Student Loan'
                else transaction_category 
                    end as transaction_category,
        transaction_amount
    from {{ ref('stg_transactions') }}
)
select * from transactions