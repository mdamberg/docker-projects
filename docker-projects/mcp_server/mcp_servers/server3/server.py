import asyncio
import json
import os
from datetime import datetime
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent
import aiohttp

# Initialize server
app = Server("n8n-manager")

# n8n configuration from environment
N8N_API_URL = os.getenv("N8N_API_URL", "http://10.0.0.7:5678")
N8N_API_KEY = os.getenv("N8N_API_KEY", "")

# Curated list of common n8n node types for workflow building assistance
NODE_TYPES = {
    "triggers": [
        {"name": "n8n-nodes-base.webhook", "description": "Receive HTTP requests to trigger workflow"},
        {"name": "n8n-nodes-base.cron", "description": "Schedule workflow execution on a cron schedule"},
        {"name": "n8n-nodes-base.manualTrigger", "description": "Manually trigger workflow execution"},
        {"name": "n8n-nodes-base.emailTrigger", "description": "Trigger on incoming email"},
        {"name": "n8n-nodes-base.scheduleTrigger", "description": "Schedule workflow at specific times"},
    ],
    "core": [
        {"name": "n8n-nodes-base.httpRequest", "description": "Make HTTP requests to external APIs"},
        {"name": "n8n-nodes-base.code", "description": "Execute custom JavaScript code"},
        {"name": "n8n-nodes-base.function", "description": "Run JavaScript functions on data"},
        {"name": "n8n-nodes-base.set", "description": "Set values on items"},
        {"name": "n8n-nodes-base.if", "description": "Conditional branching based on rules"},
        {"name": "n8n-nodes-base.switch", "description": "Route items based on multiple conditions"},
        {"name": "n8n-nodes-base.merge", "description": "Merge data from multiple branches"},
        {"name": "n8n-nodes-base.splitInBatches", "description": "Process items in batches"},
        {"name": "n8n-nodes-base.wait", "description": "Pause workflow execution"},
        {"name": "n8n-nodes-base.noOp", "description": "No operation - useful for organizing workflows"},
    ],
    "data_transformation": [
        {"name": "n8n-nodes-base.dateTime", "description": "Parse and format dates"},
        {"name": "n8n-nodes-base.crypto", "description": "Cryptographic operations"},
        {"name": "n8n-nodes-base.html", "description": "Extract data from HTML"},
        {"name": "n8n-nodes-base.xml", "description": "Parse and generate XML"},
        {"name": "n8n-nodes-base.markdown", "description": "Convert between Markdown and HTML"},
        {"name": "n8n-nodes-base.spreadsheetFile", "description": "Read/write spreadsheet files"},
        {"name": "n8n-nodes-base.moveBinaryData", "description": "Move binary data between properties"},
    ],
    "communication": [
        {"name": "n8n-nodes-base.emailSend", "description": "Send emails via SMTP"},
        {"name": "n8n-nodes-base.slack", "description": "Send messages to Slack"},
        {"name": "n8n-nodes-base.discord", "description": "Send messages to Discord"},
        {"name": "n8n-nodes-base.telegram", "description": "Send Telegram messages"},
        {"name": "n8n-nodes-base.pushover", "description": "Send push notifications via Pushover"},
    ],
    "databases": [
        {"name": "n8n-nodes-base.postgres", "description": "Query PostgreSQL databases"},
        {"name": "n8n-nodes-base.mysql", "description": "Query MySQL databases"},
        {"name": "n8n-nodes-base.mongodb", "description": "Query MongoDB databases"},
        {"name": "n8n-nodes-base.redis", "description": "Read/write Redis cache"},
    ],
    "files": [
        {"name": "n8n-nodes-base.readBinaryFiles", "description": "Read files from disk"},
        {"name": "n8n-nodes-base.writeBinaryFile", "description": "Write files to disk"},
        {"name": "n8n-nodes-base.ftp", "description": "FTP file operations"},
        {"name": "n8n-nodes-base.ssh", "description": "Execute SSH commands"},
    ],
    "services": [
        {"name": "n8n-nodes-base.googleSheets", "description": "Read/write Google Sheets"},
        {"name": "n8n-nodes-base.notion", "description": "Interact with Notion databases"},
        {"name": "n8n-nodes-base.airtable", "description": "Query Airtable bases"},
        {"name": "n8n-nodes-base.github", "description": "GitHub API operations"},
        {"name": "n8n-nodes-base.homeAssistant", "description": "Control Home Assistant entities"},
    ],
}


async def make_request(method: str, endpoint: str, data: dict = None) -> dict:
    """Make authenticated request to n8n API."""
    url = f"{N8N_API_URL}/api/v1{endpoint}"
    headers = {
        "X-N8N-API-KEY": N8N_API_KEY,
        "Content-Type": "application/json",
    }

    async with aiohttp.ClientSession() as session:
        try:
            if method == "GET":
                async with session.get(url, headers=headers) as response:
                    if response.status == 200:
                        return {"success": True, "data": await response.json()}
                    else:
                        text = await response.text()
                        return {"success": False, "error": f"HTTP {response.status}: {text}"}
            elif method == "POST":
                async with session.post(url, headers=headers, json=data) as response:
                    if response.status in [200, 201]:
                        return {"success": True, "data": await response.json()}
                    else:
                        text = await response.text()
                        return {"success": False, "error": f"HTTP {response.status}: {text}"}
            elif method == "PATCH":
                async with session.patch(url, headers=headers, json=data) as response:
                    if response.status == 200:
                        return {"success": True, "data": await response.json()}
                    else:
                        text = await response.text()
                        return {"success": False, "error": f"HTTP {response.status}: {text}"}
            elif method == "DELETE":
                async with session.delete(url, headers=headers) as response:
                    if response.status in [200, 204]:
                        return {"success": True, "data": {}}
                    else:
                        text = await response.text()
                        return {"success": False, "error": f"HTTP {response.status}: {text}"}
        except aiohttp.ClientError as e:
            return {"success": False, "error": f"Connection error: {str(e)}"}


async def trigger_webhook(webhook_url: str, data: dict = None) -> dict:
    """Trigger a workflow via webhook."""
    async with aiohttp.ClientSession() as session:
        try:
            async with session.post(webhook_url, json=data or {}) as response:
                return {
                    "success": True,
                    "status": response.status,
                    "data": await response.text()
                }
        except aiohttp.ClientError as e:
            return {"success": False, "error": f"Webhook error: {str(e)}"}


@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        # Read Operations
        Tool(
            name="list_workflows",
            description="List all n8n workflows with their status, tags, and metadata",
            inputSchema={
                "type": "object",
                "properties": {
                    "active": {
                        "type": "boolean",
                        "description": "Filter by active status (true=active, false=inactive, omit for all)"
                    },
                    "tags": {
                        "type": "string",
                        "description": "Filter by tag name"
                    }
                }
            }
        ),
        Tool(
            name="get_workflow",
            description="Get full workflow definition including nodes, connections, and settings",
            inputSchema={
                "type": "object",
                "properties": {
                    "workflow_id": {
                        "type": "string",
                        "description": "The workflow ID"
                    }
                },
                "required": ["workflow_id"]
            }
        ),
        Tool(
            name="list_executions",
            description="Get workflow execution history with filtering options",
            inputSchema={
                "type": "object",
                "properties": {
                    "workflow_id": {
                        "type": "string",
                        "description": "Filter by workflow ID"
                    },
                    "status": {
                        "type": "string",
                        "enum": ["error", "success", "waiting"],
                        "description": "Filter by execution status"
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Maximum number of executions to return (default: 20)",
                        "default": 20
                    }
                }
            }
        ),
        Tool(
            name="get_execution",
            description="Get detailed execution data including input/output for each node",
            inputSchema={
                "type": "object",
                "properties": {
                    "execution_id": {
                        "type": "string",
                        "description": "The execution ID"
                    }
                },
                "required": ["execution_id"]
            }
        ),
        Tool(
            name="get_workflow_stats",
            description="Get aggregated statistics for a workflow (success rate, avg duration, recent errors)",
            inputSchema={
                "type": "object",
                "properties": {
                    "workflow_id": {
                        "type": "string",
                        "description": "The workflow ID"
                    },
                    "days": {
                        "type": "integer",
                        "description": "Number of days to analyze (default: 7)",
                        "default": 7
                    }
                },
                "required": ["workflow_id"]
            }
        ),
        Tool(
            name="list_node_types",
            description="Get reference of available n8n nodes organized by category for workflow building",
            inputSchema={
                "type": "object",
                "properties": {
                    "category": {
                        "type": "string",
                        "enum": ["triggers", "core", "data_transformation", "communication", "databases", "files", "services", "all"],
                        "description": "Node category to list (default: all)",
                        "default": "all"
                    }
                }
            }
        ),
        # Write Operations
        Tool(
            name="create_workflow",
            description="Create a new workflow from JSON definition",
            inputSchema={
                "type": "object",
                "properties": {
                    "name": {
                        "type": "string",
                        "description": "Workflow name"
                    },
                    "nodes": {
                        "type": "array",
                        "description": "Array of node definitions"
                    },
                    "connections": {
                        "type": "object",
                        "description": "Connection definitions between nodes"
                    },
                    "settings": {
                        "type": "object",
                        "description": "Workflow settings (optional)"
                    }
                },
                "required": ["name", "nodes", "connections"]
            }
        ),
        Tool(
            name="update_workflow",
            description="Update an existing workflow definition",
            inputSchema={
                "type": "object",
                "properties": {
                    "workflow_id": {
                        "type": "string",
                        "description": "The workflow ID to update"
                    },
                    "name": {
                        "type": "string",
                        "description": "New workflow name (optional)"
                    },
                    "nodes": {
                        "type": "array",
                        "description": "Updated node definitions (optional)"
                    },
                    "connections": {
                        "type": "object",
                        "description": "Updated connections (optional)"
                    },
                    "settings": {
                        "type": "object",
                        "description": "Updated settings (optional)"
                    }
                },
                "required": ["workflow_id"]
            }
        ),
        Tool(
            name="delete_workflow",
            description="Delete a workflow permanently",
            inputSchema={
                "type": "object",
                "properties": {
                    "workflow_id": {
                        "type": "string",
                        "description": "The workflow ID to delete"
                    }
                },
                "required": ["workflow_id"]
            }
        ),
        # State Operations
        Tool(
            name="activate_workflow",
            description="Activate/enable a workflow so it can be triggered",
            inputSchema={
                "type": "object",
                "properties": {
                    "workflow_id": {
                        "type": "string",
                        "description": "The workflow ID to activate"
                    }
                },
                "required": ["workflow_id"]
            }
        ),
        Tool(
            name="deactivate_workflow",
            description="Deactivate/disable a workflow",
            inputSchema={
                "type": "object",
                "properties": {
                    "workflow_id": {
                        "type": "string",
                        "description": "The workflow ID to deactivate"
                    }
                },
                "required": ["workflow_id"]
            }
        ),
        # Execution Operations
        Tool(
            name="trigger_workflow",
            description="Execute a workflow via its webhook trigger. Workflow must have a webhook node.",
            inputSchema={
                "type": "object",
                "properties": {
                    "workflow_id": {
                        "type": "string",
                        "description": "The workflow ID (used to find webhook URL)"
                    },
                    "webhook_path": {
                        "type": "string",
                        "description": "The webhook path (e.g., 'my-webhook'). If not provided, will attempt to find from workflow."
                    },
                    "data": {
                        "type": "object",
                        "description": "JSON data to send to the webhook"
                    }
                },
                "required": ["workflow_id"]
            }
        ),
        Tool(
            name="retry_execution",
            description="Retry a failed workflow execution",
            inputSchema={
                "type": "object",
                "properties": {
                    "execution_id": {
                        "type": "string",
                        "description": "The execution ID to retry"
                    }
                },
                "required": ["execution_id"]
            }
        ),
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    if not N8N_API_KEY:
        return [TextContent(
            type="text",
            text="Error: N8N_API_KEY environment variable not set. Please configure your n8n API key."
        )]

    try:
        # Read Operations
        if name == "list_workflows":
            result = await make_request("GET", "/workflows")
            if not result["success"]:
                return [TextContent(type="text", text=f"Error: {result['error']}")]

            workflows = result["data"].get("data", [])

            # Apply filters
            active_filter = arguments.get("active")
            tag_filter = arguments.get("tags")

            if active_filter is not None:
                workflows = [w for w in workflows if w.get("active") == active_filter]

            if tag_filter:
                workflows = [w for w in workflows if any(
                    t.get("name") == tag_filter for t in w.get("tags", [])
                )]

            summary = []
            for w in workflows:
                tags = ", ".join([t.get("name", "") for t in w.get("tags", [])])
                summary.append({
                    "id": w.get("id"),
                    "name": w.get("name"),
                    "active": w.get("active"),
                    "tags": tags or "none",
                    "updatedAt": w.get("updatedAt"),
                })

            return [TextContent(
                type="text",
                text=json.dumps(summary, indent=2)
            )]

        elif name == "get_workflow":
            workflow_id = arguments["workflow_id"]
            result = await make_request("GET", f"/workflows/{workflow_id}")
            if not result["success"]:
                return [TextContent(type="text", text=f"Error: {result['error']}")]

            workflow = result["data"]

            # Format workflow info
            output = {
                "id": workflow.get("id"),
                "name": workflow.get("name"),
                "active": workflow.get("active"),
                "nodes": [
                    {
                        "name": n.get("name"),
                        "type": n.get("type"),
                        "position": n.get("position"),
                    }
                    for n in workflow.get("nodes", [])
                ],
                "connections": workflow.get("connections"),
                "settings": workflow.get("settings"),
                "tags": [t.get("name") for t in workflow.get("tags", [])],
            }

            return [TextContent(
                type="text",
                text=json.dumps(output, indent=2)
            )]

        elif name == "list_executions":
            params = []
            if "workflow_id" in arguments:
                params.append(f"workflowId={arguments['workflow_id']}")
            if "status" in arguments:
                params.append(f"status={arguments['status']}")
            limit = arguments.get("limit", 20)
            params.append(f"limit={limit}")

            query = "&".join(params)
            result = await make_request("GET", f"/executions?{query}")
            if not result["success"]:
                return [TextContent(type="text", text=f"Error: {result['error']}")]

            executions = result["data"].get("data", [])

            summary = []
            for e in executions:
                summary.append({
                    "id": e.get("id"),
                    "workflowId": e.get("workflowId"),
                    "status": e.get("status"),
                    "startedAt": e.get("startedAt"),
                    "stoppedAt": e.get("stoppedAt"),
                    "mode": e.get("mode"),
                })

            return [TextContent(
                type="text",
                text=json.dumps(summary, indent=2)
            )]

        elif name == "get_execution":
            execution_id = arguments["execution_id"]
            result = await make_request("GET", f"/executions/{execution_id}")
            if not result["success"]:
                return [TextContent(type="text", text=f"Error: {result['error']}")]

            execution = result["data"]

            # Extract node execution data
            node_data = []
            run_data = execution.get("data", {}).get("resultData", {}).get("runData", {})
            for node_name, runs in run_data.items():
                for run in runs:
                    node_data.append({
                        "node": node_name,
                        "startTime": run.get("startTime"),
                        "executionTime": run.get("executionTime"),
                        "error": run.get("error"),
                        "data_summary": f"{len(run.get('data', {}).get('main', [[]])[-1] if run.get('data', {}).get('main') else [])} items" if run.get("data") else "no data"
                    })

            output = {
                "id": execution.get("id"),
                "workflowId": execution.get("workflowId"),
                "status": execution.get("status"),
                "startedAt": execution.get("startedAt"),
                "stoppedAt": execution.get("stoppedAt"),
                "mode": execution.get("mode"),
                "nodeExecutions": node_data,
            }

            # Include error details if present
            if execution.get("data", {}).get("resultData", {}).get("error"):
                output["error"] = execution["data"]["resultData"]["error"]

            return [TextContent(
                type="text",
                text=json.dumps(output, indent=2)
            )]

        elif name == "get_workflow_stats":
            workflow_id = arguments["workflow_id"]
            days = arguments.get("days", 7)

            # Get recent executions for this workflow
            result = await make_request("GET", f"/executions?workflowId={workflow_id}&limit=100")
            if not result["success"]:
                return [TextContent(type="text", text=f"Error: {result['error']}")]

            executions = result["data"].get("data", [])

            # Calculate stats
            total = len(executions)
            success = sum(1 for e in executions if e.get("status") == "success")
            error = sum(1 for e in executions if e.get("status") == "error")
            waiting = sum(1 for e in executions if e.get("status") == "waiting")

            # Find recent errors
            recent_errors = []
            for e in executions:
                if e.get("status") == "error":
                    recent_errors.append({
                        "id": e.get("id"),
                        "startedAt": e.get("startedAt"),
                    })
                    if len(recent_errors) >= 5:
                        break

            stats = {
                "workflowId": workflow_id,
                "totalExecutions": total,
                "successCount": success,
                "errorCount": error,
                "waitingCount": waiting,
                "successRate": f"{(success/total*100):.1f}%" if total > 0 else "N/A",
                "recentErrors": recent_errors,
            }

            return [TextContent(
                type="text",
                text=json.dumps(stats, indent=2)
            )]

        elif name == "list_node_types":
            category = arguments.get("category", "all")

            if category == "all":
                output = NODE_TYPES
            elif category in NODE_TYPES:
                output = {category: NODE_TYPES[category]}
            else:
                return [TextContent(
                    type="text",
                    text=f"Error: Unknown category '{category}'. Valid categories: {', '.join(NODE_TYPES.keys())}"
                )]

            return [TextContent(
                type="text",
                text=json.dumps(output, indent=2)
            )]

        # Write Operations
        elif name == "create_workflow":
            workflow_data = {
                "name": arguments["name"],
                "nodes": arguments["nodes"],
                "connections": arguments["connections"],
                "settings": arguments.get("settings", {}),
            }

            result = await make_request("POST", "/workflows", workflow_data)
            if not result["success"]:
                return [TextContent(type="text", text=f"Error: {result['error']}")]

            created = result["data"]
            return [TextContent(
                type="text",
                text=f"Workflow created successfully!\n\nID: {created.get('id')}\nName: {created.get('name')}\nActive: {created.get('active')}"
            )]

        elif name == "update_workflow":
            workflow_id = arguments["workflow_id"]

            # First get current workflow
            current = await make_request("GET", f"/workflows/{workflow_id}")
            if not current["success"]:
                return [TextContent(type="text", text=f"Error getting workflow: {current['error']}")]

            # Merge updates
            update_data = {}
            if "name" in arguments:
                update_data["name"] = arguments["name"]
            if "nodes" in arguments:
                update_data["nodes"] = arguments["nodes"]
            if "connections" in arguments:
                update_data["connections"] = arguments["connections"]
            if "settings" in arguments:
                update_data["settings"] = arguments["settings"]

            result = await make_request("PATCH", f"/workflows/{workflow_id}", update_data)
            if not result["success"]:
                return [TextContent(type="text", text=f"Error: {result['error']}")]

            updated = result["data"]
            return [TextContent(
                type="text",
                text=f"Workflow updated successfully!\n\nID: {updated.get('id')}\nName: {updated.get('name')}"
            )]

        elif name == "delete_workflow":
            workflow_id = arguments["workflow_id"]

            result = await make_request("DELETE", f"/workflows/{workflow_id}")
            if not result["success"]:
                return [TextContent(type="text", text=f"Error: {result['error']}")]

            return [TextContent(
                type="text",
                text=f"Workflow {workflow_id} deleted successfully."
            )]

        # State Operations
        elif name == "activate_workflow":
            workflow_id = arguments["workflow_id"]

            result = await make_request("PATCH", f"/workflows/{workflow_id}", {"active": True})
            if not result["success"]:
                return [TextContent(type="text", text=f"Error: {result['error']}")]

            return [TextContent(
                type="text",
                text=f"Workflow {workflow_id} activated successfully."
            )]

        elif name == "deactivate_workflow":
            workflow_id = arguments["workflow_id"]

            result = await make_request("PATCH", f"/workflows/{workflow_id}", {"active": False})
            if not result["success"]:
                return [TextContent(type="text", text=f"Error: {result['error']}")]

            return [TextContent(
                type="text",
                text=f"Workflow {workflow_id} deactivated successfully."
            )]

        # Execution Operations
        elif name == "trigger_workflow":
            workflow_id = arguments["workflow_id"]
            webhook_path = arguments.get("webhook_path")
            data = arguments.get("data", {})

            # If no webhook path provided, try to find it from workflow
            if not webhook_path:
                wf_result = await make_request("GET", f"/workflows/{workflow_id}")
                if not wf_result["success"]:
                    return [TextContent(type="text", text=f"Error getting workflow: {wf_result['error']}")]

                workflow = wf_result["data"]
                webhook_nodes = [
                    n for n in workflow.get("nodes", [])
                    if n.get("type") == "n8n-nodes-base.webhook"
                ]

                if not webhook_nodes:
                    return [TextContent(
                        type="text",
                        text=f"Error: Workflow {workflow_id} has no webhook trigger. Add a webhook node to trigger via API."
                    )]

                # Get webhook path from first webhook node
                webhook_node = webhook_nodes[0]
                webhook_path = webhook_node.get("parameters", {}).get("path", "")

                if not webhook_path:
                    return [TextContent(
                        type="text",
                        text="Error: Could not determine webhook path from workflow. Please provide webhook_path parameter."
                    )]

            # Construct webhook URL
            webhook_url = f"{N8N_API_URL}/webhook/{webhook_path}"

            result = await trigger_webhook(webhook_url, data)
            if not result["success"]:
                return [TextContent(type="text", text=f"Error: {result['error']}")]

            return [TextContent(
                type="text",
                text=f"Workflow triggered successfully!\n\nWebhook URL: {webhook_url}\nStatus: {result['status']}\nResponse: {result['data']}"
            )]

        elif name == "retry_execution":
            execution_id = arguments["execution_id"]

            result = await make_request("POST", f"/executions/{execution_id}/retry")
            if not result["success"]:
                return [TextContent(type="text", text=f"Error: {result['error']}")]

            return [TextContent(
                type="text",
                text=f"Execution {execution_id} retry initiated successfully."
            )]

        raise ValueError(f"Unknown tool: {name}")

    except Exception as e:
        return [TextContent(
            type="text",
            text=f"Error: {str(e)}"
        )]


async def main():
    print(f"Starting n8n MCP server...")
    print(f"N8N_API_URL: {N8N_API_URL}")
    print(f"N8N_API_KEY: {'configured' if N8N_API_KEY else 'NOT SET'}")

    async with stdio_server() as (read_stream, write_stream):
        await app.run(
            read_stream,
            write_stream,
            app.create_initialization_options()
        )


if __name__ == "__main__":
    asyncio.run(main())
