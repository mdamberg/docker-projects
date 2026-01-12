-- Create schemas for dbt layer separation
-- This script runs on initial database creation only

-- Raw data layer (default public schema used for raw tables)
-- No need to create 'public' schema as it exists by default

-- Staging layer for cleaned/standardized data
CREATE SCHEMA IF NOT EXISTS staging;

-- Intermediate layer for aggregations
CREATE SCHEMA IF NOT EXISTS intermediate;

-- Marts layer for analytics-ready tables
CREATE SCHEMA IF NOT EXISTS marts;

-- Grant permissions to the metrics_user
GRANT USAGE ON SCHEMA staging TO metrics_user;
GRANT USAGE ON SCHEMA intermediate TO metrics_user;
GRANT USAGE ON SCHEMA marts TO metrics_user;

GRANT CREATE ON SCHEMA staging TO metrics_user;
GRANT CREATE ON SCHEMA intermediate TO metrics_user;
GRANT CREATE ON SCHEMA marts TO metrics_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA staging GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO metrics_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA intermediate GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO metrics_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA marts GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO metrics_user;

COMMENT ON SCHEMA staging IS 'Cleaned and standardized data from raw sources';
COMMENT ON SCHEMA intermediate IS 'Aggregated and enriched data';
COMMENT ON SCHEMA marts IS 'Analytics-ready dimensional models';
