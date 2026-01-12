# Backup & Restore

Backup and disaster recovery procedures for the analytics stack.

## Backup Strategy

### What to Back Up

1. **PostgreSQL Data**
   - All databases (home_metrics + metabase)
   - Schema definitions
   - Data in all tables

2. **Metabase Configuration**
   - Already stored in metabase PostgreSQL database
   - Includes dashboards, questions, users, settings

3. **n8n Workflows**
   - Already in docker-projects git repo
   - Workflow JSON files

4. **Configuration Files**
   - docker-compose.yml
   - .env file (store securely, not in git)
   - Init SQL scripts (in git)

### Backup Schedule

- **Daily**: Automated PostgreSQL dumps
- **Weekly**: Full system backup
- **Before Upgrades**: Manual backup
- **After Major Changes**: Manual backup

## PostgreSQL Backups

### Manual Backup

**Full Backup (Both Databases)**:
```bash
# Navigate to backup directory
mkdir -p ~/backups/home-metrics
cd ~/backups/home-metrics

# Backup home_metrics database
docker exec home-metrics-postgres pg_dump -U metrics_user home_metrics > home_metrics_$(date +%Y%m%d_%H%M%S).sql

# Backup metabase database
docker exec home-metrics-postgres pg_dump -U metrics_user metabase > metabase_$(date +%Y%m%d_%H%M%S).sql

# Compress backups
gzip home_metrics_*.sql
gzip metabase_*.sql
```

**Quick Backup Script**:
```bash
#!/bin/bash
# save as: backup-analytics.sh

BACKUP_DIR=~/backups/home-metrics
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Backing up home_metrics database..."
docker exec home-metrics-postgres pg_dump -U metrics_user home_metrics | gzip > $BACKUP_DIR/home_metrics_$DATE.sql.gz

echo "Backing up metabase database..."
docker exec home-metrics-postgres pg_dump -U metrics_user metabase | gzip > $BACKUP_DIR/metabase_$DATE.sql.gz

echo "Backup complete: $BACKUP_DIR"
ls -lh $BACKUP_DIR/*$DATE*
```

### Automated Backups

**Add to Crontab**:
```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * ~/scripts/backup-analytics.sh

# Or inline command
0 2 * * * docker exec home-metrics-postgres pg_dump -U metrics_user home_metrics | gzip > ~/backups/home-metrics/home_metrics_$(date +\%Y\%m\%d).sql.gz
```

**Using Docker Restart Policy**:
Already configured in docker-compose.yml:
```yaml
restart: unless-stopped
```

### Backup Retention

**Keep backups for**:
- Last 7 days: All daily backups
- Last 4 weeks: Weekly backups (Sunday)
- Last 12 months: Monthly backups (1st of month)

**Cleanup Script**:
```bash
#!/bin/bash
# save as: cleanup-old-backups.sh

BACKUP_DIR=~/backups/home-metrics

# Keep last 7 days
find $BACKUP_DIR -name "home_metrics_*.sql.gz" -mtime +7 -delete
find $BACKUP_DIR -name "metabase_*.sql.gz" -mtime +7 -delete

echo "Old backups cleaned up"
```

## Restore Procedures

### Restore Full Database

**From Compressed Backup**:
```bash
# Stop Metabase (to avoid connection issues)
docker-compose stop metabase

# Restore home_metrics
gunzip -c ~/backups/home-metrics/home_metrics_20260111.sql.gz | \
    docker exec -i home-metrics-postgres psql -U metrics_user -d home_metrics

# Restore metabase
gunzip -c ~/backups/home-metrics/metabase_20260111.sql.gz | \
    docker exec -i home-metrics-postgres psql -U metrics_user -d metabase

# Restart Metabase
docker-compose start metabase
```

### Restore Specific Table

```bash
# Extract and restore single table
pg_restore -U metrics_user -d home_metrics -t raw_power_consumption backup.dump
```

### Point-in-Time Recovery

PostgreSQL supports PITR with WAL archiving. To enable:

1. Update postgresql.conf:
   ```
   wal_level = replica
   archive_mode = on
   archive_command = 'cp %p /backups/wal/%f'
   ```

2. Take base backup with:
   ```bash
   docker exec home-metrics-postgres pg_basebackup -U metrics_user -D /backups/base
   ```

3. Restore to specific point:
   ```bash
   recovery_target_time = '2026-01-11 14:30:00'
   ```

## Disaster Recovery

### Complete System Recovery

**Scenario**: Server crashed, need to rebuild everything

**Steps**:

1. **Reinstall Docker** (if needed)

2. **Clone Repositories**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/home-metrics-infrastructure.git
   git clone https://github.com/YOUR_USERNAME/docker-projects.git
   ```

3. **Restore .env File**:
   ```bash
   cp ~/secure-location/.env home-metrics-infrastructure/.env
   ```

4. **Start Infrastructure** (empty databases will be created):
   ```bash
   cd home-metrics-infrastructure
   docker-compose up -d
   ```

5. **Wait for Init** (30 seconds), then stop Metabase:
   ```bash
   docker-compose stop metabase
   ```

6. **Restore Databases**:
   ```bash
   # Restore home_metrics
   gunzip -c ~/backups/home-metrics/home_metrics_latest.sql.gz | \
       docker exec -i home-metrics-postgres psql -U metrics_user -d home_metrics

   # Restore metabase
   gunzip -c ~/backups/home-metrics/metabase_latest.sql.gz | \
       docker exec -i home-metrics-postgres psql -U metrics_user -d metabase
   ```

7. **Start All Services**:
   ```bash
   docker-compose up -d
   ```

8. **Verify**:
   - Check PostgreSQL: `docker exec -it home-metrics-postgres psql -U metrics_user -d home_metrics -c "SELECT COUNT(*) FROM raw_power_consumption;"`
   - Check Metabase: http://localhost:3000
   - Verify dashboards and data

9. **Reconnect n8n**:
   ```bash
   docker network connect home-metrics n8n
   docker restart n8n
   ```

10. **Verify n8n workflows** are active and running

### Recovery Time Objective (RTO)

- **Target**: < 1 hour
- **Actual**: ~15-30 minutes with good backups

### Recovery Point Objective (RPO)

- **Target**: < 24 hours of data loss
- **Actual**: < 1 hour (with hourly backups)

## Backup Testing

**Monthly Test Restore**:
```bash
# Create test environment
mkdir -p ~/test-restore
cd ~/test-restore

# Copy compose file
cp ~/home-metrics-infrastructure/docker-compose.yml .

# Modify to use different ports
sed -i 's/5432:5432/5433:5432/' docker-compose.yml
sed -i 's/3000:3000/3001:3000/' docker-compose.yml

# Start test environment
docker-compose up -d

# Restore backup
gunzip -c ~/backups/home-metrics/home_metrics_latest.sql.gz | \
    docker exec -i test-postgres psql -U metrics_user -d home_metrics

# Verify data
docker exec -it test-postgres psql -U metrics_user -d home_metrics -c "SELECT COUNT(*) FROM raw_power_consumption;"

# Cleanup
docker-compose down -v
rm -rf ~/test-restore
```

## Off-Site Backups

### Copy to NAS
```bash
# Add to backup script
rsync -avz ~/backups/home-metrics/ user@nas:/backups/home-metrics/
```

### Cloud Backup
```bash
# Using rclone
rclone copy ~/backups/home-metrics/ remote:home-metrics-backups/
```

### Encrypted Backup
```bash
# Encrypt before upload
gpg --encrypt --recipient your@email.com home_metrics_backup.sql.gz
rclone copy home_metrics_backup.sql.gz.gpg remote:encrypted-backups/
```

## Configuration Backup

### Export n8n Workflows
Already in git, but can also export:
```bash
# From n8n UI, export each workflow as JSON
# Save to docker-projects/n8n/workflows/
```

### Backup .env Files
```bash
# Copy to secure location (encrypted USB, password manager, etc.)
cp home-metrics-infrastructure/.env ~/secure-backups/analytics-stack.env
```

### Document Credentials
Keep encrypted file with:
- PostgreSQL password
- Metabase admin credentials
- API keys
- Webhook URLs

## Monitoring Backups

### Verify Backup Success
```bash
# Check backup file exists and is recent
if [ -f ~/backups/home-metrics/home_metrics_$(date +%Y%m%d).sql.gz ]; then
    echo "✓ Backup exists"
    ls -lh ~/backups/home-metrics/home_metrics_$(date +%Y%m%d).sql.gz
else
    echo "✗ Backup missing - send alert!"
    # Send alert via email/webhook
fi
```

### Alert on Backup Failure
Add to backup script:
```bash
if [ $? -eq 0 ]; then
    echo "Backup successful"
else
    echo "Backup failed!" | mail -s "Analytics Backup Failed" your@email.com
fi
```

## Related Documentation

- [Setup Guide](setup.md)
- [Troubleshooting](troubleshooting.md)
- [PostgreSQL Service](../services/postgresql.md)
- [Metabase Service](../services/metabase.md)
