# Setup Checklist

Follow this checklist to set up the home metrics infrastructure.

## Phase 1: Infrastructure Setup

### Step 1: Create GitHub Repository
- [ ] Go to https://github.com/new
- [ ] Name: `home-metrics-infrastructure`
- [ ] Visibility: **Private**
- [ ] Initialize with README
- [ ] Create repository

### Step 2: Clone and Setup
```bash
cd "C:\Users\mattd\OneDrive\Matts Documents"
git clone https://github.com/YOUR_USERNAME/home-metrics-infrastructure.git
cd home-metrics-infrastructure
```

### Step 3: Copy Files
- [ ] Copy all files from `temp_home_metrics_files/` to `home-metrics-infrastructure/`
- [ ] Verify directory structure:
  ```
  home-metrics-infrastructure/
  ├── docker-compose.yml
  ├── .env.example
  ├── .gitignore
  ├── README.md
  ├── SETUP_CHECKLIST.md
  └── postgres/
      └── init/
          ├── 01-create-schemas.sql
          └── 02-create-raw-tables.sql
  ```

### Step 4: Configure Environment
```bash
cp .env.example .env
nano .env  # or use your preferred editor
```

- [ ] Set `POSTGRES_PASSWORD` to a secure password
- [ ] Optionally change ports if needed
- [ ] Save and close

### Step 5: Start Services
```bash
docker-compose up -d
```

- [ ] Wait for services to start (~30 seconds)
- [ ] Check logs: `docker-compose logs -f`

### Step 6: Verify PostgreSQL
```bash
docker exec -it home-metrics-postgres psql -U metrics_user -d home_metrics
```

- [ ] Connection successful
- [ ] Run: `\dt` to see raw tables
- [ ] Run: `\dn` to see schemas
- [ ] Run: `SELECT * FROM v_data_freshness;` (should be empty)
- [ ] Exit: `\q`

### Step 7: Setup Metabase
- [ ] Open http://localhost:3000
- [ ] Complete initial setup wizard:
  - Email and password for admin account
  - Choose "I'll add my own data later" OR connect to PostgreSQL now
- [ ] If connecting now:
  - Database type: PostgreSQL
  - Name: Home Metrics
  - Host: postgres (container name)
  - Port: 5432
  - Database name: home_metrics
  - Username: metrics_user
  - Password: (from .env)
- [ ] Connection successful

### Step 8: Commit and Push
```bash
git add .
git commit -m "Initial infrastructure setup

- PostgreSQL 16 with raw tables for metrics collection
- Metabase for data visualization
- Raw tables: power, media, pihole, system health
- dbt-ready schema structure (staging, intermediate, marts)"

git push origin main
```

## Phase 2: n8n Integration

### Step 1: Update n8n Workflow
In your `docker-projects` repo:

- [ ] Open the power consumption workflow in n8n
- [ ] Add PostgreSQL node after "Generate Report"
- [ ] Configure PostgreSQL credentials
- [ ] Insert data into `raw_power_consumption`
- [ ] Test workflow
- [ ] Verify data in PostgreSQL

### Step 2: Create Additional Workflows
- [ ] Plex media library stats (daily)
- [ ] Pi-hole metrics (every 15 min)
- [ ] Sonarr/Radarr stats (daily)

## Phase 3: dbt Setup

### Step 1: Create dbt Repository
- [ ] Create new GitHub repo: `home-metrics-dbt`
- [ ] Clone locally
- [ ] Install dbt: `pip install dbt-postgres`

### Step 2: Initialize dbt Project
```bash
cd home-metrics-dbt
dbt init home_metrics
```

### Step 3: Configure dbt
- [ ] Edit `profiles.yml` with PostgreSQL connection
- [ ] Test connection: `dbt debug`
- [ ] Create `sources.yml` defining raw tables
- [ ] Start building models

## Phase 4: Dashboards and Reports

### Step 1: Metabase Dashboards
- [ ] Create "Power Consumption" dashboard
- [ ] Create "Media Usage" dashboard
- [ ] Create "Pi-hole Blocking" dashboard
- [ ] Create "Home Overview" dashboard

### Step 2: n8n Report Workflow
- [ ] Create workflow to query marts
- [ ] Format weekly summary
- [ ] Send to Discord/Email via Notifiarr
- [ ] Schedule for Monday 8 AM

## Troubleshooting

### PostgreSQL won't start
```bash
docker-compose logs postgres
# Check for port conflicts
netstat -an | findstr 5432
```

### Can't connect to database
```bash
# Check if container is running
docker ps | findstr postgres

# Check network
docker network inspect home-metrics
```

### Metabase stuck loading
```bash
# Check Metabase logs
docker-compose logs metabase

# Restart if needed
docker-compose restart metabase
```

### n8n can't connect to PostgreSQL
- Ensure both are on same Docker network OR
- Use `host.docker.internal` as hostname OR
- Connect containers with: `docker network connect home-metrics n8n`

## Success Criteria

- [ ] PostgreSQL running and accessible
- [ ] Metabase web UI accessible
- [ ] Raw tables created in database
- [ ] n8n workflow inserting data
- [ ] Data visible in Metabase
- [ ] At least one dashboard created
- [ ] Weekly report generating

## Next Steps

Once everything is working:
1. Automate dbt runs (cron or Airflow)
2. Set up automated backups
3. Create more complex dashboards
4. Add data quality tests in dbt
5. Consider adding Grafana for real-time monitoring
6. Implement data retention policies
