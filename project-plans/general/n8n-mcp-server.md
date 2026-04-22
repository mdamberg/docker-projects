# Project: n8n MCP Server

**Created:** 2026-04-14
**Complexity:** Medium-Large
**Status:** Planning Complete

## Overview

Create an MCP server that connects Claude Code to the n8n workflow automation instance at `10.0.0.7:5678`. This enables monitoring, triggering, debugging, and managing n8n workflows directly from Claude, plus assistance with workflow creation through node discovery.

## Goals & Success Criteria

**Goals:**
- Full visibility into n8n workflows and execution status
- Ability to trigger workflows on-demand from Claude
- Debug failed executions with detailed logs
- Manage workflow lifecycle (enable/disable/create/update/delete)
- Assist with workflow creation via node reference

**Success Criteria:**
- [ ] Can list all workflows with status from Claude
- [ ] Can view detailed workflow definition (nodes, connections)
- [ ] Can trigger workflows via webhook
- [ ] Can view execution history and filter by status
- [ ] Can get detailed execution logs including errors
- [ ] Can activate/deactivate workflows
- [ ] Can create new workflows from JSON definition
- [ ] Can update existing workflow definitions
- [ ] Can delete workflows
- [ ] Can retry failed executions
- [ ] Can access node type reference for workflow building

**Out of Scope (v1):**
- Credential management (security concern)
- Real-time execution streaming
- Visual workflow editor integration
- Internal n8n API endpoints (session auth required)

## Approach

### Selected Approach
Docker-containerized MCP server following the existing pattern in `docker-projects/mcp_server/`. Python async server using `mcp` library with `aiohttp` for n8n API calls. Webhook-based workflow triggering.

### Rationale
- **Docker container**: Consistent with existing MCP servers (server1, server2), isolated environment, easy deployment
- **Webhook triggering**: n8n public API doesn't expose direct execution; webhooks are the supported method
- **Embedded node reference**: n8n API doesn't expose node types; curated list provides immediate value without complex workarounds
- **aiohttp**: Async HTTP client matches the async MCP server pattern

### Alternatives Considered

| Option | Pros | Cons | Why Rejected |
|--------|------|------|--------------|
| Local Python script | Simpler setup | Inconsistent with existing pattern, dependency management | Consistency matters |
| n8n internal API | Full API access | Requires session auth, more complex, may break on updates | Public API more stable |
| Separate node discovery service | More complete data | Over-engineered for MVP, additional complexity | Can add later if needed |

## MCP Tools (13 total)

### Read Operations
1. **list_workflows** - List all workflows with status, tags, metadata
2. **get_workflow** - Get full workflow definition (nodes, connections)
3. **list_executions** - Get execution history with filtering
4. **get_execution** - Get detailed execution with input/output data
5. **get_workflow_stats** - Aggregated stats (success rate, duration, recent errors)
6. **list_node_types** - Reference of available n8n nodes by category

### Write Operations
7. **create_workflow** - Create new workflow from JSON definition
8. **update_workflow** - Update existing workflow definition
9. **delete_workflow** - Delete a workflow

### State Operations
10. **activate_workflow** - Enable/publish a workflow
11. **deactivate_workflow** - Disable a workflow

### Execution Operations
12. **trigger_workflow** - Execute via webhook (requires webhook trigger in workflow)
13. **retry_execution** - Retry a failed execution

## File Structure

```
docker-projects/mcp_server/
├── docker-compose.yml           # UPDATE: Add mcp-n8n-server service
├── .env                         # UPDATE: Add N8N_API_URL, N8N_API_KEY
└── mcp_servers/
    ├── server1/                 # Existing (Docker manager)
    ├── server2/                 # Existing (Filesystem manager)
    └── server3/                 # NEW: n8n manager
        ├── Dockerfile
        ├── requirements.txt
        └── server.py
```

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Workflow trigger not in public API | High | Medium | Use webhook triggers; tool detects if webhook exists |
| Node discovery not in API | High | Low | Embed curated node list; update periodically |
| Network connectivity Docker↔n8n | Medium | High | Use `--network host` or shared Docker network |
| API key exposure | Low | High | Store in `.env`, gitignored, document in readme |
| n8n API changes after updates | Low | Medium | Test after n8n updates; pin to known patterns |

## Implementation Plan

### Tasks

1. [ ] Create `mcp_servers/server3/` directory structure
2. [ ] Create `requirements.txt` with mcp>=1.0.0, aiohttp>=3.9.0
3. [ ] Create `Dockerfile` following server1 pattern
4. [ ] Implement `server.py` with all 13 tools:
   - Connection helpers and error handling
   - Read tools (list_workflows, get_workflow, list_executions, get_execution, get_workflow_stats, list_node_types)
   - Write tools (create_workflow, update_workflow, delete_workflow)
   - State tools (activate_workflow, deactivate_workflow)
   - Execution tools (trigger_workflow, retry_execution)
5. [ ] Update `docker-compose.yml` with new service (port 8003)
6. [ ] Add `N8N_API_URL` and `N8N_API_KEY` to `.env`
7. [ ] Build container: `docker-compose build mcp-n8n-server`
8. [ ] Update Claude Desktop config
9. [ ] Update MCP server readme with new server documentation
10. [ ] Test all tools via Claude

### Dependencies
- Tasks 1-3 before task 4
- Task 4 before tasks 5-7
- Tasks 5-7 can run in parallel
- Task 8 after task 7

## Configuration

### Environment Variables (.env)
```
N8N_API_URL=http://10.0.0.7:5678
N8N_API_KEY=<your-api-key>
```

### Docker Compose Service
```yaml
mcp-n8n-server:
  build: ./mcp_servers/server3
  container_name: mcp-n8n-server
  ports:
    - "8003:8000"
  networks:
    - mcp-network
  environment:
    - SERVER_NAME=n8n-manager
    - N8N_API_URL=${N8N_API_URL}
    - N8N_API_KEY=${N8N_API_KEY}
```

### Claude Desktop Config
```json
{
  "n8n-manager": {
    "command": "docker",
    "args": [
      "run", "--rm", "-i",
      "--name", "mcp-n8n-temp",
      "-e", "N8N_API_URL=http://10.0.0.7:5678",
      "-e", "N8N_API_KEY=YOUR_API_KEY",
      "--network", "host",
      "mcp_server-mcp-n8n-server",
      "python", "/app/server.py"
    ]
  }
}
```

## Verification

1. **Build test**: `docker-compose build mcp-n8n-server` succeeds
2. **Container starts**: `docker-compose up mcp-n8n-server` runs without errors
3. **API connectivity**: Container can reach n8n at 10.0.0.7:5678
4. **Tool test via Claude**:
   - "List my n8n workflows" returns workflow list
   - "Show me workflow X" returns full definition
   - "Show recent executions" returns execution history
   - "Activate workflow X" toggles state
   - "Create a simple workflow that..." creates new workflow
5. **Error handling**: Invalid workflow ID returns helpful error message

## Open Questions

- None at this time; all requirements clarified

---
*Plan approved: pending*
