{{ config(
    materialized='table',
    schema='intmdt'
) }}

with transactions_data as (
    select * from {{ ref('stg_teller_transactions') }}
),

accounts_data as (
    select * from {{ ref('stg_teller_accounts') }}
)

select
    transaction_pk,
    account_pk,
    account_skey,
    account_
    teller_transaction_id,
    transactions_data.teller_account_id,
    account_skey,
    transaction_date,
    transaction_description,
    transaction_amount,
    transaction_status,
    transaction_type,
    transaction_category,
    vendor_name,
    vendor_category,
    running_balance,
    transactions_data.inserted_at as transaction_inserted_at,
    transactions_data.updated_at as transaction_updated_at
from transactions_data t
left join accounts_data a
    on t.teller_account_id = a.teller_account_id 
    and t.account_skey = a.account_skey
