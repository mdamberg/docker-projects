# VPN Setup Documentation

**Last Updated:** November 3, 2025

This document explains all the VPN configurations in your Docker setup, what each one does, and when to use them.

---

## 🔐 VPN Overview

You have **three separate VPN configurations** for different purposes:

| VPN | Purpose | Usage | Status |
|-----|---------|-------|--------|
| **PIA** | Torrent anonymity | Automatic (24/7) | ✅ Active |
| **WireGuard Home VPN** | Remote access to home network | Manual (when away) | ✅ Active |
| **ProtonVPN** | General browsing privacy | Manual (as needed) | ⚠️ Optional |

---

## 1️⃣ PIA (Private Internet Access)

### **What It Does:**
- Routes **only your torrent traffic** through PIA's VPN servers
- Hides your real IP address from torrent peers, trackers, and your ISP
- Runs automatically 24/7 inside your Docker media stack via Gluetun

### **Location:**
- Docker project: `media_stack`
- Container: `gluetun`
- Protected container: `qbittorrent`

### **Purpose:**
- **Primary goal:** Protect you from ISP monitoring your torrent downloads
- Prevents copyright notices and DMCA letters
- Keeps your torrenting activity completely anonymous
- Kill switch ensures if VPN drops, qBittorrent stops downloading

### **When It's Used:**
- **Automatically** - Always running, you never manually control it
- Every time Radarr/Sonarr tells qBittorrent to download, traffic goes through PIA
- Runs in the background without any intervention

### **How to Verify It's Working:**
```bash
# Check qBittorrent's IP (should show PIA server IP, not your home IP)
docker exec qbittorrent curl ifconfig.me

# Check Gluetun connection
docker logs gluetun --tail 30
```

### **Configuration:**
- Provider: Private Internet Access
- Server Region: US East
- Credentials stored in: `media_stack/.env`

### **Still Needed?**
✅ **YES - ABSOLUTELY CRITICAL**
- Without this, your ISP sees every torrent you download
- This is your primary protection for torrenting

---

## 2️⃣ WireGuard Home VPN

### **What It Does:**
- Creates a secure encrypted tunnel **FROM your phone/laptop TO your home network**
- Makes devices think they're physically connected to your home WiFi when they're not
- You manually connect to it when you're away from home

### **Location:**
- Docker project: `homevpn` (or similar folder)
- Creates a WireGuard VPN server on your network

### **Purpose:**
- **Primary goal:** Securely access your home services remotely
- Access Overseerr to request movies/shows when away from home
- Manage Radarr/Sonarr/Prowlarr from anywhere
- View your Plex library (alternative to Plex remote access)
- Secure alternative to exposing services directly to the internet

### **When to Use:**
- When you're **away from home** and want to:
  - Request content via Overseerr
  - Manage your media stack settings
  - Access your home network securely
- When you're on **public WiFi** (coffee shop, airport, hotel)
- When traveling and want to manage downloads

### **When NOT to Use:**
- When you're at home on your own WiFi (not needed)
- For general web browsing privacy (use ProtonVPN instead)

### **How to Connect:**
1. Install WireGuard app on your phone/laptop
2. Import your WireGuard configuration file
3. Toggle connection ON when away from home
4. Access services via local IPs:
   - Overseerr: `http://192.168.x.x:5055`
   - Plex: `http://192.168.x.x:32400`
   - Radarr: `http://192.168.x.x:7878`

### **Configuration:**
- Protocol: WireGuard
- Server: Running on your home network
- Clients: Your phone, laptop, etc.

### **Still Needed?**
✅ **YES - for remote access to Overseerr and management**
- Best practice for secure remote access
- More secure than port forwarding
- Essential for managing your media stack remotely

---

## 3️⃣ ProtonVPN (Privacy VPN)

### **What It Does:**
- Routes **ALL your internet traffic** through ProtonVPN servers when connected
- Hides your browsing activity, location, and identity from your ISP
- You manually turn it ON/OFF as needed

### **Location:**
- Docker project: `privacyvpn` (or similar folder)
- Separate from media stack

### **Purpose:**
- **Primary goal:** General internet privacy and security
- Hide browsing history from your ISP
- Bypass geo-restrictions on streaming services
- Protect privacy on public/untrusted WiFi networks
- Mask your location for general internet use

### **When to Use:**
- General web browsing when you want privacy
- Streaming geo-restricted content
- Using public WiFi networks
- When you want to hide your location
- Any non-torrent privacy needs

### **When NOT to Use:**
- For torrenting (use PIA instead - it's faster and optimized)
- When accessing home services remotely (use WireGuard instead)
- Your media stack doesn't use this at all

### **How to Connect:**
1. Start the ProtonVPN Docker container
2. Route your traffic through it as needed
3. Turn off when not needed

### **Configuration:**
- Provider: ProtonVPN
- Used for: General browsing privacy only

### **Still Needed?**
⚠️ **OPTIONAL - Not related to media stack**
- Nice to have for general privacy
- Your media stack works fine without it
- Keep if you use it for personal browsing
- Can be removed if unused

---

## 🔄 VPN Interaction Diagram

```
┌──────────────────────────────────────────────────────────┐
│              YOUR HOME NETWORK                            │
│                                                           │
│  ┌─────────────────────────────────────────────┐        │
│  │  Docker PC (Media Stack)                     │        │
│  │                                               │        │
│  │  ┌────────────────┐                          │        │
│  │  │  qBittorrent   │                          │        │
│  │  │       ↓        │                          │        │
│  │  │   PIA VPN      │  ← Always protecting     │        │
│  │  │  (Auto/24/7)   │    torrent traffic       │        │
│  │  └────────────────┘                          │        │
│  │                                               │        │
│  │  ┌────────────────┐                          │        │
│  │  │   Overseerr    │  ← Access via            │        │
│  │  │   Radarr       │    WireGuard when        │        │
│  │  │   Sonarr       │    away from home        │        │
│  │  │   Plex         │                          │        │
│  │  └────────────────┘                          │        │
│  └─────────────────────────────────────────────┘        │
│                                                           │
│  ┌─────────────────────────────────────────────┐        │
│  │  WireGuard Home VPN Server                   │        │
│  │  (Listening for remote connections)          │        │
│  └─────────────────────────────────────────────┘        │
│                          ▲                                │
└──────────────────────────┼────────────────────────────────┘
                           │
                           │ Secure WireGuard tunnel
                           │ (When away from home)
                           │
                  ┌────────┴─────────┐
                  │   Your Phone     │
                  │  (Coffee shop)   │
                  │                  │
                  │ Can now access:  │
                  │ • Overseerr      │
                  │ • Radarr/Sonarr  │
                  │ • Plex           │
                  └──────────────────┘


        Separate Usage (Not related to media stack)
        ┌──────────────────────────────────────┐
        │         ProtonVPN Container          │
        │                                      │
        │    Used for general browsing         │
        │    privacy when needed               │
        │                                      │
        │    Your Laptop ──► ProtonVPN ──► Internet
        │                                      │
        └──────────────────────────────────────┘
```

---

## 🎯 Quick Reference Guide

### **Scenario: I'm torrenting a movie**
- **Which VPN?** PIA (automatic)
- **Action needed?** None - it's always on

### **Scenario: I'm away from home and want to request a show on Overseerr**
- **Which VPN?** WireGuard Home VPN
- **Action needed?** Connect to WireGuard on your phone, then open Overseerr

### **Scenario: I'm at a coffee shop and want to browse privately**
- **Which VPN?** ProtonVPN
- **Action needed?** Start ProtonVPN container/connection

### **Scenario: I want to watch Plex remotely**
- **Which VPN?** None (use Plex's built-in remote access)
- **Alternative:** WireGuard Home VPN if you want extra security

### **Scenario: I'm at home on my WiFi**
- **Which VPN?** Only PIA (automatic for torrents)
- **Action needed?** None - everything works locally

---

## 📊 VPN Performance & Speeds

### **PIA:**
- Speed impact: ~10-20% slower than your full internet speed
- Always running: Yes
- Impact on other services: None (only affects qBittorrent)

### **WireGuard Home VPN:**
- Speed impact: Minimal (~5% overhead)
- Always running: No (only when you connect)
- Impact: Only affects devices connected to it

### **ProtonVPN:**
- Speed impact: Varies by server (~20-40% slower)
- Always running: No (only when you connect)
- Impact: Affects all traffic on connected device

---

## 🔒 Security Best Practices

1. **Never disable PIA** - Your torrents will be exposed
2. **Use WireGuard instead of port forwarding** - More secure
3. **Keep VPN credentials secure** - Stored in `.env` files
4. **Monitor VPN connections** - Check logs occasionally
5. **Test after changes** - Verify IP addresses after any config changes

---

## 🛠️ Troubleshooting

### **PIA not working (torrents exposed):**
```bash
# Check Gluetun logs
docker logs gluetun

# Verify qBittorrent is using PIA IP
docker exec qbittorrent curl ifconfig.me

# Should NOT show your home IP
```

### **WireGuard not connecting:**
- Check if WireGuard container is running
- Verify port forwarding on router (if required)
- Check firewall rules

### **ProtonVPN issues:**
- Verify credentials in configuration
- Check ProtonVPN service status
- Try different server location

---

## 📝 Important Notes

- **PIA** protects ONLY torrent traffic, not your general browsing
- **WireGuard** is not a "privacy VPN" - it's for accessing your home
- **ProtonVPN** is separate from your media stack entirely
- These VPNs serve **different purposes** and don't interfere with each other
- You can have all three configured simultaneously

---

## 🔗 Useful Links

- PIA Account: https://www.privateinternetaccess.com/
- ProtonVPN: https://account.protonvpn.com/
- WireGuard: https://www.wireguard.com/

---

## 📞 Support

If you need to modify these VPN settings:
- **PIA:** Edit `media_stack/.env` file
- **WireGuard:** Check `homevpn` project folder
- **ProtonVPN:** Check `privacyvpn` project folder

---

**Remember:** The best VPN setup is one you understand. Keep this document updated as you make changes!
