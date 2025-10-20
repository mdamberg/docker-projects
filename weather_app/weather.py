import requests 

city = input("Enter City Name: ")

# free weather api (no key required)
url = f"https://wttr.in/{city}?format=3"

response = requests.get(url)

if response.status_code == 200:
    print(response.text)
else:
    print("Could not fetch weather data!")