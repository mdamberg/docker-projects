---
name: new-container
description: Step-by-step process for adding a new Docker container to the homelab
---

# New Container Setup

Complete workflow for adding a new Docker container to the homelab, including configuration, secrets handling, startup integration, and health verification.

## When to Use

- Adding a new service to the Docker homelab
- Setting up a container from scratch
- Migrating a service into the Docker environment

## Pre-Setup Questions

Before starting, clarify:
1. What service/image are you deploying?
2. Does it need persistent data? (volumes)
3. Does it need external access? (ports)
4. Does it require secrets? (API keys, passwords)
5. Does it depend on other containers? (networks, depends_on)
6. Should it auto-start with the system?

## Process

### Phase 1: Create Service Directory

1. **Create the service folder**
   ```powershell
   mkdir docker-projects/<service-name>
   cd docker-projects/<service-name>
   ```

2. **Verify location makes sense**
   - Check existing structure in `docker-projects/`
   - Group with similar services if applicable (media, monitoring, etc.)

### Phase 2: Create docker-compose.yml

3. **Create the compose file with required sections**
   ```yaml
   services:
     <service-name>:
       image: <image>:<version>  # Pin version for critical services
       container_name: <service-name>
       restart: unless-stopped
       environment:
         - TZ=America/Chicago
       volumes:
         - ./config:/config  # Or appropriate paths
       ports:
         - "<host-port>:<container-port>"
       networks:
         - default

   networks:
     default:
       driver: bridge
   ```

4. **Follow compose best practices**
   - Use explicit `container_name`
   - Set `restart: unless-stopped`
   - Always set `TZ` environment variable
   - Pin image versions for databases/critical services
   - Use relative paths for local configs (`./config`)
   - Use absolute paths for shared data (`C:/media/...`)

### Phase 3: Handle Secrets and Environment Variables

5. **Create .env file for sensitive values**
   ```powershell
   # Create .env in the service directory
   New-Item -Path .env -ItemType File
   ```

6. **Structure the .env file**
   ```env
   # <service-name> configuration
   SERVICE_API_KEY=your-api-key-here
   SERVICE_PASSWORD=your-password-here
   DB_CONNECTION_STRING=postgres://user:pass@host:port/db
   ```

7. **Reference in docker-compose.yml**
   ```yaml
   environment:
     - API_KEY=${SERVICE_API_KEY}
     - PASSWORD=${SERVICE_PASSWORD}
   ```

8. **Verify .env is gitignored**
   - Check root `.gitignore` includes `**/.env`
   - Never commit secrets to git

### Phase 4: Configure Networking

9. **Determine network requirements**

   | Scenario | Network Config |
   |----------|----------------|
   | Standalone service | Default bridge (no extra config) |
   | Needs to talk to other containers | Add to shared network |
   | Analytics/dbt access | Add to `home-metrics` network |
   | VPN routing needed | Route through Gluetun |

10. **For shared networks**
    ```yaml
    networks:
      home-metrics:
        external: true
    ```

    Create if needed: `docker network create home-metrics`

### Phase 5: Set Up Volumes and Persistence

11. **Create required directories**
    ```powershell
    mkdir config
    mkdir data  # If needed
    ```

12. **Map volumes appropriately**
    ```yaml
    volumes:
      - ./config:/config        # Service config
      - ./data:/data            # Service data
      - C:/media/downloads:/downloads  # Shared media paths
    ```

### Phase 6: Test the Container

13. **Start the container**
    ```powershell
    docker compose up -d
    ```

14. **Verify it's running**
    ```powershell
    docker compose ps
    ```
    - Status should show "Up" or "healthy"

15. **Check logs for errors**
    ```powershell
    docker compose logs -f
    ```
    - Watch for startup errors
    - Verify service is listening on expected port

16. **Test the service**
    - Access via browser: `http://localhost:<port>`
    - Or test API endpoint if applicable

### Phase 7: Debug If Issues Arise

17. **If container won't start**
    ```powershell
    docker compose logs <service-name>
    ```
    - Check for missing env vars
    - Check for port conflicts: `netstat -ano | findstr :<port>`
    - Verify image name/tag is correct

18. **If container starts but service doesn't work**
    - Check internal logs: `docker exec -it <service-name> sh`
    - Verify volume mounts: `docker inspect <service-name>`
    - Check network connectivity: `docker network inspect <network>`

19. **Common issues**

    | Problem | Solution |
    |---------|----------|
    | Port already in use | Change host port in compose |
    | Permission denied on volumes | Check Windows path format (use `/` not `\`) |
    | Can't resolve other containers | Ensure on same network |
    | Env var not loading | Check .env file location (same dir as compose) |

### Phase 8: Add to Startup Script

20. **Edit start-all-services.ps1**
    ```powershell
    # Add to appropriate section in start-all-services.ps1
    cd docker-projects/<service-name>
    docker compose up -d
    ```

21. **Verify startup order**
    - If service depends on others, ensure it starts after dependencies
    - Database containers should start before services that use them

### Phase 9: Document the Service

22. **Update homelab-docs**
    - Add entry to relevant section or create new doc
    - Include: purpose, port, any special configuration

23. **Update CLAUDE.md services table** (if significant service)
    ```markdown
    | <Service> | <port> | <notes> |
    ```

## Checklist

- [ ] Service directory created in logical location
- [ ] docker-compose.yml follows best practices
- [ ] Secrets in .env file (not hardcoded)
- [ ] .env is gitignored
- [ ] Networks configured correctly
- [ ] Volumes/persistence set up
- [ ] Container starts successfully (`docker compose up -d`)
- [ ] Service accessible and functional
- [ ] Added to start-all-services.ps1
- [ ] Documentation updated

## Quick Reference

```powershell
# Full setup sequence
mkdir docker-projects/<service>
cd docker-projects/<service>
# Create docker-compose.yml and .env
docker compose up -d
docker compose ps
docker compose logs -f
# If successful, add to start-all-services.ps1
```
