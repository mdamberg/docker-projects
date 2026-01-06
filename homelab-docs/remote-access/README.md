# Remote Access with Tailscale

## Overview

This homelab uses **Tailscale** for secure remote access to all services from anywhere in the world.

**Why Tailscale?**
- Works through ISP CGNAT (Carrier-Grade NAT)
- No port forwarding required
- No router configuration needed
- Just works™ - anywhere, anytime
- Free for personal use

---

## The CGNAT Problem (Why Traditional VPN Failed)

### What We Discovered:
Our ISP uses **CGNAT** (Carrier-Grade NAT), which means:
- Our router's WAN IP is `100.65.30.217` (a shared, non-public IP)
- Hundreds of customers share the same public IP
- Port forwarding is **impossible** - traffic never reaches our router
- Traditional self-hosted VPNs (WireGuard, OpenVPN) **cannot work**

### The Solution:
Tailscale creates a **mesh VPN** that bypasses CGNAT entirely by:
- Using coordination servers to help devices find each other
- Creating direct peer-to-peer connections when possible
- Relaying traffic through Tailscale servers only when necessary
- Working through any firewall, NAT, or network configuration

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  YOUR DEVICES (Anywhere in the world)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ iPhone-14    │  │ Laptop       │  │ Tablet       │ │
│  │ 100.94.112.76│  │ (Tailscale   │  │ (Tailscale   │ │
│  │              │  │  IP when     │  │  IP when     │ │
│  │              │  │  added)      │  │  added)      │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│         ▲                 ▲                 ▲           │
│         │                 │                 │           │
│         └─────────────────┼─────────────────┘           │
│                           │                             │
│                  Tailscale Mesh Network                 │
│                  (Encrypted WireGuard)                  │
│                           │                             │
│         ┌─────────────────▼─────────────────┐           │
│         │                                   │           │
│         │  Home Server (DESKTOP-QGA3DVB)    │           │
│         │  Tailscale IP: 100.82.35.70       │           │
│         │  Local IP: 10.0.0.7               │           │
│         │                                   │           │
│         │  Services Available:              │           │
│         │  - Homarr (8181)                  │           │
│         │  - Home Assistant (8123)          │           │
│         │  - Plex (32400)                   │           │
│         │  - Portainer (9443)               │           │
│         │  - Todo App (5070)                │           │
│         │  - All other Docker services      │           │
│         └───────────────────────────────────┘           │
└─────────────────────────────────────────────────────────┘
```

---

## How Tailscale Works

1. **Coordination**: Tailscale servers help devices discover each other
2. **Direct Connection**: Devices connect peer-to-peer when possible (fast!)
3. **DERP Relay**: If P2P fails, traffic relays through Tailscale servers (still encrypted)
4. **Zero Trust**: Every connection is encrypted end-to-end with WireGuard
5. **No Central VPN Server**: No single point of failure

**Privacy Note:**
- Your traffic does NOT routinely go through Tailscale servers
- Data is encrypted end-to-end (Tailscale can't see your traffic)
- Tailscale only helps with connection coordination

---

## Current Setup

### Devices

| Device Name        | Tailscale IP   | Type   | Location  |
|--------------------|----------------|--------|-----------|
| desktop-qga3dvb    | 100.82.35.70   | Server | Home      |
| iphone-14          | 100.94.112.76  | Phone  | Mobile    |

### Services Accessible

All services on `desktop-qga3dvb` (100.82.35.70) are accessible via Tailscale:

| Service          | URL                              | Port  | Description                    |
|------------------|----------------------------------|-------|--------------------------------|
| Homarr           | http://100.82.35.70:8181         | 8181  | Dashboard homepage             |
| Home Assistant   | http://100.82.35.70:8123         | 8123  | Home automation                |
| Plex             | http://100.82.35.70:32400/web    | 32400 | Media server                   |
| Portainer        | https://100.82.35.70:9443        | 9443  | Docker management              |
| Todo App         | http://100.82.35.70:5070         | 5070  | Flask todo list                |
| Duplicati        | http://100.82.35.70:8200         | 8200  | Backup management              |
| Pi-hole Admin    | http://100.82.35.70:8082/admin   | 8082  | DNS ad blocking                |
| Sonarr           | http://100.82.35.70:8989         | 8989  | TV show management             |
| Radarr           | http://100.82.35.70:7878         | 7878  | Movie management               |
| Prowlarr         | http://100.82.35.70:9696         | 9696  | Indexer manager                |
| Overseerr        | http://100.82.35.70:5055         | 5055  | Media request management       |
| qBittorrent      | http://100.82.35.70:8080         | 8080  | Torrent client (via gluetun)   |

---

## Setup Guide

See [SETUP.md](./SETUP.md) for detailed installation and configuration instructions.

---

## Daily Usage

See [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) for quick access instructions.

---

## Troubleshooting

### Tailscale Not Connecting

**Check Tailscale Status:**
```bash
# Windows (PowerShell)
tailscale status

# Check if connected
tailscale status | Select-String "online"
```

**Common Issues:**

1. **Tailscale app not running**
   - Check system tray for Tailscale icon
   - Start Tailscale from Start menu

2. **Device shows offline**
   - Restart Tailscale app
   - Re-authenticate if needed

3. **Services not accessible**
   - Verify Tailscale is connected (green icon)
   - Check the service is running on the server
   - Verify you're using the correct Tailscale IP (100.82.35.70)

### Home Assistant "Most Secure" Error

If Home Assistant shows a "Most Secure" connection error when accessed via Tailscale:

1. This is a security setting in Home Assistant
2. You can either:
   - Configure Home Assistant to trust the Tailscale network
   - Use the local IP when at home, Tailscale IP when remote

### Can't Access from Phone

1. **Verify Tailscale app is ON** (toggle in app)
2. **Check you're using Tailscale IP** (`100.82.35.70`), not local IP
3. **WiFi off for testing** - Use cellular to verify remote access
4. **Check server is online** - In Tailscale app, devices list should show green dots

---

## Router Configuration

### What Changed

**Removed:**
- WireGuard port forwarding (UDP 51820) - No longer needed!

**Kept:**
- Plex port forwarding (TCP 32400) - Optional, for direct Plex access
  - Can remove this too if you only want Tailscale access

**No Configuration Needed:**
- Tailscale works without ANY router changes
- No port forwarding
- No firewall rules
- No DMZ
- Nothing!

### Previous Failed Attempts

**Attempt 1-3: WireGuard/OpenVPN**
- ❌ Failed due to ISP CGNAT
- ❌ Port forwarding configured correctly but packets never arrived
- ❌ Not a configuration issue - literally impossible with CGNAT

**Success: Tailscale**
- ✅ Works through CGNAT
- ✅ No router configuration
- ✅ Instant setup

---

## Security Considerations

### What's Encrypted

- ✅ All traffic between devices uses WireGuard encryption
- ✅ End-to-end encrypted (Tailscale can't see your data)
- ✅ Each device has unique encryption keys

### Access Control

**Current Setup:**
- Anyone with access to your Tailscale account can add devices
- Devices can access all services on the server

**Recommendations:**
1. Enable two-factor authentication on your Tailscale account
2. Use strong password for Tailscale login
3. Review connected devices periodically
4. Remove old/unused devices from Tailscale admin console

**Future Enhancements:**
- Enable Tailscale ACLs (Access Control Lists) to restrict which devices can access which services
- Set up key expiry for automatic device de-authorization

---

## Cost

**Tailscale Free Plan:**
- ✅ Up to 100 devices
- ✅ Unlimited data transfer
- ✅ 1 user (personal use)
- ✅ All features we need

**Perfect for homelab use!**

---

## Comparison: Tailscale vs WireGuard

| Feature                    | WireGuard (Self-Hosted) | Tailscale               |
|----------------------------|-------------------------|-------------------------|
| Works through CGNAT        | ❌ No                    | ✅ Yes                  |
| Port forwarding required   | ✅ Yes                   | ❌ No                   |
| Router configuration       | ✅ Required              | ❌ None needed          |
| Setup complexity           | 🟡 Complex               | 🟢 Simple               |
| Maintenance                | 🟡 Regular updates       | 🟢 Automatic            |
| Add new devices            | 🟡 Manual config         | 🟢 Click a button       |
| Works on any network       | ❌ No (CGNAT blocks it)  | ✅ Always               |
| Encryption                 | ✅ WireGuard             | ✅ WireGuard            |
| Self-hosted                | ✅ 100%                  | 🟡 Hybrid (mesh)        |
| Cost                       | ✅ Free                  | ✅ Free (personal)      |

**Verdict:** Tailscale is the clear winner when dealing with CGNAT.

---

## Additional Resources

- [Tailscale Official Docs](https://tailscale.com/kb/)
- [Tailscale Admin Console](https://login.tailscale.com/admin)
- [Understanding CGNAT](https://tailscale.com/blog/how-nat-traversal-works/)

---

## Maintenance

### Regular Tasks

**Monthly:**
- Review connected devices in Tailscale admin console
- Remove any old/unused devices

**As Needed:**
- Update Tailscale client on server and devices
- Add new devices when needed

### Updates

**Server (Windows):**
- Tailscale updates automatically
- Or manually: Download from https://tailscale.com/download

**Phone:**
- Updates via App Store/Google Play

---

## Backup Plan

**If Tailscale Goes Down:**
- Use local access when at home (10.0.0.7)
- Plex has direct access via port 32400 (if port forwarding still enabled)
- Can temporarily switch to different VPN service (ZeroTier, CloudFlare Tunnel, etc.)

**If Server Goes Down:**
- Check server power/network
- Access Portainer locally to restart containers: http://10.0.0.7:9443

---

*Last Updated: 2026-01-05*
*Setup by: Claude Code*
