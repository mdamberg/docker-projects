#!/bin/bash
# Duplicati Healthchecks.io Ping Script
# This script pings healthchecks.io after a successful backup

# Healthchecks.io ping URL for docker_backup_check
# This is set via environment variable in docker-compose.yml
# HEALTHCHECKS_URL is passed from the container environment

# Duplicati sets the DUPLICATI__PARSED_RESULT environment variable
# Possible values: Success, Warning, Error, Fatal
RESULT="${DUPLICATI__PARSED_RESULT}"

# Only ping healthchecks if the backup was successful
if [ "$RESULT" = "Success" ]; then
    echo "Backup successful, pinging healthchecks.io..."
    curl -fsS --retry 3 "$HEALTHCHECKS_URL" > /dev/null
    if [ $? -eq 0 ]; then
        echo "Successfully pinged healthchecks.io"
    else
        echo "Failed to ping healthchecks.io"
    fi
else
    echo "Backup result was '$RESULT', not pinging healthchecks.io"
fi
