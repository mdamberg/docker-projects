{{config(
    materialized='table',
    schema='marts'
)}}


-- n8n entities from stg_n8n_workflow_runs and stg_n8n_alerts

with n8n_workflow_entities as (

    select
        distinct 
        {{ dbt_utils.generate_surrogate_key(['workflow_id', 'workflow_name']) }} as id,
        workflow_id,
        workflow_name
    from {{ ref('stg_n8n_workflow_runs') }}
)

select
    id,
    workflow_id,
    workflow_name
from n8n_workflow_entities

