# Project: Scriptable iOS Weather Widget

**Created:** 2026-05-17
**Type:** docker
**Intent:** improve
**Status:** Planning

## Discovery Summary

The user wants to build an iOS Scriptable widget backed by their existing `weather_api_project` Flask container. The widget should display today's high/low temperature, a multi-day forecast outlook, and UV index. The container already fetches current conditions from OpenWeatherMap, but currently only renders HTML — there is no JSON API endpoint for external consumers like Scriptable to call.

The widget needs to reach the container from an iPhone. The desired connectivity model is: try the local network IP first, fall back to Tailscale if the home network is unavailable. The user is on the OpenWeatherMap free basic tier, which limits the forecast horizon to 5 days (the 8-day outlook requires One Call API 3.0). UV index will be attempted via the deprecated-but-still-functional `/data/2.5/uvi` free endpoint and will degrade gracefully if unavailable.

## Codebase Review

### Files Reviewed

- `docker-projects/weather_api_project/weather.py` — Flask app, single `/` route, renders HTML via Jinja2; calls `/data/2.5/weather`
- `docker-projects/weather_api_project/docker-compose.yml` — Runs on port 5000, reads `WEATHER_API_KEY` from env
- `docker-projects/weather_api_project/templates/index.html` — Full HTML web UI (ribbon style)
- `docker-projects/weather_api_project/readme.md` — Setup instructions
- `docker-projects/weather_app/weather.py` — Standalone CLI script using wttr.in, no Docker compose, not relevant

### Current API Endpoints

| Endpoint | Method | Returns |
|----------|--------|---------|
| `/` | GET, POST | HTML page (current weather only) |
| *(none)* | — | No JSON endpoints exist |

### OpenWeatherMap Endpoints Available (Free Tier)

| Endpoint | Data | Notes |
|----------|------|-------|
| `/data/2.5/weather` | Current conditions, lat/lon | Already used |
| `/data/2.5/forecast` | 5-day / 3-hour intervals (40 entries) | Aggregate to daily for H/L |
| `/data/2.5/uvi` | UV index at lat/lon | Deprecated but functional; graceful fallback |

## Analysis Findings

### Issues Found

| # | Severity | Issue | Location |
|---|----------|-------|----------|
| 1 | High | No JSON API endpoint — Scriptable cannot consume HTML | `weather.py` |
| 2 | Medium | Forecast data not fetched — only current weather | `weather.py` |
| 3 | Medium | UV index not fetched at all | `weather.py` |
| 4 | Low | `temp_min`/`temp_max` from `/data/2.5/weather` are city-wide, not true daily H/L | `weather.py:57-58` |

### Key Constraints

- Free tier gives **5 days** of forecast data, not 7. Widget will show 5-day outlook. Upgrade path to 7-day is One Call API 3.0.
- UV index endpoint requires `lat`/`lon`, obtained from the current weather call.
- Connectivity: Scriptable widget must handle dual-URL fallback (LAN → Tailscale).

## Scope & Goals

**Goals:**
- [ ] Add `/api/widget` JSON endpoint to the Flask app returning all data the widget needs
- [ ] Fetch and aggregate 5-day forecast into daily summaries (H/L, description, icon)
- [ ] Fetch UV index with graceful fallback if endpoint returns an error
- [ ] Create a Scriptable large widget JavaScript file with LAN→Tailscale fallback

**Success Criteria:**
- [ ] `GET /api/widget?city=Somerset,WI,US` returns valid JSON on the container
- [ ] JSON includes: current temp, today H/L, 5-day forecast array, UV index
- [ ] Scriptable widget renders on iPhone without errors in both WiFi and Tailscale scenarios
- [ ] Widget shows: current conditions, today H/L, UV index, 5-day forecast row

**Out of Scope:**
- Modifying the existing HTML web UI
- 7-day forecast (requires paid One Call API 3.0 — noted as upgrade path)
- Push notifications or background refresh beyond Scriptable's native scheduling
- Weather alerts

## Technical Approach

### Overview

Add a single new route `/api/widget` to the existing Flask app. It makes three parallel-ish sequential calls to OpenWeatherMap (current → UV → forecast), aggregates the results, and returns JSON. A separate Scriptable `.js` file is committed to the repo for easy copying to the iPhone.

### API Data Flow

```
Scriptable widget
  ↓ GET /api/widget?city=<city>
Flask /api/widget
  ├── GET /data/2.5/weather  → current conditions + lat/lon
  ├── GET /data/2.5/uvi      → UV index (uses lat/lon from above)
  └── GET /data/2.5/forecast → 5-day / 3-hour data → aggregate to daily
  ↓ JSON response
Scriptable renders widget
```

### Connectivity in Scriptable Widget

```
Try: http://<LAN_IP>:5000/api/widget  (timeout: 3s)
Fail → Try: http://<TAILSCALE_IP>:5000/api/widget
Fail → Show "offline" state in widget
```

Both IPs are configurable constants at the top of the `.js` file.

### Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| New endpoint vs. modifying `/` | New `/api/widget` route | Keeps HTML UI intact; clean separation |
| Forecast aggregation | Server-side in Flask | Keeps widget JS simple; less data over network |
| UV on free tier | `/data/2.5/uvi` with fallback | Avoids requiring One Call API 3.0 upgrade |
| Widget size | Large | Fits 5-day forecast grid comfortably |
| Config approach | Constants at top of `.js` | Simple; no external config service needed |

### JSON Response Shape

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
    {
      "date": "Mon",
      "temp_high": 78,
      "temp_low": 58,
      "description": "Partly Cloudy",
      "icon": "02d",
      "pop": 10
    },
    ...
  ],
  "updated": "2026-05-17T14:30:00"
}
```

## Proposed Changes

### Files to Create

- `docker-projects/weather_api_project/scriptable/weather_widget.js` — Scriptable widget source
- `docker-projects/weather_api_project/scriptable/README.md` — Setup instructions for copying to iPhone

### Files to Modify

- `docker-projects/weather_api_project/weather.py`
  - Add `from flask import jsonify`
  - Add helper `_aggregate_forecast(forecast_list)` to convert 3-hour intervals → daily summaries
  - Add helper `_get_uv_index(lat, lon, api_key)` with try/except returning `None` on failure
  - Add route `/api/widget` that orchestrates the three API calls and returns JSON

### Code Preview

**New `/api/widget` route (weather.py):**

```python
@app.route('/api/widget', methods=['GET'])
def widget():
    city = request.args.get('city', 'Somerset,WI,US')
    API_KEY = os.getenv('WEATHER_API_KEY')

    if not API_KEY:
        return jsonify({'error': 'API key not configured'}), 500

    # Current conditions + coordinates
    current_resp = requests.get(
        'http://api.openweathermap.org/data/2.5/weather',
        params={'q': city, 'appid': API_KEY, 'units': 'imperial'},
        timeout=10
    )
    if current_resp.status_code != 200:
        return jsonify({'error': 'City not found'}), 404
    current = current_resp.json()
    lat = current['coord']['lat']
    lon = current['coord']['lon']

    # UV index (graceful fallback)
    uv = _get_uv_index(lat, lon, API_KEY)

    # 5-day forecast
    forecast_resp = requests.get(
        'http://api.openweathermap.org/data/2.5/forecast',
        params={'q': city, 'appid': API_KEY, 'units': 'imperial', 'cnt': 40},
        timeout=10
    )
    daily_forecast = _aggregate_forecast(forecast_resp.json()['list'])

    # Build today's true H/L from forecast day 0
    today = daily_forecast[0] if daily_forecast else {}

    return jsonify({
        'city': current['name'],
        'country': current['sys']['country'],
        'current': {
            'temp': round(current['main']['temp']),
            'feels_like': round(current['main']['feels_like']),
            'temp_high': today.get('temp_high', round(current['main']['temp_max'])),
            'temp_low': today.get('temp_low', round(current['main']['temp_min'])),
            'description': current['weather'][0]['description'].title(),
            'icon': current['weather'][0]['icon'],
            'humidity': current['main']['humidity'],
            'wind_speed': round(current['wind']['speed']),
            'wind_dir': _wind_direction(current['wind'].get('deg', 0)),
            'uv_index': uv
        },
        'forecast': daily_forecast[1:6],  # next 5 days excluding today
        'updated': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S')
    })
```

**Forecast aggregation helper:**

```python
def _aggregate_forecast(entries):
    from collections import defaultdict
    days = defaultdict(lambda: {'highs': [], 'lows': [], 'icons': [], 'descs': [], 'pops': []})

    for entry in entries:
        day = datetime.utcfromtimestamp(entry['dt']).strftime('%a')
        days[day]['highs'].append(entry['main']['temp_max'])
        days[day]['lows'].append(entry['main']['temp_min'])
        days[day]['icons'].append(entry['weather'][0]['icon'])
        days[day]['descs'].append(entry['weather'][0]['description'].title())
        days[day]['pops'].append(round(entry.get('pop', 0) * 100))

    result = []
    for day, data in days.items():
        result.append({
            'date': day,
            'temp_high': round(max(data['highs'])),
            'temp_low': round(min(data['lows'])),
            'description': data['descs'][len(data['descs']) // 2],
            'icon': data['icons'][len(data['icons']) // 2],
            'pop': round(sum(data['pops']) / len(data['pops']))
        })
    return result
```

**UV helper:**

```python
def _get_uv_index(lat, lon, api_key):
    try:
        resp = requests.get(
            'http://api.openweathermap.org/data/2.5/uvi',
            params={'lat': lat, 'lon': lon, 'appid': api_key},
            timeout=5
        )
        if resp.status_code == 200:
            return resp.json().get('value')
    except Exception:
        pass
    return None
```

## Task Breakdown

### Phase 1: Flask API Endpoint

1. [ ] Add `_wind_direction()` helper (extract from existing route code)
2. [ ] Add `_get_uv_index()` helper
3. [ ] Add `_aggregate_forecast()` helper
4. [ ] Add `/api/widget` route
5. [ ] Add `jsonify` to Flask imports
6. [ ] Test endpoint locally: `curl http://localhost:5000/api/widget?city=Somerset,WI,US`

### Phase 2: Scriptable Widget

1. [ ] Create `scriptable/` directory under `weather_api_project/`
2. [ ] Write `weather_widget.js` with:
   - Configurable `LAN_URL` and `TAILSCALE_URL` constants
   - LAN → Tailscale fallback fetch with 3s timeout
   - Large widget layout: header (city + updated), current conditions row, UV badge, 5-day forecast grid
3. [ ] Write `scriptable/README.md` with iPhone setup steps

### Phase 3: Docs Update

1. [ ] Update `homelab-docs/SUMMARY.md` if a new entry is needed
2. [ ] Update services table in `CLAUDE.md` if port or service name changes (port 5000 stays the same)

## Verification Steps

1. Container rebuilt: `docker compose up -d --build` in `weather_api_project/`
2. Endpoint test: `curl "http://localhost:5000/api/widget?city=Somerset,WI,US"` returns valid JSON
3. JSON includes `forecast` array with 5 entries, `current.uv_index` field (may be null), `current.temp_high`/`temp_low`
4. Copy `weather_widget.js` to Scriptable on iPhone, set `LAN_URL` and `TAILSCALE_URL`, add widget to home screen
5. Widget renders on home Wi-Fi
6. Widget falls back gracefully when on cellular (Tailscale path)

## Upgrade Path (Future)

To get a true 7-day forecast and more reliable UV data:
- Sign up for OpenWeatherMap One Call API 3.0 (free up to 1,000 calls/day, requires credit card)
- Replace the three separate API calls with a single `/data/3.0/onecall` call
- Update `_aggregate_forecast()` to use the `daily` array directly (already pre-aggregated)
