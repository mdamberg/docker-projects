# Dashdot

## Overview

Dashdot is a simple, modern server dashboard that displays real-time system information about your server hardware and resources. It provides a clean, minimalist interface showing CPU usage, RAM, storage, network activity, and more - all in a visually appealing format.

**What it does**:
- Displays real-time CPU, RAM, and disk usage
- Shows network transfer rates (upload/download)
- Monitors storage capacity across all drives
- Displays system information (OS, CPU model, uptime)
- Updates metrics in real-time with beautiful graphs
- Minimal resource footprint

**Why you need it**: Quickly check your server's health without SSH or complex monitoring tools. Perfect for embedding in dashboards like Homarr or accessing directly.

## Ports

| Port | Purpose |
|------|---------|
| `3002` (host) ’ `3001` (container) | Dashdot Web UI |

**Note**: Your configuration maps host port 3002 to container port 3001, so access via `http://localhost:3002`

## How It Works

1. **Dashdot reads system info** from the host filesystem (via `/mnt/host` mount)
2. **Processes data** and calculates metrics (CPU %, RAM %, disk space, etc.)
3. **Serves web interface** with real-time graphs and statistics
4. **Updates continuously** without page refresh

## Service Interactions

**Monitors**:
- Your physical server/host machine (CPU, RAM, disks, network)

**Integrates With**:
- **Homarr** (can embed Dashdot widget or link to it)
- Any dashboard that supports iFrame embedding

**Workflow**:
```
Dashdot reads host system via /mnt/host mount
                “
       Calculates current metrics
                “
    Displays in web interface with graphs
                “
      Updates every few seconds
```

## Environment Variables

Your configuration doesn't specify any environment variables, which means Dashdot uses defaults. Common optional variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `DASHDOT_PORT` | Internal port | `3001` |
| `DASHDOT_USE_NETWORK` | Enable network monitoring | `true` |
| `DASHDOT_ENABLE_CPU_TEMP` | Show CPU temperature | `true` (if supported) |

## Mounts & Volumes

| Mount | Purpose | Notes |
|-------|---------|-------|
| `/:/mnt/host:ro` | Read-only access to entire host filesystem | **Critical** for reading system information |

**Important**:
- `:ro` means read-only - Dashdot can't modify your system
- Privileged mode (`privileged: true`) gives access to hardware sensors for temperature readings

## Compose File Breakdown

```yaml
dashdot:
  image: mauricenino/dashdot:latest
  container_name: dashdot
  restart: unless-stopped
  privileged: true              # Access to hardware sensors
  ports:
    - "3002:3001"               # Maps host 3002 to container 3001
  volumes:
    - /:/mnt/host:ro            # Read-only host access
```

### Privileged Mode
Dashdot runs in privileged mode to access hardware sensors (CPU temperature, fan speeds, etc.). This is safe since:
- Volume is read-only (`:ro`)
- Dashdot is a monitoring tool, not a management tool
- From a reputable developer with open-source code

## Common Use Cases

- **Quick Health Check**: At-a-glance view of server health
- **Performance Monitoring**: See if CPU/RAM is maxed out during heavy tasks
- **Storage Management**: Check which drives are filling up
- **Network Monitoring**: Monitor upload/download activity
- **Embedded in Dashboards**: Add to Homarr as widget or iFrame

## Troubleshooting Tips

**Dashdot shows no data or errors?**
- Verify `/:/mnt/host:ro` mount is correctly configured
- Check if privileged mode is enabled
- View logs: `docker logs dashdot`
- Restart container: `docker restart dashdot`

**CPU temperature not showing?**
- Some hardware doesn't expose temperature sensors
- Try enabling: Set env variable `DASHDOT_ENABLE_CPU_TEMP=true`
- Windows hosts may not support temperature monitoring

**Network stats not updating?**
- Ensure `DASHDOT_USE_NETWORK=true` (default)
- Some network configurations may not report stats correctly

**High CPU usage from Dashdot itself?**
- Unusual - Dashdot is very lightweight
- Check for system issues
- Restart container

## Features Breakdown

### CPU Monitoring
- **Real-time usage percentage** per core
- **Load averages** (1min, 5min, 15min)
- **CPU model and speed**
- **Temperature** (if available)
- **Historical graph** of usage over time

### Memory Monitoring
- **RAM usage** (used vs total)
- **Usage percentage**
- **Available memory**
- **Historical graph** of usage

### Storage Monitoring
- **All mounted drives** displayed
- **Used vs total capacity**
- **Usage percentage** with visual bar
- **Filesystem type** (NTFS, ext4, etc.)

### Network Monitoring
- **Current upload/download speeds**
- **Historical graphs** of network activity
- **Total transferred** since boot
- **Per-interface monitoring** (if multiple NICs)

### System Information
- **OS and version**
- **Kernel version**
- **Uptime** (how long system has been running)
- **Hostname**
- **CPU architecture**

## Performance Notes

- **CPU**: Extremely light (~1-2% even during updates)
- **RAM**: ~20-50MB
- **Disk**: Minimal - no persistent storage needed
- **Network**: Only what's needed to serve the web page

**Refresh Rate**: Updates every 1-2 seconds for smooth real-time monitoring

## Embedding in Dashboards

### In Homarr
1. Add Widget ’ iFrame
2. URL: `http://dashdot:3001` (or `http://localhost:3002` if accessing from outside)
3. Set size to fill space
4. Dashdot displays within your Homarr dashboard

### In Other Dashboards
- Use iFrame embed: `<iframe src="http://localhost:3002"></iframe>`
- Most dashboards support iFrame widgets

## UI Customization

Dashdot offers limited customization:
- **Theme**: Automatically adapts to light/dark mode based on browser preference
- **Layout**: Responsive and adapts to screen size
- **No settings page**: Dashdot is designed to be simple and work out of the box

## Comparison to Other Monitoring Tools

**Dashdot vs. Netdata**:
- Dashdot: Simpler, prettier, lower resource usage
- Netdata: More detailed metrics, historical data, alerting

**Dashdot vs. Glances**:
- Dashdot: Modern web UI, better looking
- Glances: CLI-friendly, more lightweight, more metrics

**Dashdot vs. Portainer**:
- Dashdot: System-level monitoring (CPU, RAM, disk)
- Portainer: Docker container management (different purpose)

**Why use Dashdot?** Clean, modern interface. Perfect for quick glances. Low resource usage.

## Access Methods

**Direct Access**: `http://localhost:3002`

**Via Homarr**: Embed as widget or link as service tile

**Mobile**: Responsive design works on phones/tablets

**Multiple Monitors**: Safe to have multiple browser tabs open

## Security Considerations

 **Read-Only Access**: Dashdot can't modify your system (`:ro` mount)
 **No Authentication**: Consider adding reverse proxy with auth if exposing to internet
 **Privileged Mode**: Required for sensors, but Dashdot is trustworthy
 **No Config Files**: Nothing to back up, nothing to secure

**Best Practice**: Don't expose Dashdot directly to the internet without authentication. Use a reverse proxy (Nginx, Traefik) with basic auth if needed.

## No Configuration Needed

Dashdot is designed to work immediately:
- No setup wizard
- No configuration files
- No user accounts
- Just access the URL and see your stats

## Use Cases by Scenario

**Troubleshooting**: "Is my CPU maxed out? Is RAM full?"

**Capacity Planning**: "Do I need to add more storage?"

**Performance Testing**: "How does my server handle Plex transcoding?"

**General Monitoring**: Embed in Homarr for constant visibility

**Show Off Your Setup**: Pretty dashboard to show friends/family

## Limitations

- **No historical data beyond graphs**: Doesn't store long-term metrics
- **No alerting**: Can't notify you of issues (use Netdata or Prometheus for that)
- **No Docker-specific metrics**: Use Portainer for container stats
- **Limited customization**: Simple by design

## When to Use Alternatives

**Need detailed metrics?** Use Netdata or Prometheus + Grafana

**Need alerting?** Use Zabbix, Nagios, or Prometheus Alertmanager

**Need Docker monitoring?** Use Portainer or cAdvisor

**Need log aggregation?** Use ELK stack or Loki

**Dashdot is perfect for**: Simple, beautiful, real-time system overview

## Important Notes

- **Windows Paths**: The `/:/mnt/host:ro` mount works on Windows - Docker handles the translation
- **Privileged Mode**: Required for full functionality but safe for this use case
- **No Data Persistence**: If container stops, no data is lost (there's nothing to lose - it's all real-time)
- **Resource Friendly**: You can leave Dashdot running 24/7 without concern
