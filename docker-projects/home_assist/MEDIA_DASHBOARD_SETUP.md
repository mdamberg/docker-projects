# Media Dashboard Setup Guide

This guide will walk you through setting up a comprehensive media dashboard in Home Assistant that displays statistics and charts from all your media services (Prowlarr, Radarr, Sonarr, qBittorrent, Plex).

## What You'll Get

- **Prowlarr Statistics**: Queries, grabs, success rates, indexer performance
- **Library Stats**: Movie/TV counts, download completion rates
- **Download Activity**: Queue monitoring, transfer speeds, torrent status
- **Plex Streams**: Who's watching what (optional)
- **Container Status**: Docker container health monitoring (optional)
- **Beautiful Charts**: Historical graphs showing trends over time

## Files Created

1. `media_dashboard_sensors.yaml` - REST sensors that pull data from your services
2. `media_dashboard_templates.yaml` - Calculated metrics (success rates, totals, etc.)
3. `media_dashboard.yaml` - The actual dashboard configuration
4. `MEDIA_DASHBOARD_SETUP.md` - This guide

---

## Step 1: Gather API Keys

You'll need API keys from your services. Here's where to find them:

### Prowlarr API Key
1. Open Prowlarr: `http://localhost:9696`
2. Go to **Settings** → **General**
3. Scroll to **Security** section
4. Copy the **API Key**

### Radarr API Key
1. Open Radarr: `http://localhost:7878`
2. Go to **Settings** → **General**
3. Scroll to **Security** section
4. Copy the **API Key**

### Sonarr API Key
1. Open Sonarr: `http://localhost:8989`
2. Go to **Settings** → **General**
3. Scroll to **Security** section
4. Copy the **API Key**

### Overseerr API Key (Optional)
1. Open Overseerr: `http://localhost:5055`
2. Go to **Settings** → **General**
3. Copy the **API Key**

---

## Step 2: Configure Sensors

### 2.1 Edit media_dashboard_sensors.yaml

Open `configuration/config/media_dashboard_sensors.yaml` and replace the placeholder API keys:

- Replace `YOUR_PROWLARR_API_KEY_HERE` with your Prowlarr API key
- Replace `YOUR_RADARR_API_KEY_HERE` with your Radarr API key
- Replace `YOUR_SONARR_API_KEY_HERE` with your Sonarr API key
- Replace `YOUR_OVERSEERR_API_KEY_HERE` with your Overseerr API key (or remove that section)

### 2.2 Add to configuration.yaml

Edit `configuration/config/configuration.yaml` and add these lines:

```yaml
# Media Dashboard Sensors
rest: !include media_dashboard_sensors.yaml

# Media Dashboard Templates
template: !include media_dashboard_templates.yaml
```

**Full example of what your configuration.yaml should look like:**

```yaml
# Loads default set of integrations. Do not remove.
default_config:

# Load frontend themes from the themes folder
frontend:
  themes: !include_dir_merge_named themes

automation: !include automations.yaml
script: !include scripts.yaml
scene: !include scenes.yaml

# Media Dashboard Sensors
rest: !include media_dashboard_sensors.yaml

# Media Dashboard Templates
template: !include media_dashboard_templates.yaml
```

### 2.3 Restart Home Assistant

1. Go to **Settings** → **System** → **Restart**
2. Wait for Home Assistant to restart (1-2 minutes)

### 2.4 Verify Sensors Are Working

After restart:
1. Go to **Developer Tools** → **States**
2. Search for "prowlarr" - you should see sensors like:
   - `sensor.prowlarr_indexer_count`
   - `sensor.prowlarr_total_queries`
   - `sensor.prowlarr_total_grabs`
3. Check that they have values (not "unavailable" or "unknown")

**If sensors show "unavailable":**
- Double-check your API keys
- Verify the service URLs are correct (use Docker service names like `prowlarr`, `radarr`, etc.)
- Check Home Assistant logs: **Settings** → **System** → **Logs**

---

## Step 3: Create the Dashboard

### 3.1 Add New Dashboard

1. Go to **Settings** → **Dashboards**
2. Click **Add Dashboard** (bottom right)
3. Enter:
   - **Title**: Media Stack
   - **Icon**: mdi:movie-open
   - **URL**: media-stack
4. Click **Create**

### 3.2 Enable YAML Mode

1. Click the **three dots** (⋮) in the top right
2. Select **Edit Dashboard**
3. Click the **three dots** again
4. Select **Raw configuration editor**

### 3.3 Paste Dashboard Configuration

1. **Delete** all existing content in the editor
2. Open `media_dashboard.yaml`
3. **Copy** the entire contents
4. **Paste** into the Raw configuration editor
5. Click **Save**

### 3.4 View Your Dashboard

1. Click the **X** to exit edit mode
2. You should now see your media dashboard with all the stats and charts!

---

## Step 4: Configure Plex Integration (Optional)

To show "who's watching what" from Plex:

### 4.1 Add Plex Integration

1. Go to **Settings** → **Devices & Services**
2. Click **Add Integration**
3. Search for "**Plex**"
4. Follow the prompts to sign in with your Plex account
5. Select your Plex server

### 4.2 Plex Sensors Will Appear

After configuration, you'll get:
- `sensor.plex_[your_server_name]` - Shows number of active streams
- `media_player.plex_[device_name]` - Individual player entities for each active stream

The dashboard will automatically show Plex activity in the "Now Streaming" section.

---

## Step 5: Container Monitoring (Optional)

To monitor Docker container status:

### Option A: Portainer Integration (if available in HACS)

1. Search HACS for "Portainer"
2. Install and configure with your Portainer API key

### Option B: Docker Socket Monitoring

Add this to your Home Assistant docker-compose.yml:

```yaml
  homeassistant:
    # ... existing config ...
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro  # Add this line
```

Then add to `configuration.yaml`:

```yaml
# Docker monitoring
docker:
  containers:
    - plex
    - radarr
    - sonarr
    - prowlarr
    - qbittorrent
    - overseerr
  scan_interval: 30
```

---

## Troubleshooting

### Sensors Show "Unknown" or "Unavailable"

**Check:**
1. API keys are correct
2. Services are running (`docker ps`)
3. Network connectivity between Home Assistant and services
4. Home Assistant logs for errors

**Test API manually:**
```bash
# Test Prowlarr API (replace API_KEY)
curl -H "X-Api-Key: YOUR_API_KEY" http://localhost:9696/api/v1/indexer
```

### Dashboard Shows "Entity not found"

1. Verify sensors exist in **Developer Tools** → **States**
2. Check sensor names match exactly (case-sensitive)
3. Wait a few minutes for sensors to populate with data

### Graphs Show No Data

- Sensors need time to collect historical data
- Wait 24 hours for meaningful graphs
- Ensure sensors are updating (check last_updated timestamp)

### qBittorrent Sensors Not Working

The qBittorrent API requires:
1. Web UI enabled
2. Bypass authentication from localhost (Settings → Web UI → Bypass authentication for localhost)
3. Correct port mapping in docker-compose (8080:8080)

---

## Customization

### Change Update Intervals

In `media_dashboard_sensors.yaml`, adjust `scan_interval`:
- `30` = 30 seconds (frequent updates, more resource usage)
- `300` = 5 minutes (balanced)
- `600` = 10 minutes (less frequent)

### Add More Metrics

Prowlarr API endpoints:
- `/api/v1/indexer` - Indexer list
- `/api/v1/indexerstats` - Statistics
- `/api/v1/history` - Search history

Radarr/Sonarr API endpoints:
- `/api/v3/movie` or `/api/v3/series` - Library
- `/api/v3/queue` - Download queue
- `/api/v3/calendar` - Upcoming releases

### Customize Dashboard Layout

Edit `media_dashboard.yaml`:
- Reorder cards by cutting/pasting sections
- Change card types (entity → statistic, gauge → sensor, etc.)
- Adjust `hours_to_show` for graphs (24, 48, 168 for 7 days)
- Add/remove sections

---

## Support

**If you encounter issues:**

1. Check Home Assistant logs: **Settings** → **System** → **Logs**
2. Verify all services are accessible from Home Assistant container
3. Test API endpoints manually with curl
4. Check that API keys haven't expired or changed

**Common fixes:**
- Restart Home Assistant after configuration changes
- Use Docker service names (`prowlarr:9696`) not `localhost`
- Ensure all services are on the same Docker network

---

## Next Steps

Once everything is working:

1. **Explore the dashboard** - Click through different views
2. **Customize layouts** - Adjust to your preference
3. **Add automations** - Trigger notifications based on sensors
4. **Create mobile view** - Optimize for phone viewing

Enjoy your unified media dashboard! 🎬📺🎵
