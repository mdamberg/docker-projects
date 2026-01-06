# Tailscale Setup Guide

Complete step-by-step guide for setting up Tailscale for remote access to your homelab.

---

## Prerequisites

- A device running your homelab services (Windows/Linux/Mac)
- Mobile device (iPhone/Android) or laptop for remote access
- Internet connection
- Email account for Tailscale registration

---

## Step 1: Create Tailscale Account (5 minutes)

1. **Go to Tailscale website:**
   - Visit: https://tailscale.com/download

2. **Download Tailscale for your server OS:**
   - Windows: Download the Windows installer
   - Linux: Follow the Linux instructions
   - Mac: Download the Mac app

3. **Create account during installation:**
   - Choose sign-in method:
     - Google (recommended)
     - GitHub
     - Microsoft
     - Email
   - Complete authentication

4. **You'll see the Tailscale admin console**
   - This is where you manage all devices
   - Bookmark: https://login.tailscale.com/admin

---

## Step 2: Install Tailscale on Server (5 minutes)

### Windows Installation

1. **Run the installer** you downloaded

2. **Windows Firewall prompt:**
   - Click "Allow access" when prompted
   - Tailscale needs to create network interfaces

3. **Authentication:**
   - A browser window will open
   - Click "Connect" to add this device
   - Give the device a recognizable name if prompted

4. **Verify installation:**
   - Look for Tailscale icon in system tray (bottom-right)
   - Should show a green check mark
   - Right-click → "Tailscale" shows your IP

5. **Note your server's Tailscale IP:**
   - Example: `100.82.35.70`
   - You'll use this to access services

### Linux Installation (If applicable)

```bash
# Download and install
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale
sudo tailscale up

# Authenticate (opens browser)
# Follow the link to add device

# Check status
tailscale status

# Get IP address
tailscale ip
```

---

## Step 3: Install Tailscale on Mobile Device (5 minutes)

### iPhone/iPad

1. **Download from App Store:**
   - Search "Tailscale"
   - Install the official Tailscale app

2. **Open the app:**
   - Tap "Sign in"
   - Use the SAME account you used for the server
   - Tap "Add this device" or "Connect"

3. **Grant VPN permissions:**
   - iOS will ask to add VPN configuration
   - Tap "Allow"
   - May require Face ID/Touch ID

4. **Toggle Tailscale ON:**
   - Green toggle = connected
   - You'll see a VPN indicator in status bar

5. **Verify connection:**
   - Tap on the device list
   - Should see your server and phone both online (green dots)

### Android

1. **Download from Google Play:**
   - Search "Tailscale"
   - Install the official Tailscale app

2. **Open the app:**
   - Tap "Sign in"
   - Use the SAME account you used for the server
   - Tap "Add this device"

3. **Grant VPN permissions:**
   - Android will prompt for VPN connection permission
   - Tap "OK"

4. **Toggle Tailscale ON:**
   - Tap the toggle to connect
   - Key icon in status bar = connected

5. **Verify connection:**
   - Check device list shows server and phone online

---

## Step 4: Test the Connection (5 minutes)

### From Your Phone

1. **Make sure you're on a different network than your server:**
   - Turn OFF WiFi (use cellular data)
   - Or connect to a different WiFi network
   - This simulates being away from home

2. **Ensure Tailscale is ON:**
   - Check for VPN indicator (iOS) or key icon (Android)
   - Green status in Tailscale app

3. **Open a web browser on your phone**

4. **Try accessing your services using the server's Tailscale IP:**

   Replace `100.82.35.70` with YOUR server's Tailscale IP:

   ```
   http://100.82.35.70:8181        # Homarr dashboard
   http://100.82.35.70:8123        # Home Assistant
   http://100.82.35.70:32400/web   # Plex
   http://100.82.35.70:5070        # Todo app
   ```

5. **Success indicators:**
   - ✅ Pages load just like when you're at home
   - ✅ Can browse your media, check sensors, etc.
   - ✅ All services accessible

6. **If it doesn't work:**
   - See [Troubleshooting](#troubleshooting) section below

---

## Step 5: Add Additional Devices (Optional)

### Add a Laptop

1. **Download Tailscale** for your laptop OS:
   - Windows: https://tailscale.com/download/windows
   - Mac: https://tailscale.com/download/mac
   - Linux: https://tailscale.com/download/linux

2. **Install and authenticate** (same as Step 2)

3. **Device appears** in your Tailscale network automatically

### Add a Tablet

Same process as mobile phone (Step 3)

---

## Step 6: Enable MagicDNS (Optional - Makes URLs Prettier)

MagicDNS gives your devices easy-to-remember names instead of IP addresses.

### Enable in Tailscale Admin Console

1. **Go to:** https://login.tailscale.com/admin/dns

2. **Click "Enable MagicDNS"**

3. **Now you can use device names instead of IPs:**

   **Before MagicDNS:**
   ```
   http://100.82.35.70:8181
   ```

   **After MagicDNS:**
   ```
   http://desktop-qga3dvb:8181
   ```

4. **Even better - set a custom name:**
   - In admin console, click on a device
   - Set "Machine name" to something like `homelab`
   - Now use: `http://homelab:8181`

---

## Configuration Reference

### Server Details

- **Device Name:** DESKTOP-QGA3DVB
- **Tailscale IP:** 100.82.35.70
- **Local IP:** 10.0.0.7
- **OS:** Windows 11

### Network Architecture

```
Internet (Anywhere)
    │
    ├─── Your Phone (Tailscale: 100.94.112.76)
    │
    ├─── Your Laptop (Tailscale: 100.x.x.x - when added)
    │
    └─── Your Server (Tailscale: 100.82.35.70)
         │
         └─── Local Network (10.0.0.0/24)
              │
              ├─ Homarr         (10.0.0.7:8181)
              ├─ Home Assistant (10.0.0.7:8123)
              ├─ Plex           (10.0.0.7:32400)
              ├─ Portainer      (10.0.0.7:9443)
              └─ All other services...
```

### Port Reference

See main [README.md](./README.md#services-accessible) for complete service list.

---

## Troubleshooting

### Tailscale Won't Connect

**Symptom:** Gray/offline status in Tailscale app

**Solutions:**
1. **Restart Tailscale app**
   - Windows: Right-click tray icon → Exit → Relaunch from Start menu
   - Phone: Force close app and reopen

2. **Check internet connection**
   - Tailscale needs internet to coordinate connections
   - Try a different network

3. **Re-authenticate**
   - Windows: Right-click tray icon → "Log out" → "Log in"
   - Phone: Settings in app → Log out → Log back in

### Services Not Loading

**Symptom:** Browser shows "Connection timed out" or "Can't reach this page"

**Check:**
1. **Tailscale is connected** (green/online status)

2. **Using correct IP:**
   - Server Tailscale IP: `100.82.35.70`
   - NOT the local IP (10.0.0.7)

3. **Service is running on server:**
   - Check in Portainer: https://100.82.35.70:9443
   - Or check Docker: `docker ps`

4. **Correct port number:**
   - See [service list](./README.md#services-accessible)
   - Example: Homarr is port 8181, not 8080

### Home Assistant Shows Security Error

**Symptom:** "Most Secure" connection error or refuses to connect

**Solutions:**

1. **Option A - Update Home Assistant Configuration:**
   ```yaml
   # In configuration.yaml
   http:
     use_x_forwarded_for: true
     trusted_proxies:
       - 100.0.0.0/8  # Trust all Tailscale IPs
   ```

2. **Option B - Use when at home:**
   - Local network: http://10.0.0.7:8123
   - Remote via Tailscale: http://100.82.35.70:8123

### Slow Performance

**Symptom:** Pages load slowly, video buffers

**Reasons:**
1. **DERP relay in use** (not peer-to-peer)
   - Tailscale tries P2P first, falls back to relay
   - Relay is slower but still works

2. **Poor cellular signal**
   - Check your phone's connection speed

3. **Server upload bandwidth**
   - Streaming large files uses your home upload speed

**Check connection type:**
```bash
# On server
tailscale status

# Look for "relay" vs "direct" in output
```

### Can't Add New Device

**Symptom:** Device won't authenticate or doesn't appear

**Solutions:**
1. **Using same account?**
   - All devices must use the same Tailscale account
   - Check email address in app settings

2. **Hit device limit?**
   - Free plan: 100 devices (unlikely to hit this)
   - Check admin console: https://login.tailscale.com/admin

3. **Device already exists?**
   - May have added it before
   - Check admin console for existing devices
   - Remove and re-add if needed

---

## Advanced Configuration

### Subnet Routing (Access to Entire Home Network)

If you want to access devices OTHER than your server via Tailscale:

1. **Enable IP forwarding on server:**
   ```bash
   # Windows (PowerShell as Admin)
   Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "IPEnableRouter" -Value 1
   ```

2. **Advertise routes:**
   ```bash
   tailscale up --advertise-routes=10.0.0.0/24
   ```

3. **Accept routes in admin console:**
   - https://login.tailscale.com/admin
   - Click on server device
   - Click "Edit route settings"
   - Enable the subnet route

4. **Now you can access ANY device on 10.0.0.0/24:**
   ```
   http://10.0.0.1      # Router
   http://10.0.0.100    # Any other device
   ```

### Exit Node (Route ALL Traffic Through Home)

Make your server act as a VPN exit node (like traditional VPN):

1. **Enable on server:**
   ```bash
   tailscale up --advertise-exit-node
   ```

2. **Accept in admin console**

3. **Enable on client devices** when you want to route all traffic through home

**Use cases:**
- Public WiFi security
- Access region-locked content
- Use home DNS/Pi-hole when remote

---

## Security Best Practices

1. **Enable 2FA on Tailscale Account:**
   - https://login.tailscale.com/admin/settings/account
   - Enable two-factor authentication

2. **Review Devices Monthly:**
   - https://login.tailscale.com/admin/machines
   - Remove old/unused devices

3. **Use ACLs (Access Control Lists):**
   - Restrict which devices can access which services
   - https://login.tailscale.com/admin/acls

4. **Keep Tailscale Updated:**
   - Enable auto-updates on all devices
   - Updates include security patches

5. **Monitor Access Logs:**
   - Check admin console for unusual activity
   - Review which devices are connecting

---

## Next Steps

After setup is complete:

1. ✅ **Bookmark important URLs** on your phone
2. ✅ **Add Tailscale to other devices** (laptop, tablet, etc.)
3. ✅ **Test from different locations** (work, coffee shop, vacation)
4. ✅ **Set up MagicDNS** for prettier URLs
5. ✅ **Enable subnet routing** if you want access to entire home network
6. ✅ **Configure Home Assistant** to work with Tailscale
7. ✅ **Remove old VPN configs** (WireGuard, etc.) from router

---

## Maintenance Schedule

### Weekly
- None required!

### Monthly
- Review connected devices
- Remove unused devices
- Check for Tailscale updates

### Quarterly
- Review access control settings
- Update documentation if you add new services

### Annually
- Review security settings
- Rotate Tailscale authentication if desired

---

## Getting Help

**Tailscale Resources:**
- Documentation: https://tailscale.com/kb/
- Community Forum: https://forum.tailscale.com/
- Support: support@tailscale.com (for paid plans)

**Homelab Specific:**
- Check logs in Portainer
- Review service-specific documentation in `homelab-docs/`

---

*Setup Date: 2026-01-05*
*Last Updated: 2026-01-05*
