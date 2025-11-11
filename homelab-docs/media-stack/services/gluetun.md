# gluetun

🧩 Gluetun
# ** Overview ** 

Gluetun is a lightweight VPN client container that routes network traffic from other Docker containers through a secure VPN tunnel. It supports multiple VPN providers (NordVPN, ProtonVPN, Mullvad, etc.) and acts as a network proxy layer for privacy, security, and bypassing geo-restrictions.

In the stack, Gluetun serves as the VPN gateway for apps like qBittorrent, Sonarr, Radarr, and Overseerr — ensuring all outbound traffic from those containers is tunneled through the VPN.

# **Environment Variables** 
## Variable	Description
**VPN_SERVICE_PROVIDER:**Specifies your VPN provider (e.g., protonvpn, nordvpn, mullvad).
**OPENVPN_USER:** Your VPN account username. Often stored in an .env file for security.
**OPENVPN_PASSWORD:** Your VPN account password (also stored in .env).
**SERVER_COUNTRIES**	(Optional) Restricts connection to servers in a specific country.
TZ	Sets the container’s timezone.
**FIREWALL_OUTBOUND_SUBNETS**	(Optional) Used when you want local LAN access while connected to the VPN (e.g., 192.168.0.0/24).


# ** Compose File Break Down **

**image:** Specifies the gluetun image (and its latest version) be pulled

**Container Name:** sets the name for the container for easy identification

**cap_add:NET_ADMIN:** Grants network administration privilages required for 
VPN operation

**devices:/dev/net/tun:** Maps the TuN device from the host, necessary from creating the VPN tunnel.

**Ports:** Exposes specific ports for Gluetun to the host, which allows access to aspps that share its network (qbittorrent)

**Environment:** Passes VPN credentials and config values, loaded from the *.env* file for securitry
    - Region, vpn service provider, passwords etc

**Volumes:** Persists Gluetun configuration files on this server host (C:\media\config\gluetun).

**Restart:** Ensures the Gluetun restarts ybkess manually stopped.