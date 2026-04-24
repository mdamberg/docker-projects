{{ config(
    materialized='view',
    schema='staging'
) }}


select
    id as balance_pk,
    teller_account_id,
    {{ dbt_utils.generate_surrogate_key(['teller_account_id']) }} as account_key,
    to_char(recorded_at, 'YYYYMMDD')::integer as date_key,
    ledger_balance,
    available_balance,
    recorded_at,
    inserted_at
from {{ source('home_metrics_raw', 'raw_teller_balances') }}