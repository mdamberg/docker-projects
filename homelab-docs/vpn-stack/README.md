# VPN Stack

## Current Setup: Tailscale (Active)

Remote access to the homelab is handled by **Tailscale**. See [Remote Access docs](../remote-access/README.md) for full details.

**Why Tailscale?** The ISP uses CGNAT (Carrier-Grade NAT), which means the router's WAN IP is a shared, non-public address. Traditional self-hosted VPNs (WireGuard, OpenVPN) can't work in this configuration because port forwarding never reaches the router. Tailscale bypasses this entirely using a mesh VPN approach.

### Quick Reference

| Item | Value |
|------|-------|
| Server Tailscale IP | `100.82.35.70` |
| Phone Tailscale IP | `100.94.112.76` |
| Tailscale Admin | https://login.tailscale.com/admin |

---

## VPN for Torrenting: Gluetun (Active)

A separate VPN is used to route torrent traffic through a privacy VPN provider. This is handled by **Gluetun** inside the media stack — it's completely separate from remote access.

- Located in: `docker-projects/media_stack/`
- See: [Media Stack docs](../media-stack/services/gluetun.md)
- qBittorrent routes through Gluetun so torrent traffic exits through the privacy VPN

---

## Legacy: WireGuard wg-easy (Deprecated)

Previously, a self-hosted WireGuard VPN was used for remote access:

- **Image**: `ghcr.io/wg-easy/wg-easy`
- **DDNS Hostname**: `damattberghome.duckdns.org`
- **VPN Network**: `10.8.0.0/24`
- **Clients configured**: Remote_access, Phone, Laptop, Tablet

This was replaced by Tailscale because CGNAT made WireGuard port forwarding unreliable. The config files are still in `docker-projects/wireguard/` but the service is no longer running. See `docker-projects/wireguard/DEPRECATED.md` for details.

---

## Legacy: homevpn WireGuard (Deprecated)

An earlier WireGuard setup also exists at `docker-projects/vpn/homevpn/` with 3 peers (peer1, peer2, peer3) and a CoreDNS config. This predates wg-easy and is also no longer active.

---

## Summary

| Setup | Status | Use Case |
|-------|--------|----------|
| Tailscale | ✅ Active | Remote access to all homelab services |
| Gluetun | ✅ Active | Privacy VPN tunnel for torrent traffic |
| wg-easy WireGuard | ❌ Deprecated | Former remote access (replaced by Tailscale) |
| homevpn WireGuard | ❌ Deprecated | Even older remote access setup |
