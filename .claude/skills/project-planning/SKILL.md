---
name: project-planning
description: Structured interview-based project planning for dbt, n8n, and Docker projects. Use this skill when the user says "/project-planning", "let's plan", "new project", wants to start a new feature, data source, n8n workflow, dbt model, docker container, or any non-trivial implementation. Activates plan mode and guides structured project planning.
---

# Project Planning Skill

A structured, interview-based approach to planning projects before any code is written. This skill ensures proper discovery, codebase understanding, pattern compliance, and user approval before implementation begins.

## When to Use

- User explicitly invokes `/project-planning` or `/planning`
- User says "let's plan" or "new project"
- User wants to add a new data source, n8n workflow, dbt model, or Docker container
- User wants to review, improve, or modify existing code/models/workflows
- Any non-trivial implementation where requirements need clarification
- Multi-step work that benefits from upfront planning

## Supported Project Types

| Type | Pattern Files | Plan Folder | Builder Skill |
|------|---------------|-------------|---------------|
| dbt | `dbt_resources/*.md`, `models/*_table_grain.md` | `project-plans/dbt/` | `dbt-model` |
| n8n | Query MCP for existing workflows | `project-plans/n8n/` | `n8n-workflow` |
| Docker | `docker-projects/*/docker-compose.yml` | `project-plans/docker/` | `docker-service` |
| General | N/A | `project-plans/general/` | (manual) |

## Process Overview

```
┌─────────────────────────────────────────────────────────────┐
│  1. ENTER PLAN MODE (automatic)                             │
├─────────────────────────────────────────────────────────────┤
│  2. DISCOVERY INTERVIEW                                     │
│     - What are you trying to do?                            │
│     - What problem does this solve?                         │
│     - What does success look like?                          │
├─────────────────────────────────────────────────────────────┤
│  3. CODEBASE & PATTERN REVIEW                               │
│     - Read relevant pattern/convention files                │
│     - Review existing related code                          │
│     - For existing work: analyze against patterns           │
├─────────────────────────────────────────────────────────────┤
│  4. ANALYSIS & FINDINGS                                     │
│     - For new work: identify approach                       │
│     - For existing work: identify issues/improvements       │
├─────────────────────────────────────────────────────────────┤
│  5. CREATE PLAN DOCUMENT                                    │
│     - Write structured plan to project-plans/<type>/        │
│     - Include all proposed changes                          │
├─────────────────────────────────────────────────────────────┤
│  6. USER REVIEW & APPROVAL                                  │
│     - Present plan for review                               │
│     - Iterate until approved                                │
├─────────────────────────────────────────────────────────────┤
│  7. EXIT PLAN MODE & HANDOFF                                │
│     - Invoke appropriate builder skill                      │
│     - Begin implementation                                  │
└─────────────────────────────────────────────────────────────┘
```

## Phase 1: Enter Plan Mode

When this skill is invoked, IMMEDIATELY call `EnterPlanMode` tool. No code should be written until the user explicitly approves the plan.

## Phase 2: Discovery Interview

Conduct a thorough interview to understand the project fully. Ask as many questions as needed.

### Required Questions (Always Ask)

1. **"What are you trying to do?"**
   - New creation vs modifying/reviewing existing
   - Understand the specific request

2. **"What problem are you trying to solve?"**
   - Understand the underlying need, not just the surface request
   - Probe for the "why" behind the request

3. **"What does success look like?"**
   - Concrete, measurable outcomes
   - How will we know when this is done correctly?

### Determine Intent

| User Intent | Flow |
|-------------|------|
| Create new (model/workflow/container) | Discovery → Pattern review → Plan creation → Build |
| Review existing | Discovery → Read code → Pattern comparison → Findings report |
| Improve/fix existing | Discovery → Read code → Pattern comparison → Improvement plan → Build |
| Understand existing | Discovery → Read code → Explanation (no plan needed) |

### Project Type Detection

| If the user mentions... | Project Type |
|-------------------------|--------------|
| dbt, model, staging, mart, dimension, fact, SQL transformation | dbt |
| n8n, workflow, automation, trigger, webhook, scheduled task | n8n |
| container, Docker, service, compose, image, Python app, JS app | docker |
| Otherwise | general |

## Phase 3: Codebase & Pattern Review

Before creating any plan, thoroughly review relevant code and patterns.

### For All Project Types

1. Search `project-plans/` for related existing plans
2. Check for existing implementations in relevant directories

---

### dbt Projects

#### Pattern Files to Read

Always read these files to understand conventions:

```
docker-projects/home_metrics_dbt/dbt_resources/key_design_cheatsheet.md
docker-projects/home_metrics_dbt/models/staging/stg_table_grain.md
docker-projects/home_metrics_dbt/models/intmdt/intmdt_table_grain.md
docker-projects/home_metrics_dbt/models/marts/marts_table_grain.md
```

#### Existing Code to Review

```powershell
# Check existing models in relevant domain
ls docker-projects/home_metrics_dbt/models/**/*.sql

# Check sources
cat docker-projects/home_metrics_dbt/models/staging/sources.yml

# Check macros
ls docker-projects/home_metrics_dbt/macros/*.sql
```

#### dbt-Specific Interview Questions

- What data source is this for? (existing raw table or new?)
- What questions should this data answer?
- What time granularity is needed? (daily, monthly, etc.)
- Does this need to join with existing domains?
- What's the refresh frequency of the source data?
- Are there specific business rules or calculations needed?

#### dbt Analysis Checklist (for existing models)

Compare the model against patterns in `key_design_cheatsheet.md`:

| Check | Pattern | Look For |
|-------|---------|----------|
| Key naming | `_pk`, `_skey`, `_key` suffixes | Incorrect key suffixes or naming |
| Surrogate keys | `generate_surrogate_key()` usage | Missing or incorrect key generation |
| Dimension keys | `_key` for grouping, not unique | Unique tests on dimension keys (wrong) |
| CTEs | No subqueries | Any subqueries that should be CTEs |
| Timestamps | `to_local_time()` macro | Raw timestamps without conversion |
| Grain | Documented in `*_table_grain.md` | Missing grain documentation |
| Tests | `_pk`/`_skey` have unique+not_null | Missing critical tests |

---

### n8n Projects

#### Discovery via MCP

Use the n8n MCP server to understand current state:

```
mcp__n8n-manager__list_workflows        # See all workflows
mcp__n8n-manager__get_workflow          # Get specific workflow details
mcp__n8n-manager__list_executions       # Check recent execution history
mcp__n8n-manager__get_workflow_stats    # Understand what's working/failing
```

#### n8n-Specific Interview Questions

- What triggers this workflow? (schedule, webhook, manual, event)
- What external services/APIs are involved?
- What data transformations are needed?
- Where should the output go? (database, notification, file, API)
- Are there existing workflows this should integrate with?
- What should happen when it fails? (retry, alert, fallback)

---

### Docker Projects

#### Existing Code to Review

```powershell
# Check existing services
ls docker-projects/*/docker-compose.yml

# Check if service name is already used
docker ps --format "{{.Names}}"

# Check port usage
docker ps --format "{{.Ports}}"

# Check networks
docker network ls
```

#### Docker-Specific Interview Questions

- What image/service are you deploying?
- What language/framework? (Python, Node.js, static HTML)
- Does it need persistent data? (volumes)
- Does it need external access? (ports)
- Does it require secrets? (API keys, passwords)
- Does it depend on other containers? (networks)
- Should it auto-start with the system?
- Does it need to connect to home-metrics network for analytics?

---

## Phase 4: Analysis & Findings

### For New Work

- Identify the technical approach
- List files to create/modify
- Note any dependencies or prerequisites

### For Existing Work Review/Improvement

Create a findings section with:

```markdown
## Analysis Findings

### Issues Found

| # | Severity | Issue | Location | Pattern Violated |
|---|----------|-------|----------|------------------|
| 1 | High | [description] | line X | [which pattern] |
| 2 | Medium | [description] | line Y | [which pattern] |

### Recommended Improvements

1. **[Improvement title]**
   - Current: [what exists]
   - Proposed: [what it should be]
   - Rationale: [why this matters]

2. **[Improvement title]**
   - Current: [what exists]
   - Proposed: [what it should be]
   - Rationale: [why this matters]
```

## Phase 5: Create Plan Document

### File Naming Convention

```
project-plans/<type>/<descriptive-name>.md
```

Examples:
- `project-plans/dbt/teller-transactions-improvement.md`
- `project-plans/dbt/youtube-watch-history-models.md`
- `project-plans/n8n/daily-backup-verification.md`
- `project-plans/docker/flask-api-container.md`

### Plan Document Template

```markdown
# Project: [Descriptive Title]

**Created:** [Date]
**Type:** [dbt | n8n | docker | general]
**Intent:** [new | review | improve | fix]
**Status:** Planning

## Discovery Summary

[2-3 paragraph summary of the discovery interview - what the user needs, why, and key context gathered]

## Codebase Review

### Files Reviewed
- `path/to/file1` - [what it contains]
- `path/to/file2` - [what it contains]

### Patterns Referenced
- `key_design_cheatsheet.md` - Key naming conventions
- `*_table_grain.md` - Grain definitions

## Analysis Findings

[For existing work: include the findings table and improvements list]
[For new work: include technical approach notes]

## Scope & Goals

**Goals:**
- [ ] [Primary goal]
- [ ] [Secondary goal]

**Success Criteria:**
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]

**Out of Scope:**
- [Explicitly excluded item]

## Technical Approach

### Overview
[High-level description of the approach]

### Key Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| [Decision 1] | [Choice] | [Why] |

## Proposed Changes

### Files to Create
- `path/to/new/file.ext` - [purpose]

### Files to Modify
- `path/to/existing.ext`
  - Line X: [current] → [proposed]
  - Line Y: [current] → [proposed]

### Code Changes

[Include actual code snippets showing before/after for modifications]

```sql
-- BEFORE (line 15-20)
[current code]

-- AFTER
[proposed code]
```

## Task Breakdown

### Phase 1: [Phase Name]
1. [ ] [Task 1]
2. [ ] [Task 2]

### Phase 2: [Phase Name]
1. [ ] [Task 1]
2. [ ] [Task 2]

## Verification Steps

1. [How to verify step 1]
2. [How to verify step 2]
```

## Phase 6: User Review

Present the plan document and explicitly ask for review:

> "I've created the project plan at `project-plans/<type>/<name>.md`. This includes [summary of proposed changes]. Please review and let me know if you'd like any changes, or if you're ready to approve and begin implementation."

### Handling Feedback

- **Changes requested**: Update the plan, re-present
- **Questions raised**: Answer them, update plan if needed
- **Approved**: Proceed to Phase 7

## Phase 7: Exit Plan Mode & Handoff

Once the user approves:

1. **Update plan status**
   ```markdown
   **Status:** Approved - Ready for Implementation
   ```

2. **Exit plan mode**
   Call `ExitPlanMode` tool

3. **Invoke the appropriate builder skill**

   | Project Type | Builder Skill |
   |--------------|---------------|
   | dbt | `dbt-model` |
   | n8n | `n8n-workflow` |
   | docker | `docker-service` |
   | general | Continue manually |

4. **Pass context to builder**
   The builder skill receives:
   - Path to the approved plan document
   - Summary of changes to implement

## Checklist

- [ ] EnterPlanMode called immediately
- [ ] Discovery interview completed (intent, problem, success)
- [ ] Project type determined
- [ ] Pattern files read (type-specific)
- [ ] Existing code reviewed
- [ ] Analysis completed (findings for existing, approach for new)
- [ ] Plan document created with all proposed changes
- [ ] Plan presented to user
- [ ] User approval obtained
- [ ] Plan status updated
- [ ] ExitPlanMode called
- [ ] Builder skill invoked with context
