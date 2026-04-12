# phpIPAM — IP Address Management

Self-hosted tool for tracking IP addresses, subnets, and network layout.

## Access

| Item | Value |
|------|-------|
| Local URL | http://10.0.0.7:8081 |
| Remote URL (Tailscale) | http://100.82.35.70:8081 |
| Port | 8081 |
| Container | `phpipam-web` |
| Image | `phpipam/phpipam-www:latest` |

> **Note:** The phpIPAM README in the project folder says port 8080, but the compose file exposes port 8081. Port 8081 is correct.

## Compose Location

```
docker-projects/phpipam/docker-compose.yml
```

## Services

Three containers run together:

| Container | Role |
|-----------|------|
| `phpipam-web` | Web interface |
| `phpipam-db` | MariaDB database |
| `phpipam-cron` | Background network scanner (runs every 1 hour) |

All three share the `phpipam_net` Docker network.

## Credentials

Default credentials (change these):
- **Username**: `Admin`
- **Password**: `ipamadmin`

Database credentials are set in the compose file — change `MYSQL_ROOT_PASSWORD` and `MYSQL_PASSWORD` in `.env`.

## What It's Used For

phpIPAM lets you:
- Track which IPs are assigned and to which devices
- Document subnets (e.g., `10.0.0.0/24`)
- Auto-discover devices via network scanning (cron job)
- See subnet utilization at a glance

## Management

```powershell
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\phpipam"

docker-compose up -d     # Start
docker-compose down      # Stop
docker-compose logs -f phpipam-web  # Web logs
docker-compose logs -f phpipam-db   # DB logs
```

## Backup & Restore

The database is stored in a bind-mounted volume at `./mysql_data`. This should be included in Duplicati backups.

To manually dump the database:
```powershell
docker exec phpipam-db mysqldump -u phpipam -pphpipampassword phpipam > phpipam_backup.sql
```

To restore:
```powershell
docker exec -i phpipam-db mysql -u phpipam -pphpipampassword phpipam < phpipam_backup.sql
```
