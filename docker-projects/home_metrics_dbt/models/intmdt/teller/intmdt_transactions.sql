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
    t.transaction_pk,
    a.account_pk,
    a.account_skey,
    a.account_holder,
    a.account_name_friendly,
    a.last_four,
    a.account_type,
    a.account_subtype,
    t.teller_transaction_id,
    t.teller_account_id,
    transaction_date,
    transaction_description,
    transaction_amount,
    transaction_status,
    transaction_type,
    transaction_category,
    vendor_name,
    vendor_category,
    running_balance,
    t.inserted_at as transaction_inserted_at,
    t.updated_at as transaction_updated_at
from transactions_data t
left join accounts_data a
    on t.teller_account_id = a.teller_account_id 
    and t.account_skey = a.account_skey

