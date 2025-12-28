# Duplicati Backup System

## Overview

Duplicati is an open-source backup solution that provides encrypted, incremental backups for the homelab infrastructure. It backs up all Docker project configurations to protect against data loss.

## Purpose

- **Automated Backups**: Scheduled nightly backups of all Docker configurations
- **Disaster Recovery**: Quick restoration of services in case of hardware failure or data corruption
- **Version Control**: Maintains backup history to restore from specific points in time
- **Security**: Encrypted backups protect sensitive configuration data

## Access Information

- **Web Interface**: http://localhost:8200 or http://192.168.4.200:8200
- **Login Password**: Set via docker-compose CLI_ARGS (currently: admin)
- **Container Name**: duplicati

## Backup Schedule

**Nightly Backup**: Runs daily at 1:00 AM
- Backs up all Docker configurations from `C:\docker-projects`
- Stores backups to `C:\backups`
- Performs incremental backups to minimize storage usage
- Retains backup history according to retention policy

## Configuration

### Docker Compose Setup

Located at: `docker-projects/backups/docker-compose.yml`

Key configuration elements:
- **Image**: linuxserver/duplicati:latest
- **Port**: 8200
- **Volumes**:
  - `./duplicati/config:/config` - Duplicati configuration
  - `C:/docker-projects:/source/docker-configs:ro` - Source files (read-only)
  - `C:/backups:/backups` - Backup destination

### Environment Variables

Stored in `.env` file (gitignored):
- `TZ`: America/Chicago
- `SETTINGS_ENCRYPTION_KEY`: Encrypts the Duplicati settings database
- `HEALTHCHECKS_URL`: Healthchecks.io ping URL for dead man's switch monitoring

### Startup/Shutdown

Duplicati is integrated into the infrastructure management scripts:

```powershell
# Start with all services
.\start-all-services.ps1

# Start only backups
.\start-all-services.ps1 -Services "backups"

# Stop with all services
.\stop-all-services.ps1

# Stop only backups
.\stop-all-services.ps1 -Services "backups"
```

## Notifications

Duplicati supports multiple notification methods for backup completion status:

### Available Notification Methods

1. **Email (SMTP)**
   - Configure in: Settings → Default options → Email settings
   - Supports both successful and failed backup notifications
   - Can customize email templates

2. **HTTP/Webhook**
   - Send POST requests to custom endpoints
   - Ideal for integration with monitoring systems
   - Supports custom JSON payloads

3. **Command/Script Execution**
   - Run custom scripts after backup completion
   - Different scripts for success vs. failure scenarios
   - Can integrate with existing monitoring tools

### Setting Up Notifications

1. Log in to the Duplicati web interface
2. Navigate to: Settings → Default options
3. Scroll to "Advanced options"
4. Configure notification settings:
   - **send-mail-to**: Email address for notifications
   - **send-mail-from**: Sender email address
   - **send-mail-subject**: Email subject template
   - **send-mail-url**: SMTP server URL
   - **send-http-url**: Webhook URL for HTTP notifications
   - **run-script-after**: Path to script to run after backup

### Notification Examples

**Email on Failure Only:**
```
send-mail-to=admin@example.com
send-mail-level=Error,Warning
```

**Webhook Integration:**
```
send-http-url=https://your-monitoring-service.com/webhook
send-http-message=Backup completed: %OPERATIONNAME% - %PARSEDRESULT%
```

**Script Execution:**
```
run-script-after=C:\scripts\backup-notification.ps1
run-script-after-arguments=--status=%PARSEDRESULT% --backup=%backup-name%
```

### Healthchecks.io Integration (Dead Man's Switch)

The backup system includes healthchecks.io integration for dead man's switch monitoring - it alerts you if backups STOP running.

**How It Works:**
- After each successful backup, the system pings a healthchecks.io URL
- If healthchecks.io doesn't receive a ping within the expected timeframe, it sends an alert
- Failed backups don't ping, triggering an alert
- Provides an additional layer of monitoring beyond ntfy notifications

**Configuration:**

1. **Environment Variable**: Set in `.env` file:
   ```
   HEALTHCHECKS_URL=https://hc-ping.com/your-check-id-here
   ```

2. **Healthcheck Script**: Located at `duplicati/config/ping-healthchecks.sh`
   - Automatically runs after backups complete
   - Only pings on successful backups
   - Configured via Duplicati's `run-script-after` option

3. **Duplicati Integration**: In backup job options:
   ```
   run-script-after=/config/ping-healthchecks.sh
   run-script-timeout=60s
   ```

**Testing:**
```bash
# Test the healthcheck script
docker exec duplicati bash -c "DUPLICATI__PARSED_RESULT=Success bash /config/ping-healthchecks.sh"

# Verify environment variable is set
docker exec duplicati bash -c "echo \$HEALTHCHECKS_URL"
```

**Setup Instructions:**
See `docker-projects/backups/SETUP_GUIDE.md` for detailed healthchecks.io setup steps.

## Monitoring

### Check Backup Status

1. Access web interface at http://192.168.4.200:8200
2. View dashboard for recent backup status
3. Check backup logs for detailed information
4. Review storage usage and retention compliance

### Common Issues

- **Backup failures**: Check logs for specific error messages
- **Storage full**: Review retention policy or increase backup storage
- **Performance issues**: Adjust backup schedule or throttle settings
- **Network errors**: Verify network connectivity to backup destination

## Maintenance

### Regular Tasks

- **Weekly**: Review backup logs for errors
- **Monthly**: Verify backup integrity by testing restoration
- **Quarterly**: Review and adjust retention policies
- **Annually**: Test full disaster recovery procedures

### Backup Retention Policy

Configure in Duplicati web interface:
- Settings → Backup → Retention
- Recommended: Keep all backups from last 30 days, weekly for 6 months, monthly for 2 years

## Restore Procedures

### Restore from Web Interface

1. Log in to Duplicati web interface
2. Select the backup job
3. Click "Restore"
4. Choose files/folders to restore
5. Select restore destination
6. Click "Restore files"

### Emergency Restore

If Duplicati container is unavailable:
1. Backups are stored in plain format at `C:\backups`
2. Reinstall Duplicati using docker-compose
3. Import backup configuration
4. Restore from existing backup sets

## Security Considerations

- Settings database is encrypted using SETTINGS_ENCRYPTION_KEY
- Web interface requires password authentication
- Backup source mounted read-only to prevent accidental modifications
- Consider encrypting backup destination for additional security
- Keep encryption keys and passwords in secure location

## References

- [Duplicati Official Documentation](https://duplicati.readthedocs.io/)
- [LinuxServer.io Duplicati Image](https://docs.linuxserver.io/images/docker-duplicati)
- Homelab backup standards: `homelab-docs/standards/backups-restore.md`
