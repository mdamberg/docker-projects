{{ config(
    materialized = 'table',
    schema = 'marts'
) }}

with accounts as (
    select 
        account_key,
        teller_account_id,
        account_holder,
        account_name_friendly,
        account_name,
        account_type,
        account_subtype,
        last_four,
        account_status,
        institution_name,
        institution_id,
        enrollment_id,
        inserted_at,
        updated_at
from {{ ref('stg_teller_accounts') }} 
)

select * from accounts