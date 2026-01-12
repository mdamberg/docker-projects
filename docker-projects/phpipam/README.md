# phpIPAM - IP Address Management

phpIPAM is an open-source IP address management (IPAM) tool that helps you track and manage your network's IP addresses, subnets, and VLANs.

## What's Included

- **phpipam-db**: MariaDB database for storing all IP data
- **phpipam-web**: Web interface (accessible at http://localhost:8080)
- **phpipam-cron**: Background scanner that discovers devices on your network

## Setup Instructions

### 1. Start the containers

```bash
cd C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\phpipam
docker-compose up -d
```

### 2. Access the web interface

Open your browser and go to: **http://localhost:8080**

### 3. First-time setup

If this is your first time running phpIPAM:

1. You'll see an installation screen
2. Click "New phpipam installation"
3. Follow the setup wizard
4. Create your admin account

**Default credentials** (if database already exists):
- Username: `Admin`
- Password: `ipamadmin` (change this immediately!)

### 4. Configure your network

Once logged in:
1. Go to "Administration" → "Subnets"
2. Add your network subnets (e.g., 192.168.1.0/24)
3. Enable scanning to discover devices

## Configuration

### Change the port

If port 8080 is already in use, edit the `.env` file:

```env
PHPIPAM_PORT=8081
```

Then restart:

```bash
docker-compose down
docker-compose up -d
```

### Change passwords

Edit the `.env` file and update:
- `MYSQL_ROOT_PASSWORD`
- `MYSQL_PASSWORD`

Then rebuild:

```bash
docker-compose down
docker-compose up -d
```

## Useful Commands

```bash
# View logs
docker logs phpipam-web
docker logs phpipam-db

# Restart services
docker-compose restart

# Stop services
docker-compose down

# Update to latest version
docker-compose pull
docker-compose up -d
```

## What You Can Do With phpIPAM

- 📊 **Track IP addresses**: See which IPs are used/free
- 🔍 **Network discovery**: Automatically scan and discover devices
- 📝 **Documentation**: Add descriptions and notes to IPs
- 🌐 **VLAN management**: Organize networks by VLANs
- 📈 **Subnet utilization**: See how full your subnets are
- 🔔 **Alerts**: Get notified when subnets are running low on IPs

## Troubleshooting

### Database connection issues

If the web container can't connect to the database:

```bash
docker-compose logs phpipam-db
```

Make sure the database is fully started before the web container.

### Reset admin password

Connect to the database:

```bash
docker exec -it phpipam-db mysql -u root -p
```

Enter password: `phpipamadmin`

Then run:

```sql
USE phpipam;
UPDATE users SET password = MD5('newpassword') WHERE username = 'Admin';
EXIT;
```
