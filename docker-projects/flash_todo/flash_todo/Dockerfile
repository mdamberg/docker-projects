 # Start with Python base
FROM python:3.11-slim        

# Create /app folder, work there
WORKDIR /app                             

# Copy shopping list
COPY requirements.txt .                  

# Install Flask
RUN pip install --no-cache-dir -r requirements.txt 

# Copy Python code
COPY app.py .                            
# Copy HTML files
COPY templates/ templates/

# Document: "I use port 5000"
EXPOSE 5000                  

# When started, run this
CMD ["python", "app.py"]             