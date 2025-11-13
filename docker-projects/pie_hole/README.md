# Pi-hole Docker Setup

This directory contains the Pi-hole DNS ad-blocker running in Docker.

## Configuration

### Docker Compose
The Pi-hole container is managed using `docker-compose.yml` with the following configuration:

- **Web Interface (HTTP)**: `http://localhost:8082/admin`
- **Web Interface (HTTPS)**: `https://localhost:8443/admin`
- **DNS Port**: `5335` (mapped from container port 53)
- **Timezone**: America/Chicago

### Volumes
- `./etc-pihole:/etc/pihole` - Pi-hole configuration and data

## Usage

### Starting Pi-hole
```bash
docker-compose up -d
```

### Stopping Pi-hole
```bash
docker-compose down
```

### Restarting Pi-hole
```bash
docker-compose restart
```

### Viewing Logs
```bash
docker-compose logs -f
```

## Password Management

### Setting a New Password
To set or change the admin password:
```bash
docker exec pihole pihole setpassword 'YourNewPassword'
docker restart pihole
```

### Removing Password
To remove the password (not recommended):
```bash
docker exec pihole pihole setpassword ''
docker restart pihole
```

## Accessing the Web Interface

### Important: Use Incognito/Private Mode
Due to browser session caching issues, it's recommended to access the Pi-hole web interface in an **incognito/private browser window** for the first login after password changes.

**Steps:**
1. Open an incognito/private browser window
2. Navigate to `http://localhost:8082/admin`
3. Enter your password
4. Once logged in successfully, you can use regular browser windows

### Troubleshooting Login Issues
If you experience "Wrong password!" errors or get kicked out immediately after login:

1. **Restart the container**: `docker restart pihole`
2. **Clear browser cache/cookies** for `localhost:8082`
3. **Use incognito/private mode** for login
4. **Try a different browser** (Chrome, Firefox, Edge)

## Network Configuration

Pi-hole is configured with:
- Network mode: `pie_hole_default` (Docker bridge network)
- IP Address: Assigned by Docker (typically `172.23.0.2`)
- DNS queries should be directed to `localhost:5335`

## Additional Commands

### Check Pi-hole Version
```bash
docker exec pihole pihole -v
```

### Update Gravity (blocklists)
```bash
docker exec pihole pihole -g
```

### View Pi-hole Status
```bash
docker exec pihole pihole status
```

### Flush Pi-hole Logs
```bash
docker exec pihole pihole -f
```

## Notes

- The password is stored as a hash in `/etc/pihole/pihole.toml`
- Database files and sensitive configurations are excluded from git via `.gitignore`
- Container requires `CAP_NET_ADMIN` capability for network operations
