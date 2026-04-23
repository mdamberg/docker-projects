# Project: Postgres "Brain" for Claude

**Created:** 2026-04-23
**Type:** General (spans n8n + Docker MCP server + Postgres schema)
**Status:** Planning

## Discovery Summary

The goal is to give Claude a single Postgres-backed interface for answering two categories
of questions without live API calls: (1) personal productivity — calendar events, tagged
emails, Notion notes; (2) homelab metrics — n8n run health, media library stats, power
consumption, and financial summaries.

For personal productivity, data doesn't exist yet and must be synced via new n8n workflows
into a new `claude_brain` schema. For homelab metrics, the data already lives in
`home-metrics-postgres` — existing n8n workflows collect it and dbt models transform it
into queryable marts. No new sync infrastructure is needed for that half; server4 simply
needs read access to the existing schemas alongside `claude_brain`.

The original concept included CRM-style client joining (client_id), but the actual use cases
are personal productivity and homelab monitoring — no client dimension is needed.

## Scope & Goals

**Goals:**
- [ ] Pre-sync Gmail, Google Calendar, and Notion into Postgres on a schedule via n8n
- [ ] Expose a new MCP server (server4) with targeted query tools for Claude covering both personal and homelab data
- [ ] Monitor sync health with alerts on failure or stale data
- [ ] Establish a repeatable pattern so additional sources can be added later

**Success Criteria — Personal Productivity:**
- [ ] Claude can answer "Do I have any appointments this week?" without a live API call
- [ ] Claude can answer "Have I received any emails tagged X?" without a live API call
- [ ] Claude can answer "What are my HomeLab notes in Notion?" without a live API call
- [ ] Each sync runs on schedule and alerts (Pushover) on failure within 5 minutes
- [ ] `sync_log` table shows last successful sync per source; stale data triggers daily alert

**Success Criteria — Homelab Metrics (data already in DB, no new sync needed):**
- [ ] Claude can answer "Have any n8n workflows failed recently?"
- [ ] Claude can answer "How many movies do I have and what's the total storage?"
- [ ] Claude can answer "How much energy has my house used this month?"
- [ ] Claude can answer "What was my total income and spending last month?"

**Out of Scope (v1):**
- HubSpot, Slack, or other external sources (added later using the same pattern)
- Writing back to any source (read-only throughout)
- Full email body storage (snippets + metadata only, for token efficiency)
- Notion page content beyond plain text extraction

## Technical Approach

### Overview

```
── NEW SYNCS ──────────────────────────────────────────────────────────────────────────────┐
Gmail ──────── n8n (hourly)   ──┐                                                          │
Google Cal ─── n8n (every 4h) ──┼── UPSERT ──► home-metrics-postgres / schema: claude_brain│
Notion ──────── n8n (every 2h) ─┘                                                          │
                                                                                            │
── ALREADY SYNCED ─────────────────────────────────────────────────────────────────────────┤
n8n run logs ─── existing workflow ──► raw.raw_n8n_workflow_runs                           │
Media library ── existing workflow ──► raw.raw_media_library_metrics                       │
Power data ───── existing workflow ──► marts.fct_power_consumption                         │
Transactions ─── existing workflow ──► marts.monthly_transactions                          │
                                            │                                              │
                                   MCP server4 (read-only, queries both schemas)           │
                                            │                                              │
                                         Claude ◄─────────────────────────────────────────┘
```

### Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Postgres instance | Existing `home-metrics-postgres`, new schema `claude_brain` | No new container; clean isolation via schema |
| Schema design | Flat tables per source, no client join | Use cases are personal productivity, not CRM |
| MCP server | New server4 (`mcp-postgres-brain`) | No existing SQL/Postgres MCP server; follows server1-3 pattern |
| MCP tool design | Named tools per query type (8 tools) | More compact responses than raw SQL; prevents injection |
| Homelab data access | Read existing `raw` + `public` schemas | Data already collected — no new sync needed for homelab metrics |
| Gmail storage | Snippet + metadata only, no full body | Token efficiency; full body not needed for the use cases |
| Notion content | Plain text extraction, no blocks/rich text | Keeps rows lean and queryable |
| Sync approach | n8n upsert on unique ID | Idempotent; re-runs don't duplicate data |
| Error alerting | n8n error handler → Pushover + `raw_n8n_alerts` | Consistent with existing homelab alert pattern |
| Heartbeat monitoring | n8n pings Uptime Kuma after each successful sync | Consistent with existing workflow monitoring |

### Schema: `claude_brain`

```sql
-- Google Calendar events
CREATE TABLE claude_brain.calendar_events (
  id              SERIAL PRIMARY KEY,
  google_event_id TEXT UNIQUE NOT NULL,
  title           TEXT,
  start_time      TIMESTAMPTZ,
  end_time        TIMESTAMPTZ,
  all_day         BOOLEAN DEFAULT FALSE,
  location        TEXT,
  description     TEXT,
  calendar_name   TEXT,
  event_type      TEXT,   -- 'meeting', 'pto', 'holiday', 'personal', etc.
  synced_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Gmail messages (metadata + snippet only)
CREATE TABLE claude_brain.gmail_messages (
  id              SERIAL PRIMARY KEY,
  gmail_id        TEXT UNIQUE NOT NULL,
  thread_id       TEXT,
  subject         TEXT,
  sender          TEXT,
  snippet         TEXT,    -- first ~200 chars; not full body
  labels          TEXT[],  -- ['INBOX', 'Label_123', ...]
  received_at     TIMESTAMPTZ,
  is_read         BOOLEAN,
  synced_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Notion pages (plain text content)
CREATE TABLE claude_brain.notion_pages (
  id              SERIAL PRIMARY KEY,
  notion_id       TEXT UNIQUE NOT NULL,
  title           TEXT,
  database_name   TEXT,
  content_text    TEXT,    -- extracted plain text from page blocks
  tags            TEXT[],
  last_edited     TIMESTAMPTZ,
  notion_url      TEXT,
  synced_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Sync health log
CREATE TABLE claude_brain.sync_log (
  id              SERIAL PRIMARY KEY,
  source          TEXT NOT NULL,  -- 'gmail', 'calendar', 'notion'
  status          TEXT NOT NULL,  -- 'success', 'error'
  records_synced  INT,
  error_message   TEXT,
  synced_at       TIMESTAMPTZ DEFAULT NOW()
);
```

### MCP Server4 Tools (8 tools)

All tools are read-only, parameterized queries — no raw SQL exposed to Claude.

**Personal Productivity (queries `claude_brain` schema):**

| Tool | Description |
|------|-------------|
| `get_upcoming_events` | Calendar events for a date range (default: next 7 days). Returns title, start/end, location, event_type. |
| `search_emails` | Search gmail_messages by label, sender, subject keyword, or date range. Returns subject, sender, snippet, received_at. |
| `search_notion` | Search notion_pages by database name or keyword in title/content. Returns title, database_name, excerpt, last_edited, url. |
| `get_sync_status` | Returns last successful sync time per source and record counts from `claude_brain.sync_log`. |

**Homelab Metrics (queries existing `raw` + dbt mart schemas — no new sync needed):**

| Tool | Source Table(s) | Description |
|------|-----------------|-------------|
| `get_n8n_run_health` | `raw.raw_n8n_workflow_runs` | Recent workflow executions with status. Params: lookback hours (default 24), status filter (all/error/success). Returns workflow name, status, started_at, duration. |
| `get_media_stats` | `raw.raw_media_library_metrics` | Media library summary. Returns movie count, TV show count, total storage in GB, breakdown by library — from most recent snapshot. |
| `get_power_stats` | `fct_power_consumption`, `monthly_hardware_sensors` | Energy usage summary. Params: period (today/week/month). Returns kWh total, daily average, peak reading. |
| `get_financial_summary` | `monthly_transactions` | Income and spending summary. Params: month (default current). Returns total income, total expenses, net, top spending categories. |

### n8n Workflows (3 new workflows)

**1. gmail-brain-sync** (trigger: every 1 hour)
- Fetch emails modified in last 2 hours via Gmail API
- Extract: gmail_id, thread_id, subject, sender, snippet, labels, received_at, is_read
- Upsert to `claude_brain.gmail_messages` on `gmail_id`
- On success: update `sync_log`, ping Uptime Kuma heartbeat
- On error: write to `raw_n8n_alerts`, send Pushover notification

**2. calendar-brain-sync** (trigger: every 4 hours)
- Fetch events from Google Calendar for -7 days to +30 days window
- Extract: google_event_id, title, start_time, end_time, all_day, location, description, calendar_name
- Derive `event_type` from title keywords (PTO, OOO → pto; holiday → holiday; else meeting/personal)
- Upsert to `claude_brain.calendar_events` on `google_event_id`
- On success: update `sync_log`, ping Uptime Kuma heartbeat
- On error: write to `raw_n8n_alerts`, send Pushover notification

**3. notion-brain-sync** (trigger: every 2 hours)
- Fetch pages from configured Notion database IDs (stored as n8n env vars)
- Extract: notion_id, title, database_name, plain text content, tags, last_edited, url
- Upsert to `claude_brain.notion_pages` on `notion_id`
- On success: update `sync_log`, ping Uptime Kuma heartbeat
- On error: write to `raw_n8n_alerts`, send Pushover notification

**4. brain-sync-health-check** (trigger: daily at 8am)
- Query `sync_log` for any source with no successful sync in >6h (Gmail), >12h (Calendar), >6h (Notion)
- If stale: send Pushover alert listing which sources are behind

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Google OAuth token expiration | Medium | High | n8n credential refresh is automatic; monitor via sync_log |
| Notion API rate limits (3 req/s) | Low | Medium | Add delay node between page fetches in n8n |
| Gmail snippet truncation misses context | Low | Low | Acceptable for v1; full body can be added per use case later |
| Schema changes break MCP queries | Low | Medium | Parameterized tools insulate Claude from schema; update both together |
| Notion database IDs change | Low | Medium | Store as n8n env vars so they're easy to update without code changes |
| home-metrics-postgres unavailable | Low | High | Existing monitoring already covers this; MCP tools return graceful error |

## Task Breakdown

### Phase 1: Schema Setup
1. [ ] Connect to `home-metrics-postgres` and create schema `claude_brain`
2. [ ] Create `calendar_events`, `gmail_messages`, `notion_pages`, `sync_log` tables
3. [ ] Add indexes: `gmail_messages(received_at)`, `gmail_messages(labels)`, `calendar_events(start_time)`, `notion_pages(database_name)`
4. [ ] Verify schema visible from existing dbt connection (smoke test)

### Phase 2: MCP Server4
1. [ ] Create `mcp_servers/server4/` directory with `Dockerfile`, `requirements.txt`, `server.py`
2. [ ] Confirm exact schema/table names for homelab data by inspecting `home-metrics-postgres` (dbt output schema may differ from model names)
3. [ ] Implement personal productivity tools: `get_upcoming_events`, `search_emails`, `search_notion`, `get_sync_status`
4. [ ] Implement homelab tools: `get_n8n_run_health`, `get_media_stats`, `get_power_stats`, `get_financial_summary`
5. [ ] Add `mcp-postgres-brain` service to `mcp_server/docker-compose.yml` (port 8004)
6. [ ] Add `BRAIN_DB_URL` to `mcp_server/.env` (single connection string covers all schemas)
7. [ ] Build and smoke-test container
8. [ ] Add server4 to Claude Desktop config

### Phase 3: n8n Credential Setup
1. [ ] Create Google OAuth credential in n8n (covers Gmail + Calendar)
2. [ ] Create Notion API credential in n8n
3. [ ] Create Postgres credential in n8n pointing to `home-metrics-postgres` / `claude_brain` schema
4. [ ] Identify and note Notion database IDs to sync (HomeLab notes DB at minimum)

### Phase 4: n8n Sync Workflows
1. [ ] Build `gmail-brain-sync` workflow with error handler and Uptime Kuma heartbeat
2. [ ] Build `calendar-brain-sync` workflow with error handler and Uptime Kuma heartbeat
3. [ ] Build `notion-brain-sync` workflow with error handler and Uptime Kuma heartbeat
4. [ ] Build `brain-sync-health-check` daily stale-data alert workflow
5. [ ] Add Uptime Kuma heartbeat monitors for each sync (3 new monitors)
6. [ ] Run all three syncs manually and verify row counts in Postgres

### Phase 5: Verification & Docs
1. [ ] Test all 8 MCP tools from Claude using the example queries in the success criteria
2. [ ] Verify Pushover alert fires on simulated sync failure
3. [ ] Add server4 entry to `mcp_server/readme`
4. [ ] Update `homelab-docs/` with new brain infrastructure entry
5. [ ] Save n8n workflow JSON exports to `docker-projects/n8n/`

## Implementation Sequence

```
Phase 1 (Schema)
      ↓
Phase 2 (MCP Server4) ──────────────── Phase 3 (n8n Credentials)
      ↓                                          ↓
      └──────────────── Phase 4 (n8n Workflows) ─┘
                                 ↓
                          Phase 5 (Verify + Docs)
```

Phases 2 and 3 can run in parallel after Phase 1 is done.

## Expected Output

### Files to Create
- `docker-projects/mcp_server/mcp_servers/server4/Dockerfile`
- `docker-projects/mcp_server/mcp_servers/server4/requirements.txt`
- `docker-projects/mcp_server/mcp_servers/server4/server.py`

### Files to Modify
- `docker-projects/mcp_server/docker-compose.yml` — add `mcp-postgres-brain` service
- `docker-projects/mcp_server/.env` — add `BRAIN_DB_URL`
- `docker-projects/mcp_server/readme` — add server4 documentation
- `homelab-docs/` — new or updated entry for Claude Brain infrastructure

### n8n Workflows to Export
- `docker-projects/n8n/gmail-brain-sync.json`
- `docker-projects/n8n/calendar-brain-sync.json`
- `docker-projects/n8n/notion-brain-sync.json`
- `docker-projects/n8n/brain-sync-health-check.json`

### Verification Steps
1. `psql` into `home-metrics-postgres` → `\dt claude_brain.*` shows all 4 tables
2. `docker-compose build mcp-postgres-brain` succeeds
3. Claude: "Do I have anything on my calendar this week?" → returns events from DB
4. Claude: "Any emails labeled Important?" → returns matching rows
5. Claude: "What are my HomeLab notes in Notion?" → returns notion_pages rows
6. Claude: "What's the sync status?" → returns last sync time per source
7. Claude: "Have any n8n workflows failed in the last 24 hours?" → returns run health
8. Claude: "How many movies do I have and what's the total storage?" → returns media stats
9. Claude: "How much energy has my house used this month?" → returns power summary
10. Claude: "What was my income and spending last month?" → returns financial summary
11. Disable a sync workflow → verify Pushover alert fires within schedule window

## Pre-Implementation Checklist (Manual Steps Before Starting)

These must be done by the user before n8n workflows can be built:

- [ ] **Google OAuth app**: Create or reuse a Google Cloud project; enable Gmail API and Google Calendar API; create OAuth 2.0 credentials; add as credential in n8n
- [ ] **Notion integration**: Create a Notion integration at notion.so/my-integrations; get API key; share your HomeLab database(s) with the integration; note the database IDs
- [ ] **Pushover app token**: Confirm existing Pushover credential in n8n (likely already set up from other workflows)
- [ ] **Uptime Kuma**: Create 3 new heartbeat monitors (one per sync source)

## Post-Implementation

- [ ] Documentation updated in `homelab-docs/`
- [ ] n8n workflow JSONs exported and committed
- [ ] All 3 sync workflows enabled and running on schedule
- [ ] Monitoring confirmed active in Uptime Kuma
