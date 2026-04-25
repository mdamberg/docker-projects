{{ config(
    materialized='table',
    schema='marts'
) }}


with transactions as (
    select
        
        -- Primary and Surrogate Keys
        transaction_pk,
        transaction_skey,  
        
        -- Date Key
        date_key,
        
        -- Account Keys
        account_pk,
        account_key,
        
        -- Account Attributes
        account_holder_key,
        transaction_type_key,
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
        row_number() over(partition by vendor_key order by transaction_date) as vendor_transaction_num,
        
        -- Category fields (mapped with fallback to original)
        category_key,
        category,
        subcategory,
        teller_category,
        
        -- Vendor fields (mapped with fallback)
        vendor_key,
        vendor,
        teller_vendor_name,
        teller_vendor_category,
        
        -- Flags
        is_recurring,
        is_mapped,
        running_balance,
        
        -- Timestamps
        transaction_inserted_at,
        transaction_updated_at

    from {{ ref('intmdt_transactions') }}
)

select * from transactions