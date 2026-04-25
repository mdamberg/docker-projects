with accounts as (
    select 
        account_holder,
        account_name_friendly,
        account_name,
        account_type,
        account_subtype,
        last_four,
        account_status,
        institution_name,
        institution_id,
        account_key,
        teller_account_id,
        enrollment_id,
        account_type,
        account_subtype,
        inserted_at,
        updated_at
from {{ ref('stg_teller_accounts') }} 
)

select * from accounts