# home_metrics_dbt

dbt (data build tool) project for transforming raw home metrics data into analytics-ready models.

## Overview

This project is the transformation layer of the Analytics Stack, responsible for cleaning, standardizing, and aggregating raw data from PostgreSQL into structured marts for visualization and reporting.

## Architecture

```
PostgreSQL (raw tables)
         ↓
    dbt Staging Models (views)
         ↓
    dbt Intermediate Models (views/tables)
         ↓
    dbt Marts Models (tables)
         ↓
Metabase / n8n (consumption)
```

## Project Structure

```
home_metrics_dbt/
├── models/
│   ├── staging/          # Clean and standardize raw data
│   │   ├── __sources.yml # Source definitions
│   │   ├── stg_customers.sql
│   │   ├── stg_orders.sql
│   │   ├── stg_products.sql
│   │   └── ...
│   ├── intermediate/     # Aggregations and transformations
│   │   └── (coming soon)
│   └── marts/           # Business-ready models
│       ├── customers.sql
│       ├── orders.sql
│       ├── products.sql
│       └── ...
├── macros/              # Custom SQL functions
├── seeds/               # Static reference data
├── tests/               # Custom data tests
├── dbt_project.yml      # Project configuration
└── packages.yml         # dbt package dependencies
```

## Database Connection

**Profile**: `home_metrics_dbt`

Connection details configured in `~/.dbt/profiles.yml`:
- Type: PostgreSQL
- Host: localhost
- Port: 5432
- Database: home_metrics
- Schema: public
- User: metrics_user

## Model Layers

### Staging Layer
**Materialization**: View

Purpose: Light transformations on raw data
- Rename columns to consistent naming
- Cast data types
- Basic filtering
- No joins or aggregations

Current models:
- `stg_customers` - Customer dimension
- `stg_orders` - Order facts
- `stg_order_items` - Line item details
- `stg_products` - Product dimension
- `stg_supplies` - Supply chain data
- `stg_locations` - Location dimension

### Intermediate Layer
**Materialization**: View (configurable)

Purpose: Complex transformations and aggregations
- Join staging models
- Calculate metrics
- Aggregate time-series data

### Marts Layer
**Materialization**: Table

Purpose: Business-ready models for consumption
- Denormalized for query performance
- Analytics-ready dimensions and facts
- Documented and tested

Current models:
- `customers` - Customer analytics
- `orders` - Order analytics
- `order_items` - Line item analytics
- `products` - Product analytics
- `supplies` - Supply chain analytics
- `locations` - Location analytics

## Common Commands

### Development
```bash
# Navigate to project
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\home_metrics_dbt"

# Test connection
dbt debug

# Install dependencies
dbt deps

# Run all models
dbt run

# Run specific model
dbt run --select stg_customers

# Run models with dependencies
dbt run --select stg_customers+

# Test all models
dbt test

# Build everything (run + test)
dbt build

# Generate documentation
dbt docs generate
dbt docs serve
```

### Targeting
```bash
# Run staging models only
dbt run --select staging

# Run marts only
dbt run --select marts

# Run specific model and downstream
dbt run --select stg_orders+

# Run modified models
dbt run --select state:modified+
```

## Configuration

### dbt_project.yml
Key configurations:
- Project name: `home_metrics_dbt`
- Profile: `home_metrics_dbt`
- Staging models: materialized as views
- Marts models: materialized as tables
- Seeds: loaded into `raw` schema

### profiles.yml
Location: `~/.dbt/profiles.yml`

```yaml
home_metrics_dbt:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      user: metrics_user
      password: [your_password]
      port: 5432
      dbname: home_metrics
      schema: public
      threads: 4
      keepalives_idle: 0
```

## Data Sources

Sources are defined in `models/staging/__sources.yml` and represent raw tables populated by n8n workflows.

Expected raw tables:
- `raw_power_consumption` - Power usage from Home Assistant
- `raw_media_library` - Media catalog from Plex
- `raw_media_activity` - Viewing history from Plex
- `raw_pihole_metrics` - DNS blocking stats
- `raw_system_health` - System health metrics

## Testing

dbt tests validate data quality:

**Generic tests** (in .yml files):
- `unique` - Column values are unique
- `not_null` - No null values
- `relationships` - Foreign key validity
- `accepted_values` - Value in allowed list

**Custom tests** (in tests/ folder):
- Custom SQL assertions
- Business logic validation

## Documentation

dbt automatically generates documentation from:
- Model descriptions in .yml files
- Column descriptions in .yml files
- Inline SQL comments
- Lineage graphs

View docs:
```bash
dbt docs generate
dbt docs serve  # Opens browser
```

## Development Workflow

1. Pull latest changes from git
2. Test connection: `dbt debug`
3. Install dependencies: `dbt deps`
4. Develop new model in `models/` directory
5. Add description and tests in `.yml` file
6. Run model: `dbt run --select my_model`
7. Test model: `dbt test --select my_model`
8. Generate docs: `dbt docs generate`
9. Commit and push changes

## Best Practices

1. **Naming conventions**:
   - Staging: `stg_<source>_<table>`
   - Intermediate: `int_<entity>_<verb>`
   - Marts: `<entity>` or `fact_<entity>`

2. **SQL style**:
   - Use CTEs for readability
   - One column per line in SELECT
   - Trailing commas
   - Descriptive CTE names

3. **Testing**:
   - Test all primary keys (unique + not_null)
   - Test all foreign keys (relationships)
   - Test critical business logic

4. **Documentation**:
   - Document all models
   - Document complex transformations
   - Keep descriptions business-friendly

## Troubleshooting

### Connection Issues
```bash
# Verify profiles.yml location
echo $HOME\.dbt\profiles.yml

# Test connection
dbt debug

# Check PostgreSQL is running
docker ps | grep postgres
```

### Model Failures
```bash
# Run with verbose logging
dbt run --select my_model --log-level debug

# Compile SQL without running
dbt compile --select my_model

# Check compiled SQL
cat target/compiled/home_metrics_dbt/models/my_model.sql
```

### Performance Issues
```bash
# Check query plans
dbt run --select my_model --log-level debug

# Materialize slow models as tables
# Update dbt_project.yml or use config() in model
```

## Related Documentation

- [Analytics Stack Overview](../analytics-stack/README.md)
- [PostgreSQL Service](../analytics-stack/services/postgresql.md)
- [n8n Workflows](../analytics-stack/services/n8n.md)
- [dbt Official Docs](https://docs.getdbt.com/)

## Project Info

- **Location**: `C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\home_metrics_dbt`
- **Profile**: `home_metrics_dbt`
- **Target Database**: PostgreSQL (localhost:5432)
- **dbt Version**: dbt-fusion 2.0.0-preview.92
- **Git Repository**: (TBD)

## Future Enhancements

- [ ] Add intermediate layer models
- [ ] Implement incremental models for large fact tables
- [ ] Add data quality macros
- [ ] Set up CI/CD with GitHub Actions
- [ ] Add snapshot models for slowly changing dimensions
- [ ] Implement data freshness checks
- [ ] Add custom schema tests
