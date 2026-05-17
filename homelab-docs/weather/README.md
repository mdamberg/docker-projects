# Weather Stack

## Overview

A Flask-based weather service that fetches real-time weather data from OpenWeatherMap and exposes it via both a web UI and a JSON API endpoint consumed by an iOS Scriptable widget.

## Services

| Service | Port | Container | Purpose |
|---------|------|-----------|---------|
| weather_api | 5000 | `weather_api` | Flask app — web UI + JSON API |

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET, POST | Web UI — current conditions for a city |
| `/api/widget` | GET | JSON — current conditions + 5-day forecast + UV index |

### `/api/widget` query parameters

| Param | Default | Example |
|-------|---------|---------|
| `city` | `Somerset,WI,US` | `Minneapolis,MN,US` |

### `/api/widget` response shape

```json
{
  "city": "Somerset",
  "country": "US",
  "current": {
    "temp": 72,
    "feels_like": 70,
    "temp_high": 78,
    "temp_low": 58,
    "description": "Partly Cloudy",
    "icon": "02d",
    "humidity": 55,
    "wind_speed": 8,
    "wind_dir": "SW",
    "uv_index": 5.2
  },
  "forecast": [
    { "date": "Tue", "temp_high": 80, "temp_low": 60, "description": "Sunny", "icon": "01d", "pop": 0 }
  ],
  "updated": "2026-05-17T14:30:00"
}
```

`uv_index` may be `null` if the OpenWeatherMap `/uvi` endpoint is unavailable.

## Scriptable Widget (iOS)

The widget source lives at `docker-projects/weather_api_project/scriptable/weather_widget.js`.

See `docker-projects/weather_api_project/scriptable/README.md` for full setup instructions. In brief:

1. Edit `LAN_URL` and `TAILSCALE_URL` constants in the script
2. Paste into a new Scriptable script on your iPhone
3. Add a **Large** Scriptable widget to your home screen and select the script

The widget tries the LAN URL first (home Wi-Fi) and falls back to Tailscale automatically.

## Data Sources

- **API**: OpenWeatherMap free tier
- **Current weather**: `/data/2.5/weather`
- **Forecast (5-day)**: `/data/2.5/forecast`
- **UV index**: `/data/2.5/uvi` (deprecated endpoint; graceful null fallback)

## Compose

```
docker-projects/weather_api_project/docker-compose.yml
```

```powershell
cd docker-projects/weather_api_project
docker compose up -d --build
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `WEATHER_API_KEY` | Yes | OpenWeatherMap API key |

## Upgrade Path

To enable a true 7-day forecast and more reliable UV data, sign up for OpenWeatherMap One Call API 3.0 (free up to 1,000 calls/day, requires a credit card on file). The `/api/widget` endpoint can then be simplified to a single API call.
