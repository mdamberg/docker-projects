@echo off
echo Creating shared network for Home Automation services...

REM Create a shared network
docker network create home-automation

REM Connect both containers
echo Connecting Home Assistant to shared network...
docker network connect home-automation homeassistant

echo Connecting n8n to shared network...
docker network connect home-automation n8n

echo.
echo Done! Containers are now on the same network.
echo.
echo You can now use this URL in n8n workflows:
echo http://homeassistant:8123/api/states
echo.
echo Press any key to exit...
pause > nul
