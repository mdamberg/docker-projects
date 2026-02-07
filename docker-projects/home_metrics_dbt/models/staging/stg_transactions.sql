
{{ config(
    materialized='view',
    schema='staging'
) }}

with transactions_data as (
    select
        *
    from {{ source('home_metrics_raw', 'raw_transactions') }}
),
cleaning as (
    select
        -- Primary key (unique row identifier)
        id as transaction_pk,
        -- Surrogate key for unique row identification
        {{ dbt_utils.generate_surrogate_key(['id']) }} as transaction_skey,
        -- Dimension keys (for grouping/joining)
        {{ dbt_utils.generate_surrogate_key(['account_name']) }} as account_key,
        {{ dbt_utils.generate_surrogate_key(['category']) }} as category_key,
        case
            when account_name like '%CHECKING%' then 'checking'
            when account_name like '%SAVINGS%' then 'savings'
            when account_name like '%CARD%'then 'credit'
                end as account_type,
        
        case
            when account_name = 'EVERYDAY CHECKING ...7868' then 'Matt Checking '
            when account_name = 'WAY2SAVE�� SAVINGS ...0999' then 'Jessica Savings'
            when account_name = 'WAY2SAVE�� SAVINGS ...8119' then 'Matt Savings'
            when account_name = 'WELLS FARGO CASH BACK VISA SIGNATURE�� CARD ...5766' then 'Matt Credit Card'
            when account_name = 'EVERYDAY CHECKING ...0325' then 'Jessica Checking'
            when account_name = 'PLATINUM CARD ...4113' then 'Jessica CapitalOne Credit Card'
            when account_name = 'WELLS FARGO CASH BACK VISA SIGNATURE® CARD ...2410' then 'Jessica WF Credit Card'
                end as account_name,
        account_number,
        case
            when account_number = '7868' then 'Matt'
            when account_number = '0325' then 'Jessica'
            when account_number = '8119' then 'Matt'
            when account_number = '5766' then 'Matt'
            when account_number = '0999' then 'Jessica'
            when account_number = '2410' then 'Jessica'
                end as account_holder,
        name as transaction_name,
        cast(amount as numeric(12,2)) * -1 as transaction_amount,   -- switched to negative for debits
        -- description, duplicate column
        category as transaction_category,
        cast(transaction_date as date) as transaction_date,
        cast({{ to_local_time('transaction_date') }} as time) as transaction_time,
        inserted_at::date as date_inserted,
        cast({{ to_local_time('inserted_at') }} as time) as time_of_insertion
    from transactions_data
)

select
    transaction_pk,
    transaction_skey,
    account_key,
    category_key,
    account_type,
    account_name,
    account_number,
    account_holder,
    transaction_name,
    case when transaction_amount > 0 then 'Credit' else 'Debit' end as transaction_type,
    transaction_amount,
    transaction_category,
    transaction_date,
    transaction_time,
    date_inserted,
    time_of_insertion
from cleaning