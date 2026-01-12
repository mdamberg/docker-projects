# Home Metrics Data Warehouse Setup Guide

## Overview
This guide helps you set up the complete home metrics data warehouse infrastructure.

## Repository Structure

You'll have **THREE** repos:

1. **docker-projects** (this repo) - Existing Docker services + n8n workflows
2. **home-metrics-infrastructure** (new, private) - PostgreSQL + Metabase + init scripts
3. **home-metrics-dbt** (new, can be public) - dbt transformation models

## Step 1: Create the home-metrics-infrastructure Repo

### On GitHub:
1. Go to https://github.com/new
2. Repository name: `home-metrics-infrastructure`
3. Description: "PostgreSQL data warehouse and Metabase for home infrastructure metrics"
4. **Private** ✅
5. Initialize with README ✅
6. Add .gitignore: None (we'll create custom)
7. License: MIT or None
8. Create repository

### Clone it locally:
```bash
cd "C:\Users\mattd\OneDrive\Matts Documents"
git clone https://github.com/YOUR_USERNAME/home-metrics-infrastructure.git
cd home-metrics-infrastructure
```

## Step 2: Add Files to home-metrics-infrastructure

I'll provide all the files you need. Copy them to your new repo:

### Files to create:
- `docker-compose.yml` - PostgreSQL + Metabase services
- `.env.example` - Environment variable template
- `.env` - Actual credentials (gitignored)
- `.gitignore` - Exclude data and secrets
- `postgres/init/01-create-raw-tables.sql` - Raw table DDL
- `postgres/init/02-create-schemas.sql` - Schema structure
- `README.md` - Setup instructions

## Step 3: Set Up dbt (Later Phase)

After infrastructure is running:
```bash
pip install dbt-postgres
cd "C:\Users\mattd\OneDrive\Matts Documents"
git clone https://github.com/YOUR_USERNAME/home-metrics-dbt.git  # Create this repo
cd home-metrics-dbt
dbt init home_metrics
```

## Step 4: Update n8n Workflows

Modify the power consumption workflow (in THIS repo) to:
1. Keep generating reports
2. ALSO insert data into PostgreSQL raw tables

## Architecture Flow

```
Data Sources (HA, Plex, Pi-hole)
  ↓
n8n workflows (docker-projects repo)
  ↓
PostgreSQL raw tables (home-metrics-infrastructure)
  ↓
dbt models (home-metrics-dbt repo)
  ↓
Metabase dashboards (home-metrics-infrastructure)
  ↓
Reports back through n8n
```

## Next Steps

1. Create the GitHub repo
2. Clone it locally
3. I'll generate all the infrastructure files
4. Test PostgreSQL + Metabase
5. Update n8n workflow to write to database
6. Set up dbt project

Ready? Let me know when you've created the repo!
