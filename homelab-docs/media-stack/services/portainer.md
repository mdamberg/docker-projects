# Portainer

## Overview

Portainer is a powerful Docker management platform that provides a web-based GUI for managing your Docker containers, images, networks, and volumes. Instead of using command-line Docker commands, Portainer lets you start, stop, inspect, and manage containers with clicks and visual interfaces.

**What it does**:
- Manage Docker containers (start, stop, restart, delete)
- View container logs and statistics in real-time
- Access container consoles (terminal/shell)
- Manage Docker images (pull, delete, build)
- Monitor resource usage per container
- Edit container configurations
- Manage networks and volumes
- Deploy stacks (docker-compose) via GUI
- View and manage all Docker resources in one place

**Why you need it**: While CLI Docker commands work, Portainer makes management visual, intuitive, and faster - especially helpful when troubleshooting issues or when you're learning Docker.

## Ports

| Port | Purpose |
|------|---------|
| `9443` | Portainer Web UI (HTTPS) |

**Note**: Portainer uses HTTPS by default on port 9443. Access via `https://localhost:9443`

## How It Works

1. **Portainer connects to Docker Engine** via the Docker socket (`/var/run/docker.sock`)
2. **Reads container, image, network, and volume information**
3. **Displays everything in a web interface**
4. **When you take actions** (restart container, pull image, etc.), Portainer sends commands to Docker Engine
5. **Updates in real-time** as containers start, stop, or change

Think of Portainer as a graphical remote control for your Docker environment.

## Service Interactions

**Manages**:
- All Docker containers in your media stack (Plex, Sonarr, Radarr, qBittorrent, etc.)
- Docker images, networks, volumes

**Monitors**:
- Container CPU, RAM, network usage
- Container health status
- Container logs

**Workflow**:
```
User accesses Portainer web interface
              “
    Views all running containers
              “
 Clicks "Restart" on a container
              “
Portainer sends restart command to Docker Engine
              “
      Container restarts
              “
   Portainer updates UI
```

## Environment Variables

Your configuration doesn't specify environment variables, using Portainer's defaults.

## Mounts & Volumes

| Mount | Purpose | Notes |
|-------|---------|-------|
| `/var/run/docker.sock:/var/run/docker.sock` | Docker engine access | **Critical** - allows Portainer to manage Docker |
| `C:/media/config/portainer:/data` | Portainer data and settings | Stores user accounts, configurations, custom templates |

**Critical**:
- Docker socket gives Portainer full control over Docker - this is a privileged mount
- Data volume stores all your Portainer settings - back this up

## Compose File Breakdown

```yaml
portainer:
  image: portainer/portainer-ce:latest
  container_name: portainer
  ports:
    - "9443:9443"                               # HTTPS web interface
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock  # Docker engine access
    - 'C:/media/config/portainer:/data'           # Settings and data
  restart: unless-stopped
```

**CE vs EE**: This uses `portainer-ce` (Community Edition) which is free. `portainer-ee` (Enterprise Edition) requires a license.

## Common Use Cases

- **Container Management**: Quickly restart containers when they misbehave
- **Log Viewing**: Check container logs without SSH or CLI commands
- **Resource Monitoring**: See which containers use the most CPU/RAM
- **Troubleshooting**: Access container shells to diagnose issues
- **Stack Deployment**: Deploy new docker-compose stacks via GUI
- **Learning Docker**: Visual way to understand Docker concepts

## Troubleshooting Tips

**Can't access Portainer?**
- Use HTTPS: `https://localhost:9443` (not http://)
- Check if container is running: `docker ps | grep portainer`
- View logs: `docker logs portainer`
- Browser security warning: Accept the self-signed certificate (safe for local use)

**"Cannot connect to Docker daemon"?**
- Verify Docker socket is mounted: `/var/run/docker.sock:/var/run/docker.sock`
- Check Docker is running on host
- Restart Portainer: `docker restart portainer`

**Can't perform actions on containers?**
- Check Portainer has Docker socket access
- Ensure you're logged in with proper permissions
- Some actions require stopping dependent containers first

**Lost admin password?**
- Stop Portainer container
- Delete `/data/portainer.db` in config folder (WARNING: resets everything)
- Restart Portainer and recreate admin account

## Initial Configuration Steps

### 1. First Launch
- Access: `https://localhost:9443`
- **Accept security warning** (self-signed certificate - normal for local use)
- **Create admin account** (username and strong password)
- **IMPORTANT**: Save these credentials - Portainer doesn't allow password recovery easily

### 2. Connect to Docker Environment
- Portainer will auto-detect local Docker environment
- Select "Get Started" or "Local"
- Portainer connects via Docker socket

### 3. Explore the Interface
- **Dashboard**: Overview of running containers, images, networks
- **Containers**: List of all containers with status
- **Images**: Available Docker images
- **Networks**: Docker networks
- **Volumes**: Persistent storage volumes
- **Stacks**: Docker Compose stacks

## Key Features Explained

### Container Management
- **Start/Stop/Restart**: One-click container control
- **Pause/Unpause**: Temporarily freeze containers
- **Kill**: Force stop unresponsive containers
- **Remove**: Delete containers (with option to remove volumes)
- **Recreate**: Rebuild container from image

### Container Details
- **Stats**: Real-time CPU, RAM, network, disk I/O
- **Logs**: Stream container logs (equivalent to `docker logs -f`)
- **Inspect**: View full container configuration (JSON)
- **Console**: Access container shell (like `docker exec -it bash`)
- **Attach**: Attach to container's main process output

### Stack Management
- **Deploy Stack**: Paste docker-compose YAML and deploy
- **Edit Stack**: Modify running stack configurations
- **Update Stack**: Redeploy with new compose file
- **Remove Stack**: Delete entire stack and its containers

### Image Management
- **Pull Images**: Download images from Docker Hub
- **Remove Images**: Delete unused images to free space
- **Build Images**: Build from Dockerfile via GUI
- **Image Layers**: View image layer history

### Network & Volume Management
- **Create Networks**: Custom Docker networks
- **Inspect Networks**: See which containers use which networks
- **Create Volumes**: Persistent storage volumes
- **Browse Volumes**: View volume contents

## Performance Notes

- **CPU**: Minimal - only when you interact with it
- **RAM**: ~50-100MB
- **Disk**: ~200MB for Portainer itself, plus database grows with usage
- **Network**: Only when accessing web UI or performing operations

## Common Tasks via Portainer

### Restart a Container
1. Containers ’ Select container ’ Restart

### View Container Logs
1. Containers ’ Select container ’ Logs
2. Auto-refresh enabled by default
3. Search and filter logs

### Access Container Shell
1. Containers ’ Select container ’ Console
2. Select shell (bash, sh, etc.)
3. Click "Connect"
4. Execute commands directly in container

### Check Resource Usage
1. Containers ’ Select container ’ Stats
2. View real-time CPU, RAM, network graphs

### Deploy a New Stack
1. Stacks ’ Add Stack
2. Name your stack
3. Paste docker-compose.yml content
4. Set environment variables if needed
5. Deploy

### Pull New Image Version
1. Images ’ Select image ’ Pull
2. Watchtower handles this automatically, but useful for manual updates

### Clean Up Unused Resources
1. Images ’ Remove unused images
2. Volumes ’ Remove unused volumes
3. Networks ’ Remove unused networks

## Security Features

**User Management**: Create multiple users with different access levels (Business Edition feature)

**Access Control**: Restrict which users can access which environments

**Activity Logs**: Audit trail of all actions taken in Portainer

**HTTPS**: Encrypted communication (self-signed cert by default)

## Security Best Practices

 **Strong Admin Password**: Use a complex password
 **Regular Backups**: Backup `/data` folder regularly
 **Network Isolation**: Don't expose Portainer to internet without VPN/firewall
 **Update Regularly**: Keep Portainer updated (Watchtower handles this)
 **Limited Access**: Only trusted users should have Portainer access

**Warning**: Portainer has full Docker control - anyone with access can manage all containers, including starting/stopping critical services.

## Advanced Features

**App Templates**: Quick-deploy popular applications from templates

**Custom Templates**: Create your own templates for frequently deployed services

**Webhooks**: Trigger stack updates via webhooks (CI/CD integration)

**Edge Agent**: Manage remote Docker hosts (not needed for local setup)

**Registry Management**: Connect to private Docker registries

**Kubernetes Support** (Business Edition): Manage Kubernetes clusters

## Portainer Business Edition

Free Business Edition features (up to 5 nodes):
- Better RBAC (Role-Based Access Control)
- More app templates
- Better UI/UX
- OAuth/SSO support
- Support and updates

**Do you need it?** Not for homelab use - Community Edition is perfect for your setup.

## Monitoring and Alerting

Portainer doesn't provide alerting, but you can:
- Monitor container health (visual indicators)
- Check resource usage via Stats
- View logs for errors

For alerting, use dedicated tools like:
- Uptime Kuma (in your monitoring stack)
- Netdata
- Prometheus + Alertmanager

## When to Use Portainer vs. CLI

**Use Portainer when**:
- Quickly checking container status
- Viewing logs
- Restarting containers
- Learning Docker concepts
- Managing multiple containers visually

**Use CLI when**:
- Scripting/automation
- Complex operations
- You prefer command line
- Faster for single commands (if you know them)

**Both are valid** - use what works best for your workflow!

## Backup & Restore

**Backup**:
- Backup `C:/media/config/portainer` folder
- Contains user accounts, templates, settings

**Restore**:
- Stop Portainer
- Restore backed-up data folder
- Start Portainer
- Login with previous credentials

## Important Notes

- **Docker Socket Access**: Portainer has full Docker control - be cautious who has access
- **Self-Signed Certificate**: Browser warnings are normal for local use; add exception
- **No Multi-Factor Auth** (CE): Use strong passwords since MFA isn't available in free version
- **Resource Cleanup**: Periodically remove unused images/volumes to free disk space
- **Container Dependencies**: Be aware of dependencies before stopping/removing containers (e.g., qBittorrent needs Gluetun)
