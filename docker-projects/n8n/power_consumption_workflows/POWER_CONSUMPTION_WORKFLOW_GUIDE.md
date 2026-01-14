# Home Assistant Power Consumption Report - n8n Workflow Guide

## Overview
This workflow will:
1. Connect to your Home Assistant instance
2. Fetch power consumption data from all tracked devices
3. Calculate total power consumption
4. Generate a formatted report
5. Send the report via your preferred notification method (email, webhook, etc.)

## Prerequisites

### 1. Home Assistant Long-Lived Access Token
You need to create a long-lived access token in Home Assistant:

1. Open Home Assistant (http://localhost:8123)
2. Click on your profile (bottom left)
3. Scroll down to "Long-Lived Access Tokens"
4. Click "Create Token"
5. Give it a name like "n8n Integration"
6. Copy the token (you won't be able to see it again!)

### 2. Identify Your Power Monitoring Devices
In Home Assistant, go to Developer Tools > States and look for entities with:
- `sensor.*_power` (current power usage in W)
- `sensor.*_energy` (cumulative energy in kWh)

Common examples:
- `sensor.living_room_power`
- `sensor.bedroom_energy`
- `sensor.kitchen_outlet_power`

## Workflow Setup in n8n

### Step 1: Access n8n
Open n8n at http://localhost:5678

### Step 2: Create Credentials for Home Assistant

1. In n8n, go to Credentials menu
2. Click "Create New Credential"
3. Select "Home Assistant"
4. Fill in:
   - **Host**: `http://homeassistant:8123` (if both containers are on same Docker network) OR `http://192.168.x.x:8123` (your actual IP)
   - **Access Token**: Paste the long-lived token you created
5. Test the connection and save

### Step 3: Import the Workflow

You can either:
- **Option A**: Import the provided workflow JSON file (`power_consumption_workflow.json`)
- **Option B**: Create manually following the structure below

## Workflow Structure

### Manual Creation Steps:

1. **Schedule Trigger** (Optional)
   - Trigger the workflow on a schedule (daily, weekly, etc.)
   - Use Cron node: `0 8 * * *` for 8 AM daily

2. **Get All Power Sensors**
   - Node: HTTP Request
   - Method: GET
   - URL: `http://homeassistant:8123/api/states`
   - Headers: `Authorization: Bearer YOUR_TOKEN`
   - This returns all entity states

3. **Filter Power Sensors**
   - Node: Function/Code
   - Filter entities that contain "power" or "energy" in entity_id

4. **Process Each Device**
   - Node: Function/Code
   - Extract device name and current power/energy value
   - Calculate totals

5. **Format Report**
   - Node: Function/Code
   - Create a formatted text or HTML report

6. **Send Notification**
   - Node: Email, Telegram, Webhook, etc.
   - Send the formatted report

## Sample Code for Processing

### Filter Power Sensors (Function Node)
```javascript
// Get all items from previous node
const items = $input.all();

// Filter for power and energy sensors
const powerSensors = items[0].json.filter(entity => {
  const id = entity.entity_id.toLowerCase();
  return (id.includes('power') || id.includes('energy')) &&
         entity.state !== 'unavailable' &&
         entity.state !== 'unknown' &&
         !isNaN(parseFloat(entity.state));
});

return powerSensors.map(sensor => ({
  json: sensor
}));
```

### Calculate and Format Report (Function Node)
```javascript
const items = $input.all();

let totalPower = 0;
let totalEnergy = 0;
const deviceReports = [];

items.forEach(item => {
  const entity = item.json;
  const entityId = entity.entity_id;
  const state = parseFloat(entity.state);
  const unit = entity.attributes.unit_of_measurement || '';

  // Extract friendly name
  const friendlyName = entity.attributes.friendly_name || entityId;

  if (unit.toLowerCase().includes('w')) {
    // Power in Watts
    totalPower += state;
    deviceReports.push({
      device: friendlyName,
      type: 'Power',
      value: state.toFixed(2),
      unit: 'W'
    });
  } else if (unit.toLowerCase().includes('kwh')) {
    // Energy in kWh
    totalEnergy += state;
    deviceReports.push({
      device: friendlyName,
      type: 'Energy',
      value: state.toFixed(2),
      unit: 'kWh'
    });
  }
});

// Create formatted report
const report = {
  timestamp: new Date().toISOString(),
  summary: {
    totalCurrentPower: totalPower.toFixed(2) + ' W',
    totalEnergy: totalEnergy.toFixed(2) + ' kWh',
    deviceCount: deviceReports.length
  },
  devices: deviceReports,
  reportText: generateTextReport(totalPower, totalEnergy, deviceReports)
};

function generateTextReport(power, energy, devices) {
  let text = '=== POWER CONSUMPTION REPORT ===\n\n';
  text += `Generated: ${new Date().toLocaleString()}\n\n`;
  text += `Total Current Power: ${power.toFixed(2)} W\n`;
  text += `Total Energy: ${energy.toFixed(2)} kWh\n`;
  text += `Devices Tracked: ${devices.length}\n\n`;
  text += '--- BY DEVICE ---\n\n';

  devices.forEach(device => {
    text += `${device.device}: ${device.value} ${device.unit}\n`;
  });

  return text;
}

return [{
  json: report
}];
```

## Notification Options

### Email
- Use Gmail/SMTP node
- Subject: "Daily Power Consumption Report"
- Body: `{{ $json.reportText }}`

### Telegram
- Use Telegram node
- Message: `{{ $json.reportText }}`

### Webhook
- Send to your preferred endpoint
- Body: Full JSON report

## Testing

1. Use "Execute Workflow" button in n8n to test
2. Check each node's output
3. Verify data is being fetched correctly
4. Confirm report format meets your needs

## Scheduling

For automated reports:
1. Add a "Schedule Trigger" node at the beginning
2. Set your preferred schedule:
   - Daily: `0 8 * * *` (8 AM)
   - Weekly: `0 8 * * 1` (Monday 8 AM)
   - Monthly: `0 8 1 * *` (1st of month 8 AM)

## Troubleshooting

### Connection Issues
- Verify both containers are on the same Docker network
- Test Home Assistant API manually: `curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8123/api/states`

### No Data Returned
- Check that your power sensors are actually reporting data in Home Assistant
- Verify entity IDs match your devices
- Check Home Assistant logs for any issues

### Empty Report
- Adjust the filter criteria in the Function node
- Check entity naming conventions in your Home Assistant setup

## Next Steps

1. Customize the report format to your preferences
2. Add data visualization (charts, graphs)
3. Store historical data in a database
4. Set up alerts for high consumption
5. Compare consumption over time periods
