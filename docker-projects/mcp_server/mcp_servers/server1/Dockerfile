FROM python:3.11-slim

WORKDIR /app

# Install Docker client
RUN apt-get update && \
    apt-get install -y docker.io && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY server.py .

# Set Docker host for Windows
ENV DOCKER_HOST=unix:///var/run/docker.sock

EXPOSE 8000

CMD ["python", "/app/server.py"]