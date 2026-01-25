# DBT Key Design Cheat Sheet

## Key Types Overview

| Key Type      | Suffix  | Unique?         | Purpose                         | Example                                       |
|----------     |-------- |---------        |---------                        |---------                                      |
| Primary Key   | `_pk`   | Yes             | Raw table's original ID         | `id as alert_pk`                              |
| Surrogate Key | `_skey` | Yes             | Hashed unique row identifier    | `generate_surrogate_key(['id', 'timestamp'])` |
| Dimension Key | `_key`  | No (1-to-many)  | Grouping/joining to dimensions  | `generate_surrogate_key(['source', 'type'])`  |

---

## Naming Conventions

```
{entity}_{descriptor}_pk     -- Primary key (from raw table)
{entity}_{descriptor}_skey   -- Surrogate key (unique per row)
{entity}_{descriptor}_key    -- Dimension key (shared across rows)
```

### Examples
```sql
-- Unique identifiers
id as order_pk                    -- Raw table's ID
workflow_run_skey                 -- Surrogate for workflow runs
alert_skey                        -- Surrogate for alerts

-- Dimension keys (1-to-many)
customer_key                      -- Groups all orders by customer
workflow_status_key               -- Groups runs by workflow + status
alert_type_key                    -- Groups alerts by source + type
```

---

## When to Use Each Key Type

### Primary Key (`_pk`)
- **Use when:** You want to preserve the raw table's unique identifier
- **Source:** Directly from raw table's `id` column
- **Always unique:** Yes

```sql
id as order_pk,
```

### Surrogate Key (`_skey`)
- **Use when:** You need a hashed unique identifier (useful for slowly changing dimensions, hiding raw IDs)
- **Source:** Hash of columns that uniquely identify a row
- **Always unique:** Yes (if based on unique columns)

```sql
{{ dbt_utils.generate_surrogate_key(['id']) }} as order_skey,

-- Or with multiple columns for composite uniqueness
{{ dbt_utils.generate_surrogate_key(['id', 'recorded_at']) }} as reading_skey,
```

### Dimension Key (`_key`)
- **Use when:** You need to group rows or join to dimension tables
- **Source:** Hash of dimension attributes
- **Always unique:** No - multiple rows share the same key

```sql
-- All orders from same customer share this key
{{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_key,

-- All alerts of same type from same source share this key
{{ dbt_utils.generate_surrogate_key(['source', 'alert_type']) }} as alert_type_key,
```

---

## Common Patterns

### Pattern 1: Basic Staging Model
```sql
select
    -- Primary key (unique row identifier)
    id as {entity}_pk,

    -- Surrogate key (hashed unique identifier)
    {{ dbt_utils.generate_surrogate_key(['id']) }} as {entity}_skey,

    -- Dimension keys (for grouping/joining)
    {{ dbt_utils.generate_surrogate_key(['category']) }} as category_key,
    {{ dbt_utils.generate_surrogate_key(['category', 'status']) }} as category_status_key,

    -- Other columns...
from {{ source('raw', 'table') }}
```

### Pattern 2: Time-Series Data
```sql
select
    -- Unique per reading
    id as reading_pk,
    {{ dbt_utils.generate_surrogate_key(['id', 'recorded_at']) }} as reading_skey,

    -- Dimension keys
    {{ dbt_utils.generate_surrogate_key(['sensor_id']) }} as sensor_key,
    {{ dbt_utils.generate_surrogate_key(['sensor_id', 'sensor_type']) }} as sensor_type_key,

    -- Time dimensions
    recorded_at,
    cast(recorded_at as date) as date_recorded,
from {{ source('raw', 'sensor_readings') }}
```

### Pattern 3: Event/Activity Data
```sql
select
    -- Unique per event
    id as event_pk,
    {{ dbt_utils.generate_surrogate_key(['id', 'event_time']) }} as event_skey,

    -- Dimension keys
    {{ dbt_utils.generate_surrogate_key(['user_id']) }} as user_key,
    {{ dbt_utils.generate_surrogate_key(['event_type']) }} as event_type_key,
    {{ dbt_utils.generate_surrogate_key(['user_id', 'event_type']) }} as user_event_key,

from {{ source('raw', 'events') }}
```

---

## Common Mistakes to Avoid

### 1. Referencing aliases in surrogate key generation
```sql
-- WRONG: 'workflow_status' is an alias defined later
{{ dbt_utils.generate_surrogate_key(['workflow_id', 'workflow_status']) }} as key,
status as workflow_status,  -- alias defined here

-- CORRECT: Use the actual column name
{{ dbt_utils.generate_surrogate_key(['workflow_id', 'status']) }} as key,
status as workflow_status,
```

### 2. Naming dimension keys like unique keys
```sql
-- CONFUSING: 'alert_id' sounds unique but it's 1-to-many
{{ dbt_utils.generate_surrogate_key(['source', 'type']) }} as alert_id,

-- CLEAR: '_key' suffix indicates it's a dimension key
{{ dbt_utils.generate_surrogate_key(['source', 'type']) }} as alert_type_key,
```

### 3. Using unique tests on dimension keys
```yaml
# WRONG: This will fail - dimension keys are not unique per row
columns:
  - name: customer_key
    tests:
      - unique  # Will fail!

# CORRECT: Only test uniqueness on _pk and _skey columns
columns:
  - name: order_pk
    tests:
      - unique
      - not_null
  - name: customer_key
    tests:
      - not_null  # Just test not null for dimension keys
```

### 4. Forgetting that surrogate keys need unique inputs
```sql
-- MIGHT NOT BE UNIQUE: If multiple records have same source + type
{{ dbt_utils.generate_surrogate_key(['source', 'type']) }} as record_skey,

-- GUARANTEED UNIQUE: Include the raw ID
{{ dbt_utils.generate_surrogate_key(['id']) }} as record_skey,
```

---

## Quick Reference: Key Selection Guide

```
Do you need to uniquely identify each row?
├── Yes → Use _pk (raw ID) or _skey (surrogate)
│   └── Need to hide raw ID? → _skey
│   └── Raw ID is fine? → _pk
│
└── No → Use _key (dimension key)
    └── What are you grouping by?
        └── Single attribute? → {attribute}_key
        └── Multiple attributes? → {attr1}_{attr2}_key
```

---

## Testing Keys in YML

```yaml
version: 2

models:
  - name: stg_orders
    columns:
      # Unique keys - test both unique and not_null
      - name: order_pk
        tests:
          - unique
          - not_null

      - name: order_skey
        tests:
          - unique
          - not_null

      # Dimension keys - only test not_null
      - name: customer_key
        description: "Dimension key - shared by all orders from same customer"
        tests:
          - not_null

      - name: product_key
        description: "Dimension key - shared by all orders for same product"
        tests:
          - not_null
```
