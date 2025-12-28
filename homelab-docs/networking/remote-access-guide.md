# Remote Access Setup Guide

## Overview

This guide covers how to securely access your homelab services when away from home.

## Security Considerations

**IMPORTANT**: Exposing services to the internet comes with security risks. Always follow best practices:

- ✅ **Use VPN when possible** - Most secure option for accessing your network
- ✅ **Use strong passwords** - Enable 2FA where available
- ✅ **Keep services updated** - Patch security vulnerabilities regularly
- ✅ **Use HTTPS** - Encrypt traffic with SSL/TLS certificates
- ✅ **Limit exposed services** - Only expose what you actually need
- ❌ **Don't expose admin interfaces** - Never expose Portainer, Duplicati admin, etc.
- ❌ **Don't use default ports** - Change default ports when possible

## Option 1: VPN Access (Recommended)

VPN (Virtual Private Network) creates an encrypted tunnel to your home network, allowing secure access to ALL services.

### Benefits
- **Most Secure**: All traffic is encrypted
- **Access Everything**: Reach all internal services as if you're home
- **No Port Forwarding Needed**: Only one port (VPN) exposed to internet
- **No Individual Service Configuration**: Services don't need internet exposure

### VPN Solutions

#### WireGuard (Recommended)
Modern, fast, and secure VPN protocol.

**Setup Steps:**
1. Install WireGuard on your router or a dedicated device
2. Configure WireGuard server with your network settings
3. Generate client configurations for your devices
4. Forward UDP port 51820 on your router to WireGuard server
5. Install WireGuard client on phone/laptop
6. Connect via VPN when away from home

**Resources:**
- [WireGuard Official Site](https://www.wireguard.com/)
- [PiVPN](https://pivpn.io/) - Easy WireGuard setup for Raspberry Pi

#### OpenVPN (Alternative)
Older, well-established VPN protocol.

**Setup Steps:**
- Similar to WireGuard but uses TCP/UDP port 1194
- More complex configuration
- Broader device support

### After VPN Setup
Once connected via VPN:
- Access Home Assistant: `http://192.168.4.200:8123` (or your local IP)
- Access Plex: `http://192.168.4.200:32400/web` (or your local IP)
- Access all other services using local IPs

## Option 2: Direct Port Forwarding

Port forwarding opens specific ports on your router to allow internet access to individual services.

### When to Use Direct Port Forwarding
- **Plex Media Server**: Works well with Plex's built-in security
- **Web services with strong authentication**: Services with HTTPS and 2FA
- **Public-facing services**: Services you want others to access

### Services You Should NOT Expose Directly
- Duplicati (backup admin interface)
- Portainer (Docker admin interface)
- Router admin interface
- Database servers
- Internal monitoring tools

### Port Forwarding Setup Steps

The exact steps vary by router, but the general process is:

#### 1. Find Your Router's Admin Interface

Common router IPs:
- `192.168.1.1` or `192.168.0.1` (most common)
- `192.168.4.1` (your network might use this)
- `10.0.0.1` (some routers)

Try accessing these in your web browser. Look for login page.

#### 2. Log Into Router Admin Panel

- Username/password often on sticker on router
- Common defaults: admin/admin, admin/password (change these!)

#### 3. Locate Port Forwarding Settings

Common menu locations:
- "Advanced" → "Port Forwarding"
- "NAT/QoS" → "Port Forwarding"
- "Firewall" → "Port Forwarding"
- "Virtual Servers"
- "Gaming" or "Applications"

#### 4. Find Your Server's Local IP

On your Docker host, run:
```bash
ipconfig
```

Look for "IPv4 Address" - likely `192.168.4.200` based on your setup.

#### 5. Create Port Forwarding Rules

For each service, create a rule:

**Plex Media Server:**
- **Service Name**: Plex
- **External Port**: 32400
- **Internal IP**: 192.168.4.200 (your server IP)
- **Internal Port**: 32400
- **Protocol**: TCP

**Home Assistant:**
- **Service Name**: Home Assistant
- **External Port**: 8123 (or use 443 with reverse proxy)
- **Internal IP**: 192.168.4.200
- **Internal Port**: 8123
- **Protocol**: TCP

#### 6. Find Your Public IP Address

Visit: https://whatismyipaddress.com/

This is your WAN (internet) IP address.

#### 7. Test Access

From outside your network (use phone with WiFi off):
- Plex: `http://YOUR_PUBLIC_IP:32400/web`
- Home Assistant: `http://YOUR_PUBLIC_IP:8123`

## Option 3: Hybrid Approach (Best of Both)

Combine VPN and selective port forwarding:

1. **Set up VPN** for secure access to sensitive services
2. **Port forward Plex** for easy media streaming (Plex has good built-in security)
3. **Access Home Assistant via VPN** for security

This gives you:
- Easy Plex access for family/friends
- Secure access to admin/sensitive services via VPN

## Router-Specific Guides

### pfSense
1. Navigate to: Firewall → NAT → Port Forward
2. Click "Add" to create new rule
3. Fill in:
   - Interface: WAN
   - Protocol: TCP
   - Destination: WAN address
   - Destination Port: External port
   - Redirect Target IP: Internal server IP
   - Redirect Target Port: Internal port
4. Click "Save" and "Apply Changes"

### Consumer Routers (Netgear, TP-Link, Linksys, etc.)
1. Access router admin (usually 192.168.1.1)
2. Look for "Advanced" or "Advanced Setup"
3. Find "Port Forwarding" or "Virtual Servers"
4. Add new forwarding rule with external/internal ports and internal IP
5. Save settings

### UniFi/Ubiquiti
1. Open UniFi Network Controller
2. Go to: Settings → Routing & Firewall → Port Forwarding
3. Click "Create New Port Forward Rule"
4. Configure:
   - Name: Service name
   - Forward IP: Internal server IP
   - Forward Port: Internal port
   - External Port: External port (can be different)
5. Apply changes

## Dynamic DNS (DDNS)

Most home internet connections have dynamic IPs that change periodically. Use DDNS to get a stable domain name.

### Popular DDNS Providers
- **DuckDNS** (Free): https://www.duckdns.org/
- **No-IP** (Free tier): https://www.noip.com/
- **Dynu** (Free): https://www.dynu.com/

### Setup Process
1. Create account with DDNS provider
2. Create a hostname (e.g., `yourhomelab.duckdns.org`)
3. Configure your router to update DDNS (most routers have built-in DDNS clients)
4. Access services via hostname instead of IP: `http://yourhomelab.duckdns.org:32400`

## SSL/HTTPS with Let's Encrypt (Advanced)

For secure HTTPS access, use a reverse proxy with Let's Encrypt SSL certificates.

### Requirements
- Domain name or DDNS hostname
- Reverse proxy (Nginx Proxy Manager, Traefik, or Caddy)
- Ports 80 and 443 forwarded to reverse proxy

### Quick Setup with Nginx Proxy Manager
1. Deploy Nginx Proxy Manager container
2. Forward ports 80 and 443 to NPM
3. Add proxy hosts for each service
4. Request Let's Encrypt SSL certificates (automatic)
5. Access services via HTTPS: `https://plex.yourdomain.com`

This is more advanced - let me know if you want a detailed guide for this.

## Security Hardening

Once you've set up remote access:

### 1. Use Fail2Ban
Protects against brute force attacks by banning IPs after failed login attempts.

### 2. Enable Service Authentication
- Plex: Ensure Plex authentication is enabled
- Home Assistant: Use strong passwords and enable 2FA

### 3. Monitor Access Logs
- Check logs regularly for unauthorized access attempts
- Set up alerts for suspicious activity

### 4. Use Non-Standard Ports
- Instead of port 8123, use 18123 (example)
- Obscurity isn't security, but it reduces automated scans

### 5. Firewall Rules
- Only allow necessary ports
- Consider geo-blocking if you only access from specific countries

## Testing Your Setup

### From Inside Your Network
Some routers don't support NAT loopback (accessing your public IP from inside your network). Test from outside using:
- Phone with WiFi disabled (cellular data)
- https://www.yougetsignal.com/tools/open-ports/
- Ask a friend to test from their network

### Verify Ports Are Open
1. Go to: https://www.yougetsignal.com/tools/open-ports/
2. Enter your public IP
3. Enter the port number
4. Check if it's open

## Troubleshooting

### Can't Access Services from Outside
- ✓ Verify port forwarding rules are correct
- ✓ Check firewall on your Docker host (Windows Firewall)
- ✓ Confirm service is running: `docker ps`
- ✓ Test with cellular data, not WiFi
- ✓ Some ISPs block common ports (80, 443, 25) - try alternative ports

### Connection Times Out
- Port forwarding rule may be incorrect
- Service may not be listening on correct interface
- Firewall blocking traffic

### Works Inside Network but Not Outside
- NAT loopback issue (normal for some routers)
- Test from actual external network (phone cellular)

### Public IP Keeps Changing
- Set up Dynamic DNS (DDNS)
- Configure router to auto-update DDNS

## Next Steps

1. **Choose your approach**: VPN (most secure) or port forwarding
2. **Identify your router** and access admin interface
3. **Set up DDNS** for stable hostname
4. **Configure port forwarding** or VPN as needed
5. **Test access** from outside your network
6. **Enable security features** (strong passwords, 2FA, monitoring)
7. **(Optional) Set up reverse proxy** with HTTPS for production use

## Additional Resources

- [Home Assistant Remote Access Guide](https://www.home-assistant.io/docs/configuration/remote/)
- [Plex Remote Access Setup](https://support.plex.tv/articles/200289506-remote-access/)
- [Tailscale](https://tailscale.com/) - Easy mesh VPN alternative (zero-config)

## Questions?

If you need help with any specific step, refer to this guide or search for your router model's specific instructions.

Remember: **Security first!** When in doubt, use VPN instead of direct port forwarding.
