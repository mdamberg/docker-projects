# Scriptable Weather Widget — Setup Guide

## Prerequisites

- [Scriptable](https://apps.apple.com/us/app/scriptable/id1405459188) installed on your iPhone
- Weather container running (`docker compose up -d` in `weather_api_project/`)

## Step 1 — Find your IPs

**Local network IP** (for home Wi-Fi):

```powershell
ipconfig  # look for your PC's IPv4 address, e.g. 192.168.1.100
```

**Tailscale IP** (for anywhere access):

Open the Tailscale app on your phone or check the Tailscale admin panel. It looks like `100.X.X.X`.

## Step 2 — Edit the script

Open `weather_widget.js` and update the two lines at the top:

```js
const LAN_URL       = "http://192.168.1.100:5000/api/widget";  // your PC's local IP
const TAILSCALE_URL = "http://100.X.X.X:5000/api/widget";      // your Tailscale IP
```

If you only want home Wi-Fi support, set `TAILSCALE_URL` to the same as `LAN_URL`.

## Step 3 — Add to Scriptable

1. Open Scriptable on your iPhone
2. Tap **+** to create a new script
3. Paste the full contents of `weather_widget.js`
4. Tap the script title and rename it to **Weather Widget**
5. Tap the play button to test — it should present a large widget preview

## Step 4 — Add to Home Screen

1. Long-press your home screen → tap **+** (Add Widget)
2. Search for **Scriptable**
3. Choose the **Large** size and tap **Add Widget**
4. Long-press the new widget → **Edit Widget**
5. Set **Script** → `Weather Widget`
6. Leave **When Interacting** as default
7. (Optional) Set **Parameter** to a different city, e.g. `Minneapolis,MN,US`

## Changing the city

The widget defaults to `Somerset,WI,US`. To use a different city:

- **Per-widget**: Set the widget's **Parameter** field in the Scriptable widget editor
- **Global default**: Change `DEFAULT_CITY` at the top of the script

City format: `CityName,StateCode,CountryCode` — e.g. `Chicago,IL,US`

## Refresh rate

iOS controls widget refresh. Scriptable widgets typically update every 15–60 minutes depending on system conditions. You cannot force more frequent updates from within the script.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| "Weather Unavailable" | Verify the container is running and both IPs are correct |
| UV shows "N/A" | The OpenWeatherMap `/uvi` endpoint is deprecated; it will be null until you upgrade to One Call API 3.0 |
| Forecast is empty | Check `docker logs weather_api` for errors on the `/data/2.5/forecast` call |
| Widget won't load on cellular | Confirm Tailscale is active on your phone and the Tailscale IP is correct |
