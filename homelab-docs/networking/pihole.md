# Pi-hole

## Overview

Pi-hole is a network-wide ad blocker that acts as a DNS sinkhole. Instead of blocking ads at the browser level, Pi-hole blocks them at the network level by preventing your devices from even connecting to ad servers. When a device on your network tries to reach an ad domain, Pi-hole returns a "this domain doesn't exist" response, effectively blocking the ad before it loads.

**What it does**:
- Blocks ads network-wide for all devices (computers, phones, smart TVs, IoT devices)
- Functions as a DNS server that filters malicious and advertising domains
- Provides detailed statistics on DNS queries and blocked domains
- Speeds up browsing by blocking unnecessary requests
- Protects privacy by blocking tracking domains
- Can act as a DHCP server (optional)

**Why you need it**: Browser-based ad blockers only work on browsers and require installation on each device. Pi-hole protects your entire network, including devices that can't run ad blockers (smart TVs, mobile apps, IoT devices).

## Ports

| Port | Purpose |
|------|---------|
| `5335` (TCP & UDP) | DNS server (non-standard port to avoid conflicts) |
| `8082` (host) → `80` (container) | Pi-hole Web Admin Interface |
| `8443` | HTTPS for Web Admin (if configured) |

**Note**: Standard DNS port is 53, but yours is configured to 5335 to avoid conflicts with other DNS services.

## How It Works

1. **Device makes DNS request** (e.g., "What's the IP of example.com?")
2. **Request goes to Pi-hole** (configured as network DNS server)
3. **Pi-hole checks its blocklists**:
   - If domain is on blocklist → Returns 0.0.0.0 (blocked)
   - If domain is safe → Forwards to upstream DNS (Cloudflare, Google, etc.)
4. **Upstream DNS returns IP** (for allowed domains)
5. **Pi-hole caches the response** for faster future lookups
6. **Device receives response** and proceeds accordingly

**Result**: Ads never load because the ad domains are blocked at the DNS level.

## Service Interactions

**Protects**:
- All devices on your network (computers, phones, tablets, smart TVs, IoT devices)

**Forwards DNS To**:
- Upstream DNS providers (Cloudflare 1.1.1.1, Google 8.8.8.8, etc.)

**Accessed By**:
- Network administrator via Web Interface (`http://localhost:8082/admin`)

**Workflow**:
```
Device DNS query → Pi-hole (checks blocklist)
                        ↓
                Is domain blocked?
                  ↙           ↘
            YES: Return      NO: Forward to
            0.0.0.0          upstream DNS
                                 ↓
                          Get real IP
                                 ↓
                        Return to device
```

## Environment Variables

| Variable | Description | Value in Your Setup |
|----------|-------------|---------------------|
| `TZ` | Timezone for logs and statistics | Loaded from `.env` |
| `FTLCONF_webserver_api_password` | Web interface password | Loaded from `.env` as `${PIHOLE_PASSWORD}` |

**Security Note**: Store your Pi-hole password in your `.env` file, not in the docker-compose.yml directly.

## Mounts & Volumes

| Mount | Purpose | Notes |
|-------|---------|-------|
| `./etc-pihole:/etc/pihole` | Pi-hole configuration and blocklists | Contains all settings, custom DNS entries, blocklists |

**Important**: This directory contains all your Pi-hole data. Back it up regularly!

## Compose File Breakdown

```yaml
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      - "5335:53/tcp"              # DNS (TCP) - custom port to avoid conflicts
      - "5335:53/udp"              # DNS (UDP) - custom port to avoid conflicts
      - "8082:80/tcp"              # Web interface (changed to avoid port conflicts)
      - "8443:443/tcp"             # HTTPS for web interface
    environment:
      TZ: ${TZ}                    # Timezone
      FTLCONF_webserver_api_password: ${PIHOLE_PASSWORD}  # Admin password from .env
      # Optional: Set custom DNS servers (Cloudflare by default)
      # PIHOLE_DNS_: "1.1.1.1;1.0.0.1"
    volumes:
      - './etc-pihole:/etc/pihole'  # Config and data storage
    cap_add:
      - NET_ADMIN                  # Required for network management capabilities
    restart: unless-stopped
```

### NET_ADMIN Capability
Pi-hole requires `NET_ADMIN` capability to manage DNS and network functions within the container.

## Common Use Cases

- **Ad Blocking**: Block ads on all devices without installing software on each one
- **Smart TV Ad Blocking**: Block ads on smart TVs and streaming devices (Roku, Fire TV, etc.)
- **Mobile Ad Blocking**: Block ads in mobile apps (not just browsers)
- **Tracking Prevention**: Block analytics and tracking domains for privacy
- **Malware Protection**: Block known malicious domains
- **Parental Controls**: Block adult content or specific website categories
- **Network Monitoring**: See what domains your devices are accessing

## Troubleshooting Tips

**Can't access Pi-hole admin interface?**
- Access via `http://localhost:8082/admin` (note the `/admin` path)
- Check if container is running: `docker ps | grep pihole`
- View logs: `docker logs pihole`

**DNS queries not being blocked?**
- Devices must use Pi-hole as their DNS server (see Configuration section)
- Check if blocklists are loaded: Admin Interface → Group Management → Adlists
- Update blocklists: Tools → Update Gravity
- Check query log to see if queries are reaching Pi-hole

**Pi-hole not resolving domains?**
- Check upstream DNS settings (Settings → DNS)
- Test upstream connectivity: `docker exec pihole ping 1.1.1.1`
- Check container logs for errors

**Websites loading slowly or breaking?**
- Pi-hole might be blocking necessary domains (false positives)
- Check query log for recently blocked domains
- Whitelist the domain: Whitelist → Add domain
- Temporarily disable Pi-hole to test: Settings → Disable (1 hour)

**Password not working?**
- Check `.env` file has correct `PIHOLE_PASSWORD` value
- Reset password: `docker exec pihole pihole -a -p newpassword`
- Make sure no spaces or special characters causing issues

## Initial Configuration Steps

### 1. Start Pi-hole
```bash
cd docker-projects/pie_hole
docker-compose up -d
```

### 2. Access Web Interface
- Open browser: `http://localhost:8082/admin`
- Login with password from your `.env` file

### 3. Configure Upstream DNS (Optional)
- Settings → DNS
- Choose upstream DNS servers:
  - **Cloudflare**: 1.1.1.1 / 1.0.0.1 (privacy-focused, fast)
  - **Google**: 8.8.8.8 / 8.8.4.4 (reliable, fast)
  - **Quad9**: 9.9.9.9 (security-focused, blocks malicious domains)
  - **OpenDNS**: 208.67.222.222 / 208.67.220.220 (customizable filtering)

### 4. Update Blocklists
- Tools → Update Gravity
- This downloads/updates blocklists
- Run this weekly or after adding new lists

### 5. Configure Devices to Use Pi-hole

**Option A - Per Device** (Easiest for testing):
- Go to device's network settings
- Set DNS server to your Pi-hole server IP
- Windows: Network Settings → Change Adapter Options → Properties → IPv4 → DNS
- Mac: System Preferences → Network → Advanced → DNS
- Phone/Tablet: WiFi Settings → Modify Network → Advanced → DNS

**Option B - Router Level** (Recommended - affects all devices):
- Login to your router (usually 192.168.1.1 or 192.168.0.1)
- Find DHCP settings
- Set Primary DNS to your Pi-hole server IP
- Secondary DNS: Leave blank or use a fallback (8.8.8.8)
- Save and reboot router
- Devices will automatically use Pi-hole after renewing DHCP lease

**Finding Your Pi-hole Server IP**:
- Run: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
- Look for your local network adapter's IP (e.g., 192.168.1.x)

### 6. Test Pi-hole
- Visit a website with ads (like a news site)
- Ads should be blocked
- Check Admin Interface → Dashboard for query statistics

## Understanding the Web Interface

### Dashboard
- **Total Queries**: How many DNS requests Pi-hole handled
- **Queries Blocked**: Percentage and count of blocked requests
- **Blocklist**: Total number of domains on blocklists
- **Graphs**: Visual representation of queries over time

### Query Log
- Real-time view of all DNS queries
- See which domains are allowed/blocked
- Shows which device made the query
- Great for troubleshooting

### Whitelist/Blacklist
- **Whitelist**: Domains to always allow (even if on blocklists)
- **Blacklist**: Domains to always block (even if not on blocklists)
- **Regex**: Advanced filtering with regular expressions

### Group Management
- **Adlists**: Manage blocklist sources
- **Groups**: Organize devices and apply different blocking rules
- **Clients**: Assign devices to groups

### Settings
- **DNS**: Configure upstream DNS servers
- **DHCP**: Enable Pi-hole as DHCP server (advanced)
- **API**: API token for external integrations
- **Teleporter**: Backup and restore settings

## Popular Blocklists

Pi-hole comes with default lists, but you can add more:

**General Ad Blocking**:
- StevenBlack's Unified Hosts: `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts`
- OISD Basic: `https://big.oisd.nl/domainswild`

**Privacy & Tracking**:
- EasyPrivacy: Available through filter list repositories
- Disconnect Tracking: Blocks analytics and trackers

**Malware**:
- Malware Domain List: Blocks known malicious domains

**Social Media** (optional):
- Can block Facebook, Twitter, TikTok, etc. if desired

**Add Lists**: Group Management → Adlists → Add New Adlist → Paste URL → Update Gravity

## Performance Notes

- **CPU**: Very light (~1-3% during normal use)
- **RAM**: ~50-150MB depending on query volume
- **Disk**: Minimal - logs can grow over time
- **Network**: Negligible impact on network speed (often faster by blocking unnecessary requests)

**Query Response Time**: Usually <50ms for cached queries, <100ms for uncached

## Advanced Features

### Local DNS Records
- Create custom DNS entries for local servers
- Example: `homelab.local` → `192.168.1.100`
- Settings → Local DNS → DNS Records

### Conditional Forwarding
- Forward specific domain queries to specific DNS servers
- Example: Forward `*.lan` to your router

### DHCP Server (Advanced)
- Pi-hole can replace your router's DHCP server
- Provides better integration with Pi-hole
- **Caution**: Only enable if you understand networking - can break network if misconfigured

### Group Management
- Apply different blocking rules to different devices
- Example: Strict blocking for kids' devices, lenient for adults
- Create groups, assign clients to groups, apply adlists to groups

### API Integration
- Integrate with Home Assistant, monitoring tools, etc.
- API token available in Settings → API

## Whitelisting Common False Positives

Some blocklists can be overly aggressive. Common domains to whitelist:

**Microsoft Services**:
- `cdn.optimizely.com` (Microsoft services)
- `s.youtube.com` (YouTube functionality)

**Amazon**:
- `device-metrics-us-2.amazon.com` (Kindle/Alexa functionality)

**Roku/Streaming**:
- `logs.roku.com` (Roku functionality)

**Mobile Apps**:
- Various app-specific tracking domains that break functionality

**How to Whitelist**:
1. Check Query Log for blocked domain
2. Click on domain
3. Click "Whitelist" button
4. Confirm

## Monitoring & Statistics

### Real-Time Statistics
- Dashboard shows live query counts
- Query types (A, AAAA, PTR, etc.)
- Top clients (which devices query most)
- Top permitted/blocked domains

### Long-Term Statistics
- Tools → Long-term Data
- Historical query data
- Analyze trends over weeks/months

### Query Types
- **A**: IPv4 address lookup (most common)
- **AAAA**: IPv6 address lookup
- **PTR**: Reverse DNS lookup
- **SRV**: Service record

## Backup & Restore

### Manual Backup
- Settings → Teleporter → Backup
- Downloads a `.tar.gz` file with all settings

### Restore
- Settings → Teleporter → Restore
- Upload backup file
- Pi-hole restarts and applies settings

### What's Backed Up
- Blocklists and whitelist/blacklist
- Custom DNS records
- DHCP settings
- Group configurations

### What's NOT Backed Up
- Query history and statistics (stored separately)
- Container volumes (backup `./etc-pihole` folder separately)

## Security Best Practices

✅ **Strong Admin Password**: Use a complex password in your `.env` file
✅ **Limited External Access**: Don't expose Pi-hole to the internet directly
✅ **Regular Updates**: Keep Pi-hole updated (Watchtower can handle this)
✅ **Firewall Rules**: Only allow DNS queries from your local network
✅ **HTTPS** (Optional): Configure SSL for admin interface
✅ **API Token Security**: Keep API tokens private

## Privacy Considerations

**What Pi-hole Sees**:
- All DNS queries from your network (which domains devices access)
- Does NOT see full URLs or page content
- Does NOT see HTTPS encrypted traffic content
- Logs are stored locally (not sent to third parties)

**Privacy Settings**:
- Settings → Privacy
- Configure query logging level
- Can disable logging entirely (but lose statistics)

## DNS Over HTTPS (DoH) / DNS Over TLS (DoT)

Some apps bypass traditional DNS using DoH/DoT:
- **Problem**: Bypasses Pi-hole blocking
- **Examples**: Firefox, Chrome (if configured), some mobile apps
- **Solution**: Disable DoH in applications or block DoH servers at router level

**Blocking DoH**:
- Add DoH provider domains to blacklist (e.g., `dns.google`, `cloudflare-dns.com`)

## Pi-hole vs Other Solutions

**Pi-hole vs Browser Ad Blockers**:
- Pi-hole: Network-wide, all devices, no per-device setup
- Browser: Only protects browser, requires installation

**Pi-hole vs AdGuard Home**:
- Pi-hole: More established, larger community
- AdGuard: More modern UI, built-in DoH/DoT

**Pi-hole vs NextDNS**:
- Pi-hole: Self-hosted, full control, free
- NextDNS: Cloud-based, easier setup, limited free tier

**Pi-hole vs pfSense/pfBlockerNG**:
- Pi-hole: Easier to set up, focused on DNS blocking
- pfSense: Full firewall solution, more complex

## Common Issues and Solutions

**Issue**: YouTube ads still showing
- **Cause**: YouTube serves ads from same domains as content
- **Solution**: Use browser extension (SponsorBlock) in addition to Pi-hole

**Issue**: Website says "Ad blocker detected"
- **Solution**: Whitelist the site or disable Pi-hole temporarily

**Issue**: Device ignoring Pi-hole
- **Cause**: Device using hardcoded DNS (8.8.8.8) or DoH
- **Solution**: Block alternative DNS at router level, or disable DoH in app settings

**Issue**: Pi-hole not starting after system reboot
- **Cause**: Port conflict or Docker not fully started
- **Solution**: Check logs, ensure ports are free, restart container

## Integration with Other Services

**Home Assistant**: Monitor Pi-hole statistics

**Grafana**: Visualize Pi-hole data with dashboards

**Homarr**: Add Pi-hole as service tile for quick access

**Uptime Kuma**: Monitor Pi-hole availability

## Important Notes

- **DNS Port 5335**: Your Pi-hole uses non-standard DNS port 5335 to avoid conflicts. Devices need to be pointed to your server's IP, not just set to use port 5335.
- **Learning Period**: Pi-hole may block some legitimate domains initially. Use the whitelist feature to fix false positives.
- **Updates**: Regularly update blocklists (Tools → Update Gravity) for best protection.
- **Blocklist Size**: More blocklists = more blocking, but diminishing returns. Default lists are usually sufficient.
- **Secondary DNS**: Don't set a secondary DNS (like 8.8.8.8) on devices, or they'll bypass Pi-hole when it's "slow" to respond.
