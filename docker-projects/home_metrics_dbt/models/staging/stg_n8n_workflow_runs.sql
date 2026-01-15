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
    id,
    workflow_id,
    workflow_name,
    metadata->>'execution_id' as execution_id,
    status as workflow_status,
   
    cast(started_at as date) as date_started,
    cast(started_at as time) as time_started,
    
    cast(finished_at as date) as date_finished,
    cast(finished_at as time) as time_finished,
    
    cast(inserted_at as date) as date_inserted,
    cast(inserted_at as time) as time_of_insertion,
    metadata
from workflow_runs