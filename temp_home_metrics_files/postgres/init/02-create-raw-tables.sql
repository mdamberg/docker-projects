-- ============================================================================
-- Raw tables for data collection from n8n workflows
-- These tables live in the raw schema
-- ============================================================================

-- Set search path to raw schema for all table creation
SET search_path TO raw;

-- ============================================================================
-- Home Assistant Power Consumption
-- ============================================================================
CREATE TABLE IF NOT EXISTS raw_power_consumption (
    id BIGSERIAL PRIMARY KEY,
    entity_id VARCHAR(255) NOT NULL,
    friendly_name VARCHAR(255),
    state NUMERIC(10, 2),
    unit_of_measurement VARCHAR(50),
    device_class VARCHAR(50),
    recorded_at TIMESTAMP NOT NULL,
    inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    attributes JSONB,
    CONSTRAINT valid_state CHECK (state IS NULL OR state >= 0)
);

CREATE INDEX IF NOT EXISTS idx_power_entity_time ON raw_power_consumption(entity_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_power_inserted ON raw_power_consumption(inserted_at DESC);
CREATE INDEX IF NOT EXISTS idx_power_recorded ON raw_power_consumption(recorded_at DESC);

COMMENT ON TABLE raw_power_consumption IS 'Raw power consumption readings from Home Assistant sensors';
COMMENT ON COLUMN raw_power_consumption.entity_id IS 'Home Assistant entity ID (e.g., sensor.living_room_power)';
COMMENT ON COLUMN raw_power_consumption.recorded_at IS 'Timestamp from Home Assistant when reading was taken';
COMMENT ON COLUMN raw_power_consumption.inserted_at IS 'Timestamp when n8n inserted the record';

-- ============================================================================
-- Media Library Stats (Plex/Sonarr/Radarr)
-- ============================================================================
CREATE TABLE IF NOT EXISTS raw_media_library (
    id BIGSERIAL PRIMARY KEY,
    source VARCHAR(50) NOT NULL,
    media_type VARCHAR(50) NOT NULL,
    library_name VARCHAR(255),
    title VARCHAR(200),
    genre VARCHAR(100),
    year INTEGER,
    overview VARCHAR(500),
    ratings VARCHAR(10),
    recorded_at TIMESTAMP NOT NULL,
    inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_media_source_time ON raw_media_library(source, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_media_type ON raw_media_library(media_type);

COMMENT ON TABLE raw_media_library IS 'Media library statistics from Plex, Sonarr, and Radarr';
COMMENT ON COLUMN raw_media_library.source IS 'Which service provided the data';
COMMENT ON COLUMN raw_media_library.metadata IS 'Additional data like genres, quality profiles, etc.';

-- ============================================================================
-- Media Activity (Watch History)
-- ============================================================================
CREATE TABLE IF NOT EXISTS raw_media_activity (
    id BIGSERIAL PRIMARY KEY,
    source VARCHAR(50) NOT NULL DEFAULT 'plex',
    user_name VARCHAR(255),
    media_type VARCHAR(50),
    title VARCHAR(500),
    series_title VARCHAR(500),
    duration_seconds INTEGER,
    watched_at TIMESTAMP NOT NULL,
    inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_activity_user_time ON raw_media_activity(user_name, watched_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_watched ON raw_media_activity(watched_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_media_type ON raw_media_activity(media_type);

COMMENT ON TABLE raw_media_activity IS 'Watch/listen history from Plex';
COMMENT ON COLUMN raw_media_activity.metadata IS 'Additional details like device, client, quality, etc.';

-- ============================================================================
-- Pi-hole DNS Metrics
-- ============================================================================
CREATE TABLE IF NOT EXISTS raw_pihole_metrics (
    id BIGSERIAL PRIMARY KEY,
    pihole_instance VARCHAR(100) DEFAULT 'primary',
    total_queries INTEGER,
    blocked_queries INTEGER,
    percent_blocked NUMERIC(5, 2),
    unique_domains INTEGER,
    unique_clients INTEGER,
    recorded_at TIMESTAMP NOT NULL,
    inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    top_blocked_domains JSONB,
    top_queries JSONB,
    metadata JSONB,
    CONSTRAINT valid_queries CHECK (total_queries >= 0 AND blocked_queries >= 0),
    CONSTRAINT valid_percent CHECK (percent_blocked >= 0 AND percent_blocked <= 100)
);

CREATE INDEX IF NOT EXISTS idx_pihole_time ON raw_pihole_metrics(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_pihole_instance ON raw_pihole_metrics(pihole_instance, recorded_at DESC);

COMMENT ON TABLE raw_pihole_metrics IS 'DNS blocking statistics from Pi-hole';
COMMENT ON COLUMN raw_pihole_metrics.top_blocked_domains IS 'Array of most blocked domains with counts';
COMMENT ON COLUMN raw_pihole_metrics.top_queries IS 'Array of most queried domains';

-- ============================================================================
-- System Health
-- ============================================================================
CREATE TABLE IF NOT EXISTS raw_system_health (
    id BIGSERIAL PRIMARY KEY,
    hostname VARCHAR(255) NOT NULL,
    recorded_at TIMESTAMP NOT NULL,
    inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    cpu_percent NUMERIC(5, 2),
    memory_percent NUMERIC(5, 2),
    disk_percent NUMERIC(5, 2),
    temperature_c NUMERIC(5, 2),
    windows_logical_disk_read_latency_seconds_total NUMERIC(10, 4),
    windows_logical_disk_write_latency_seconds_total NUMERIC(10, 4),
    windows_logical_disk_read_bytes_total BIGINT,
    windows_logical_disk_write_bytes_total BIGINT,
    windows_net_bytes_received_total BIGINT,
    windows_net_bytes_sent_total BIGINT,
    windows_system_processor_queue_length NUMERIC(10, 2),
    windows_os_paging_free_bytes BIGINT,
    windows_memory_commit_limit BIGINT,
    windows_memory_committed_bytes BIGINT,
    metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_health_host_time ON raw_system_health(hostname, recorded_at DESC);

COMMENT ON TABLE raw_system_health IS 'System health metrics for monitoring server performance';

-- ============================================================================
-- N8N Workflow Runs
-- ============================================================================
CREATE TABLE IF NOT EXISTS raw_n8n_workflow_runs (
    id BIGSERIAL PRIMARY KEY,
    workflow_id VARCHAR(100) NOT NULL,
    workflow_name VARCHAR(255),
    source VARCHAR(100),
    status VARCHAR(50),
    started_at TIMESTAMP NOT NULL,
    finished_at TIMESTAMP,
    inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_workflow_runs_workflow ON raw_n8n_workflow_runs(workflow_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_workflow_runs_status ON raw_n8n_workflow_runs(status, started_at DESC);

COMMENT ON TABLE raw_n8n_workflow_runs IS 'Execution history for n8n workflows';

-- ============================================================================
-- N8N Alerts
-- ============================================================================
CREATE TABLE IF NOT EXISTS raw_n8n_alerts (
    id BIGSERIAL PRIMARY KEY,
    alert_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) DEFAULT 'warning',
    source VARCHAR(100),
    title VARCHAR(500),
    message TEXT,
    triggered_at TIMESTAMP NOT NULL,
    resolved_at TIMESTAMP,
    inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_alerts_type_time ON raw_n8n_alerts(alert_type, triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_severity ON raw_n8n_alerts(severity, triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_source ON raw_n8n_alerts(source, triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_unresolved ON raw_n8n_alerts(resolved_at) WHERE resolved_at IS NULL;

COMMENT ON TABLE raw_n8n_alerts IS 'Unified alerts table for workflow failures, data staleness, and threshold breaches';

-- ============================================================================
-- Hardware Sensors (LibreHardwareMonitor)
-- ============================================================================
CREATE TABLE IF NOT EXISTS raw_hardware_sensors (
    id BIGSERIAL PRIMARY KEY,
    hostname VARCHAR(100),
    sensor_type VARCHAR(50) NOT NULL,
    sensor_name VARCHAR(200) NOT NULL,
    sensor_id VARCHAR(200),
    value NUMERIC,
    value_min NUMERIC,
    value_max NUMERIC,
    unit VARCHAR(20),
    hardware_name VARCHAR(200),
    hardware_type VARCHAR(50),
    recorded_at TIMESTAMP NOT NULL,
    inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_hardware_sensors_type ON raw_hardware_sensors(sensor_type, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_hardware_sensors_name ON raw_hardware_sensors(sensor_name, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_hardware_sensors_host ON raw_hardware_sensors(hostname, recorded_at DESC);

COMMENT ON TABLE raw_hardware_sensors IS 'Hardware sensor data from LibreHardwareMonitor (temperatures, fans, voltages, power)';

-- ============================================================================
-- Date Dimension
-- ============================================================================
CREATE TABLE IF NOT EXISTS dim_date (
    date_id INT PRIMARY KEY NOT NULL,
    date_day DATE NOT NULL,
    day_of_week VARCHAR(10) NOT NULL,
    day_of_week_num SMALLINT NOT NULL,
    month_start_date DATE NOT NULL,
    month_end_date DATE NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    month_number SMALLINT NOT NULL,
    year_start_date DATE NOT NULL,
    year_num INT NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

COMMENT ON TABLE dim_date IS 'Date dimension for time-based analytics';

-- ============================================================================
-- Data Freshness View (uses fully qualified schema names)
-- ============================================================================
CREATE OR REPLACE VIEW raw.v_data_freshness AS
SELECT
    'raw_power_consumption' AS table_name,
    MAX(recorded_at) AS last_recorded,
    MAX(inserted_at) AS last_inserted,
    COUNT(*) AS total_rows,
    NOW() - MAX(inserted_at) AS staleness
FROM raw.raw_power_consumption
UNION ALL
SELECT
    'raw_media_library',
    MAX(recorded_at),
    MAX(inserted_at),
    COUNT(*),
    NOW() - MAX(inserted_at)
FROM raw.raw_media_library
UNION ALL
SELECT
    'raw_media_activity',
    MAX(watched_at),
    MAX(inserted_at),
    COUNT(*),
    NOW() - MAX(inserted_at)
FROM raw.raw_media_activity
UNION ALL
SELECT
    'raw_pihole_metrics',
    MAX(recorded_at),
    MAX(inserted_at),
    COUNT(*),
    NOW() - MAX(inserted_at)
FROM raw.raw_pihole_metrics;

COMMENT ON VIEW raw.v_data_freshness IS 'Monitor data pipeline health and freshness';

-- ============================================================================
-- Grant Permissions
-- ============================================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA raw TO metrics_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA raw TO metrics_user;
GRANT SELECT ON raw.v_data_freshness TO metrics_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA raw GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO metrics_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA raw GRANT USAGE, SELECT ON SEQUENCES TO metrics_user;

-- Reset search path
SET search_path TO public, raw;




-- ============================================================================
-- Finances
-- ============================================================================



CREATE TABLE IF NOT EXISTS raw.raw_transactions (                                                                                                                                                             id BIGSERIAL PRIMARY KEY,
      transaction_date DATE NOT NULL,                                                                                                                                                                           original_date DATE,
      account_type VARCHAR(100),                                                                                                                                                                          
      account_name VARCHAR(255),
      account_number VARCHAR(50),
      institution_name VARCHAR(255),
      name VARCHAR(500),
      custom_name VARCHAR(500),
      amount NUMERIC(12, 2),
      description TEXT,
      category VARCHAR(255),
      note TEXT,
      ignored_from VARCHAR(255),
      tax_deductible BOOLEAN,
      transaction_tags VARCHAR(500),
      inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
  );

  CREATE INDEX IF NOT EXISTS idx_transactions_date ON raw.raw_transactions(transaction_date DESC);
  CREATE INDEX IF NOT EXISTS idx_transactions_category ON raw.raw_transactions(category);
  CREATE INDEX IF NOT EXISTS idx_transactions_account ON raw.raw_transactions(account_name);
  CREATE INDEX IF NOT EXISTS idx_transactions_institution ON raw.raw_transactions(institution_name);

  GRANT SELECT, INSERT, UPDATE, DELETE ON raw.raw_transactions TO metrics_user;
  GRANT USAGE, SELECT ON raw.raw_transactions_id_seq TO metrics_user;