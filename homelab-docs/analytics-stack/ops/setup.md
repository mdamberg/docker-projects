# Analytics Stack Setup

Complete setup guide for the home metrics data warehouse.

## Prerequisites

- Docker and Docker Compose installed
- Git
- GitHub account
- Basic SQL knowledge
- Python 3.8+ (for dbt, later phase)

## Phase 1: Infrastructure Setup

### Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `home-metrics-infrastructure`
3. Description: "PostgreSQL data warehouse and Metabase for home infrastructure metrics"
4. **Private** repository
5. Initialize with README
6. Create repository

### Step 2: Clone Repository

```bash
cd ~/Documents  # or your preferred location
git clone https://github.com/YOUR_USERNAME/home-metrics-infrastructure.git
cd home-metrics-infrastructure
```

### Step 3: Add Project Files

Copy all files from `docker-projects/temp_home_metrics_files/`:

```bash
# From docker-projects repo
cp -r temp_home_metrics_files/* ../home-metrics-infrastructure/

# Verify structure
cd ../home-metrics-infrastructure
ls -la
# Should see:
# - docker-compose.yml
# - .env.example
# - .gitignore
# - README.md
# - postgres/init/01-create-schemas.sql
# - postgres/init/02-create-raw-tables.sql
```

### Step 4: Configure Environment

```bash
cp .env.example .env
nano .env  # or use your preferred editor
```

**Update these values**:
```bash
POSTGRES_PASSWORD=<generate_secure_password>
```

Save and close.

### Step 5: Start Services

```bash
docker-compose up -d
```

Wait 30-60 seconds for first-time initialization.

### Step 6: Verify PostgreSQL

```bash
# Check container is running
docker ps | grep postgres

# Connect to database
docker exec -it home-metrics-postgres psql -U metrics_user -d home_metrics

# Run verification queries
\dn  # List schemas (should see: public, staging, intermediate, marts)
\dt  # List tables (should see 5 raw tables)
SELECT * FROM v_data_freshness;  # Should return empty results
\q  # Exit
```

Expected output:
```
 Schema Name  |    Owner
--------------+-------------
 intermediate | metrics_user
 marts        | metrics_user
 public       | postgres
 staging      | metrics_user
```

### Step 7: Create Metabase Database

```bash
docker exec home-metrics-postgres psql -U metrics_user -d postgres -c "CREATE DATABASE metabase OWNER metrics_user;"
```

### Step 8: Restart Metabase

```bash
docker restart home-metrics-metabase
```

Wait 1-2 minutes for Metabase to start and run migrations.

### Step 9: Setup Metabase

1. Open http://localhost:3000
2. Complete initial setup wizard:
   - Create admin account (email/password)
   - Click "Let's get started"
3. Skip or complete the tour
4. Connect to PostgreSQL:
   - Click Settings (gear) → Admin → Databases
   - Click "Add database"
   - Fill in details:
     ```
     Display name: Home Metrics
     Database type: PostgreSQL
     Host: postgres
     Port: 5432
     Database name: home_metrics
     Username: metrics_user
     Password: <from .env file>
     ```
   - Click "Save"
   - Wait for schema scan

### Step 10: Commit and Push

```bash
git add .
git commit -m "Initial infrastructure setup

- PostgreSQL 16 with raw tables
- Metabase for visualization
- Raw tables for power, media, pihole metrics
- dbt-ready schema structure"

git push origin main
```

## Phase 2: n8n Integration

### Step 1: Connect n8n to PostgreSQL Network

```bash
# From docker-projects directory
docker network connect home-metrics n8n
docker restart n8n
```

### Step 2: Configure PostgreSQL Credentials in n8n

1. Open n8n at http://localhost:5678
2. Go to Credentials menu
3. Click "Create New Credential"
4. Select "Postgres"
5. Fill in:
   ```
   Name: Home Metrics PostgreSQL
   Host: postgres
   Database: home_metrics
   User: metrics_user
   Password: <from .env>
   Port: 5432
   SSL: Disabled
   ```
6. Click "Test" to verify connection
7. Save

### Step 3: Update Power Consumption Workflow

1. Open your existing power consumption workflow
2. After the "Generate Report" node, add a "Function" node:
   - Name: "Prepare Data for DB"
   - Code: (see n8n service docs)
3. Add a "Postgres" node after Function:
   - Credential: Select "Home Metrics PostgreSQL"
   - Operation: Insert
   - Table: `raw_power_consumption`
   - Columns: Map all fields
4. Test the workflow
5. Check data was inserted:
   ```sql
   SELECT * FROM raw_power_consumption ORDER BY inserted_at DESC LIMIT 5;
   ```

### Step 4: Schedule Workflow

1. Add or modify Schedule Trigger node
2. Set to run every 5 minutes: `*/5 * * * *`
3. Save workflow
4. Toggle to "Active"

### Step 5: Verify Data Collection

Wait 5 minutes, then check:
```sql
SELECT COUNT(*), MAX(inserted_at) FROM raw_power_consumption;
```

Should see rows with recent timestamps.

## Phase 3: dbt Setup (Optional for now)

We'll tackle this later once data is flowing consistently.

### Quick Overview

1. Create `home-metrics-dbt` repository
2. Install dbt: `pip install dbt-postgres`
3. Initialize project: `dbt init home_metrics`
4. Configure profiles.yml
5. Create staging models
6. Create mart models
7. Schedule dbt runs

See dbt documentation for detailed steps.

## Phase 4: Dashboards and Reports

### Create Your First Dashboard in Metabase

1. In Metabase, click "New" → "Dashboard"
2. Name it "Power Consumption Overview"
3. Add widgets:

**Widget 1: Current Total Power**
- Click "Add a question"
- Native query:
  ```sql
  SELECT SUM(state) AS total_watts
  FROM raw_power_consumption
  WHERE recorded_at = (SELECT MAX(recorded_at) FROM raw_power_consumption);
  ```
- Visualization: Number
- Save

**Widget 2: Power Over Time**
- Native query:
  ```sql
  SELECT
      DATE_TRUNC('hour', recorded_at) AS time,
      SUM(state) AS total_watts
  FROM raw_power_consumption
  WHERE recorded_at > NOW() - INTERVAL '24 hours'
  GROUP BY time
  ORDER BY time;
  ```
- Visualization: Line chart
- X-axis: time
- Y-axis: total_watts
- Save

**Widget 3: Top Consumers**
- Native query:
  ```sql
  SELECT
      friendly_name,
      AVG(state) AS avg_watts
  FROM raw_power_consumption
  WHERE recorded_at > NOW() - INTERVAL '24 hours'
  GROUP BY friendly_name
  ORDER BY avg_watts DESC
  LIMIT 10;
  ```
- Visualization: Bar chart
- Save

4. Arrange widgets on dashboard
5. Save dashboard

## Verification Checklist

- [ ] PostgreSQL container running and healthy
- [ ] Metabase accessible at http://localhost:3000
- [ ] Raw tables created in database
- [ ] Metabase connected to home_metrics database
- [ ] n8n can connect to PostgreSQL
- [ ] Power consumption workflow active
- [ ] Data flowing into raw_power_consumption
- [ ] First dashboard created in Metabase
- [ ] Infrastructure repo pushed to GitHub

## Next Steps

1. **Add More Workflows**:
   - Plex media stats
   - Pi-hole metrics
   - Sonarr/Radarr stats

2. **Set Up dbt**:
   - Create transformation models
   - Build mart tables
   - Schedule dbt runs

3. **Create More Dashboards**:
   - Media usage
   - Pi-hole blocking
   - Combined home overview

4. **Implement Reporting**:
   - Weekly summary workflow
   - Send to Discord/email

5. **Monitoring & Alerts**:
   - Data freshness alerts
   - Anomaly detection
   - Cost threshold alerts

## Troubleshooting

See [Troubleshooting Guide](troubleshooting.md) for common issues and solutions.

## Support

- PostgreSQL Docs: https://www.postgresql.org/docs/16/
- Metabase Docs: https://www.metabase.com/docs/latest/
- n8n Docs: https://docs.n8n.io/
- dbt Docs: https://docs.getdbt.com/
