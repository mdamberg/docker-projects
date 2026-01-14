# Troubleshooting home_metrics_dbt

Common issues and solutions for the home_metrics_dbt project.

## dbt debug Failures

### Profile Not Found Error

**Error**:
```
error: dbt1001: Profile 'home_metrics_dbt' not found in profiles.yml
```

**Solution**:
Ensure the `home_metrics_dbt` profile exists in `~/.dbt/profiles.yml` (not in the project directory).

**Location**: `C:\Users\mattd\.dbt\profiles.yml`

The profile should include:
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

**Status**: ✅ RESOLVED - Profile added to standard location

---

### Windows DLL Error (dbt-fusion)

**Error**:
```
error: dbt1011: Error with dynamic library: LoadLibraryExW failed
```

**Root Cause**:
dbt-fusion requires system DLLs that may not be present on Windows. This is a known issue with the dbt-fusion preview on Windows.

**Solutions**:

#### Option 1: Install Visual C++ Redistributables (Recommended)
1. Download and install Microsoft Visual C++ Redistributables:
   - [Latest x64 Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)
2. Restart your terminal
3. Test: `dbt debug`

#### Option 2: Use dbt-core Instead of dbt-fusion
dbt-fusion is a preview version with native compilation. Using standard dbt-core may avoid Windows DLL issues:

```bash
# Uninstall dbt-fusion
pip uninstall dbt-fusion

# Install dbt-core with postgres adapter
pip install dbt-core dbt-postgres

# Test connection
dbt debug
```

#### Option 3: Use WSL2 (Windows Subsystem for Linux)
Run dbt in a Linux environment within Windows:

```bash
# In WSL2 Ubuntu
pip install dbt-core dbt-postgres

# Profile location in WSL: ~/.dbt/profiles.yml
# Project location: /mnt/c/Users/mattd/OneDrive/Matts Documents/Docker/docker-projects/home_metrics_dbt
```

#### Option 4: Run dbt in Docker
Create a Docker container to run dbt commands:

```dockerfile
FROM python:3.11-slim

RUN pip install dbt-core dbt-postgres

WORKDIR /usr/app/dbt
```

```bash
# Build and run
docker build -t dbt-runner .
docker run -v "./home_metrics_dbt:/usr/app/dbt" --network host dbt-runner dbt debug
```

**Verification**:
After applying any solution, verify with:
```bash
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\home_metrics_dbt"
dbt debug
```

You should see:
```
All checks passed!
```

**Status**: 🔴 UNRESOLVED - Awaiting fix implementation

---

## Connection Issues

### PostgreSQL Not Running

**Error**:
```
could not connect to server: Connection refused
```

**Solution**:
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Start PostgreSQL if not running
cd [your analytics-stack location]
docker-compose up -d postgres

# Verify it's healthy
docker ps --filter "name=postgres"
```

**Expected**:
```
home-metrics-postgres   Up X hours (healthy)   0.0.0.0:5432->5432/tcp
```

---

### Wrong Database Credentials

**Error**:
```
FATAL: password authentication failed for user "metrics_user"
```

**Solution**:
1. Check your password in `~/.dbt/profiles.yml`
2. Verify it matches the PostgreSQL user password
3. Update if needed and test: `dbt debug`

---

### Database Does Not Exist

**Error**:
```
FATAL: database "home_metrics" does not exist
```

**Solution**:
```bash
# Connect to PostgreSQL container
docker exec -it home-metrics-postgres psql -U postgres

# Create database
CREATE DATABASE home_metrics;
CREATE USER metrics_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE home_metrics TO metrics_user;
\q
```

---

## Model Errors

### Model Compilation Failures

**Error**:
```
Compilation Error in model [model_name]
```

**Debug Steps**:
1. Check SQL syntax in the model file
2. Verify all referenced models exist
3. Check for circular dependencies
4. Compile without running: `dbt compile --select model_name`
5. Review compiled SQL: `target/compiled/home_metrics_dbt/models/[model_name].sql`

---

### Model Runtime Failures

**Error**:
```
Database Error in model [model_name]
relation "table_name" does not exist
```

**Solutions**:
1. Run upstream dependencies first:
   ```bash
   dbt run --select +model_name
   ```

2. Verify source tables exist:
   ```bash
   docker exec -it home-metrics-postgres psql -U metrics_user -d home_metrics
   \dt
   ```

3. Run from scratch:
   ```bash
   dbt clean
   dbt deps
   dbt build
   ```

---

## Test Failures

### Generic Test Failures

**Error**:
```
Failure in test unique_customers_customer_id
```

**Debug**:
```bash
# Run tests with verbose output
dbt test --select unique_customers_customer_id --log-level debug

# View compiled test SQL
cat target/compiled/home_metrics_dbt/models/[path]/[test_name].sql

# Run test SQL directly in PostgreSQL
docker exec -it home-metrics-postgres psql -U metrics_user -d home_metrics
[paste test SQL]
```

---

## Performance Issues

### Slow Model Runs

**Symptoms**:
- Models take minutes to run
- dbt run times out

**Solutions**:
1. Check PostgreSQL performance:
   ```bash
   docker stats home-metrics-postgres
   ```

2. Reduce threads in profiles.yml:
   ```yaml
   threads: 2  # Instead of 4
   ```

3. Materialize large staging models as tables:
   ```yaml
   # In model .yml file
   models:
     - name: stg_large_table
       config:
         materialized: table
   ```

4. Use incremental models for large fact tables

---

## Dependency Issues

### dbt Packages Not Found

**Error**:
```
Module not found: [package_name]
```

**Solution**:
```bash
# Install packages
dbt deps

# If packages.yml updated, clean and reinstall
dbt clean
dbt deps
```

---

## Common Commands for Debugging

```bash
# Full debug output
dbt debug --log-level debug

# Compile without running
dbt compile --select model_name

# View compiled SQL
cat target/compiled/home_metrics_dbt/models/[path]/[model_name].sql

# Run with debug logging
dbt run --select model_name --log-level debug

# Check dbt version
dbt --version

# List all models
dbt list

# Show model dependencies
dbt list --select +model_name+
```

---

## Getting Help

1. Check dbt logs: `logs/dbt.log`
2. Review compiled SQL: `target/compiled/`
3. Run with debug logging: `--log-level debug`
4. Check [dbt documentation](https://docs.getdbt.com/)
5. Search [dbt Slack community](https://www.getdbt.com/community/)

---

## Issue Status

| Issue | Status | Date Resolved |
|-------|--------|---------------|
| Profile not found | ✅ Resolved | 2026-01-12 |
| Windows DLL error | 🔴 Unresolved | - |
| PostgreSQL connection | ✅ Working | 2026-01-12 |
