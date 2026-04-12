# Static IP Assignments

## Server

The primary Docker host has a static IP assigned at the OS or router level.

| Host | IP | Method |
|------|----|--------|
| Home Server (DESKTOP-QGA3DVB) | `10.0.0.7` | Static (configured in Windows or DHCP reservation) |
| Router / Gateway | `10.0.0.1` | Fixed (router default) |

> **Note:** Add details here on whether this is set as a static IP in Windows network settings or as a DHCP reservation in the router. Both achieve the same result but the approach matters if the server is reinstalled.

---

## Tailscale IPs (Assigned by Tailscale)

These are stable within your Tailscale network and don't change unless the device is removed and re-added.

| Device | Tailscale IP |
|--------|-------------|
| Home Server (DESKTOP-QGA3DVB) | `100.82.35.70` |
| iPhone 14 | `100.94.112.76` |

---

## Service Addresses

All Docker services run on the server and are accessed via the server's IP + their port. See [docker-projects/README.md](../../docker-projects/README.md) for the full port table.

---

## Previous IPs

An earlier network configuration used the `192.168.4.x` range (server at `192.168.4.200`, router at `192.168.4.1`). Some older documentation may still reference these. The current network uses `10.0.0.x`.
