# Weather API Docker Project 🌤️
A Flask web application that displays real-time weather data using the OpenWeatherMap API, containerized with Docker.


# Project Structure
weather_api_project/
├── templates/
│   └── index.html          # Web interface (purple gradient design)
├── app.py                   # Flask application
├── requirements.txt         # Python dependencies
├── Dockerfile              # Docker configuration
├── .env.example            # Template for environment variables
├── .env                    # Your API key (create this, NOT committed to Git)
└── .gitignore             # Protects your secrets

# Set up Instructions
1. **Get Your API Key**

Go to OpenWeatherMap
Sign up for a free account
Navigate to API Keys section
Copy your API key

Note: Free tier allows 1,000 calls/day - plenty for learning!
2. **Create Your .env File**
Copy the example and add your real API key:
***cp .env.example .env***
Edit .env file and add actual key 

3. **Build Docker Image**
- ***Docker build -t weather-api***

4. # Run Container 
- ***docker run -it -p 8080:5000 --env-file .env weather-api

5. **Open Browser**
- *http://locatlhost:8080


Troubleshooting
Port already in use?

# Use a different port
docker run -it -p 9000:5000 --env-file .env weather-api
# Then open: http://localhost:9000

# See Running containers
docker ps

# Stop a Container
docker stop <container_id>

# View Logs
docker -logs <container_id>