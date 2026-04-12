# Networking Overview

## Network Layout

The homelab runs on a home network with a static IP assigned to the server.

| Device / Service | IP Address | Notes |
|-----------------|------------|-------|
| Router / Gateway | `10.0.0.1` | Home router |
| Home Server | `10.0.0.7` | Static IP — primary Docker host |
| Pi-hole (DNS) | `10.0.0.7:53` | DNS runs on the server |
| Tailscale (server) | `100.82.35.70` | Remote access VPN IP |

> **Note:** The router model / firewall software (e.g., pfSense, consumer router) is TBD — add details here once confirmed.

---

## DNS

Pi-hole handles DNS for the network. It runs as a Docker container on the server and listens on port 53.

- **Web admin**: http://10.0.0.7:8082/admin
- See [Pi-hole docs](../pi-hole/pi-home.md) for full setup details
- Upstream DNS: Google + Cloudflare (with DNSSEC)

To use Pi-hole network-wide, configure your router's DHCP to hand out `10.0.0.7` as the DNS server.

---

## Remote Access

Tailscale is used for remote access. It bypasses CGNAT without requiring port forwarding.

- **Server Tailscale IP**: `100.82.35.70`
- See [Remote Access docs](../remote-access/README.md) for full details

---

## Service Ports

See the port reference in [docker-projects/README.md](../../docker-projects/README.md) for the full list of services and ports.

Key external access via Tailscale: all services on `100.82.35.70` using their respective ports.

---

## Static IP Assignment

The server is assigned static IP `10.0.0.7`. See [static-ips.md](static-ips.md) for how this is configured.

---

## Sections to Fill In

- [ ] Router model / firewall software
- [ ] VLAN configuration (if any)
- [ ] WiFi setup
- [ ] ISP details (CGNAT confirmed — see remote-access docs)
