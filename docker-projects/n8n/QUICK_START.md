# Quick Start Guide - Power Consumption Workflow

## Import the Workflow (Easy Method)

1. **Open n8n** at http://localhost:5678

2. **Import the workflow**:
   - Click the menu (☰) in top right
   - Select "Import from File"
   - Choose `power_consumption_workflow.json`
   - Click "Import"

3. **Test the workflow**:
   - Click "Execute Workflow" button (top right)
   - Check each node to see the data flowing through
   - The final "Generate Report" node will show your power consumption report

4. **Activate the workflow**:
   - Toggle the switch at the top to "Active"
   - It will now run daily at 8 AM

## What the Workflow Does

The workflow generates a detailed report showing:
- **Total current power consumption** across all devices (in Watts)
- **Total cumulative energy** used (in kWh)
- **Per-device breakdown** of power and energy
- **Top 5 power consumers** ranked
- **Estimated cost** (based on $0.12/kWh - you can adjust this)

## Output Formats

The workflow generates two formats:
1. **Text Report** (`reportText`) - Great for console/terminal or plain text notifications
2. **HTML Report** (`reportHtml`) - Beautiful formatted HTML for emails

## Adding Notifications

To send the report via email, Telegram, or other methods:

### Option 1: Email
1. Add a new node after "Generate Report"
2. Select "Email" or "Gmail" node
3. Configure your email settings
4. In the message body, use: `{{ $json.reportHtml }}`

### Option 2: Telegram
1. Add a "Telegram" node after "Generate Report"
2. Configure your Telegram bot
3. In the message, use: `{{ $json.reportText }}`

### Option 3: Webhook/API
1. Add an "HTTP Request" node
2. POST to your preferred endpoint
3. Send the full JSON: `{{ $json }}`

## Customization

### Change the Schedule
Edit the first node "Schedule Daily 8 AM":
- Daily at 6 PM: `0 18 * * *`
- Every 12 hours: `0 */12 * * *`
- Weekly on Monday: `0 8 * * 1`
- Hourly: `0 * * * *`

### Change the Cost Rate
Edit the "Generate Report" node and find this line:
```javascript
const estimatedCost = totalEnergyKwh * 0.12;  // Change 0.12 to your rate
```

### Change Home Assistant URL
If your containers aren't on the same Docker network, edit the "Get All HA States" node:
- Change URL from `http://homeassistant:8123/api/states`
- To your HA IP: `http://192.168.1.X:8123/api/states`

## Troubleshooting

### "Cannot connect to Home Assistant"
- Make sure both containers are running: `docker ps`
- Try using your local IP instead of "homeassistant" hostname
- Verify the token is correct

### "No devices found"
The workflow looks for entities with "power", "energy", or "watt" in the name.
Check your Home Assistant entities:
1. Go to http://localhost:8123
2. Developer Tools > States
3. Search for sensors containing these keywords

### "Empty report"
- Ensure your power monitoring devices are reporting valid data
- Check that sensors aren't showing "unavailable" or "unknown"
- Verify sensor states are numeric values

## Network Configuration

If n8n and Home Assistant are on the same Docker network:
- URL: `http://homeassistant:8123/api/states` ✅ (already configured)

If they're NOT on the same network:
1. Find your Home Assistant IP:
   ```bash
   docker inspect homeassistant | grep IPAddress
   ```
2. Use that IP in the workflow URL

## Next Steps

1. ✅ Import and test the workflow
2. 📧 Add your preferred notification method
3. ⏰ Adjust the schedule to your preference
4. 💰 Update the electricity cost rate
5. 🎨 Customize the report format as needed

Enjoy your automated power consumption reports!
