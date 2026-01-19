# Table Grain Definitions for Mart Schema Tables

## DIM TABLES 
1. dim_date
    - Grain: 1 row per day

2. dim_hardware_entities
    - Grain:  1 row per hardware entity 

3. dim_media_entities
    - Grain 1 row per service (plex,sonarr, radarr)

4. dim_n8n_entities
    - Grain: 1 row per workflow (system health metrics collection, Workflow Run Tracker etc.)

5. dim_power_entities
    - Grain: 1 row per electrical entity (server desktop, work/gaming setup)


## FCT TABLES
1. fct_desktop_health
    - Grain: 1 row per quarter hour (15-minute interval) per hostname
    - Primary key: `desktop_health_sk`
2. fct_power_daily
    - 1 row per day (aggregates the average for that day)   - NEED TO JOIN TO DATE SPINE