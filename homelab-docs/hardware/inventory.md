# Hardware Inventory

## Primary Server

The homelab runs on an older gaming PC repurposed as a server.

| Item | Detail |
|------|--------|
| Role | Primary Docker host |
| OS | Windows 11 |
| Hostname | DESKTOP-QGA3DVB |
| Local IP | 10.0.0.7 (static) |
| Tailscale IP | 100.82.35.70 |

> **To fill in:** CPU model, RAM amount, storage (drives and sizes), GPU (if relevant), approximate age. Run `msinfo32` or check Task Manager → Performance for specs.

---

## Display

Single monitor connected to visualize the server when needed. Typically headless during normal operation — all management is done remotely via Portainer, Tailscale, or PowerShell.

---

## Networking Equipment

| Device | IP | Notes |
|--------|----|-------|
| Router/Gateway | 10.0.0.1 | ISP CGNAT — no public IP |

> **To fill in:** Router model/brand. Also note: ISP uses CGNAT (Carrier-Grade NAT), confirmed during WireGuard setup — this is why Tailscale is used for remote access.

---

## Planned / Future Hardware

- **NAS**: Planned — would move media storage and backups off the main server
- **UPS (Uninterruptible Power Supply)**: TBD — would protect against power loss corrupting running containers
- **Dedicated server hardware**: Possibly a proper rack-mount server or mini PC down the road

---

## Notes

- Server must remain powered on for services to be available (Pi-hole especially — if it goes down, DNS on the whole network stops resolving)
- Consider a UPS for the server to prevent unclean shutdowns
