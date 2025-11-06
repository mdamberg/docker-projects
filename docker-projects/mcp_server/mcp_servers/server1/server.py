import asyncio
import json
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent
import docker

# Initialize server
app = Server("docker-manager")

# Initialize Docker client with timeout and error handling
try:
    docker_client = docker.DockerClient(base_url='unix://var/run/docker.sock', timeout=120)
    # Test connection
    docker_client.ping()
    print("Docker client connected successfully")
except Exception as e:
    print(f"Warning: Could not connect to Docker: {e}")
    docker_client = None

@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="list_containers",
            description="List all Docker containers with their status",
            inputSchema={
                "type": "object",
                "properties": {
                    "all": {
                        "type": "boolean",
                        "description": "Show all containers (default shows only running)",
                        "default": False
                    }
                }
            }
        ),
        Tool(
            name="get_container_logs",
            description="Get logs from a specific container",
            inputSchema={
                "type": "object",
                "properties": {
                    "container_name": {
                        "type": "string",
                        "description": "Name of the container"
                    },
                    "tail": {
                        "type": "integer",
                        "description": "Number of lines to show from the end",
                        "default": 50
                    }
                },
                "required": ["container_name"]
            }
        ),
        Tool(
            name="container_stats",
            description="Get resource usage stats for a container",
            inputSchema={
                "type": "object",
                "properties": {
                    "container_name": {
                        "type": "string",
                        "description": "Name of the container"
                    }
                },
                "required": ["container_name"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    # Check if Docker client is connected
    if docker_client is None:
        return [TextContent(
            type="text",
            text="Error: Docker client not connected. Check Docker socket mount."
        )]
    
    try:
        if name == "list_containers":
            show_all = arguments.get("all", False)
            containers = docker_client.containers.list(all=show_all)
            
            result = []
            for container in containers:
                result.append({
                    "name": container.name,
                    "status": container.status,
                    "image": container.image.tags[0] if container.image.tags else "unknown",
                    "id": container.short_id
                })
            
            return [TextContent(
                type="text",
                text=json.dumps(result, indent=2)
            )]
        
        elif name == "get_container_logs":
            container_name = arguments["container_name"]
            tail = arguments.get("tail", 50)
            
            container = docker_client.containers.get(container_name)
            logs = container.logs(tail=tail).decode('utf-8')
            
            return [TextContent(
                type="text",
                text=f"Logs for {container_name}:\n\n{logs}"
            )]
        
        elif name == "container_stats":
            container_name = arguments["container_name"]
            container = docker_client.containers.get(container_name)
            stats = container.stats(stream=False)
            
            memory_stats = stats.get('memory_stats', {})
            
            result = {
                "name": container_name,
                "status": container.status,
                "memory_usage_mb": round(memory_stats.get('usage', 0) / (1024 * 1024), 2),
                "memory_limit_mb": round(memory_stats.get('limit', 0) / (1024 * 1024), 2)
            }
            
            return [TextContent(
                type="text",
                text=json.dumps(result, indent=2)
            )]
        
        raise ValueError(f"Unknown tool: {name}")
    
    except Exception as e:
        return [TextContent(
            type="text",
            text=f"Error: {str(e)}"
        )]

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(
            read_stream,
            write_stream,
            app.create_initialization_options()
        )

if __name__ == "__main__":
    asyncio.run(main())