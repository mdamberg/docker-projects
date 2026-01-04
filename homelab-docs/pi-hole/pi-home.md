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

## Understanding Network-Wide Ad Blocking

### What Happens When You Enable Network-Wide Blocking?

**For Other Devices on Your Network:**
- ✅ All websites work normally
- ✅ All apps work normally (Netflix, YouTube, games, banking, etc.)
- ✅ No configuration needed on phones/laptops/tablets
- ✅ Guests who join your WiFi automatically get ad-blocking
- ✅ Devices can still access everything they need
- ❌ Ads and trackers get blocked (this is the benefit!)
- ⚠️ Very rarely, some websites/apps might break if Pi-hole blocks something they need (easily fixed by whitelisting)

**For Your Home Server:**
- ✅ Static IPs stay exactly the same
- ✅ Port forwarding rules unchanged
- ✅ Docker containers work identically
- ✅ All services (Plex, Radarr, Sonarr, etc.) work the same
- ✅ Remote access unchanged

**Why?** DNS is completely separate from:
- Static IP assignments (like 192.168.4.200)
- Port forwarding (routing external traffic to services)
- Network routing (how traffic flows between devices)
- Firewall rules

**DNS does only one thing**: Translates domain names to IP addresses (e.g., `google.com` → `142.250.80.46`)

### How DNS Blocking Works

**Normal website request:**
```
Device asks: "What's the IP for google.com?"
    ↓
Router says: "Ask Pi-hole at 192.168.4.200"
    ↓
Pi-hole checks: Is google.com on blocklist?
    ↓ NO - It's legitimate
Pi-hole asks upstream DNS (Cloudflare): "What's google.com?"
    ↓
Cloudflare responds: "142.250.80.46"
    ↓
Pi-hole returns to device: "142.250.80.46"
    ↓
Device connects to google.com normally
```

**Ad/tracker request:**
```
Device asks: "What's the IP for ads.doubleclick.net?"
    ↓
Router says: "Ask Pi-hole at 192.168.4.200"
    ↓
Pi-hole checks: Is ads.doubleclick.net on blocklist?
    ↓ YES - BLOCKED
Pi-hole returns: "0.0.0.0" (doesn't exist)
    ↓
Device can't connect to ad tracker
    ↓
No ad loads, webpage loads faster and more privately
```

### What About Guests and Visitors?

**When someone joins your WiFi:**
- ✅ They connect normally (same WiFi password as always)
- ✅ Internet works normally for them
- ✅ They automatically get ad-blocking (they'll probably think your WiFi is fast!)
- ✅ Zero configuration needed on their devices
- ✅ They likely won't notice anything except fewer ads

**Most common reaction**: "Wow, your internet is fast!"

### Potential Issues (Rare, Easily Fixed)

**Things that might occasionally break:**

1. **Smart home devices** - Some poorly-designed IoT devices use ad/tracking domains for core functionality
   - **Fix**: Whitelist specific domains in Pi-hole (takes 10 seconds)
   - **Example**: Some smart light bulbs phone home to tracking servers

2. **Mobile apps with ads** - Apps that rely heavily on ads might not work properly
   - **Fix**: Whitelist the app's domains, or disable Pi-hole on that specific device
   - **Example**: Free mobile games

3. **Parental control apps** - Some use tracking mechanisms that Pi-hole blocks
   - **Fix**: Whitelist their specific domains

**Reality**: 99% of things work perfectly fine. The 1% that breaks is easy to fix.

### Easy Rollback Plan

If something breaks and you want to revert:

**Option 1 - Disable Pi-hole temporarily** (30 seconds):
1. Go to http://192.168.4.200:8082/admin
2. Click "Disable" button
3. Choose duration (5 minutes, 30 minutes, indefinitely)

**Option 2 - Revert router DNS** (2 minutes):
1. Log into pfSense at http://192.168.4.1
2. Change DNS back to `1.1.1.1` or `8.8.8.8`
3. Save and apply
4. Devices will use normal DNS again

**Option 3 - Whitelist specific domain** (10 seconds):
1. Go to Pi-hole → Domains → Whitelist
2. Add the domain that's being blocked
3. Save
4. Device works again

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

**pfSense Router Configuration** (Step-by-Step):

#### Step 1: Access pfSense Web Interface
1. Open browser and go to `http://192.168.4.1`
2. Log in with your pfSense admin credentials

#### Step 2: Configure DNS Servers for pfSense Itself
1. Navigate to **System → General Setup**
2. Scroll to **DNS Server Settings**
3. Configure DNS servers:
   - **DNS Server 1**: `192.168.4.200` (Pi-hole)
   - **DNS Server 2**: `1.1.1.1` (Cloudflare backup - in case Pi-hole is down)
   - **DNS Server 3**: `8.8.8.8` (Google backup)
4. ✅ Check "DNS Server Override" (allows DHCP/VPN clients to override)
5. Click **Save**

#### Step 3: Configure DHCP to Distribute Pi-hole to Clients
1. Navigate to **Services → DHCP Server**
2. Select your LAN interface tab
3. Scroll to **Servers** section
4. Configure DNS servers for DHCP clients:
   - **DNS Server 1**: `192.168.4.200` (Pi-hole)
   - **DNS Server 2**: `1.1.1.1` (Cloudflare backup)
5. Click **Save**

#### Step 4: Apply Changes and Test
1. Click **Apply Changes** at the top of the page
2. Wait 2-3 minutes for changes to propagate
3. On a device, renew DHCP lease:
   - **Windows**: `ipconfig /release` then `ipconfig /renew`
   - **macOS/Linux**: Turn WiFi off and back on
   - **Mobile**: Forget WiFi network and reconnect
4. Verify DNS is working:
   ```powershell
   nslookup google.com
   ```
   Should show `Server: 192.168.4.200`

#### Step 5: Verify in Pi-hole Dashboard
1. Go to http://192.168.4.200:8082/admin
2. Refresh the page
3. Within a few minutes, you should see:
   - **Total Queries** increasing
   - **Active Clients** showing connected devices
   - **Queries Blocked** showing percentage blocked

#### Expected Results
After 5-10 minutes, your Pi-hole dashboard should show:
- **Total Queries**: Growing number (10+, 50+, 100+ depending on usage)
- **Active Clients**: 5-15+ (all your devices: phones, laptops, tablets, smart TVs, etc.)
- **Percentage Blocked**: 5-30% (varies by usage)
- **Domains on Lists**: 213,264 (unchanged)

---

### Alternative Method: pfSense DNS Resolver (Unbound)

If you use pfSense's built-in DNS Resolver (Unbound), you can forward queries to Pi-hole:

1. Navigate to **Services → DNS Resolver**
2. Scroll to **General Settings**
3. Under **Outgoing Network Interfaces**, select your LAN
4. Enable **Forwarding Mode**
5. Add Pi-hole as upstream server:
   - **DNS Server**: `192.168.4.200`
6. Save and Apply Changes

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

## Common Questions and Issues

### "Verify You Are Human" / CAPTCHA Prompts

**Problem**: Getting frequent CAPTCHA challenges when searching on Google, Bing, or other sites.

**Is Pi-hole the cause?**
- **No** - If you're not using Pi-hole yet (0 queries on dashboard), it's not the cause
- **Unlikely** - Even with Pi-hole enabled, it rarely causes CAPTCHAs

**Common Causes**:

1. **ISP IP Reputation** (Most Likely)
   - Your home IP address might be flagged due to:
     - Other customers on the same IP block engaging in malicious activity
     - Shared IP addresses (CGNAT - Carrier-Grade NAT)
     - Previous owner of your IP doing suspicious things
   - **Test**: Check if your IP is blacklisted at https://mxtoolbox.com/blacklists.aspx
   - **Fix**:
     - Contact your ISP and request a new IP address
     - Wait it out (IPs get cycled eventually)
     - Use a different search engine (DuckDuckGo, Brave Search)

2. **Shared Network / Public WiFi**
   - CAPTCHAs are common on shared networks
   - **Fix**: This is normal behavior, not fixable

3. **Search Engine Behavior**
   - Google/Bing sometimes require CAPTCHAs randomly
   - More common with:
     - Ad blockers (browser extensions)
     - Privacy-focused browsers
     - Frequent searching
   - **Fix**: Clear cookies, use incognito mode, or switch search engines

4. **VPN Usage** (If Applicable)
   - VPNs frequently trigger CAPTCHAs
   - VPN IPs are shared among many users
   - **Test**: Disable VPN temporarily and check if CAPTCHAs stop
   - **Fix**: Use VPN only for torrenting, not general browsing

5. **Malware or Botnet Activity**
   - If your computer is infected, it might be sending automated requests
   - **Test**: Run Windows Defender or Malwarebytes scan
   - **Fix**: Clean malware if found

**Will Pi-hole make it worse?**
- **Unlikely** - Pi-hole blocks ads/trackers, not search engines
- **Possible**: If Pi-hole blocks a domain that Google uses for verification, you might see more CAPTCHAs
  - **Fix**: Check Pi-hole query log when CAPTCHA appears, whitelist if needed

**Bottom Line**:
- If you AND your wife both get CAPTCHAs, and she doesn't use VPN, it's likely an **ISP IP reputation issue**
- Contact your ISP or try switching to a different search engine
- Pi-hole won't help or hurt this issue

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