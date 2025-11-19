from flask import Flask, render_template, request
import requests
import os

app = Flask(__name__)

@app.route('/', methods=['GET', 'POST'])
def index():
    weather_data = None
    error = None
    city = None
    
    if request.method == 'POST':
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
                    weather_data = {
                        'city': data['name'],
                        'temperature': round(data['main']['temp']),
                        'description': data['weather'][0]['description'].title(),
                        'icon': data['weather'][0]['icon'],
                        'humidity': data['main']['humidity'],
                        'wind_speed': round(data['wind']['speed'])
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