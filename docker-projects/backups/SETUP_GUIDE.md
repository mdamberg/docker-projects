# Duplicati Backup + Ntfy Notifications Setup Guide

## Step 1: Access Duplicati Web Interface

Open your browser and go to: **http://localhost:8200** or **http://192.168.4.200:8200**

On first run, Duplicati will ask you to set a password. Choose a secure password and save it.

## Step 2: Create Backup Job

1. Click **"Add backup"** button
2. Choose **"Configure a new backup"**
3. Click **Next**

### General Settings
- **Name**: "Homelab Docker Configs Nightly Backup"
- **Description**: "Nightly backup of all Docker project configurations"
- **Encryption**: Choose "AES-256 encryption" and set a passphrase (SAVE THIS!)
- Click **Next**

### Destination
- **Storage Type**: Choose "Local folder or drive"
- **Path**: `/backups` (this maps to C:\backups on your host)
- Click **Next**

### Source Data
- Click **"Add path"**
- Select `/source/docker-configs` (this maps to C:\docker-projects on your host)
- You can exclude certain patterns if needed (e.g., `*/node_modules/*`, `*/.git/*`)
- Click **Next**

### Schedule
- **Automatically run backups**: Check this box
- **Run**: Choose "Daily"
- **Time**: Set to "1:00 AM" (or your preferred time)
- Click **Next**

### Options - IMPORTANT FOR NOTIFICATIONS

In the options screen, scroll down and click **"Edit as text"** to add these advanced options:

```
--send-http-url=https://ntfy.sh/YOUR_TOPIC_NAME
--send-http-message=Backup %OPERATIONNAME% completed: %PARSEDRESULT%
--send-http-level=Success,Warning,Error
--send-http-result-output-format=Json
```

**Replace `YOUR_TOPIC_NAME` with a unique topic name** (e.g., `homelab-backups-matt-2024`).
This topic name is what you'll subscribe to in the ntfy app.

### Alternative: Use Custom JSON Payload (Recommended)

For better formatted notifications, use:
```
--send-http-url=https://ntfy.sh/YOUR_TOPIC_NAME
--send-http-message={"topic":"YOUR_TOPIC_NAME","title":"Duplicati Backup %PARSEDRESULT%","message":"Backup: %OPERATIONNAME%\\nResult: %PARSEDRESULT%\\nBackup: %backup-name%","priority":3,"tags":["backup","duplicati"]}
--send-http-level=Success,Warning,Error
--send-http-result-output-format=Json
```

Click **Save** to create the backup job.

## Step 3: Set Up Ntfy Notifications on Your Device

### On Your Phone:
1. Install ntfy app from Google Play Store or Apple App Store
2. Open the app
3. Click **"+"** to add a subscription
4. Enter the same topic name you used above (e.g., `homelab-backups-matt-2024`)
5. Click Subscribe

### On Your Computer:
1. Go to https://ntfy.sh
2. Enter your topic name in the subscribe box
3. Click Subscribe
4. Keep the tab open or enable browser notifications

## Step 4: Test the Backup

1. In Duplicati, find your newly created backup job
2. Click the job name
3. Click **"Run now"** to test it immediately
4. You should receive a notification on your phone/browser when it completes!

## Step 5: Verify Backup Files

After the backup runs, check that files were created in `C:\backups` on your host machine.

## Important Notes

- **Save your encryption passphrase!** You'll need it to restore backups.
- **Save your ntfy topic name!** You'll need it to receive notifications.
- **New encryption key**: Your new Duplicati encryption key is stored in `.env`:
  `Ci4slb7PedRe2k982YqrhB6usueFeZF80POQ4SQwLrs=`
- Backups will run automatically at the scheduled time (1:00 AM by default)
- You can create multiple backup jobs for different directories if needed

## Troubleshooting

### Not Receiving Notifications?
- Check that the ntfy URL in Duplicati options is correct
- Make sure you're subscribed to the same topic name
- Try running the backup manually and check Duplicati logs
- Test the ntfy URL by sending a test notification:
  ```bash
  curl -d "Test notification" https://ntfy.sh/YOUR_TOPIC_NAME
  ```

### Backup Failing?
- Check Duplicati logs in the web interface
- Verify source and destination paths are accessible
- Check disk space on C:\backups drive

## Next Steps

- Consider setting up retention policies (how long to keep old backups)
- Set up additional backup destinations (cloud storage, network drive)
- Test restoration process to ensure backups are working correctly
- Document your encryption passphrase in a secure location
