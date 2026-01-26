{{ config(
    materialized='view',
    schema='staging'
) }}


with workflow_runs as (
    select
        id,
        workflow_id,
        workflow_name,
        status,
        started_at,
        finished_at,
        inserted_at,
        metadata
    from {{ source('home_metrics_raw', 'raw_n8n_workflow_runs') }}
)

select
    -- Primary key (unique row identifier)
    id as workflow_run_pk,
    -- Surrogate key for unique row identification
    {{ dbt_utils.generate_surrogate_key(['id']) }} as workflow_run_skey,
    -- Dimension keys (for grouping/joining)
    {{ dbt_utils.generate_surrogate_key(['workflow_id']) }} as workflow_key,
    {{ dbt_utils.generate_surrogate_key(['workflow_id', 'status']) }} as workflow_status_key,
    workflow_id,
    workflow_name,
    metadata->>'execution_id' as execution_id,
    status as workflow_status,
   
    cast(started_at as date) as date_started,
    cast({{ to_local_time('started_at') }} as time) as time_started,
    
    cast(finished_at as date) as date_finished,
    cast({{ to_local_time('finished_at') }} as time) as time_finished,
    
    cast(inserted_at as date) as date_inserted,
    cast({{ to_local_time('inserted_at') }} as time) as time_of_insertion,
    metadata
from workflow_runs