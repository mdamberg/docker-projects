---
name: project-planning
description: Structured interview-based project planning for dbt, n8n, and Docker projects. Use this skill when the user says "/project-planning", "let's plan", "new project", wants to start a new feature, data source, n8n workflow, dbt model, docker container, or any non-trivial implementation. Activates plan mode and guides structured project planning.
---

# Project Planning Skill

A structured, interview-based approach to planning projects before any code is written. This skill ensures proper discovery, clear goals, and user approval before implementation begins.

## When to Use

- User explicitly invokes `/project-planning`
- User says "let's plan" or "new project"
- User wants to add a new data source, n8n workflow, dbt model, or Docker container
- Any non-trivial implementation where requirements need clarification
- Multi-step work that benefits from upfront planning

## Supported Project Types

| Type | Folder | Post-Approval Skill |
|------|--------|---------------------|
| dbt models/queries | `project-plans/dbt/` | `dbt-query` |
| n8n workflows | `project-plans/n8n/` | `n8n-workflow` |
| Docker containers | `project-plans/docker/` | `docker-service` |
| General/other | `project-plans/general/` | (manual) |

## Process Overview

```
┌─────────────────────────────────────────────────────────────┐
│  1. ENTER PLAN MODE (automatic)                             │
├─────────────────────────────────────────────────────────────┤
│  2. EXISTING WORK DETECTION                                 │
│     - Check for related plans, code, workflows              │
│     - For n8n: query MCP for existing workflows             │
├─────────────────────────────────────────────────────────────┤
│  3. DISCOVERY INTERVIEW                                     │
│     - Core questions (problem, success criteria)            │
│     - Project-type specific questions                       │
│     - As many questions as needed for full context          │
├─────────────────────────────────────────────────────────────┤
│  4. CREATE PLAN DOCUMENT                                    │
│     - Write structured plan to project-plans/<type>/        │
│     - Present to user for review                            │
├─────────────────────────────────────────────────────────────┤
│  5. USER REVIEW                                             │
│     - User approves, requests changes, or adds requirements │
│     - Iterate until approved                                │
├─────────────────────────────────────────────────────────────┤
│  6. EXIT PLAN MODE & HANDOFF                                │
│     - Auto-invoke appropriate builder skill                 │
│     - Begin implementation                                  │
└─────────────────────────────────────────────────────────────┘
```

## Phase 1: Enter Plan Mode

When this skill is invoked, IMMEDIATELY call `EnterPlanMode` tool. No code should be written until the user explicitly approves the plan.

## Phase 2: Existing Work Detection

Before asking questions, check for related existing work. This prevents duplicate effort and informs the interview.

### For All Projects
1. Search `project-plans/` for related plan documents
2. Search relevant code directories for existing implementations

### For dbt Projects
```powershell
# Check existing models
ls docker-projects/home_metrics_dbt/models/**/*.sql
# Check sources
cat docker-projects/home_metrics_dbt/models/staging/sources.yml
```

### For n8n Projects
Use the n8n MCP server to understand current state:
```
mcp__n8n-manager__list_workflows        # See all workflows
mcp__n8n-manager__get_workflow          # Get specific workflow details
mcp__n8n-manager__list_executions       # Check recent execution history
mcp__n8n-manager__get_workflow_stats    # Understand what's working/failing
```

### For Docker Projects
```powershell
# Check existing services
ls docker-projects/*/docker-compose.yml
# Check if service name is already used
docker ps --format "{{.Names}}"
```

**If existing work is found**, acknowledge it:
> "I found an existing [workflow/model/service] called X. Are we extending this or creating something new?"

## Phase 3: Discovery Interview

Conduct a thorough interview to understand the project fully. Ask as many questions as needed to gain correct context.

### Required Questions (Always Ask)

These must be asked unless already answered in the initial prompt:

1. **"What problem are you trying to solve?"**
   - Understand the underlying need, not just the surface request
   - Probe for the "why" behind the request

2. **"What does success look like?"**
   - Concrete, measurable outcomes
   - How will we know when this is done correctly?

### Project Type Detection

After the core questions, determine the project type:

| If the user mentions... | Project Type |
|-------------------------|--------------|
| dbt, model, staging, mart, dimension, fact, SQL transformation | dbt |
| n8n, workflow, automation, trigger, webhook, scheduled task | n8n |
| container, Docker, service, compose, image | docker |
| Otherwise | general |

### dbt-Specific Questions

- What data source is this for? (existing raw table or new?)
- What questions should this data answer?
- What time granularity is needed? (daily, monthly, etc.)
- Does this need to join with existing domains?
- What's the refresh frequency of the source data?
- Are there specific business rules or calculations needed?

### n8n-Specific Questions

- What triggers this workflow? (schedule, webhook, manual, event)
- What external services/APIs are involved?
- What data transformations are needed?
- Where should the output go? (database, notification, file, API)
- Are there existing workflows this should integrate with?
- What should happen when it fails? (retry, alert, fallback)
- Does this need the MCP server for creation/management?

### Docker-Specific Questions

- What image/service are you deploying?
- Does it need persistent data? (volumes)
- Does it need external access? (ports)
- Does it require secrets? (API keys, passwords)
- Does it depend on other containers? (networks)
- Should it auto-start with the system?
- Does it need to connect to home-metrics network for analytics?

### General Follow-Up Questions

- Are there any constraints or limitations to be aware of?
- What's the priority of this work?
- Are there related changes that should happen together?
- Any security considerations?
- Who/what will consume the output?

## Phase 4: Create Plan Document

After gathering sufficient context, create a structured plan document.

### File Naming Convention
```
project-plans/<type>/<descriptive-name>.md
```

If the type subfolder doesn't exist, create it before saving the plan.

Examples:
- `project-plans/dbt/youtube-watch-history-models.md`
- `project-plans/n8n/daily-backup-verification.md`
- `project-plans/docker/jellyfin-media-server.md`

### Plan Document Template

```markdown
# Project: [Descriptive Title]

**Created:** [Date]
**Type:** [dbt | n8n | docker | general]
**Status:** Planning

## Discovery Summary

[2-3 paragraph summary of the discovery interview - what the user needs, why, and key context gathered]

## Scope & Goals

**Goals:**
- [ ] [Primary goal]
- [ ] [Secondary goal]
- [ ] [Additional goal]

**Success Criteria:**
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
- [ ] [Measurable outcome 3]

**Out of Scope:**
- [Explicitly excluded item 1]
- [Explicitly excluded item 2]

## Technical Approach

### Overview
[High-level description of the approach]

### Key Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| [Decision 1] | [Choice] | [Why] |
| [Decision 2] | [Choice] | [Why] |

### Architecture/Design
[Describe the technical design - data flow, component relationships, etc.]

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | Low/Med/High | Low/Med/High | [How to address] |
| [Risk 2] | Low/Med/High | Low/Med/High | [How to address] |

## Task Breakdown

### Phase 1: [Phase Name]
1. [ ] [Task 1]
2. [ ] [Task 2]
3. [ ] [Task 3]

### Phase 2: [Phase Name]
1. [ ] [Task 1]
2. [ ] [Task 2]

### Phase 3: [Phase Name]
1. [ ] [Task 1]
2. [ ] [Task 2]

## Implementation Sequence

```
[Step 1] → [Step 2] → [Step 3] → [Step 4]
                ↓
          [Parallel Step]
```

[Describe the order of operations and any dependencies]

## Expected Output

### Files to Create
- `path/to/file1.ext` - [purpose]
- `path/to/file2.ext` - [purpose]

### Files to Modify
- `path/to/existing.ext` - [what changes]

### Verification Steps
1. [How to verify step 1]
2. [How to verify step 2]
3. [How to verify step 3]

## Post-Implementation

- [ ] Documentation updated
- [ ] Added to startup scripts (if applicable)
- [ ] Tested end-to-end
- [ ] Monitoring/alerts configured (if applicable)
```

## Phase 5: User Review

Present the plan document to the user and explicitly ask for their review:

> "I've created the project plan at `project-plans/<type>/<name>.md`. Please review it and let me know if you'd like any changes, have additional requirements, or if you're ready to approve and begin implementation."

### Handling Feedback

- **Changes requested**: Update the plan document, re-present for review
- **Questions raised**: Answer them, update plan if needed
- **Additional requirements**: Add to scope, update tasks, re-present
- **Approved**: Proceed to Phase 6

## Phase 6: Exit Plan Mode & Handoff

Once the user approves:

1. **Update plan status**
   ```markdown
   **Status:** Approved - Ready for Implementation
   ```

2. **Exit plan mode**
   Call `ExitPlanMode` tool

3. **Auto-invoke the appropriate builder skill**

   | Project Type | Invoke |
   |--------------|--------|
   | dbt | `dbt-query` skill (creates/optimizes models) |
   | n8n | `n8n-workflow` skill (creates workflows via MCP) |
   | docker | `docker-service` skill (sets up containers) |
   | general | Continue manually with implementation |

4. **Reference the plan during implementation**
   - Follow the task breakdown in order
   - Check off tasks as completed
   - Update the plan document with actual files created

## Post-Implementation

After implementation is complete, update the plan document:

```markdown
**Status:** Complete
**Completed:** [Date]

## Files Created/Modified

### Created
- `actual/path/file1.ext` - [what it does]
- `actual/path/file2.ext` - [what it does]

### Modified
- `actual/path/existing.ext` - [what changed]

## Remaining Steps (User Actions)

1. [Any manual steps the user needs to take]
2. [Configuration in UIs, etc.]

## Verification Commands

```powershell
# Command to verify implementation
[actual commands]
```
```

This creates a complete record of the project from planning through implementation.

## Interview Best Practices

1. **Don't ask questions already answered** - If the initial prompt contains clear answers, acknowledge them and ask follow-up questions instead

2. **Probe for depth** - Don't accept surface-level answers; understand the underlying need

3. **Summarize understanding** - Periodically confirm: "So to confirm, you need X because of Y, and success means Z. Is that right?"

4. **Identify assumptions** - Make implicit assumptions explicit: "I'm assuming this needs to run daily - is that correct?"

5. **Look for dependencies** - Ask what else this might affect or depend on

6. **Consider maintenance** - How will this be monitored, updated, or debugged?

## Examples

### Example 1: dbt Project

**User**: "I want to track my YouTube watch history in the analytics database"

**Interview flow**:
1. ✓ "What problem are you trying to solve?" → User wants to see viewing patterns
2. ✓ "What does success look like?" → Monthly summary of hours watched by category
3. Check existing: No YouTube models exist, but there's a pattern from media_activity
4. "Where is the raw data coming from?" → Google Takeout export, CSV files
5. "What dimensions do you care about?" → Video title, channel, category, watch duration
6. "What aggregations?" → Daily and monthly summaries
7. Create plan → `project-plans/dbt/youtube-watch-history-models.md`
8. User approves → Exit plan mode → Invoke `dbt-query` skill

### Example 2: n8n Project

**User**: "I need a workflow that backs up my Plex database daily"

**Interview flow**:
1. Check existing workflows via MCP → Find there's already a media backup workflow
2. "I found an existing media-backup workflow. Are we extending that or creating something new?"
3. ✓ "What does success look like?" → Daily backup in specific location, notification on failure
4. "Where should backups be stored?" → NAS share
5. "Retention policy?" → Keep 7 daily, 4 weekly
6. "How should failures be reported?" → Discord notification
7. Create plan → `project-plans/n8n/plex-database-backup.md`
8. User approves → Exit plan mode → Invoke `n8n-workflow` skill with MCP

## Checklist

- [ ] EnterPlanMode called immediately
- [ ] Existing work checked before interview
- [ ] Core questions asked (problem, success criteria)
- [ ] Project type determined
- [ ] Type-specific questions asked
- [ ] Sufficient context gathered
- [ ] Plan document created in correct folder
- [ ] Plan presented to user for review
- [ ] User approval obtained
- [ ] Plan status updated
- [ ] ExitPlanMode called
- [ ] Appropriate builder skill invoked
