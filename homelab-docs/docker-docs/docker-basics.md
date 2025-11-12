# Docker Basics

This document serves as an overview of Docker fundamentals and common usage patterns.

---

## Overview

Docker is an **open-source platform** that allows you to package and run applications in **isolated environments** called **containers**.  
Each container includes everything the application needs to run—its code, runtime, system tools, libraries, and settings—ensuring consistent behavior across environments.

---

## Key Concepts

### 🧱 Docker Images
- **Definition:** Templates used to create containers.
- **Characteristics:**
  - Read-only, versioned blueprints containing application code, configurations, and dependencies.
  - Built from a `Dockerfile`.
- **Example:**  
  A `python:3.10` image provides a pre-configured environment with Python installed.

---

### 📦 Docker Containers
- **Definition:** Running instances of Docker images.
- **Key idea:** An image is like a class; a container is like an object instantiated from that class.
- **Usage:**  
  Each container runs its own isolated process but shares the host OS kernel for efficiency.

---

### 🧰 Dockerfile
- **Purpose:** Text file containing step-by-step build instructions for an image.
- **Common sections:**
  - `FROM` — base image (e.g., Ubuntu, Alpine, Python)
  - `RUN` — commands to install software or dependencies
  - `COPY` / `ADD` — include local files in the image
  - `EXPOSE` — declare ports the container will use
  - `ENV` — set environment variables
  - `CMD` / `ENTRYPOINT` — define the command to run at container start
- **Example:**
  ```Dockerfile
  FROM python:3.10-slim
  WORKDIR /app
  COPY requirements.txt .
  RUN pip install -r requirements.txt
  COPY . .
  CMD ["python", "app.py"]


# Docker Daemon
- **Definition:** Background service (dockerd) that manages Docked objects (images, containers, volumes and networks)
- **Interactions:** Users communicate with it via the Docker CLI (docker) or API 


# Docker Compose
- **Purpose:** Simplifies multi-container environments.
- **File:** ***docker-compose.yml***  
- **Usage:** Defines and runs MULTIPLE containers together with one command
    - This of this as the director of an orchestraw

# Common Sections:
- **services:** — defines containers
- **image: / build:** — specify how the image is obtained
- **environment:** — pass variables into containers
- **volumes:** — map storage between host and container
- **ports:** — publish container ports to the host
- **depends_on:** — set startup order

# Environment Variables (.env)
- **Purpose:** Provide dynamic configuration values (eg. credentials, API keys, ports).
- **Usage:**
    - Declared in a .env file or passed inline.
    - Prevents sensitive values from being hard-coded into compose or image )

# Networks
- **Purpose:** Control how containers communicate with each other and the outside world.
- **Types:**
    - **Bridge(default):** isolates containers but allows communications through exposed ports.
    - **Host:** container share host network (no isolation).
    - **none:** no network access
    - **Custom:** user defined network for controlled inter-container communication.

# Volumes
- **Purposes:** Persist and share data between containers or between containers and the host
- **Types:**
    - **Names Volumnes:** managed by Docker
    - **Bind Mounts:** maps a specific host directory.
- **Example:**
    - volumes:
        - C:\media\config\plex:/config
        - D:\downloads:/downloads

# Dependencies
- **Definition:** Containers often rely on others (eg an app container needs a db container)
- ***depends_on:*** in docker_compose.yml defines starup order but no readiness
- Uses healthchecks if one service must wait for another to be *ready* 

# How Docker Works
1). You write a Dockerfile defining your app’s environment and dependencies.
2). You build it into an image (docker build -t myapp .).
3). Docker runs the image as a container (docker run myapp).
4). Optionally, multiple services are orchestrated together via Docker Compose.
5).Volumes store persistent data, networks connect services, and the daemon manages everything in the background.
