---
name: dbt-model
description: Generate dbt models following home_metrics_dbt conventions
---

# dbt Model Generation

Create dbt models for the home_metrics_dbt project following established conventions. This project tracks personal data: finances, power consumption, media activity, hardware sensors, n8n workflows, and system health.

## When to Use

- Adding a new data source to the analytics pipeline
- Creating new staging, intermediate, or mart models
- Adding dimensions or facts for existing data domains
- Building aggregations (monthly, weekly summaries)

## Project Structure

```
docker-projects/home_metrics_dbt/
├── models/
│   ├── staging/           # stg_* (views) - direct from source
│   │   └── sources.yml    # Source definitions
│   ├── intmdt/            # intmdt_* (tables) - transformations
│   └── marts/
│       ├── dim/           # dim_* (tables) - dimensions
│       ├── fct/           # fct_* (tables) - facts
│       ├── monthly/       # monthly_* (tables) - aggregates
│       └── <domain>/      # Domain-specific marts
├── seeds/                 # CSV reference data
├── macros/                # Custom macros
└── dbt_project.yml
```

## Layer Conventions

| Layer | Prefix | Materialization | Purpose |
|-------|--------|-----------------|---------|
| staging | `stg_` | view | Clean/rename raw source columns |
| intermediate | `intmdt_` | table | Complex transformations, joins |
| dimension | `dim_` | table | Descriptive attributes, slowly changing |
| fact | `fct_` | table | Measurable events/transactions |
| monthly | `monthly_` | table | Time-aggregated summaries |

## Process

### Phase 1: Understand the Data Source

1. **Identify the raw data location**
   - Is there already a `raw_*` table in Postgres?
   - Check `sources.yml` for existing sources
   - Determine the data's refresh frequency

2. **Document the data domain**
   - What does this data represent?
   - What questions will it answer?
   - How does it relate to existing domains?

### Phase 2: Create/Update Source Definition

3. **Add to sources.yml** (if new source)
   ```yaml
   # models/staging/sources.yml
   - name: raw_<domain>
     description: "Raw table containing <domain> data"
     loaded_at_field: inserted_at
     freshness:
       warn_after: {count: <N>, period: hour}
       error_after: {count: <N>, period: hour}
     columns:
       - name: id
         description: "Unique identifier"
       - name: <column>
         description: "<description>"
   ```

### Phase 3: Create Staging Model

4. **Create the staging SQL file**
   ```sql
   -- models/staging/stg_<domain>.sql
   {{ config(
       materialized='view',
       schema='staging'
   ) }}

   with raw_<domain> as (
       select *
       from {{ source('home_metrics_raw', 'raw_<domain>') }}
   )

   select
       -- Surrogate keys
       {{ dbt_utils.generate_surrogate_key(['id']) }} as <domain>_id,

       -- Dimensions
       <column> as <clean_name>,

       -- Dates (use to_local_time macro for timestamps)
       recorded_at::date as recorded_date,
       cast({{ to_local_time('recorded_at') }} as timestamp) as recorded_datetime,
       inserted_at::date as inserted_date,
       cast({{ to_local_time('inserted_at') }} as timestamp) as inserted_datetime

   from raw_<domain>
   ```

5. **Create the staging yml file**
   ```yaml
   # models/staging/stg_<domain>.yml
   version: 2

   models:
     - name: stg_<domain>
       description: "Staging table for <domain> data"
       columns:
         - name: <domain>_id
           description: "Surrogate key for <domain> record"
           tests:
             - not_null
             - unique
         - name: <column>
           description: "<description>"
           config:
             meta:
               dimension:
                 type: string  # or date, number, timestamp
   ```

### Phase 4: Create Intermediate Model (if needed)

6. **Create intermediate model for complex transformations**
   ```sql
   -- models/intmdt/intmdt_<domain>.sql
   {{ config(
       materialized='table',
       schema='intmdt'
   ) }}

   with staged as (
       select *
       from {{ ref('stg_<domain>') }}
   ),

   enriched as (
       select
           s.*,
           -- Add calculated fields, joins, etc.
       from staged s
       left join {{ ref('other_model') }} o
           on s.key = o.key
   )

   select * from enriched
   ```

### Phase 5: Create Mart Models

7. **Create dimension table** (for descriptive attributes)
   ```sql
   -- models/marts/dim/dim_<entity>.sql
   {{ config(
       materialized='table',
       schema='marts'
   ) }}

   with source as (
       select distinct
           <entity>_id,
           <entity>_name,
           <attribute_1>,
           <attribute_2>
       from {{ ref('stg_<domain>') }}
   )

   select * from source
   ```

8. **Create fact table** (for measurable events)
   ```sql
   -- models/marts/fct/fct_<domain>.sql
   {{ config(
       materialized='table',
       schema='marts'
   ) }}

   with <domain> as (
       select
           recorded_date,
           <entity>_id,
           <measure_1>,
           <measure_2>
       from {{ ref('intmdt_<domain>') }}  -- or stg_ if no intermediate
   )

   select * from <domain>
   ```

9. **Create monthly aggregation** (if applicable)
   ```sql
   -- models/marts/monthly/monthly_<domain>.sql
   {{ config(
       materialized='table',
       schema='marts'
   ) }}

   with daily as (
       select *
       from {{ ref('fct_<domain>') }}
   )

   select
       date_trunc('month', recorded_date)::date as month,
       <entity>_id,
       sum(<measure>) as total_<measure>,
       avg(<measure>) as avg_<measure>,
       count(*) as record_count
   from daily
   group by 1, 2
   ```

### Phase 6: Test and Document

10. **Run and test the models**
    ```powershell
    cd docker-projects/home_metrics_dbt

    # Run specific model
    dbt run --select stg_<domain>

    # Run model and downstream
    dbt run --select stg_<domain>+

    # Test the model
    dbt test --select stg_<domain>
    ```

11. **Verify in database**
    - Check row counts
    - Verify key uniqueness
    - Spot-check values

## SQL Style Guide

**Always follow these conventions:**

- **CTEs over subqueries** - Never use subqueries; use CTEs
- **Explicit columns** - No `SELECT *` in final select (staging CTE exception)
- **Lowercase keywords** - `select`, `from`, `where` (not `SELECT`)
- **Trailing commas** - Place commas at end of lines
- **Descriptive aliases** - `stg` not `s`, `transactions` not `t`
- **Clear CTE names** - `with staged as`, `with enriched as`

**Key generation:**
```sql
-- Use dbt_utils for surrogate keys
{{ dbt_utils.generate_surrogate_key(['column1', 'column2']) }} as entity_id
```

**Timezone handling:**
```sql
-- Use the to_local_time macro for timestamps
cast({{ to_local_time('recorded_at') }} as timestamp) as recorded_datetime
```

**Date extraction:**
```sql
recorded_at::date as recorded_date
date_trunc('month', recorded_at)::date as month_recorded_at
```

## Existing Data Domains

| Domain | Source Table | Staging | Description |
|--------|--------------|---------|-------------|
| Power | raw_power_consumption | stg_power_consumption | Smart plug readings |
| Media Activity | raw_media_activity | stg_media_activity | Plex/Sonarr/Radarr events |
| Media Library | raw_media_library | stg_media_library | Library contents |
| Hardware Sensors | raw_hardware_sensors | stg_hardware_sensors | CPU/GPU temps, fans |
| Transactions | raw_transactions | stg_transactions | Financial data |
| n8n Workflows | raw_n8n_workflow_runs | stg_n8n_workflow_runs | Automation runs |
| n8n Alerts | raw_n8n_alerts | stg_n8n_alerts | Workflow failures |
| System Health | raw_system_health | stg_system_health | CPU/memory/disk |
| Pi-hole | raw_pihole_metrics | stg_pihole_metrics | DNS stats |

## Common Macros

```sql
-- Timezone conversion (defined in macros/)
{{ to_local_time('column_name') }}

-- Surrogate key generation (from dbt_utils)
{{ dbt_utils.generate_surrogate_key(['col1', 'col2']) }}

-- Reference other models
{{ ref('model_name') }}

-- Reference source tables
{{ source('home_metrics_raw', 'raw_table_name') }}
```

## Checklist

- [ ] Source defined in sources.yml (if new)
- [ ] Staging model created with proper naming (stg_*)
- [ ] Staging yml with column descriptions and tests
- [ ] Intermediate model if complex transformations needed
- [ ] Dimension table for descriptive attributes
- [ ] Fact table for measurable events
- [ ] Monthly aggregation if time-series data
- [ ] All models run without errors (`dbt run`)
- [ ] Tests pass (`dbt test`)
- [ ] No subqueries used (CTEs only)
- [ ] Surrogate keys generated properly
- [ ] Timestamps use to_local_time macro
