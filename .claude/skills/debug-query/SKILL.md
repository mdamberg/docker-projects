---
name: debugger
description: Systematic root cause analysis for SQL, Python, JavaScript, and YAML errors
---

# Debugger

Systematic process for identifying root causes of errors (both silent and explicit) across SQL, Python, JavaScript, and YAML/Docker Compose. Considers the full data pipeline and upstream/downstream effects.

## When to Use

- Explicit errors: stack traces, exceptions, failed queries
- Silent failures: unexpected nulls, missing data, wrong results, no output
- Unexpected behavior: code runs but produces incorrect results
- Performance issues: slow queries, timeouts, memory problems

## Process

### Phase 1: Reproduce and Isolate

1. **Confirm the error is reproducible**
   - Run the failing code/query in isolation
   - Note exact error messages, line numbers, timestamps

2. **Identify the failure point**
   - Which specific line/query/function fails?
   - Is it consistent or intermittent?

3. **Check recent changes**
   - What changed since it last worked?
   - Review git diff for relevant files

### Phase 2: Trace Data Flow (Upstream)

4. **Map the data lineage**
   - What inputs feed into the failing component?
   - Trace back: source tables → transformations → current point

5. **Validate upstream data**
   - Are source tables/APIs returning expected data?
   - Check for nulls, type mismatches, missing records
   - Verify row counts at each transformation step

6. **Check dependencies**
   - Are all required services/containers running?
   - Are connections (DB, API, file paths) valid?
   - Environment variables set correctly?

### Phase 3: Analyze the Failure Point

7. **Examine the specific error**
   - Parse the full error message/stack trace
   - Identify the root exception (not just the surface error)

8. **Add diagnostic output**
   - Insert logging/print statements at key points
   - For SQL: run subqueries/CTEs independently
   - For Python/JS: check variable states before failure

9. **Test with minimal input**
   - Reduce to smallest failing case
   - Hardcode known-good values to isolate the issue

### Phase 4: Assess Downstream Impact

10. **Identify what depends on this component**
    - What queries/functions consume this output?
    - Which dashboards, reports, or services rely on it?

11. **Check for cascading failures**
    - Are downstream processes failing silently?
    - Verify data integrity in dependent tables/outputs

### Phase 5: Fix and Verify

12. **Implement the fix**
    - Address root cause, not just symptoms
    - Consider edge cases the fix might introduce

13. **Test the full pipeline**
    - Run upstream → failure point → downstream
    - Verify data integrity at each step

14. **Document if non-obvious**
    - Add inline comment only if the fix isn't self-explanatory

## Language-Specific Guidance

### SQL

| Issue | Diagnostic Approach |
|-------|---------------------|
| Wrong results | Run each CTE independently, check row counts |
| Nulls appearing | Check JOIN conditions, use COALESCE to trace |
| Duplicates | Look for missing GROUP BY or bad JOIN keys |
| Performance | Check EXPLAIN plan, look for table scans |

**Common culprits:**
- JOIN creating cartesian product (missing/wrong key)
- WHERE clause filtering out needed rows
- Aggregation without proper GROUP BY
- Data type mismatches in comparisons

**Debug pattern:**
```sql
-- Break CTEs into separate queries
WITH step1 AS (...) SELECT * FROM step1;  -- Check output
WITH step1 AS (...), step2 AS (...) SELECT * FROM step2;  -- Next step
```

### Python

| Issue | Diagnostic Approach |
|-------|---------------------|
| Silent failure | Add try/except with logging, check return values |
| Wrong output | Print intermediate variables, use debugger |
| Import errors | Check virtual env, package versions |
| Type errors | Print type() of variables at failure point |

**Common culprits:**
- Mutable default arguments
- Variable scope issues (global vs local)
- Off-by-one errors in loops/slices
- None returned instead of expected value

**Debug pattern:**
```python
# Add before failure point
print(f"DEBUG: var={var}, type={type(var)}, len={len(var) if hasattr(var, '__len__') else 'N/A'}")
```

### JavaScript

| Issue | Diagnostic Approach |
|-------|---------------------|
| undefined errors | Check object property access chain |
| Async issues | Verify await/then chains, check Promise rejections |
| Silent failure | Add .catch() to promises, check console |
| Wrong this | Log this context, check arrow vs regular functions |

**Common culprits:**
- Missing await on async functions
- Accessing properties on null/undefined
- Closure capturing wrong variable
- Event handler losing context

**Debug pattern:**
```javascript
// Add before failure point
console.log('DEBUG:', { var, typeofVar: typeof var, keys: Object.keys(var || {}) });
```

### YAML / Docker Compose

| Issue | Diagnostic Approach |
|-------|---------------------|
| Container won't start | Check `docker compose logs <service>` for startup errors |
| Service not found | Verify service name matches between depends_on and service definition |
| Env var not loading | Confirm .env file is in same directory as compose file |
| Port conflict | Run `netstat -ano \| findstr :<port>` to find conflict |
| Volume mount fails | Check path format (use `/` not `\`), verify host path exists |
| Network connectivity | Ensure containers are on same network |

**Common culprits:**
- Indentation errors (YAML is whitespace-sensitive)
- Tabs instead of spaces
- Missing quotes around values with special characters (`:`, `@`, `#`)
- Wrong image name or tag
- Environment variable typo (case-sensitive)
- Relative path when absolute needed (or vice versa)
- `depends_on` doesn't wait for service to be *ready*, just *started*

**Debug pattern:**
```powershell
# Validate compose file syntax
docker compose config

# Check what compose sees (with env vars resolved)
docker compose config --resolve-image-digests

# Inspect running container
docker inspect <container-name>

# Check container can reach other containers
docker exec -it <container> ping <other-container>
```

**Indentation validation:**
```yaml
# Correct (2-space indent, consistent)
services:
  myservice:
    image: nginx
    ports:
      - "8080:80"

# Wrong (mixed indentation)
services:
  myservice:
   image: nginx    # 1 space - will fail
    ports:         # 2 spaces - inconsistent
```

## Checklist

- [ ] Error reproduced and isolated
- [ ] Upstream data validated
- [ ] Dependencies confirmed working
- [ ] Root cause identified (not just symptom)
- [ ] Fix addresses root cause
- [ ] Downstream impact assessed
- [ ] Full pipeline tested after fix
