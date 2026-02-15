#!/usr/bin/env bash
set -euo pipefail

# ─── update.sh ────────────────────────────────────────────────
# Update OpenClaw image and rolling-restart all tenant containers.
#
# Usage:
#   ./update.sh                          # pull latest + rolling restart
#   ./update.sh --image ghcr.io/...:v2   # use specific image
#   ./update.sh --no-pull                # skip pull (use local image)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TENANTS_FILE="$ROOT_DIR/tenants.conf"
OVERRIDE_FILE="$ROOT_DIR/docker-compose.override.yml"
ENV_FILE="$ROOT_DIR/.env"

# Load .env to get OPENCLAW_IMAGE
if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

IMAGE="${OPENCLAW_IMAGE:-ghcr.io/openclaw/openclaw:main}"
DO_PULL=true

# ─── Parse flags ──────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)
      IMAGE="$2"
      shift 2
      ;;
    --no-pull)
      DO_PULL=false
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--image <image>] [--no-pull]"
      exit 1
      ;;
  esac
done

# Ensure docker compose uses the selected image for this run.
export OPENCLAW_IMAGE="$IMAGE"

# ─── Compose files ────────────────────────────────────────────

COMPOSE_FILES=("-f" "$ROOT_DIR/docker-compose.yml")
if [[ -f "$OVERRIDE_FILE" ]]; then
  COMPOSE_FILES+=("-f" "$OVERRIDE_FILE")
fi

# ─── Pull new image ──────────────────────────────────────────

if [[ "$DO_PULL" == true ]]; then
  echo "==> Pulling image: $IMAGE"
  docker pull "$IMAGE"
  echo ""
fi

# ─── Backup before update ────────────────────────────────────

echo "==> Creating pre-update backup"
"$ROOT_DIR/backup.sh"
echo ""

# ─── Collect services ────────────────────────────────────────

SERVICES=("admin")
if [[ -f "$TENANTS_FILE" ]]; then
  while IFS=' ' read -r name port; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    SERVICES+=("$name")
  done < "$TENANTS_FILE"
fi

# ─── Rolling restart ─────────────────────────────────────────

echo "==> Rolling restart (${#SERVICES[@]} services)"
echo ""

FAILED=()
for service in "${SERVICES[@]}"; do
  echo "  Updating: $service"

  if docker compose "${COMPOSE_FILES[@]}" up -d --no-deps "$service" 2>/dev/null; then
    # Wait for health
    container="mtp-${service}"
    healthy=false
    for i in $(seq 1 6); do
      sleep 5
      status=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}running{{end}}' "$container" 2>/dev/null || echo "unknown")
      if [[ "$status" == "healthy" || "$status" == "running" ]]; then
        healthy=true
        break
      fi
    done

    if [[ "$healthy" == true ]]; then
      echo "    ✓ $service is up"
    else
      echo "    ! $service started but health check pending"
      FAILED+=("$service")
    fi
  else
    echo "    ✗ $service failed to start"
    FAILED+=("$service")
  fi
done

# ─── Summary ─────────────────────────────────────────────────

echo ""
echo "════════════════════════════════════════════════════"
echo "  Update complete: $IMAGE"
echo "  Services: ${#SERVICES[@]} total"

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "  Failed: ${FAILED[*]}"
  echo ""
  echo "  Check logs: docker compose ${COMPOSE_FILES[*]} logs <service>"
else
  echo "  All services healthy"
fi
echo "════════════════════════════════════════════════════"
