from mcp import Server
import mcp.types as types
import os
import json
from pathlib import Path

server = Server("filesystem-manager")

@server.list_tools()
async def list_tools() -> list[types.Tool]:
    return [
        types.Tool(
            name="list_directory",
            description="List contents of a directory",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Directory path to list",
                        "default": "/host"
                    }
                }
            }
        ),
        types.Tool(
            name="get_disk_usage",
            description="Get disk usage information for a path",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path to check disk usage",
                        "default": "/host"
                    }
                }
            }
        ),
        types.Tool(
            name="file_info",
            description="Get detailed information about a file",
            inputSchema={
                "type": "object",
                "properties": {
                    "filepath": {
                        "type": "string",
                        "description": "Path to the file"
                    }
                },
                "required": ["filepath"]
            }
        )
    ]

@server.call_tool()
async def call_tool(name: str, arguments: dict) -> list[types.TextContent]:
    try:
        if name == "list_directory":
            dir_path = arguments.get("path", "/host")
            
            if not os.path.exists(dir_path):
                return [types.TextContent(
                    type="text",
                    text=f"Error: Directory {dir_path} does not exist"
                )]
            
            items = []
            for item in os.listdir(dir_path):
                full_path = os.path.join(dir_path, item)
                is_dir = os.path.isdir(full_path)
                size = os.path.getsize(full_path) if not is_dir else 0
                
                items.append({
                    "name": item,
                    "type": "directory" if is_dir else "file",
                    "size_bytes": size
                })
            
            return [types.TextContent(
                type="text",
                text=json.dumps(items, indent=2)
            )]
        
        elif name == "get_disk_usage":
            path = arguments.get("path", "/host")
            
            stat = os.statvfs(path)
            total = stat.f_blocks * stat.f_frsize
            free = stat.f_bfree * stat.f_frsize
            used = total - free
            
            result = {
                "path": path,
                "total_gb": total / (1024**3),
                "used_gb": used / (1024**3),
                "free_gb": free / (1024**3),
                "percent_used": (used / total) * 100
            }
            
            return [types.TextContent(
                type="text",
                text=json.dumps(result, indent=2)
            )]
        
        elif name == "file_info":
            filepath = arguments["filepath"]
            
            if not os.path.exists(filepath):
                return [types.TextContent(
                    type="text",
                    text=f"Error: File {filepath} does not exist"
                )]
            
            stat = os.stat(filepath)
            result = {
                "path": filepath,
                "size_bytes": stat.st_size,
                "size_mb": stat.st_size / (1024**2),
                "is_file": os.path.isfile(filepath),
                "is_directory": os.path.isdir(filepath),
                "modified_time": stat.st_mtime
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
    print("Starting Filesystem Manager MCP Server on port 8000...")
    server.run(transport="sse", port=8000)