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
    id,
    alert_type,
    severity,
    source as alert_source,
    title,
    message,
    triggered_at,
    cast(triggered_at as date) as date_triggered,
    cast(triggered_at as time) as time_triggered,
    resolved_at,
    case when resolved_at is null then true else false end as is_active,
    inserted_at,
    metadata,
    metadata->>'execution_id' as execution_id,
    metadata->>'workflow_id' as workflow_id,
    metadata->>'last_node_executed' as failed_node
from n8n_alerts
