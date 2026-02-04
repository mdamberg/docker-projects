
{{ config(
    materialized='view',
    schema='staging'
) }}

with transactions_data as (
    select
        *
    from {{ source('home_metrics_raw', 'raw_transactions') }}
)

select
    -- Primary key (unique row identifier)
    id as transaction_pk,
    -- Surrogate key for unique row identification
    {{ dbt_utils.generate_surrogate_key(['id']) }} as transaction_skey,
    -- Dimension keys (for grouping/joining)
    {{ dbt_utils.generate_surrogate_key(['account_name']) }} as account_key,
    {{ dbt_utils.generate_surrogate_key(['category']) }} as category_key,
    account_type,
    account_name,
    account_number,
    name as transaction_name,
    cast(amount as numeric(12,2)) as transaction_amount,
    description,
    category,
    cast(transaction_date as date) as transaction_date,
    cast({{ to_local_time('transaction_date') }} as time) as transaction_time,
    inserted_at::date as date_inserted,
    cast({{ to_local_time('inserted_at') }} as time) as time_of_insertion
from transactions_data