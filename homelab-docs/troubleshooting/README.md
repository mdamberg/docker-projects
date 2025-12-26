# Troubleshooting Documentation

This folder contains documentation for issues encountered in the homelab and their resolutions.

## Purpose

- **Knowledge Base**: Document problems and solutions for future reference
- **Learning**: Understand what went wrong and why
- **Prevention**: Identify patterns and prevent recurring issues
- **Onboarding**: Help others (or future you) understand past decisions

## File Naming Convention

```
YYYY-MM-DD-brief-description.md
```

Examples:
- `2025-12-23-vpn-routing-issue.md`
- `2025-12-15-docker-network-dns-failure.md`
- `2026-01-05-homeassistant-integration-timeout.md`

## Document Template

Each troubleshooting document should include:

### 1. Header
- **Date**: When the issue occurred
- **Status**: RESOLVED / ONGOING / WORKAROUND
- **Severity**: Low / Medium / High / Critical
- **Duration**: How long it took to resolve

### 2. Symptoms
- What was observed
- What broke or stopped working
- Error messages
- User impact

### 3. Root Cause
- What actually caused the problem
- Why it happened
- Technical explanation

### 4. Investigation Process
- Steps taken to diagnose
- What was ruled out
- How the cause was identified
- Commands/tests used

### 5. Resolution
- Immediate fix applied
- Long-term solution
- Configuration changes
- Scripts or tools created

### 6. What We Learned
- Key takeaways
- Best practices identified
- Mistakes to avoid
- Prevention strategies

### 7. Prevention
- How to avoid this in the future
- Monitoring to add
- Scripts to run regularly
- Configuration changes

### 8. Remaining Issues
- Related problems not yet fixed
- Follow-up tasks needed

### 9. Technical Details
- Configuration snapshots
- Network diagrams
- Command outputs
- Logs

### 10. References
- Related documentation
- External resources
- Configuration files
- Scripts

## Quick Reference

### Common Issues

| Date | Issue | Status | Tags |
|------|-------|--------|------|
| 2025-12-23 | System VPN blocking local network | RESOLVED | #networking #vpn #homeassistant |

## Tags

Use tags to categorize issues for easy searching:

- `#networking` - Network connectivity, routing, DNS
- `#docker` - Docker, containers, compose
- `#homeassistant` - Home Assistant specific
- `#vpn` - VPN related issues
- `#storage` - Disk, NAS, storage issues
- `#security` - Security, firewall, certificates
- `#performance` - Slow performance, resource issues
- `#backup` - Backup and restore issues

## Search Tips

```bash
# Find all networking issues
grep -r "#networking" troubleshooting/

# Find resolved issues
grep -r "Status: RESOLVED" troubleshooting/

# Find issues from December 2025
ls troubleshooting/2025-12-*.md
```
