# Financial Data Integration

Automated financial data collection using Teller API, replacing manual Rocket Money CSV exports.

## Architecture

```
Teller API → n8n Workflow → PostgreSQL Raw Tables → dbt Staging → dbt Marts → Lightdash
```

### Components

| Component | Purpose | Location |
|-----------|---------|----------|
| Teller API | Bank data aggregation | External service |
| n8n Workflow | Daily data sync | `docker-projects/n8n/teller_financial_sync.json` |
| Raw Tables | Data lake storage | `raw.raw_teller_*` |
| dbt Models | Transformation | `home_metrics_dbt/models/staging/stg_teller_*.sql` |
| Lightdash | Visualization | Existing dashboards |

## Accounts

7 accounts configured across 2 institutions:
- **Checking (2)**: Matt, Jessica
- **Savings (2)**: Matt, Jessica
- **Credit Cards (3)**: Matt WF, Jessica WF, Jessica CapitalOne

## Security

### Certificate Storage

Teller requires mTLS authentication. Certificates stored outside git repository:

```
C:\Users\mattd\AppData\Local\teller-certs\
├── certificate.pem
└── private_key.pem
```

**Never commit certificates to git.** Multiple safeguards in place:
- Certificates stored in `%LOCALAPPDATA%` (outside repo)
- `.gitignore` patterns for `*.pem`, `*.key`, `**/certs/`
- Volume mounted read-only into n8n container

### Access Token

Stored in n8n's encrypted credential store (configured via UI, not files).

### Environment Variables

```bash
# docker-projects/n8n/.env
TELLER_APPLICATION_ID=<your_app_id>  # Not secret
TELLER_CERTS_HOST_PATH=C:/Users/mattd/AppData/Local/teller-certs
```

## Setup

### 1. Certificate Setup

1. Download certs from Teller dashboard
2. Save to `C:\Users\mattd\AppData\Local\teller-certs\`
3. Verify file permissions (current user only)

### 2. Database Setup

Run migration script:
```sql
-- Connect to home-metrics-postgres
psql -h localhost -U postgres -d home_metrics -f docker-projects/n8n/migrations/001_teller_tables.sql
```

### 3. n8n Configuration

1. Restart n8n to pick up volume mount:
   ```bash
   cd docker-projects/n8n
   docker compose down && docker compose up -d
   ```

2. Verify cert mount:
   ```bash
   docker exec n8n ls -la /certs/teller/
   ```

3. Create credentials in n8n UI:
   - **Teller Access Token**: Header Auth with `Authorization: Bearer <token>`
   - **Home Metrics Postgres**: Existing database connection

4. Import workflow:
   - Open n8n UI (http://10.0.0.7:5678)
   - Import `teller_financial_sync.json`
   - Test manually before enabling schedule

### 4. dbt Build

```bash
cd docker-projects/home_metrics_dbt
dbt run --select stg_teller_accounts stg_teller_balances stg_teller_transactions
```

## Data Model

### Raw Tables

| Table | Purpose | Key |
|-------|---------|-----|
| `raw_teller_accounts` | Account metadata | `teller_account_id` |
| `raw_teller_balances` | Daily balance snapshots | `id` (serial) |
| `raw_teller_transactions` | Transactions | `teller_transaction_id` |

### Staging Models

| Model | Description |
|-------|-------------|
| `stg_teller_accounts` | Cleaned accounts with derived `account_holder` |
| `stg_teller_balances` | Balances enriched with account details |
| `stg_teller_transactions` | Transactions with category mapping, deduplication |

## Validation

### Compare with Rocket Money (during parallel run)

```sql
SELECT 'Teller' as source, COUNT(*), SUM(amount)
FROM raw.raw_teller_transactions
WHERE transaction_date >= '2026-01-01'
UNION ALL
SELECT 'Rocket Money', COUNT(*), SUM(amount)*-1
FROM raw.raw_transactions
WHERE transaction_date >= '2026-01-01';
```

### Daily Health Check

```sql
-- Recent transaction counts by account
SELECT
  a.account_name,
  COUNT(*) as txn_count,
  MAX(t.transaction_date) as latest_date
FROM raw.raw_teller_transactions t
JOIN raw.raw_teller_accounts a USING (teller_account_id)
WHERE t.transaction_date >= CURRENT_DATE - 7
GROUP BY a.account_name;
```

## Troubleshooting

### mTLS Connection Failed

1. Verify certs mounted: `docker exec n8n ls -la /certs/teller/`
2. Test from host:
   ```bash
   curl --cert certificate.pem --key private_key.pem https://api.teller.io/accounts
   ```
3. Check cert expiration date

### No Transactions Appearing

1. Check Teller enrollment status (may need re-auth)
2. Verify workflow execution logs in n8n
3. Check PostgreSQL for insert errors

### Workflow Errors

1. Check n8n execution history
2. Discord alerts should fire (if configured)
3. Review error details in workflow execution

## Maintenance

### Certificate Renewal

Teller certificates expire annually. Watch for:
- Email notifications from Teller
- Add expiration date to calendar

### Re-enrollment

If bank connection breaks:
1. Log into Teller dashboard
2. Re-authenticate with bank
3. Enrollment ID may change (workflow handles this)

## Cutover from Rocket Money

After 2-4 week parallel run:

1. Validate Teller transaction counts match Rocket Money
2. Update `fct_transactions` to source from `stg_teller_transactions`
3. Disable Rocket Money CSV import workflow
4. Archive Rocket Money raw data (don't delete)
