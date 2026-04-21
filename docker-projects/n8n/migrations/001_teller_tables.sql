-- Teller Financial Data Integration
-- Creates raw tables for storing Teller API data

-- Ensure raw schema exists
CREATE SCHEMA IF NOT EXISTS raw;

-- Teller Accounts
CREATE TABLE IF NOT EXISTS raw.raw_teller_accounts (
    id SERIAL PRIMARY KEY,
    teller_account_id VARCHAR(255) NOT NULL UNIQUE,
    enrollment_id VARCHAR(255),
    institution_name VARCHAR(255),
    institution_id VARCHAR(255),
    account_name VARCHAR(255),
    account_type VARCHAR(50),
    account_subtype VARCHAR(50),
    account_status VARCHAR(50),
    currency VARCHAR(10),
    last_four VARCHAR(10),
    inserted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Teller Account Balances
CREATE TABLE IF NOT EXISTS raw.raw_teller_balances (
    id SERIAL PRIMARY KEY,
    teller_account_id VARCHAR(255) NOT NULL,
    ledger_balance NUMERIC(12,2),
    available_balance NUMERIC(12,2),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    inserted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_teller_account FOREIGN KEY (teller_account_id)
        REFERENCES raw.raw_teller_accounts(teller_account_id) ON DELETE CASCADE
);

-- Teller Transactions
CREATE TABLE IF NOT EXISTS raw.raw_teller_transactions (
    id SERIAL PRIMARY KEY,
    teller_transaction_id VARCHAR(255) NOT NULL UNIQUE,
    teller_account_id VARCHAR(255) NOT NULL,
    transaction_date DATE NOT NULL,
    description VARCHAR(500),
    amount NUMERIC(12,2) NOT NULL,
    status VARCHAR(50),
    type VARCHAR(50),
    category VARCHAR(100),
    merchant_name VARCHAR(255),
    merchant_category VARCHAR(100),
    running_balance NUMERIC(12,2),
    inserted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_teller_account_txn FOREIGN KEY (teller_account_id)
        REFERENCES raw.raw_teller_accounts(teller_account_id) ON DELETE CASCADE
);

-- Indexes for query performance
CREATE INDEX IF NOT EXISTS idx_teller_transactions_account
    ON raw.raw_teller_transactions(teller_account_id);

CREATE INDEX IF NOT EXISTS idx_teller_transactions_date
    ON raw.raw_teller_transactions(transaction_date DESC);

CREATE INDEX IF NOT EXISTS idx_teller_balances_account
    ON raw.raw_teller_balances(teller_account_id);

CREATE INDEX IF NOT EXISTS idx_teller_balances_recorded
    ON raw.raw_teller_balances(recorded_at DESC);

-- Comments for documentation
COMMENT ON TABLE raw.raw_teller_accounts IS 'Bank accounts connected via Teller API';
COMMENT ON TABLE raw.raw_teller_balances IS 'Daily account balance snapshots from Teller';
COMMENT ON TABLE raw.raw_teller_transactions IS 'Financial transactions from Teller API';
