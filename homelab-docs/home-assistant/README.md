# Home Assistant

Home Assistant runs in a VirtualBox VM with bridged networking for full LAN access to IoT devices.

## Why VirtualBox (Not Docker)?

Docker Desktop on Windows runs containers inside a Linux VM that cannot directly access the physical LAN. This breaks integrations with local IoT devices (Tapo, Reolink, etc.).

VirtualBox with **bridged networking** gives Home Assistant a real IP on your network (10.0.0.x), enabling direct communication with all local devices.

## Quick Reference

| Item | Value |
|------|-------|
| VM Name | `HomeAssistant` |
| Access URL | `http://homeassistant.local:8123` or `http://10.0.0.46:8123` |
| IP Address | `10.0.0.46` (set DHCP reservation to keep this) |
| VM Location | `C:\VirtualBox VMs\HomeAssistant\` |
| Disk Image | `haos_ova-17.2.vdi` |
| RAM | 2048 MB |
| CPUs | 2 |
| Network | Bridged (Intel I211 Gigabit) |

## Starting and Stopping

### Start Home Assistant
```powershell
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' startvm 'HomeAssistant'
```

### Start Headless (no window)
```powershell
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' startvm 'HomeAssistant' --type headless
```

### Stop Home Assistant (graceful)
```powershell
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' controlvm 'HomeAssistant' acpipowerbutton
```

### Force Stop (if unresponsive)
```powershell
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' controlvm 'HomeAssistant' poweroff
```

### Check Status
```powershell
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' showvminfo 'HomeAssistant' --machinereadable | Select-String 'VMState'
```

## Auto-Start on Boot

To have Home Assistant start automatically when Windows boots:

1. Create a shortcut to VBoxManage with the start command
2. Place it in: `C:\Users\<username>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup`

Or use Task Scheduler:
1. Open Task Scheduler
2. Create Basic Task → "Start Home Assistant"
3. Trigger: "When the computer starts"
4. Action: Start a program
   - Program: `C:\Program Files\Oracle\VirtualBox\VBoxManage.exe`
   - Arguments: `startvm "HomeAssistant" --type headless`

## How It Was Built

### Prerequisites
- VirtualBox installed from https://www.virtualbox.org/wiki/Downloads
- Home Assistant OS VDI image from https://www.home-assistant.io/installation/windows

### VM Creation Commands

```powershell
# Create the VM
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' createvm --name 'HomeAssistant' --ostype 'Linux_64' --register --basefolder 'C:\VirtualBox VMs'

# Configure resources and EFI boot
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' modifyvm 'HomeAssistant' --memory 2048 --cpus 2 --firmware efi --graphicscontroller vmsvga --vram 16

# Add storage controller
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' storagectl 'HomeAssistant' --name 'SATA' --add sata --controller IntelAhci --portcount 2

# Attach the disk image
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' storageattach 'HomeAssistant' --storagectl 'SATA' --port 0 --device 0 --type hdd --medium 'C:\VirtualBox VMs\HomeAssistant\haos_ova-17.2.vdi'

# Configure bridged networking (use your adapter name)
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' modifyvm 'HomeAssistant' --nic1 bridged --bridgeadapter1 'Intel(R) I211 Gigabit Network Connection'

# Start the VM
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' startvm 'HomeAssistant'
```

### Finding Your Network Adapter
```powershell
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' list bridgedifs | Select-String 'Name:'
```

## Network Configuration

Home Assistant uses **bridged networking**, meaning it gets its own IP address from your router's DHCP server, just like a physical device.

### Verify Network Access
From inside the VM console (or via SSH), Home Assistant should be able to ping:
- Your router (10.0.0.1)
- Other devices on your network
- The internet

### Set a Static IP (Recommended)
To prevent the IP from changing:
1. Access Home Assistant at `http://homeassistant.local:8123`
2. Go to **Settings → System → Network**
3. Configure a static IP (e.g., 10.0.0.50)

Or set a DHCP reservation in your router.

## Connecting Other Services

### n8n Workflows
Update your n8n Home Assistant connection to use the new IP:
- Old (Docker): `http://homeassistant:8123`
- New (VirtualBox): `http://10.0.0.x:8123`

### Docker Containers
Containers can reach the Home Assistant VM via its LAN IP since they can access the host network.

## Migrating from Docker

If you had Home Assistant running in Docker, you can migrate your configuration:

### Option 1: Backup/Restore (Recommended)
1. In old HA: **Settings → System → Backups → Create Backup**
2. Download the backup file
3. In new HA: **Settings → System → Backups → Upload Backup**
4. Restore

### Option 2: Manual Config Copy
Your old config is at:
```
C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\home_assist\configuration\config
```

Copy these files/folders to the new HA via Samba share or File Editor add-on:
- `configuration.yaml`
- `automations.yaml`
- `scripts.yaml`
- `scenes.yaml`
- `secrets.yaml`
- `custom_components/` (if any)

### Stop Old Docker HA
Once migration is complete:
```bash
cd "C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\home_assist"
docker compose down
```

## Backups

### Home Assistant Backups
- **Settings → System → Backups**
- Backups stored inside the VM
- Download important backups to your PC

### VM Snapshot (Full State Backup)
```powershell
# Create snapshot
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' snapshot 'HomeAssistant' take 'backup-2026-04-10' --description 'Before major update'

# List snapshots
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' snapshot 'HomeAssistant' list

# Restore snapshot
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' snapshot 'HomeAssistant' restore 'backup-2026-04-10'
```

### Backup the VDI File
Stop the VM first, then copy:
```
C:\VirtualBox VMs\HomeAssistant\haos_ova-17.2.vdi
```

## Troubleshooting

### Can't Access Home Assistant
1. Check VM is running: Look for VirtualBox window or check status
2. Find the IP: Look at VM console or check router's DHCP leases
3. Try: `http://homeassistant.local:8123` or `http://<IP>:8123`

### VM Won't Start
```powershell
# Check for errors
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' startvm 'HomeAssistant' 2>&1
```

### Network Not Working
1. Verify bridged adapter is correct:
   ```powershell
   & 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' showvminfo 'HomeAssistant' | Select-String 'NIC 1'
   ```
2. Try a different adapter (WiFi vs Ethernet)
3. Check Windows Firewall isn't blocking VirtualBox

### Integrations Can't Find Devices
- Ensure devices are on same network/VLAN as Home Assistant
- Check device IPs haven't changed (use DHCP reservations)
- Restart the integration in Home Assistant

### VM Running Slow
Increase resources:
```powershell
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' modifyvm 'HomeAssistant' --memory 4096 --cpus 4
```

## Useful Commands

```powershell
# List all VMs
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' list vms

# List running VMs
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' list runningvms

# Show VM details
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' showvminfo 'HomeAssistant'

# Modify VM (must be stopped)
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' modifyvm 'HomeAssistant' --memory 4096
```

## File Locations

| Item | Path |
|------|------|
| VirtualBox Install | `C:\Program Files\Oracle\VirtualBox\` |
| VM Files | `C:\VirtualBox VMs\HomeAssistant\` |
| VM Config | `C:\VirtualBox VMs\HomeAssistant\HomeAssistant.vbox` |
| Disk Image | `C:\VirtualBox VMs\HomeAssistant\haos_ova-17.2.vdi` |
| Old Docker Config | `C:\Users\mattd\OneDrive\Matts Documents\Docker\docker-projects\home_assist\configuration\config` |
