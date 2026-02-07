# Setup Instructions - Fix "Credentials not found" Error

The error occurs because n8n requires proper credential configuration. Here's how to fix it:

## Method 1: Use the Updated Workflow (Easiest)

I've created an updated workflow file that has the token embedded directly in the HTTP request.

1. **Import the new workflow**:
   - Open n8n at http://localhost:5678
   - Menu (☰) → "Import from File"
   - Select `power_consumption_workflow_v2.json` (the new version)
   - Click "Import"

2. **Test it**:
   - Click "Execute Workflow" button
   - It should work immediately!

## Method 2: Manual Test (Quick Check)

If you want to verify the connection first:

1. **Test from command line**:
   ```bash
   curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI1NTUzNzU2ODc4NGU0ZDBlYjUxOThkMDE4ZDk2MmE3NCIsImlhdCI6MTc2ODAyMDAyMCwiZXhwIjoyMDgzMzgwMDIwfQ.Kj40JyRm33ql-Im4v9tFgH7TGuZeNIvV8Y3nCKO2Rg0" http://localhost:8123/api/states
   ```

   If this works, your token is valid and HA is accessible.

## Method 3: Check Docker Networking (If Still Having Issues)

If the workflow still can't connect:

1. **Check if containers are on same network**:
   ```bash
   docker network ls
   docker network inspect bridge
   ```

2. **Find Home Assistant IP**:
   ```bash
   docker inspect homeassistant -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
   ```

3. **Update the workflow**:
   - Click on "Get All HA States" node
   - Change URL from `http://homeassistant:8123/api/states`
   - To: `http://[HA_IP_ADDRESS]:8123/api/states`
   - Example: `http://172.17.0.2:8123/api/states`

## Method 4: Put Containers on Same Network (Recommended for Future)

Create a shared network for better integration:

```bash
# Create a network
docker network create home-automation

# Connect both containers
docker network connect home-automation homeassistant
docker network connect home-automation n8n

# Restart both containers
docker restart homeassistant n8n
```

After this, the hostname `http://homeassistant:8123` will work perfectly.

## Troubleshooting

### Error: "ENOTFOUND homeassistant"
- Containers aren't on the same network
- Solution: Use the IP address method (Method 3) or shared network (Method 4)

### Error: "401 Unauthorized"
- Token is incorrect or expired
- Solution: Generate a new token in Home Assistant

### Error: "Connection refused"
- Home Assistant isn't running or not accessible
- Solution: Check with `docker ps` and verify HA is running

### Still not working?
Try accessing from within the n8n container:
```bash
docker exec -it n8n sh
wget -O- --header="Authorization: Bearer YOUR_TOKEN" http://homeassistant:8123/api/states
```

This will show if n8n can reach Home Assistant.

## Next Steps

Once the workflow is running:
1. Check the output of the "Generate Report" node
2. You should see your power consumption data
3. Add notification nodes (Email, Telegram, etc.)
4. Activate the workflow for daily reports
