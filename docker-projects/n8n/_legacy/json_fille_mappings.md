  # Mappings for json worflow files in n8n
  ┌─────────────────────────────────────────────────────┬───────────────────┬───────────────┬────────────────────────────────────┐
  │                 Workflow JSON File                  │   Target Table    │   Schedule    │            Data Source             │
  ├─────────────────────────────────────────────────────┼───────────────────┼───────────────┼────────────────────────────────────┤
  │ plex_media_workflows/media_library_workflow.json    │ raw_media_library │ Every 6 hours │ Tautulli, Sonarr, Radarr, Prowlarr │
  ├─────────────────────────────────────────────────────┼───────────────────┼───────────────┼────────────────────────────────────┤
  │ system_health_workflows/system_health_workflow.json │ raw_system_health │ Every 15 min  │ Windows Exporter (port 9182)       │
  ├─────────────────────────────────────────────────────┼───────────────────┼───────────────┼────────────────────────────────────┤
  │ workflow_alerts/workflow_health_monitor.json        │ raw_n8n_alerts    │ Every 1 hour  │ PostgreSQL (self-check)            │
  ├─────────────────────────────────────────────────────┼───────────────────┼───────────────┼────────────────────────────────────┤
  │ workflow_alerts/global_error_catcher.json           │ raw_n8n_alerts    │ On error      │ Any failing workflow               │
  └─────────────────────────────────────────────────────┴───────────────────┴───────────────┴────────────────────────────────────┘

  ## Column mappings for raw_n8n_alerts (used by both alert workflows):
  ┌──────────────┬──────────────────────────┐
  │    Column    │        Expression        │
  ├──────────────┼──────────────────────────┤
  │ alert_type   │ {{ $json.alert_type }}   │
  ├──────────────┼──────────────────────────┤
  │ severity     │ {{ $json.severity }}     │
  ├──────────────┼──────────────────────────┤
  │ source       │ {{ $json.source }}       │
  ├──────────────┼──────────────────────────┤
  │ title        │ {{ $json.title }}        │
  ├──────────────┼──────────────────────────┤
  │ message      │ {{ $json.message }}      │
  ├──────────────┼──────────────────────────┤
  │ triggered_at │ {{ $json.triggered_at }} │
  ├──────────────┼──────────────────────────┤
  │ metadata     │ {{ $json.metadata }}     │
  └──────────────┴──────────────────────────┘