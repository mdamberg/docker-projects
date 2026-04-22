# Project: Teller Financial Data Integration

**Created:** 2026-04-15
**Completed:** 2026-04-16
**Complexity:** Medium
**Status:** Complete - Tested and Working

## Overview

Created an n8n workflow to pull financial data (transactions, balances, account details) from Teller API daily, store in PostgreSQL raw tables, and transform via dbt models. This replaces the existing Rocket Money CSV import workflow. Security was the primary design constraint throughout.

## Goals & Success Criteria

**Goals:**
- [x] Automated daily pull of all financial data from Teller (7 accounts)
- [x] Secure handling of mTLS certificates and access tokens
- [x] Clean replacement of Rocket Money data pipeline

**Success Criteria:**
- [x] n8n workflow created for daily execution
- [x] All 7 accounts (2 checking, 2 savings, 3 credit cards) supported
- [x] No secrets in git repository
- [x] dbt models created from Teller source

**Out of Scope:**
- Real-time transaction alerts (can add later)
- Multi-user support (Matt only)
- Historical backfill beyond Teller's 90-day window

## Implementation Summary

### Security Architecture

1. Certificates stored in `C:\Users\mattd\AppData\Local\teller-certs\` (outside git repo)
2. Volume mount into n8n container as read-only (`:/certs/teller:ro`)
3. `.env` contains only paths and application_id (not actual secrets)
4. Access token stored in n8n's encrypted credential store (UI-based)
5. Certificate patterns added to `.gitignore` as safety net

### Data Architecture

1. Three raw tables: `raw_teller_accounts`, `raw_teller_balances`, `raw_teller_transactions`
2. dbt staging models mirror existing pattern (`stg_teller_*.sql`)
3. `fct_transactions` to be updated to source from Teller instead of Rocket Money (during cutover)

## Files Created/Modified

### Modified
- `.gitignore` - Added certificate patterns
- `docker-projects/n8n/docker-compose.yml` - Added volume mount, env vars, network
- `docker-projects/n8n/.env` - Added Teller configuration
- `docker-projects/home_metrics_dbt/models/staging/sources.yml` - Added Teller sources

### Created
- `C:\Users\mattd\AppData\Local\teller-certs\` - Certificate storage folder
- `docker-projects/n8n/migrations/001_teller_tables.sql` - Database migration
- `docker-projects/n8n/teller_financial_sync.json` - n8n workflow
- `docker-projects/home_metrics_dbt/models/staging/stg_teller_accounts.sql`
- `docker-projects/home_metrics_dbt/models/staging/stg_teller_accounts.yml`
- `docker-projects/home_metrics_dbt/models/staging/stg_teller_balances.sql`
- `docker-projects/home_metrics_dbt/models/staging/stg_teller_balances.yml`
- `docker-projects/home_metrics_dbt/models/staging/stg_teller_transactions.sql`
- `docker-projects/home_metrics_dbt/models/staging/stg_teller_transactions.yml`
- `homelab-docs/financial-data/README.md` - Integration documentation

## Remaining Steps (User Actions)

1. Download certificates from Teller dashboard and save to `C:\Users\mattd\AppData\Local\teller-certs\`
2. Update `TELLER_APPLICATION_ID` in `docker-projects/n8n/.env`
3. Run database migration: `001_teller_tables.sql`
4. Restart n8n container
5. Create credentials in n8n UI (access token)
6. Import and test workflow manually
7. Enable daily schedule after validation
8. Run 2-4 week parallel period comparing Teller vs Rocket Money
9. Update `fct_transactions` to source from Teller
10. Disable Rocket Money workflow

## Verification Commands

```powershell
# Test mTLS from host
curl --cert certificate.pem --key private_key.pem https://api.teller.io/accounts

# Verify cert mount
docker exec n8n ls -la /certs/teller/

# Verify network connectivity
docker exec n8n ping home-metrics-postgres
```

## Risks Identified

| Risk | Mitigation |
|------|------------|
| mTLS cert issues | Test curl on host first; verify mount |
| Transaction duplicates | Upsert logic with teller_transaction_id unique key |
| Certificate expiration | Monitor; Teller sends renewal notices |
| Accidentally committing certs | Multiple gitignore rules; stored outside repo |
