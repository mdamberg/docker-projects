{{ config(
    materialized='view',
    schema='staging'
) }}

with n8n_alerts as (
    select
        id,
        alert_type,
        severity,
        source,
        title,
        message,
        triggered_at,
        resolved_at,
        inserted_at,
        metadata
    from {{ source('home_metrics_raw', 'raw_n8n_alerts') }}
)

select
    -- Primary key (unique row identifier)
    id as alert_pk,
    -- Surrogate key for unique row identification
    {{ dbt_utils.generate_surrogate_key(['id', 'triggered_at']) }} as alert_skey,
    -- Dimension keys (for grouping/joining)
    {{ dbt_utils.generate_surrogate_key(['source', 'alert_type']) }} as alert_type_key,
    {{ dbt_utils.generate_surrogate_key(['source', 'alert_type', 'severity']) }} as alert_severity_key,
    alert_type,
    severity,
    source as alert_source,
    title,
    message,
    triggered_at,
    {{ to_local_time('triggered_at') }} as triggered_at_local,
    cast({{ to_local_time('triggered_at') }} as date) as date_triggered,
    cast({{ to_local_time('triggered_at') }} as time) as time_triggered,
    resolved_at,
    case when resolved_at is null then true else false end as is_active,
    inserted_at,
    metadata,
    metadata->>'execution_id' as execution_id,
    metadata->>'workflow_id' as workflow_id,
    metadata->>'last_node_executed' as failed_node
from n8n_alerts
