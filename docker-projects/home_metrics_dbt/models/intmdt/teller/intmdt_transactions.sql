{{ config(
    materialized='table',
    schema='intmdt'
) }}

with transactions_data as (
    select * from {{ ref('stg_teller_transactions') }}
),

accounts_data as (
    select * from {{ ref('stg_teller_accounts') }}
),

enriched as (
    select
        --Primary and Surrogate Keys
        t.transaction_pk,
        {{ dbt_utils.generate_surrogate_key(['t.transaction_pk']) }} as transaction_skey,

        -- Account Keys
        a.account_pk,
        a.account_key,

        --Dimensional Keys (for Grouping)
        {{ dbt_utils.generate_surrogate_key(['a.account_holder']) }} as account_holder_key,
        {{ dbt_utils.generate_surrogate_key(['t.transaction_type']) }} as transaction_type_key,
        {{ dbt_utils.generate_surrogate_key(['t.transaction_category']) }} as transaction_category_key,
        {{ dbt_utils.generate_surrogate_key(['t.vendor_name']) }} as vendor_key,

        -- Account Attributes
        a.account_holder,
        a.account_name_friendly,
        a.last_four,
        a.account_type,
        a.account_subtype,

        -- Transaction Identifiers
        t.teller_transaction_id,
        t.teller_account_id,
        
        -- Transaction Attributes
        t.transaction_date,
        t.transaction_description,
        t.transaction_amount,
        t.transaction_status,
        t.transaction_type,
        t.transaction_category,
        t.vendor_name,
        t.vendor_category,
        t.running_balance,

        -- Timestamps
        t.inserted_at as transaction_inserted_at,
        t.updated_at as transaction_updated_at
    from transactions_data t
    left join accounts_data a
        on t.teller_account_id = a.teller_account_id
)

select * from enriched
