# MTP SaaS — Multi-Tenant OpenClaw Infrastructure

Multi-tenant Docker Compose infrastructure for running OpenClaw instances as agents-as-a-service. Each client gets their own isolated container with Telegram bot integration.

## Prerequisites

- Docker Engine 24+ with Docker Compose v2
- A server with 4GB+ RAM (Hetzner CX22+ recommended)
- Telegram bot tokens from [@BotFather](https://t.me/BotFather)
- LLM provider API key (Anthropic, OpenAI, or OpenRouter)

## Quick Start

```bash
# 1. Configure admin instance
cp .env.example .env
# Edit .env — fill in ADMIN_* variables

# 2. Create admin data directory
mkdir -p data/admin/.openclaw data/admin/workspace

# 3. Copy config template for admin
cp config/tenant-template.json5 data/admin/.openclaw/openclaw.json

# 4. Start admin
docker compose up -d admin

# 5. Provision your first tenant
./provision-tenant.sh acme 7123456789:AAFxxx sk-ant-api03-xxx
```

## Directory Structure

```
mtp/
├── docker-compose.yml          # Base compose (admin service)
├── docker-compose.override.yml # Auto-generated tenant services
├── .env                        # Secrets (git-ignored)
├── .env.example                # Template for .env
├── tenants.conf                # Registry of active tenants
├── config/
│   └── tenant-template.json5   # Base config for new tenants
├── data/
│   ├── admin/                  # Admin instance data
│   │   ├── .openclaw/          # Config, sessions, credentials
│   │   └── workspace/          # Skills, workspace files
│   └── <tenant>/               # Per-tenant data (same structure)
├── backups/                    # Backup archives
├── provision-tenant.sh         # Add a new tenant
├── remove-tenant.sh            # Remove a tenant
├── status.sh                   # Show all tenant status
├── backup.sh                   # Backup tenant data
├── update.sh                   # Update image + rolling restart
└── _generate-override.sh       # Internal: regenerates override YAML
```

## Scripts

### Provision a tenant

```bash
./provision-tenant.sh <name> <telegram-token> [anthropic-key]

# Example:
./provision-tenant.sh acme 7123456789:AAFxxx sk-ant-api03-xxx
```

This will:
1. Create `data/<name>/` directory structure
2. Generate OpenClaw config from template
3. Add environment variables to `.env`
4. Register in `tenants.conf`
5. Regenerate `docker-compose.override.yml`
6. Start the container
7. Wait for health check

### Remove a tenant

```bash
./remove-tenant.sh <name>              # backs up data, then removes
./remove-tenant.sh <name> --keep-data  # keeps data directory
```

### Check status

```bash
./status.sh          # table view
./status.sh --json   # JSON output for scripting
```

### Backup

```bash
./backup.sh                 # backup all tenants
./backup.sh <name>          # backup specific tenant
./backup.sh --list          # list existing backups
```

### Update OpenClaw

```bash
./update.sh                              # pull latest + rolling restart
./update.sh --image ghcr.io/...:v2.0.0   # use specific image tag
./update.sh --no-pull                     # restart without pulling
```

## Architecture

Each tenant runs in an isolated Docker container:
- **Own filesystem**: config, sessions, credentials, workspace
- **Own Telegram bot**: polling mode (no webhook complexity)
- **Own gateway token**: for admin API access
- **Shared Docker network**: admin can reach tenants internally via `ws://<name>:18789`

```
┌─────────────────────────────────────────────┐
│  Docker Host                                │
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  admin   │  │  acme    │  │  beta    │  │
│  │  :18789  │  │  :18801  │  │  :18802  │  │
│  │  +docker │  │          │  │          │  │
│  │  socket  │  │          │  │          │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  │
│       │  mtp network │             │        │
│       └──────────────┴─────────────┘        │
└─────────────────────────────────────────────┘
```

The admin container has read-only access to the Docker socket for container management. Tenant containers have no Docker socket access.

## Environment Variables

Each tenant uses the pattern `<PREFIX>_<VAR>` where prefix is the uppercase tenant name with hyphens replaced by underscores:

| Variable | Description |
|----------|-------------|
| `<PREFIX>_GATEWAY_TOKEN` | Auto-generated bearer token for WS/HTTP auth |
| `<PREFIX>_TELEGRAM_TOKEN` | Telegram bot token from @BotFather |
| `<PREFIX>_ANTHROPIC_KEY` | Anthropic API key |
| `<PREFIX>_OPENAI_KEY` | OpenAI API key (optional) |
| `<PREFIX>_OPENROUTER_KEY` | OpenRouter API key (optional) |
| `<PREFIX>_PORT` | Host port mapping |

## Tenant Config

The base config template (`config/tenant-template.json5`) uses env var substitution for secrets. Edit it to change defaults for new tenants. Existing tenants keep their config in `data/<name>/.openclaw/openclaw.json`.

Key settings:
- **`channels.telegram.accounts.default.dmPolicy`**: `"open"` (anyone can DM), `"pairing"` (approval required), `"allowlist"`
- **`channels.telegram.accounts.default.groupPolicy`**: `"open"`, `"allowlist"`, `"disabled"`
- **`models.primary`**: Default LLM model for the tenant

## Admin API

The admin can interact with tenant gateways via WebSocket RPC from within the Docker network:

```bash
# From admin container, reach tenant "acme":
# ws://acme:18789 (using acme's gateway token)

# Key RPC methods:
# health         — check tenant health
# config.get     — read tenant config
# config.patch   — modify tenant config
# agent          — send message to tenant's agent
# usage.cost     — get LLM usage/cost data
# sessions.list  — list active sessions
# channels.status — check Telegram connection
```

## Onboarding a New Client

1. **Create Telegram bot**: Open Telegram → @BotFather → `/newbot` → get token (~30s)
2. **Get API key**: Client provides their Anthropic/OpenAI key, or use a shared key
3. **Provision**: `./provision-tenant.sh <name> <telegram-token> <api-key>`
4. **Create Telegram group**: Add bot + client to a shared group
5. **Customize**: Edit `data/<name>/.openclaw/openclaw.json` as needed
6. **Install skills**: Via admin API or direct config edit

## Resource Estimates

| VPS Size | RAM | Idle Tenants | Active (concurrent) |
|----------|-----|-------------|-------------------|
| 4 GB     | CX22 | ~10-15 | 3-5 |
| 8 GB     | CX32 | ~25-30 | 8-12 |
| 16 GB    | CX42 | ~55-65 | 15-25 |

Each idle tenant uses ~200MB RAM. Active LLM calls spike temporarily.
