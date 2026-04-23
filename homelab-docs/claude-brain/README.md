# Claude Brain — Postgres-Backed AI Assistant Layer

A unified Postgres interface that lets Claude answer questions about personal productivity
and homelab metrics with a single database query instead of multiple live API calls.

## Purpose

Instead of Claude calling Gmail, Google Calendar, Notion, or homelab APIs at query time,
data is pre-synced into Postgres on a schedule. Claude queries one MCP server (`server4`)
and gets compact, structured results. This reduces token usage, latency, and the number of
MCP tool definitions loaded at session start.

**Two categories of data, one interface:**

| Category | Sources | Sync needed? |
|---|---|---|
| Personal productivity | Gmail, Google Calendar, Notion | Yes — new n8n workflows |
| Homelab metrics | n8n runs, media library, power, finances | No — already in Postgres |

## Architecture

```
── PERSONAL PRODUCTIVITY (new syncs) ──────────────────────────────────────────┐
Gmail ──────── n8n (hourly)   ──┐                                              │
Google Cal ─── n8n (every 4h) ──┼── UPSERT ──► home-metrics-postgres           │
Notion ──────── n8n (every 2h) ─┘              schema: claude_brain            │
                                                                                │
── HOMELAB METRICS (already collected) ────────────────────────────────────────┤
n8n run logs ─── existing workflow ──► raw.raw_n8n_workflow_runs               │
Media library ── existing workflow ──► raw.raw_media_library_metrics           │
Power data ───── existing workflow ──► marts.fct_power_consumption             │
Transactions ─── existing workflow ──► marts.monthly_transactions              │
                                                │                              │
                               MCP server4 — mcp-postgres-brain (port 8004)   │
                                                │                              │
                                             Claude ◄──────────────────────────┘
```

## MCP Server4 — Query Tools

All tools are read-only and parameterized. No raw SQL is exposed to Claude.

### Personal Productivity

| Tool | What it answers |
|---|---|
| `get_upcoming_events` | "Do I have anything on my calendar this week?" / "Any PTO coming up?" |
| `search_emails` | "Have I received any emails labeled X?" / "Any emails from person Y?" |
| `search_notion` | "What are my HomeLab notes in Notion?" / "Find my notes on topic X" |
| `get_sync_status` | "When did the brain last sync?" — checks `sync_log` per source |

### Homelab Metrics

| Tool | What it answers |
|---|---|
| `get_n8n_run_health` | "Have any n8n workflows failed recently?" |
| `get_media_stats` | "How many movies do I have? What's the total storage?" |
| `get_power_stats` | "How much energy has my house used this month?" |
| `get_financial_summary` | "What was my total income and spending last month?" |

## Database Schema

All personal productivity data lives in the `claude_brain` schema inside `home-metrics-postgres`.
Homelab metrics are read from the existing `raw` and mart schemas — no changes to those tables.

```sql
-- Claude Brain schema (new)
claude_brain.calendar_events   -- Google Calendar events (-7d to +30d window)
claude_brain.gmail_messages    -- Gmail metadata + snippet (no full body)
claude_brain.notion_pages      -- Notion page text content
claude_brain.sync_log          -- Last successful sync per source

-- Homelab schemas (existing, read-only)
raw.raw_n8n_workflow_runs      -- n8n execution history
raw.raw_media_library_metrics  -- Media counts and storage snapshots
marts.fct_power_consumption    -- Cleaned power consumption facts
marts.monthly_transactions     -- Monthly financial summaries
```

### Key schema decisions

- **Gmail**: Snippet + metadata only (no full body) — keeps rows lean and queries fast
- **Calendar**: `event_type` derived from title keywords (PTO/OOO → `pto`, etc.)
- **Notion**: Plain text extraction only — no block-level rich text
- **No client/person join key** — use cases are personal productivity, not CRM

## n8n Sync Workflows

Three new workflows handle the personal productivity sync. Homelab data uses existing workflows.

| Workflow | Schedule | Source | Target table |
|---|---|---|---|
| `gmail-brain-sync` | Every 1 hour | Gmail API | `claude_brain.gmail_messages` |
| `calendar-brain-sync` | Every 4 hours | Google Calendar API | `claude_brain.calendar_events` |
| `notion-brain-sync` | Every 2 hours | Notion API | `claude_brain.notion_pages` |
| `brain-sync-health-check` | Daily 8am | `claude_brain.sync_log` | — (alerts only) |

Each sync workflow:
1. Fetches recent data from the API
2. Upserts to Postgres on the source's unique ID (idempotent)
3. Writes a row to `sync_log` on success
4. Pings an Uptime Kuma heartbeat on success
5. On error: writes to `raw.raw_n8n_alerts` + sends Pushover notification

The daily health-check workflow queries `sync_log` and alerts if any source hasn't synced
within its expected window (Gmail/Notion: 6h, Calendar: 12h).

## Monitoring

| Monitor | Type | Expected ping interval |
|---|---|---|
| Gmail brain sync | Uptime Kuma heartbeat | Every 1 hour |
| Calendar brain sync | Uptime Kuma heartbeat | Every 4 hours |
| Notion brain sync | Uptime Kuma heartbeat | Every 2 hours |

Check sync health from Claude:

```
"What's the brain sync status?"
→ get_sync_status returns last successful sync per source
```

Check directly in Postgres:

```sql
SELECT source, status, records_synced, synced_at
FROM claude_brain.sync_log
ORDER BY synced_at DESC;
```

## Service Details

| Property | Value |
|---|---|
| Container name | `mcp-postgres-brain` |
| Port | 8004 |
| Compose file | `docker-projects/mcp_server/docker-compose.yml` |
| Server directory | `docker-projects/mcp_server/mcp_servers/server4/` |
| DB connection env var | `BRAIN_DB_URL` |

## Pre-Implementation Requirements

These must be set up manually before the n8n workflows can be built:

- [ ] **Google OAuth**: Create OAuth 2.0 credentials in Google Cloud Console; enable Gmail API
  and Google Calendar API; add credential in n8n (one credential covers both services)
- [ ] **Notion integration**: Create integration at notion.so/my-integrations; share your
  HomeLab database(s) with it; note the database IDs for n8n workflow config
- [ ] **Pushover**: Confirm existing Pushover credential is active in n8n
- [ ] **Uptime Kuma**: Create 3 heartbeat monitors (gmail-brain, calendar-brain, notion-brain)

## Adding New Sources

The sync pattern is designed to be repeatable. To add a new source (e.g. Slack, HubSpot):

1. Add a table to `claude_brain` schema for the new source
2. Build an n8n workflow that upserts to it on schedule with error handler + heartbeat
3. Add a new tool to `server4/server.py` with a parameterized query
4. Update `brain-sync-health-check` to include the new source in its staleness check
5. Add a heartbeat monitor in Uptime Kuma
6. Update this document

## Related Documentation

- [Analytics Stack Overview](../analytics-stack/README.md) — the Postgres instance this uses
- [PostgreSQL Service](../analytics-stack/services/postgresql.md) — connection details
- [n8n Workflows](../analytics-stack/services/n8n.md) — existing workflow patterns
- [Monitoring Stack](../monitoring-stack/README.md) — Uptime Kuma heartbeat setup
- [Project Plan](../../project-plans/general/postgres-brain-for-claude.md) — full implementation plan
