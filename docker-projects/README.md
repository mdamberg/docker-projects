# Docker Projects - Infrastructure Management

This directory contains Docker-based infrastructure services and development projects.

## Directory Structure

```
docker-projects/
├── start-all-services.ps1    # Start all infrastructure services
├── stop-all-services.ps1     # Stop all infrastructure services
├── README.md                  # This file
│
├── Infrastructure Services/
│   ├── pie_hole/             # Pi-hole DNS ad-blocking (port 8082, 53)
│   ├── home_assist/          # Home Assistant (port 8123)
│   ├── media_stack/          # Full media server stack
│   │                         # - Plex (32400), Sonarr (8989), Radarr (7878)
│   │                         # - qBittorrent (8080), Overseerr (5055)
│   │                         # - Homarr (7575), Portainer (9443)
│   │                         # - LazyLibrarian (5299), Audiobookshelf (13378)
│   ├── LinkAce/              # Bookmark manager (port 8282)
│   ├── monitoring/           # System monitoring stack
│   │                         # - Uptime Kuma (3001), Glances (61208)
│   └── vpn/                  # VPN services
│                             # - HomeVPN/WireGuard (51820), PrivacyVPN (8888)
│
└── Development Projects/
    ├── flash_todo/
    ├── weather_api_project/
    ├── weather_app/
    ├── mcp_server/
    └── input_project/
```

## Quick Start

### Start All Infrastructure Services
```powershell
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects"
.\start-all-services.ps1
```

### Start Specific Services
```powershell
# Start only Pi-hole and Home Assistant
.\start-all-services.ps1 -Services "pihole,homeassistant"

# Start only media stack
.\start-all-services.ps1 -Services "mediastack"
```

### Stop All Services
```powershell
.\stop-all-services.ps1
```

### Stop Specific Services
```powershell
.\stop-all-services.ps1 -Services "mediastack"
```

## Service Management

### Available Services
- `pihole` - DNS ad-blocking and network filtering
- `homeassistant` - Home automation platform
- `mediastack` - Complete media server (Plex, Sonarr, Radarr, etc.)
- `linkace` - Bookmark and link manager
- `monitoring` - System monitoring (Uptime Kuma, Glances)
- `vpn` - VPN services (WireGuard server, ProtonVPN client)

### Individual Service Management

To manage a single service, navigate to its directory:

```powershell
cd pie_hole
docker-compose up -d      # Start
docker-compose down       # Stop
docker-compose restart    # Restart
docker-compose logs -f    # View logs
```

## Auto-Start on System Boot

All services have `restart: unless-stopped` policies, which means:
- ✅ Once started, they'll automatically restart after system reboot
- ✅ They'll restart if they crash
- ❌ They WON'T start if you've manually stopped them
- ❌ They won't start automatically the first time (need manual start)

### Option 1: Run Script on Login (Simplest)

1. Press `Win + R`, type `shell:startup`, press Enter
2. Right-click in the folder → New → Shortcut
3. Browse to: `C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\start-all-services.ps1`
4. Click Next, name it "Start Docker Services", Finish

**Note:** You may need to adjust PowerShell execution policy:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Option 2: Task Scheduler (Runs Before Login)

1. Open Task Scheduler (`Win + R` → `taskschd.msc`)
2. Create Basic Task
   - Name: "Start Docker Infrastructure"
   - Trigger: "When the computer starts"
   - Action: "Start a program"
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\start-all-services.ps1"`
3. Check "Run with highest privileges"
4. Check "Run whether user is logged on or not"

### Option 3: Docker Desktop Auto-Start

1. Open Docker Desktop Settings
2. General → Check "Start Docker Desktop when you log in"
3. Resources → Advanced → Check "Start Docker when system starts"

Then run the `start-all-services.ps1` script once after Docker starts.

## Adding New Services

When adding a new infrastructure service:

1. Create a new directory under `docker-projects/`
2. Add your `docker-compose.yml` with `restart: unless-stopped`
3. Update both scripts:
   - `start-all-services.ps1`
   - `stop-all-services.ps1`

   Add the service to the `$InfraServices` hashtable:
   ```powershell
   $InfraServices = @{
       'pihole' = 'pie_hole'
       'homeassistant' = 'home_assist'
       'mediastack' = 'media_stack'
       'linkace' = 'LinkAce'
       'yournewservice' = 'your_service_directory'  # Add this
   }
   ```

## Troubleshooting

### Check Running Containers
```powershell
docker ps
```

### Check All Containers (including stopped)
```powershell
docker ps -a
```

### View Service Logs
```powershell
cd <service-directory>
docker-compose logs -f
```

### Restart a Problematic Service
```powershell
cd <service-directory>
docker-compose restart
```

### Completely Rebuild a Service
```powershell
cd <service-directory>
docker-compose down
docker-compose up -d --build
```

## Port Reference

| Service | Port(s) | URL |
|---------|---------|-----|
| Pi-hole | 8082, 53 | http://localhost:8082/admin |
| Home Assistant | 8123 | http://localhost:8123 |
| Plex | 32400 | http://localhost:32400/web |
| Sonarr | 8989 | http://localhost:8989 |
| Radarr | 7878 | http://localhost:7878 |
| qBittorrent | 8080 | http://localhost:8080 |
| Overseerr | 5055 | http://localhost:5055 |
| Homarr | 7575 | http://localhost:7575 |
| Portainer | 9443 | https://localhost:9443 |
| LazyLibrarian | 5299 | http://localhost:5299 |
| Audiobookshelf | 13378 | http://localhost:13378 |
| Prowlarr | 9696 | http://localhost:9696 |
| LinkAce | 8282 | http://localhost:8282 |

## Notes

- All infrastructure services maintain their data in volumes or bind mounts
- Development projects are kept separate and not included in startup scripts
- Environment variables are loaded from `.env` files in each service directory
- All services use timezone `America/Chicago` (configurable per service)
