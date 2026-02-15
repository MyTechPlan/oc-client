#!/usr/bin/env bash
set -euo pipefail

# ─── remove-tenant.sh ────────────────────────────────────────
# Remove a tenant from the MTP infrastructure.
#
# Usage:
#   ./remove-tenant.sh <tenant-name> [--keep-data]
#
# Options:
#   --keep-data   Don't delete the tenant's data directory (default: prompt)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TENANTS_FILE="$ROOT_DIR/tenants.conf"
ENV_FILE="$ROOT_DIR/.env"
OVERRIDE_FILE="$ROOT_DIR/docker-compose.override.yml"

# ─── Argument parsing ────────────────────────────────────────

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <tenant-name> [--keep-data]"
  exit 1
fi

TENANT_NAME="$1"
KEEP_DATA=false
if [[ "${2:-}" == "--keep-data" ]]; then
  KEEP_DATA=true
fi

# ─── Validation ──────────────────────────────────────────────

if [[ "$TENANT_NAME" == "admin" ]]; then
  echo "Error: cannot remove the admin instance via this script" >&2
  exit 1
fi

if [[ ! -f "$TENANTS_FILE" ]] || ! grep -q "^${TENANT_NAME} " "$TENANTS_FILE"; then
  echo "Error: tenant '$TENANT_NAME' not found in tenants.conf" >&2
  exit 1
fi

ENV_PREFIX=$(echo "$TENANT_NAME" | tr '[:lower:]-' '[:upper:]_')

# ─── Stop the container ──────────────────────────────────────

echo "==> Stopping tenant container: mtp-${TENANT_NAME}"
docker compose -f "$ROOT_DIR/docker-compose.yml" -f "$OVERRIDE_FILE" stop "$TENANT_NAME" 2>/dev/null || true
docker compose -f "$ROOT_DIR/docker-compose.yml" -f "$OVERRIDE_FILE" rm -f "$TENANT_NAME" 2>/dev/null || true

echo "  Container stopped and removed"

# ─── Remove from tenants.conf ────────────────────────────────

sed -i "/^${TENANT_NAME} /d" "$TENANTS_FILE"
echo "  Removed from tenants.conf"

# ─── Remove from .env ────────────────────────────────────────

sed -i "/^${ENV_PREFIX}_/d" "$ENV_FILE"
sed -i "/^# --- Tenant: ${TENANT_NAME}$/d" "$ENV_FILE"
echo "  Removed env vars (prefix: ${ENV_PREFIX}_*)"

# ─── Regenerate docker-compose.override.yml ──────────────────

source "$ROOT_DIR/_generate-override.sh"
echo "  Updated docker-compose.override.yml"

# ─── Handle data directory ───────────────────────────────────

TENANT_DATA="$ROOT_DIR/data/$TENANT_NAME"
if [[ -d "$TENANT_DATA" ]]; then
  if [[ "$KEEP_DATA" == true ]]; then
    echo "  Data preserved at: data/$TENANT_NAME/"
  else
    # Create a backup before deleting
    BACKUP_DIR="$ROOT_DIR/backups"
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/${TENANT_NAME}-$(date +%Y%m%d-%H%M%S)-final.tar.gz"
    tar -czf "$BACKUP_FILE" -C "$ROOT_DIR/data" "$TENANT_NAME"
    echo "  Final backup: $BACKUP_FILE"

    rm -rf "$TENANT_DATA"
    echo "  Data directory removed"
  fi
fi

echo ""
echo "  Tenant '$TENANT_NAME' removed successfully."
