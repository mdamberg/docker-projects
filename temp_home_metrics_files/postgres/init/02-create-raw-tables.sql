-- Raw tables for data collection from n8n workflows
-- These tables live in the public schema by default

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

CREATE INDEX idx_power_entity_time ON raw_power_consumption(entity_id, recorded_at DESC);
CREATE INDEX idx_power_inserted ON raw_power_consumption(inserted_at DESC);
CREATE INDEX idx_power_recorded ON raw_power_consumption(recorded_at DESC);

COMMENT ON TABLE raw_power_consumption IS 'Raw power consumption readings from Home Assistant sensors';
COMMENT ON COLUMN raw_power_consumption.entity_id IS 'Home Assistant entity ID (e.g., sensor.living_room_power)';
COMMENT ON COLUMN raw_power_consumption.recorded_at IS 'Timestamp from Home Assistant when reading was taken';
COMMENT ON COLUMN raw_power_consumption.inserted_at IS 'Timestamp when n8n inserted the record';

-- ============================================================================
-- Media Library Stats (Plex/Sonarr/Radarr)
-- ============================================================================
CREATE TABLE IF NOT EXISTS raw_media_library (
    id BIGSERIAL PRIMARY KEY,
    source VARCHAR(50) NOT NULL, -- 'plex', 'sonarr', 'radarr'
    media_type VARCHAR(50) NOT NULL, -- 'movie', 'tv_show', 'episode', 'music'
    library_name VARCHAR(255),
    item_count INTEGER,
    total_size_bytes BIGINT,
    recorded_at TIMESTAMP NOT NULL,
    inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    metadata JSONB,
    CONSTRAINT valid_counts CHECK (item_count IS NULL OR item_count >= 0),
    CONSTRAINT valid_size CHECK (total_size_bytes IS NULL OR total_size_bytes >= 0)
);

CREATE INDEX idx_media_source_time ON raw_media_library(source, recorded_at DESC);
CREATE INDEX idx_media_type ON raw_media_library(media_type);

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
    media_type VARCHAR(50), -- 'movie', 'episode', 'track'
    title VARCHAR(500),
    series_title VARCHAR(500), -- For TV episodes
    duration_seconds INTEGER,
    watched_at TIMESTAMP NOT NULL,
    inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    metadata JSONB
);

CREATE INDEX idx_activity_user_time ON raw_media_activity(user_name, watched_at DESC);
CREATE INDEX idx_activity_watched ON raw_media_activity(watched_at DESC);
CREATE INDEX idx_activity_media_type ON raw_media_activity(media_type);

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

CREATE INDEX idx_pihole_time ON raw_pihole_metrics(recorded_at DESC);
CREATE INDEX idx_pihole_instance ON raw_pihole_metrics(pihole_instance, recorded_at DESC);

COMMENT ON TABLE raw_pihole_metrics IS 'DNS blocking statistics from Pi-hole';
COMMENT ON COLUMN raw_pihole_metrics.top_blocked_domains IS 'Array of most blocked domains with counts';
COMMENT ON COLUMN raw_pihole_metrics.top_queries IS 'Array of most queried domains';

-- ============================================================================
-- System Health (Optional - for future expansion)
-- ============================================================================
CREATE TABLE IF NOT EXISTS raw_system_health (
    id BIGSERIAL PRIMARY KEY,
    hostname VARCHAR(255) NOT NULL,
    cpu_percent NUMERIC(5, 2),
    memory_percent NUMERIC(5, 2),
    disk_percent NUMERIC(5, 2),
    temperature_c NUMERIC(5, 2),
    recorded_at TIMESTAMP NOT NULL,
    inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    metadata JSONB
);

CREATE INDEX idx_health_host_time ON raw_system_health(hostname, recorded_at DESC);

COMMENT ON TABLE raw_system_health IS 'System health metrics for monitoring server performance';

-- ============================================================================
-- Data Quality Views
-- ============================================================================

-- View to check for data freshness
CREATE OR REPLACE VIEW v_data_freshness AS
SELECT
    'raw_power_consumption' AS table_name,
    MAX(recorded_at) AS last_recorded,
    MAX(inserted_at) AS last_inserted,
    COUNT(*) AS total_rows,
    NOW() - MAX(inserted_at) AS staleness
FROM raw_power_consumption
UNION ALL
SELECT
    'raw_media_library',
    MAX(recorded_at),
    MAX(inserted_at),
    COUNT(*),
    NOW() - MAX(inserted_at)
FROM raw_media_library
UNION ALL
SELECT
    'raw_media_activity',
    MAX(watched_at),
    MAX(inserted_at),
    COUNT(*),
    NOW() - MAX(inserted_at)
FROM raw_media_activity
UNION ALL
SELECT
    'raw_pihole_metrics',
    MAX(recorded_at),
    MAX(inserted_at),
    COUNT(*),
    NOW() - MAX(inserted_at)
FROM raw_pihole_metrics;

COMMENT ON VIEW v_data_freshness IS 'Monitor data pipeline health and freshness';

-- ============================================================================
-- Grant Permissions
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO metrics_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO metrics_user;
GRANT SELECT ON v_data_freshness TO metrics_user;

-- Set default privileges for future tables in public schema
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO metrics_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO metrics_user;
