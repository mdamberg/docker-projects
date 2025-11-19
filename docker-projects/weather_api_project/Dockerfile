FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir-requirements

COPY weather.py .
COPY templates/ templates

EXPOSE 5000

CMD ["python", "weather.py"]
