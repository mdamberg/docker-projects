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

category_map as (
    select * from {{ ref('map_transactions') }}
),

transactions_with_accounts as (
    select
        t.*,
        a.account_pk,
        a.account_holder,
        a.account_name_friendly,
        a.last_four,
        a.account_type,
        a.account_subtype
    from transactions_data t
    left join accounts_data a
        on t.teller_account_id = a.teller_account_id
),

mapped as (
    select
        t.*,
        m.custom_category,
        m.custom_subcategory,
        m.vendor_normalized,
        m.is_recurring,
        row_number() over (partition by t.transaction_pk order by length(m.description_pattern) desc) as match_rank
    from transactions_with_accounts t
    left join category_map m
        on t.transaction_description ilike '%' || m.description_pattern || '%'
),

best_match as (
    select * from mapped
    where match_rank = 1 or match_rank is null
),

enriched as (
    select
        -- Primary and Surrogate Keys
        transaction_pk,
        {{ dbt_utils.generate_surrogate_key(['transaction_pk']) }} as transaction_skey,

        -- Account Keys
        account_pk,
        account_key,

        -- Dimensional Keys (for Grouping)
        {{ dbt_utils.generate_surrogate_key(['account_holder']) }} as account_holder_key,
        {{ dbt_utils.generate_surrogate_key(['transaction_type']) }} as transaction_type_key,
        {{ dbt_utils.generate_surrogate_key(['coalesce(custom_category, transaction_category)']) }} as category_key,
        {{ dbt_utils.generate_surrogate_key(['coalesce(vendor_normalized, vendor_name, transaction_description)']) }} as vendor_key,

        -- Date Key
        date_key,

        -- Account Attributes
        account_holder,
        account_name_friendly,
        last_four,
        account_type,
        account_subtype,

        -- Transaction Identifiers
        teller_transaction_id,
        teller_account_id,

        -- Transaction Attributes
        transaction_date,
        transaction_description,
        transaction_amount,
        transaction_status,
        transaction_type,

        -- Category fields (mapped with fallback to original)
        coalesce(custom_category, transaction_category) as category,
        custom_subcategory as subcategory,
        transaction_category as teller_category,

        -- Vendor fields (mapped with fallback)
        coalesce(vendor_normalized, vendor_name, transaction_description) as vendor,
        vendor_name as teller_vendor_name,
        vendor_category as teller_vendor_category,

        -- Flags
        coalesce(is_recurring, false) as is_recurring,
        case when custom_category is not null then true else false end as is_mapped,

        running_balance,

        -- Timestamps
        inserted_at as transaction_inserted_at,
        updated_at as transaction_updated_at
    from best_match
)

select * from enriched
