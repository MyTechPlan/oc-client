#!/usr/bin/env bash
set -euo pipefail

# ─── provision-tenant.sh ─────────────────────────────────────
# Add a new tenant to the MTP multi-tenant infrastructure.
#
# Usage:
#   ./provision-tenant.sh <tenant-name> <telegram-bot-token> [anthropic-key]
#
# Example:
#   ./provision-tenant.sh acme 7123456789:AAF... sk-ant-api03-...

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TENANTS_FILE="$ROOT_DIR/tenants.conf"
ENV_FILE="$ROOT_DIR/.env"
OVERRIDE_FILE="$ROOT_DIR/docker-compose.override.yml"
TEMPLATE_FILE="$ROOT_DIR/config/tenant-template.json5"

# ─── Argument parsing ────────────────────────────────────────

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <tenant-name> <telegram-bot-token> [anthropic-key]"
  echo ""
  echo "  tenant-name       Lowercase alphanumeric + hyphens (e.g., acme, client-a)"
  echo "  telegram-bot-token  From @BotFather (e.g., 7123456789:AAF...)"
  echo "  anthropic-key     Optional Anthropic API key (sk-ant-...)"
  exit 1
fi

TENANT_NAME="$1"
TELEGRAM_TOKEN="$2"
ANTHROPIC_KEY="${3:-}"

# ─── Validation ──────────────────────────────────────────────

if ! [[ "$TENANT_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "Error: tenant name must be lowercase alphanumeric with hyphens (e.g., acme, client-a)" >&2
  exit 1
fi

if [[ "$TENANT_NAME" == "admin" ]]; then
  echo "Error: 'admin' is reserved for the admin instance" >&2
  exit 1
fi

# Check for duplicate
if [[ -f "$TENANTS_FILE" ]] && grep -q "^${TENANT_NAME} " "$TENANTS_FILE"; then
  echo "Error: tenant '$TENANT_NAME' already exists" >&2
  exit 1
fi

# ─── Generate secrets ────────────────────────────────────────

if command -v openssl >/dev/null 2>&1; then
  GATEWAY_TOKEN="$(openssl rand -hex 32)"
else
  GATEWAY_TOKEN="$(python3 -c 'import secrets; print(secrets.token_hex(32))')"
fi

# ─── Determine port ──────────────────────────────────────────

BASE_PORT=18801

if [[ -f "$TENANTS_FILE" ]]; then
  # Find highest used port and increment
  MAX_PORT=$(awk '{print $2}' "$TENANTS_FILE" | sort -n | tail -1)
  if [[ -n "$MAX_PORT" ]]; then
    PORT=$((MAX_PORT + 1))
  else
    PORT=$BASE_PORT
  fi
else
  PORT=$BASE_PORT
fi

# ─── Create data directories ─────────────────────────────────

TENANT_DATA="$ROOT_DIR/data/$TENANT_NAME"
mkdir -p "$TENANT_DATA/.openclaw/credentials"
mkdir -p "$TENANT_DATA/.openclaw/agents"
mkdir -p "$TENANT_DATA/workspace/.openclaw"
mkdir -p "$TENANT_DATA/workspace/skills"
mkdir -p "$TENANT_DATA/workspace/memory"

echo "  Created data directories: data/$TENANT_NAME/"

# ─── Copy workspace templates ────────────────────────────────

TEMPLATES_DIR="$ROOT_DIR/config/templates"
if [[ -d "$TEMPLATES_DIR" ]]; then
  # Copy shared service info (read-only reference)
  cp "$TEMPLATES_DIR/MTP-SERVICE.md" "$TENANT_DATA/workspace/"
  cp "$TEMPLATES_DIR/AGENTS.md" "$TENANT_DATA/workspace/"
  cp "$TEMPLATES_DIR/BOOTSTRAP.md" "$TENANT_DATA/workspace/"
  cp "$TEMPLATES_DIR/HEARTBEAT.md" "$TENANT_DATA/workspace/"

  # Process SOUL template with placeholders
  if [[ -f "$TEMPLATES_DIR/SOUL-template.md" ]]; then
    BOT_DISPLAY_NAME=$(echo "$TENANT_NAME" | sed 's/./\U&/' )  # Capitalize first letter
    sed -e "s/{{BOT_NAME}}/$BOT_DISPLAY_NAME/g" \
        -e "s/{{CLIENT_NAME}}/(pendiente de onboarding)/g" \
        -e "s/{{BOT_CONTEXT}}/Contexto pendiente — se completará durante el onboarding./g" \
        "$TEMPLATES_DIR/SOUL-template.md" > "$TENANT_DATA/workspace/SOUL.md"
  fi

  # Process USER template with placeholders
  if [[ -f "$TEMPLATES_DIR/USER-template.md" ]]; then
    sed -e "s/{{CLIENT_NAME}}/(pendiente)/g" \
        -e "s/{{CLIENT_NICKNAME}}/(pendiente)/g" \
        -e "s/{{CLIENT_EMAIL}}/(pendiente)/g" \
        -e "s/{{CLIENT_TIMEZONE}}/Europe\/Madrid/g" \
        "$TEMPLATES_DIR/USER-template.md" > "$TENANT_DATA/workspace/USER.md"
  fi

  echo "  Copied workspace templates (BOOTSTRAP, SOUL, USER, AGENTS, MTP-SERVICE)"
else
  echo "  Warning: templates directory not found at $TEMPLATES_DIR" >&2
fi

# ─── Generate config from template ───────────────────────────

if [[ -f "$TEMPLATE_FILE" ]]; then
  cp "$TEMPLATE_FILE" "$TENANT_DATA/.openclaw/openclaw.json"
  echo "  Generated config from template"
else
  echo "  Warning: template not found at $TEMPLATE_FILE, creating minimal config" >&2
  cat > "$TENANT_DATA/.openclaw/openclaw.json" <<'EOF'
{
  "models": { "primary": "anthropic/claude-sonnet-4-5-20250929" },
  "channels": {
    "telegram": {
      "enabled": true,
      "accounts": {
        "default": { "dmPolicy": "open", "groupPolicy": "open" }
      }
    }
  },
  "gateway": {
    "auth": { "token": "${OPENCLAW_GATEWAY_TOKEN}" }
  }
}
EOF
fi

# ─── Convert tenant name to env prefix ───────────────────────
# "client-a" → "CLIENT_A"
ENV_PREFIX=$(echo "$TENANT_NAME" | tr '[:lower:]-' '[:upper:]_')

# ─── Add to .env ─────────────────────────────────────────────

touch "$ENV_FILE"

# Remove any existing entries for this tenant (idempotent)
sed -i "/^${ENV_PREFIX}_/d" "$ENV_FILE"
sed -i "/^# --- Tenant: ${TENANT_NAME}/d" "$ENV_FILE"

cat >> "$ENV_FILE" <<EOF
# --- Tenant: ${TENANT_NAME}
${ENV_PREFIX}_GATEWAY_TOKEN=${GATEWAY_TOKEN}
${ENV_PREFIX}_TELEGRAM_TOKEN=${TELEGRAM_TOKEN}
${ENV_PREFIX}_ANTHROPIC_KEY=${ANTHROPIC_KEY}
${ENV_PREFIX}_PORT=${PORT}
EOF

echo "  Added env vars (prefix: ${ENV_PREFIX}_*)"

# ─── Register in tenants.conf ────────────────────────────────

touch "$TENANTS_FILE"
echo "${TENANT_NAME} ${PORT}" >> "$TENANTS_FILE"
echo "  Registered in tenants.conf (port: $PORT)"

# ─── Regenerate docker-compose.override.yml ──────────────────

source "$ROOT_DIR/_generate-override.sh"

echo "  Updated docker-compose.override.yml"

# ─── Start the tenant ────────────────────────────────────────

echo ""
echo "==> Starting tenant container: mtp-${TENANT_NAME}"
docker compose -f "$ROOT_DIR/docker-compose.yml" -f "$OVERRIDE_FILE" up -d "$TENANT_NAME"

# ─── Wait for health ─────────────────────────────────────────

echo "==> Waiting for health check..."
HEALTHY=false
for i in $(seq 1 12); do
  sleep 5
  STATUS=$(docker inspect --format='{{.State.Health.Status}}' "mtp-${TENANT_NAME}" 2>/dev/null || echo "starting")
  if [[ "$STATUS" == "healthy" ]]; then
    HEALTHY=true
    break
  fi
  echo "  Attempt $i/12: $STATUS"
done

echo ""
echo "════════════════════════════════════════════════════"
if [[ "$HEALTHY" == true ]]; then
  echo "  Tenant '$TENANT_NAME' provisioned successfully!"
else
  echo "  Tenant '$TENANT_NAME' provisioned (health check pending)"
  echo "  Check logs: docker compose logs -f $TENANT_NAME"
fi
echo ""
echo "  Container:  mtp-${TENANT_NAME}"
echo "  Host port:  ${PORT}"
echo "  Gateway:    http://localhost:${PORT}"
echo "  Token:      ${GATEWAY_TOKEN}"
echo "  Data:       data/${TENANT_NAME}/"
echo ""
echo "  Internal (from other containers):"
echo "    ws://${TENANT_NAME}:18789"
echo "════════════════════════════════════════════════════"
