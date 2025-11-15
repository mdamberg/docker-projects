# Pi-hole Documentation

## What is it?
Pi-hole is a network-wide ad blocker that acts as a DNS sinkhole. It blocks ads by preventing DNS resolution for known advertising and tracking domains. Instead of blocking ads at the browser level, Pi-hole blocks them at the network level before they even reach your devices.

## Benefits
- **Network-wide protection**: Blocks ads on all devices including phones, tablets, smart TVs, and IoT devices
- **Faster browsing**: Ads are blocked before they load, reducing bandwidth usage and page load times
- **Privacy**: Blocks tracking and telemetry domains
- **Customizable**: Add your own blocklists or whitelist specific domains
- **Detailed statistics**: See exactly what's being blocked and when

---

## Configuration Levels

Pi-hole can be configured at two different levels:

### Device Level
- Allows users to utilize different configurations for each of their devices (phone, desktop, laptop, etc.)
- Set DNS manually on each device to point to Pi-hole
- Provides flexibility - some devices can use Pi-hole while others don't
- Useful for testing before network-wide deployment

### Network Level (Recommended)
- An "all encompassing" version where any and all devices on that network get ad blocking automatically
- Configured at the router/DHCP server level
- All devices receive Pi-hole's IP address as their DNS server automatically
- No manual configuration needed on individual devices

---

## Our Setup

### Environment
- **Host OS**: Windows 11
- **Deployment Method**: Docker container
- **Container Image**: `pihole/pihole:latest`
- **Working Directory**: `C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\pie_hole`

### Port Configuration
- **DNS Port**: `53` (TCP/UDP) - Standard DNS port
  - Initially attempted port `5335` due to port 53 conflict
  - Resolved by disabling Windows Internet Connection Sharing (ICS) service
- **Web Interface**: `8082` (HTTP)
- **HTTPS**: `8443`

### Network Details
- **Host IP Address**: `192.168.4.200`
- **Subnet Mask**: `255.255.252.0`
- **Gateway/Router**: `192.168.4.1`
- **DNS Configuration**: Localhost (`127.0.0.1`) for testing on host machine

---

## Docker Setup

### docker-compose.yml
```yaml
version: '3'
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      - "8082:80"      # Web interface
      - "8443:443"     # HTTPS
      - "53:53/tcp"    # DNS
      - "53:53/udp"    # DNS
    environment:
      - TZ=America/Chicago
    volumes:
      - ./etc-pihole:/etc/pihole
    cap_add:
      - CAP_NET_ADMIN
    restart: unless-stopped
```

### Volume Mapping
- **Local Path**: `./etc-pihole`
- **Container Path**: `/etc/pihole`
- **Purpose**: Persists Pi-hole configuration, blocklists, and databases across container restarts

---

## Initial Configuration Steps

### 1. Port 53 Conflict Resolution

**Problem**: Windows Internet Connection Sharing (ICS) service was using port 53

**Solution**:
```powershell
# Open PowerShell as Administrator

# Disable ICS service
Set-Service -Name "SharedAccess" -StartupType Disabled

# Set registry key to ensure it stays disabled
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess" /v Start /t REG_DWORD /d 4 /f

# Force kill the process
taskkill /F /PID <process_id>

# Restart computer to ensure ICS doesn't restart
```

### 2. DNS Settings Configuration

**Upstream DNS Servers** (Settings → DNS):
- ✅ Google (ECS, DNSSEC) - IPv4 and IPv6
- ✅ Cloudflare (DNSSEC) - IPv4 and IPv6

**Advanced DNS Settings**:
- ✅ Never forward non-FQDN queries
- ✅ Never forward reverse lookups for private IP ranges
- ✅ Use DNSSEC

**Interface Settings**:
- ✅ Allow only local requests (recommended for security)

### 3. Blocklists Added

Total domains blocked: **263,689**

**Blocklists**:
1. `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts` - Comprehensive unified hosts file
2. `https://dbl.oisd.nl/` - Very popular, well-maintained list
3. `https://v.firebog.net/hosts/AdguardDNS.txt` - AdGuard's DNS blocklist
4. `https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt` - Additional comprehensive list
5. `https://v.firebog.net/hosts/Easylist.txt` - EasyList for ads

**After adding blocklists**: Run "Update Gravity" (Tools → Update Gravity) to activate them

---

## DNS Configuration Methods

### Method 1: Device-Level (Current Implementation)

**Windows Network Adapter Settings**:
1. Press `Windows Key + R`
2. Type: `ncpa.cpl` and press Enter
3. Right-click "Wi-Fi" → Properties
4. Double-click "Internet Protocol Version 4 (TCP/IPv4)"
5. Select "Use the following DNS server addresses:"
   - **Preferred DNS**: `127.0.0.1` (localhost - for host machine)
   - **Alternate DNS**: `1.1.1.1` (Cloudflare backup)
6. Click OK twice

**Alternative - PowerShell Method** (requires Administrator):
```powershell
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("127.0.0.1","1.1.1.1")

# Verify
Get-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -AddressFamily IPv4
```

### Method 2: Network-Level (Recommended for All Devices)

**Router Configuration**:
1. Access router admin panel (typically http://192.168.4.1)
2. Navigate to DHCP/DNS settings
3. Set Primary DNS: `192.168.4.200` (host machine IP)
4. Set Secondary DNS: `1.1.1.1` (Cloudflare backup)
5. Save and reboot router

**Note**: All devices will automatically receive Pi-hole's IP as their DNS server via DHCP

### Method 3: Pi-hole DHCP Server (Alternative)

If router doesn't support custom DNS configuration:
1. Disable DHCP on router
2. Enable DHCP in Pi-hole (Settings → DHCP)
3. Configure DHCP range (e.g., 192.168.4.100 - 192.168.4.250)
4. Set gateway to router IP (192.168.4.1)

---

## Accessing Pi-hole

### Web Interface
- **URL**: http://localhost:8082/admin (from host machine)
- **URL**: http://192.168.4.200:8082/admin (from other devices on network)

### API Integration
- **API Key Location**: Retrieved from container via `docker exec -it pihole cat /etc/pihole/cli_pw`
- **Used by**: Homarr dashboard integration using `http://host.docker.internal:8082/admin`

---

## Docker Management Commands

### Starting/Stopping Pi-hole
```powershell
# Navigate to project directory
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\pie_hole"

# Stop Pi-hole
docker-compose down

# Start Pi-hole
docker-compose up -d

# View logs
docker logs pihole

# View real-time logs
docker logs -f pihole
```

### Checking Status
```powershell
# Check if container is running
docker ps | Select-String pihole

# Check port bindings
netstat -ano | findstr ":53"
```

### Accessing Pi-hole Container
```powershell
# Execute commands in container
docker exec -it pihole <command>

# Examples:
docker exec -it pihole pihole -v                    # Check version
docker exec -it pihole pihole -g                    # Update gravity
docker exec -it pihole cat /etc/pihole/pihole.toml  # View config
```

---

## Troubleshooting

### Common Issues

**1. Port 53 Already in Use**
- Check what's using port 53: `netstat -ano | findstr ":53"`
- Identify process: `Get-Process -Id <PID>`
- Common culprits: ICS, Docker Desktop, WSL, DNS Client service

**2. No Queries Showing on Dashboard**
- Verify DNS is configured correctly on client device
- Test with: `nslookup google.com 192.168.4.200`
- Check Pi-hole container is running: `docker ps`
- Verify port 53 is accessible: `Test-NetConnection -ComputerName 192.168.4.200 -Port 53`

**3. Some Websites Not Loading**
- Check Pi-hole query log for blocked domains
- Whitelist necessary domains (Domains → Whitelist)
- Temporarily disable Pi-hole to test: Click "Disable" on dashboard

**4. Container Won't Start on Port 53**
- Restart computer after disabling ICS
- Check for other services using port 53
- Consider using alternative port (5335) if necessary

---

## Important Notes

### Host Machine Requirements
- **Must be always on**: Pi-hole only works when the host machine is running
- If host shuts down, devices lose DNS resolution
- Consider using a dedicated machine (Raspberry Pi, old PC, or always-on server)

### VPN Considerations
- ProtonVPN (or other VPNs) may interfere with DNS queries
- May need to configure VPN to use Pi-hole DNS
- Some VPNs override DNS settings

### Backup and Restore
```powershell
# Backup Pi-hole configuration
docker exec pihole pihole -a -t

# Configuration stored in: ./etc-pihole/ (persisted volume)
# Manually backup this directory for full restore capability
```

---

## Maintenance

### Regular Tasks

**Update Blocklists** (Weekly/Monthly):
- Go to Tools → Update Gravity
- Or via command: `docker exec -it pihole pihole -g`

**Review Query Log**:
- Check for false positives (legitimate domains being blocked)
- Add to whitelist as needed

**Update Pi-hole**:
```powershell
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\pie_hole"
docker-compose pull
docker-compose down
docker-compose up -d
```

**Monitor Dashboard**:
- Review blocking statistics
- Check for unusual query patterns
- Verify upstream DNS servers are responding

---

## Additional Resources

- **Pi-hole Documentation**: https://docs.pi-hole.net/
- **Pi-hole GitHub**: https://github.com/pi-hole/pi-hole
- **Docker Hub**: https://hub.docker.com/r/pihole/pihole
- **Community Blocklists**: https://firebog.net/

---

## Summary

Pi-hole is successfully deployed on Windows 11 using Docker, running on standard DNS port 53 after resolving Windows ICS conflicts. The web interface is accessible on port 8082, and the system is currently configured for device-level DNS (localhost). For network-wide ad blocking, configure the router to use `192.168.4.200` as the primary DNS server, ensuring all devices on the network benefit from Pi-hole's ad-blocking capabilities.

**Current Status**: ✅ Operational - Blocking ads on host machine  
**Total Domains on Blocklists**: 263,689  
**Web Interface**: http://localhost:8082/admin