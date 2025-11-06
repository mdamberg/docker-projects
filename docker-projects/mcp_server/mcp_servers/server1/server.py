from mcp import Server
import mcp.types as types
import docker
import json

server = Server("docker-manager")

# Initialize Docker client
docker_client = docker.from_env()

@server.list_tools()
async def list_tools() -> list[types.Tool]:
    return [
        types.Tool(
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
        types.Tool(
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
        types.Tool(
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

@server.call_tool()
async def call_tool(name: str, arguments: dict) -> list[types.TextContent]:
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
            
            return [types.TextContent(
                type="text",
                text=json.dumps(result, indent=2)
            )]
        
        elif name == "get_container_logs":
            container_name = arguments["container_name"]
            tail = arguments.get("tail", 50)
            
            container = docker_client.containers.get(container_name)
            logs = container.logs(tail=tail).decode('utf-8')
            
            return [types.TextContent(
                type="text",
                text=f"Logs for {container_name}:\n\n{logs}"
            )]
        
        elif name == "container_stats":
            container_name = arguments["container_name"]
            container = docker_client.containers.get(container_name)
            stats = container.stats(stream=False)
            
            # Extract useful stats
            cpu_stats = stats.get('cpu_stats', {})
            memory_stats = stats.get('memory_stats', {})
            
            result = {
                "name": container_name,
                "status": container.status,
                "memory_usage_mb": memory_stats.get('usage', 0) / (1024 * 1024),
                "memory_limit_mb": memory_stats.get('limit', 0) / (1024 * 1024),
                "cpu_usage": cpu_stats
            }
            
            return [types.TextContent(
                type="text",
                text=json.dumps(result, indent=2)
            )]
        
        raise ValueError(f"Unknown tool: {name}")
    
    except Exception as e:
        return [types.TextContent(
            type="text",
            text=f"Error: {str(e)}"
        )]

if __name__ == "__main__":
    print("Starting Docker Manager MCP Server on port 8000...")
    server.run(transport="sse", port=8000)