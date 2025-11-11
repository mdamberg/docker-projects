# Common Docker Commands


docker ps                   # List running containers
docker logs <container>     # View container logs
docker exec -it <name> sh   # Open a shell in a container
docker inspect <name>       # Get detailed container info
docker compose up -d        # Start all services in background
docker compose down         # Stop and remove containers/networks
docker system prune -a      # Remove unused images and containers
