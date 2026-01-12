# Analytics Stack Docker Compose

## Repository Location

**Separate Repo**: `home-metrics-infrastructure`

This stack lives in its own private repository, not in the main `docker-projects` repo.

## Compose File Structure

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: home-metrics-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      PGDATA: /var/lib/postgresql/data/pgdata
    ports:
      - "5432:5432"
    volumes:
      - ./postgres/data:/var/lib/postgresql/data
      - ./postgres/init:/docker-entrypoint-initdb.d:ro
    networks:
      - home-metrics
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  metabase:
    image: metabase/metabase:latest
    container_name: home-metrics-metabase
    restart: unless-stopped
    environment:
      MB_DB_TYPE: postgres
      MB_DB_DBNAME: metabase
      MB_DB_PORT: 5432
      MB_DB_USER: ${POSTGRES_USER}
      MB_DB_PASS: ${POSTGRES_PASSWORD}
      MB_DB_HOST: postgres
    ports:
      - "3000:3000"
    volumes:
      - ./metabase/data:/metabase-data
    networks:
      - home-metrics
    depends_on:
      postgres:
        condition: service_healthy

networks:
  home-metrics:
    name: home-metrics
    driver: bridge
```

## Environment Variables

Create `.env` file in repo root:

```bash
# PostgreSQL Configuration
POSTGRES_DB=home_metrics
POSTGRES_USER=metrics_user
POSTGRES_PASSWORD=YOUR_SECURE_PASSWORD_HERE
POSTGRES_PORT=5432

# Metabase Configuration
METABASE_PORT=3000
METABASE_DB_NAME=metabase

# Timezone
TZ=America/New_York
```

## Initialization Scripts

Located in `postgres/init/`:

### 01-create-schemas.sql
Creates dbt-ready schema structure:
- `public` - Raw data tables
- `staging` - Cleaned data (dbt)
- `intermediate` - Aggregations (dbt)
- `marts` - Analytics-ready (dbt)

### 02-create-raw-tables.sql
Creates raw tables for n8n data insertion:
- `raw_power_consumption`
- `raw_media_library`
- `raw_media_activity`
- `raw_pihole_metrics`
- `raw_system_health`

Also creates `v_data_freshness` view for monitoring.

## Volume Mounts

```
./postgres/data/        → Database files (gitignored)
./postgres/init/        → SQL init scripts (committed)
./metabase/data/        → Metabase config (gitignored)
```

## Networking

### home-metrics Network
- Bridge network for internal communication
- Postgres accessible as `postgres` hostname
- n8n can connect via `docker network connect home-metrics n8n`

### Port Mappings
- `5432:5432` - PostgreSQL (localhost only)
- `3000:3000` - Metabase web UI

## Starting the Stack

```bash
cd ~/home-metrics-infrastructure
docker-compose up -d
```

## Verifying Startup

```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs -f

# Check PostgreSQL
docker exec home-metrics-postgres psql -U metrics_user -d home_metrics -c "\dt"

# Check Metabase (wait 1-2 min for first startup)
# Open http://localhost:3000
```

## Stopping the Stack

```bash
docker-compose down
```

## Database Access

### From Docker Host
```bash
psql -h localhost -p 5432 -U metrics_user -d home_metrics
```

### From Container
```bash
docker exec -it home-metrics-postgres psql -U metrics_user -d home_metrics
```

### From n8n Workflow
- Host: `postgres` (if on same network) or `host.docker.internal`
- Port: `5432`
- Database: `home_metrics`
- User: `metrics_user`
- Password: (from .env)

## Connecting n8n

n8n lives in `docker-projects` repo. To allow connection:

```bash
# Option 1: Connect n8n to home-metrics network
docker network connect home-metrics n8n

# Option 2: Use host networking in n8n workflow
# Use host: host.docker.internal
```

## Resource Usage

- **PostgreSQL**: ~200MB RAM (idle), grows with data
- **Metabase**: ~1.5GB RAM, 2GB JVM heap
- **Disk**: Grows with time-series data
  - Power data at 5-min intervals: ~10MB/month
  - Media/pihole data: ~1MB/month

## Backup Strategy

See [Backup & Restore](../ops/backup-restore.md)

## Upgrading Services

### PostgreSQL
```bash
# Backup first!
docker-compose down
# Update image version in compose file
docker-compose up -d
```

### Metabase
```bash
docker-compose pull metabase
docker-compose up -d metabase
```

## Troubleshooting

See [Troubleshooting Guide](../ops/troubleshooting.md)

## Security Notes

- PostgreSQL only listens on localhost (not 0.0.0.0)
- Use strong passwords in `.env`
- `.env` is gitignored
- Data volumes are gitignored
- Metabase requires authentication
- Consider enabling PostgreSQL SSL for production
