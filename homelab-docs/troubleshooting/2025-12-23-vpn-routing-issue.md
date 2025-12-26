# System-Wide VPN Blocking Local Network Access

**Date:** December 23, 2025
**Status:** RESOLVED
**Severity:** High - All Home Assistant devices unavailable
**Duration:** ~6 hours

---

## Symptoms

- Home Assistant integrations (TP-Link, Reolink) randomly became "Unavailable"
- Devices worked normally in vendor mobile apps (cloud access intact)
- Re-adding integrations failed with `TimeoutError`
- Router admin UI (http://192.168.1.9) became unreachable (`ERR_NETWORK_ACCESS_DENIED`)
- Pings to local IPs (192.168.x.x) timed out from host machine
- Docker containers still had internet access
- Issues affected multiple vendors simultaneously

---

## Root Cause

**ProtonVPN system-wide client altered Windows routing tables**, blocking access to RFC1918 private network addresses (192.168.x.x).

Even when ProtonVPN appeared "off" or inactive:
- VPN network drivers remained active
- Routing rules blocked local LAN traffic
- Kill switch functionality persisted
- Virtual network adapter intercepted local traffic

---

## Investigation Process

### 1. Eliminated Docker/Application Issues
```bash
# Verified containers running
docker ps

# Tested outbound internet
docker exec homeassistant ping google.com  # ✅ Works

# Tested local network
docker exec homeassistant ping 192.168.1.1  # ❌ Failed (during VPN)
```

### 2. Verified IP Configuration
```cmd
ipconfig
# IP: 192.168.1.7 (Static) ✅
# Gateway: 192.168.1.1 ✅
```

### 3. Tested Router Access
```cmd
ping 192.168.1.1  # ❌ Failed
# Browser: ERR_NETWORK_ACCESS_DENIED
```

### 4. Identified VPN Interference
```cmd
# Checked for VPN processes
tasklist | findstr /I "proton vpn"

# Disabled ProtonVPN
# Result: Immediate restoration of local network access ✅
```

---

## Resolution

### Immediate Fix
1. Stopped ProtonVPN client
2. Verified routing tables restored:
   ```cmd
   route print | findstr "0.0.0.0"
   # 0.0.0.0  0.0.0.0  192.168.1.1  192.168.1.7  ✅
   ```
3. Tested connectivity:
   ```bash
   ping 192.168.1.1  # ✅ Success
   docker exec homeassistant ping 192.168.1.1  # ✅ Success
   ```

### Long-Term Solution
**Use Gluetun (containerized VPN) instead of system-wide VPN**

Already configured in `media_stack/docker-compose.yml`:
```yaml
gluetun:
  image: qmcgaw/gluetun
  container_name: gluetun
  cap_add:
    - NET_ADMIN
  environment:
    - VPN_SERVICE_PROVIDER=custom
    - VPN_TYPE=wireguard
  # Only qBittorrent routes through VPN

qbittorrent:
  network_mode: "service:gluetun"  # ✅ Correct approach
```

---

## What We Learned

### ✅ DO
- **Use containerized VPNs** (Gluetun) for specific services
- Keep VPN isolated to containers that need it
- Test local network access immediately after VPN changes
- Check routing tables when local network fails

### ❌ DON'T
- **Never use system-wide VPN** on Home Assistant server
- Don't assume VPN is "off" just because it appears inactive
- Don't trust VPN GUI status - verify with network tests
- Don't use kill switches on machines running local services

---

## Prevention

### Network Verification Script
Created: `fix-docker-firewall.ps1`

Add this check to prevent future issues:
```powershell
# Test local network access
Test-NetConnection -ComputerName 192.168.1.1 -Port 80

# Verify routing
route print | findstr "0.0.0.0"
```

### For Future Torrenting
1. Use qBittorrent (already configured with Gluetun) ✅
2. Do NOT use ProtonVPN system-wide ❌
3. Verify downloads go through VPN:
   ```bash
   docker exec qbittorrent curl ifconfig.me
   # Should show VPN IP, not home IP
   ```

---

## Remaining Device Issues

### TP-Link (192.168.1.24) - Offline
**Status:** Not responding (unrelated to VPN issue)

**Troubleshooting:**
- [ ] Check if powered on
- [ ] Verify network cable connected
- [ ] Check router DHCP table for IP change
- [ ] Power cycle device
- [ ] Check Kasa mobile app

### Reolink Camera (192.168.1.15) - Duplicate Registration
**Status:** Online but duplicate entry in Home Assistant

**Fix:**
1. Settings → Devices & Services
2. Find duplicate "Kitchen" (Reolink) entries
3. Delete one duplicate
4. Restart Home Assistant
5. Verify camera works

---

## Technical Details

### Network Configuration (Post-Fix)
```
Interface: Ethernet
IP: 192.168.1.7 (Static)
Subnet: 255.255.255.0
Gateway: 192.168.1.1
DNS: 192.168.1.1
DHCP: Disabled ✅
```

### Routing Table (Correct)
```
Network         Netmask      Gateway       Interface    Metric
0.0.0.0         0.0.0.0      192.168.1.1   192.168.1.7  281 ✅
```

### Home Assistant Connectivity Tests
```bash
# Router
docker exec homeassistant ping -c 2 192.168.1.1
# ✅ 0% packet loss

# Reolink Camera
docker exec homeassistant ping -c 2 192.168.1.15
# ✅ 0% packet loss

# TP-Link (separate device issue)
docker exec homeassistant ping -c 2 192.168.1.24
# ❌ 100% packet loss (device offline, not VPN related)
```

---

## References

- [Docker Gluetun Documentation](https://github.com/qdm12/gluetun)
- [WireGuard Configuration](../docker-projects/media_stack/docker-compose.yml)
- [Firewall Configuration](../fix-docker-firewall.ps1)

---

## Related Issues

- None (first occurrence)

## Tags

`#networking` `#vpn` `#home-assistant` `#routing` `#docker` `#troubleshooting`
