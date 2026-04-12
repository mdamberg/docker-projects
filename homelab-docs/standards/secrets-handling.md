# Secrets Handling

## Current Approach

Secrets (passwords, API keys, tokens) are stored in `.env` files within each service's directory. These files are loaded by Docker Compose at runtime.

### What's in .env files

Each service has its own `.env` containing credentials specific to that service:

```
# Example pattern
SERVICE_PASSWORD=somepassword
API_KEY=abc123
TZ=America/Chicago
```

### What keeps .env files safe

- `.env` files are listed in `.gitignore` — they are not committed to version control
- Only exist on the local machine (the server)
- Backed up via Duplicati as part of the Docker configs backup

---

## Rules

**Do not commit secrets to git.** If a `.env` file accidentally gets committed, rotate the credential immediately.

**Do not use default passwords in production.** Several services ship with defaults (e.g., `changeme`, `admin`). These must be changed before a service is actively used:
- Linkding: `LD_SUPERUSER_PASSWORD` defaults to `changeme` — change this
- phpIPAM: Default admin password is `ipamadmin` — change this
- Lightdash: `LIGHTDASH_SECRET` defaults to `changemeplease123456789` — set a real secret

**Do not store secrets in docker-compose.yml directly.** Always reference them via environment variables from `.env`.

---

## Where Secrets Live by Service

| Service | Credentials Location |
|---------|---------------------|
| n8n | `docker-projects/n8n/.env` |
| Media Stack | `docker-projects/media_stack/.env` |
| Backups (Duplicati) | `docker-projects/backups/.env` |
| Pi-hole | No .env — password set via web UI |
| Home Assistant | `docker-projects/home_assist/.env` |
| Linkding | `docker-projects/linkding/.env` |
| phpIPAM | `docker-projects/phpipam/.env` |
| Lightdash | `docker-projects/lightdash/.env` |
| MCP Server | `docker-projects/mcp_server/.env` |
| WireGuard | `docker-projects/wireguard/.env` (deprecated) |

---

## Backup of Secrets

Secrets are included in the Duplicati backup because the Docker project directory (including `.env` files) is part of the backup source. Duplicati backups are encrypted.

If restoring from scratch, restore the backup first — then `docker-compose up -d` will pick up the existing `.env` files.

---

## Future Improvements

- Consider moving to Docker secrets or a secrets manager (e.g., Infisical, Vault) for more sensitive credentials
- Enable 2FA on any service that supports it (especially remote-accessible ones)
- Audit all `.env` files periodically to rotate old or default passwords
