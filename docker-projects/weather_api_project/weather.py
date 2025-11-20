from flask import Flask, render_template, request
import requests
import os
from datetime import datetime

app = Flask(__name__)

@app.route('/', methods=['GET', 'POST'])
def index():
    weather_data = None
    error = None
    city = None

    # Load default city on GET request (page load)
    if request.method == 'GET':
        city = 'Somerset,WI,US'  # Default city
    elif request.method == 'POST':
        city = request.form.get('city')

    # Get API key from environment variable
    API_KEY = os.getenv('WEATHER_API_KEY')

    if not API_KEY:
        error = "⚠️ API Key not found! Set WEATHER_API_KEY environment variable."
    elif city:
        # Call OpenWeatherMap API
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

                # Convert sunrise/sunset timestamps to readable time
                timezone_offset = data.get('timezone', 0)
                sunrise_ts = data['sys']['sunrise'] + timezone_offset
                sunset_ts = data['sys']['sunset'] + timezone_offset
                sunrise = datetime.utcfromtimestamp(sunrise_ts).strftime('%I:%M %p')
                sunset = datetime.utcfromtimestamp(sunset_ts).strftime('%I:%M %p')

                # Get wind direction as compass
                wind_deg = data['wind'].get('deg', 0)
                directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                             'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW']
                wind_dir = directions[round(wind_deg / 22.5) % 16]

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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)