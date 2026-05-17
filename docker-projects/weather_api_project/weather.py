from flask import Flask, render_template, request, jsonify
import requests
import os
from datetime import datetime
from collections import defaultdict

app = Flask(__name__)


def _wind_direction(deg):
    directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                  'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW']
    return directions[round(deg / 22.5) % 16]


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


def _aggregate_forecast(entries):
    """Convert 3-hour forecast entries into daily high/low summaries."""
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
        mid = len(data['icons']) // 2
        result.append({
            'date': day,
            'temp_high': round(max(data['highs'])),
            'temp_low': round(min(data['lows'])),
            'description': data['descs'][mid],
            'icon': data['icons'][mid],
            'pop': round(sum(data['pops']) / len(data['pops']))
        })
    return result


@app.route('/', methods=['GET', 'POST'])
def index():
    weather_data = None
    error = None
    city = None

    if request.method == 'GET':
        city = 'Somerset,WI,US'
    elif request.method == 'POST':
        city = request.form.get('city')

    API_KEY = os.getenv('WEATHER_API_KEY')

    if not API_KEY:
        error = "⚠️ API Key not found! Set WEATHER_API_KEY environment variable."
    elif city:
        url = "http://api.openweathermap.org/data/2.5/weather"
        params = {
            'q': city,
            'appid': API_KEY,
            'units': 'imperial'
        }

        try:
            response = requests.get(url, params=params)

            if response.status_code == 200:
                data = response.json()

                timezone_offset = data.get('timezone', 0)
                sunrise_ts = data['sys']['sunrise'] + timezone_offset
                sunset_ts = data['sys']['sunset'] + timezone_offset
                sunrise = datetime.utcfromtimestamp(sunrise_ts).strftime('%I:%M %p')
                sunset = datetime.utcfromtimestamp(sunset_ts).strftime('%I:%M %p')

                wind_dir = _wind_direction(data['wind'].get('deg', 0))

                weather_data = {
                    'city': data['name'],
                    'country': data['sys']['country'],
                    'temperature': round(data['main']['temp']),
                    'feels_like': round(data['main']['feels_like']),
                    'temp_min': round(data['main']['temp_min']),
                    'temp_max': round(data['main']['temp_max']),
                    'description': data['weather'][0]['description'].title(),
                    'icon': data['weather'][0]['icon'],
                    'humidity': data['main']['humidity'],
                    'pressure': data['main']['pressure'],
                    'visibility': round(data.get('visibility', 0) / 1609.34, 1),
                    'wind_speed': round(data['wind']['speed']),
                    'wind_dir': wind_dir,
                    'wind_gust': round(data['wind'].get('gust', 0)),
                    'clouds': data['clouds']['all'],
                    'sunrise': sunrise,
                    'sunset': sunset,
                    'rain_1h': data.get('rain', {}).get('1h', 0),
                    'snow_1h': data.get('snow', {}).get('1h', 0)
                }
            else:
                error = f"❌ City not found or API error (Status: {response.status_code})"

        except requests.exceptions.RequestException as e:
            error = f"❌ Network error: {str(e)}"
    else:
        error = "⚠️ Please enter a city name"

    return render_template('index.html', weather=weather_data, error=error, city=city)


@app.route('/api/widget', methods=['GET'])
def widget():
    city = request.args.get('city', 'Somerset,WI,US')
    API_KEY = os.getenv('WEATHER_API_KEY')

    if not API_KEY:
        return jsonify({'error': 'API key not configured'}), 500

    try:
        current_resp = requests.get(
            'http://api.openweathermap.org/data/2.5/weather',
            params={'q': city, 'appid': API_KEY, 'units': 'imperial'},
            timeout=10
        )
    except requests.exceptions.RequestException as e:
        return jsonify({'error': f'Network error: {str(e)}'}), 503

    if current_resp.status_code != 200:
        return jsonify({'error': 'City not found or API error'}), 404

    current = current_resp.json()
    lat = current['coord']['lat']
    lon = current['coord']['lon']

    uv = _get_uv_index(lat, lon, API_KEY)

    try:
        forecast_resp = requests.get(
            'http://api.openweathermap.org/data/2.5/forecast',
            params={'q': city, 'appid': API_KEY, 'units': 'imperial', 'cnt': 40},
            timeout=10
        )
        daily = _aggregate_forecast(forecast_resp.json()['list'])
    except Exception:
        daily = []

    # Use today's aggregated H/L when available; fall back to current weather min/max
    today = daily[0] if daily else {}

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
        'forecast': daily[1:6],
        'updated': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S')
    })


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
