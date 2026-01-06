# ⚠️ DEPRECATED - WireGuard (wg-easy)

**This WireGuard setup is NO LONGER IN USE.**

## Why It Was Replaced

Our ISP uses **CGNAT** (Carrier-Grade NAT):
- Router WAN IP: `100.65.30.217` (shared, non-public IP)
- Port forwarding is impossible with CGNAT
- Traditional self-hosted VPN cannot work through CGNAT

## Current Solution

**We now use Tailscale** for remote access.

See: `homelab-docs/remote-access/` for current documentation.

---

## What This Directory Was

This was an attempt to set up self-hosted WireGuard using wg-easy for remote access.

**Configuration:**
- Service: wg-easy (WireGuard with web UI)
- Port: 51820 UDP
- DDNS: damattberghome.duckdns.org
- Admin password: WireGuardAdmin2024!

**Why It Failed:**
1. Configured port forwarding correctly ✅
2. Added Windows Firewall rules ✅
3. Set up DuckDNS correctly ✅
4. But packets never reached the server ❌

**Root Cause:** ISP CGNAT blocks all inbound traffic before it reaches our router.

---

## Timeline

- **First attempt:** Failed (unknown reason at the time)
- **Second attempt:** Failed (still debugging)
- **Third attempt (2026-01-05):** Discovered CGNAT was the blocker
- **Solution (2026-01-05):** Switched to Tailscale, works perfectly

---

## Lessons Learned

1. **Check for CGNAT first** - Look at router WAN IP
   - `100.64.0.0/10` range = CGNAT
   - Saves hours of troubleshooting

2. **Tailscale for CGNAT situations** - Works around ISP restrictions

3. **Port forwarding isn't always the answer** - Sometimes the network topology prevents it

---

## Files in This Directory

- `docker-compose.yml` - WireGuard server config (not used)
- `README.md` - Original setup documentation
- `.gitignore` - Prevented committing private keys
- `DEPRECATED.md` - This file

**Removed:**
- `client_configs/` - Old VPN client configurations
- `config/` - Server configuration and keys

---

*Deprecated: 2026-01-05*
*Replaced by: Tailscale (see homelab-docs/remote-access/)*
