# Common Docker Commands

**Docker Basics**

**Command**                     **Description**
docker ps                   # List running containers
docker logs <container>     # View container logs
docker exec -it <name> sh   # Open a shell in a container
docker inspect <name>       # Get detailed container info
docker compose up -d        # Start all services in background
docker compose down         # Stop and remove containers/networks
docker system prune -a      # Remove unused images and containers
docker --version	        # Show your Docker version
docker info	                # System-wide info (containers, images, storage drivers, etc.)
docker help	                # Show help for Docker CLI or subcommands (docker run --help)

**Docker Compose Commands**

**Command**                      **Description**
docker compose up	                # Start all services defined in docker-compose.yml
docker compose up -d	            # Same as above, but detached (runs in background)
docker compose down	                # Stop and remove containers, networks, and volumes created by Compose
docker compose ps                   # Show running services in the Compose project
docker compose logs -f	            # View and follow logs from all containers
docker compose restart	            # Restart all services
docker compose build	            # Rebuild images from the Compose file
docker compose pull	                # Pull images defined in Compose
docker compose exec <service> sh	# Run a shell inside a running Compose container

**Images**

**Command**                     **Description**
docker pull nginx	                # Download an image from Docker Hub
docker images	                    # List all images on your system
docker rmi nginx	                # Remove an image
docker build -t myapp .	            # Build an image from a Dockerfile (tags it myapp)
docker tag myapp myrepo/myapp:v1	# Add a new tag for an existing image
docker push myrepo/myapp:v1	        # Push an image to Docker Hub or another registry

**Containers** 

**Command**                     **Description**
docker ps	                        # List running containers
docker ps -a	                    # List all containers (including stopped ones)
docker run hello-world	            # Run a container from the hello-world image
docker stop <id>	                # Stop a running container
docker start <id>	                # Start a stopped container
docker restart <id>	                # Restart a container
docker rm <id>	                    # Remove a stopped container
docker logs <name>	                # Show logs from a container
docker exec -it <name> sh	        # Open an interactive shell inside a running container
docker inspect <name>	            # Show detailed configuration info about a container

**Volumes and Networks**

**Command**                     **Description**
docker volume ls	                # List volumes
docker volume rm <volume>	        # Remove a volume
docker network ls	                # List networks
docker network inspect <network>	# Show network details
docker network prune	            # Remove unused networks

# System Clean Up
docker system df	                # Show how much disk space Docker uses
docker system prune	                # Remove stopped containers and unused images/volumes
docker system prune -a	            # Remove all unused containers, networks, and images
docker builder prune	            # Clear build cache