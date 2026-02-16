#!/usr/bin/env bash
set -euo pipefail

# ─── status.sh ────────────────────────────────────────────────
# Show status of all MTP tenant containers.
#
# Usage:
#   ./status.sh           # table view
#   ./status.sh --json    # JSON output

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TENANTS_FILE="$ROOT_DIR/tenants.conf"
JSON_MODE=false

if [[ "${1:-}" == "--json" ]]; then
  JSON_MODE=true
fi

# ─── Header ──────────────────────────────────────────────────

get_container_info() {
  local container_name="$1"
  local status uptime health memory

  status=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null || echo "not found")
  if [[ "$status" == "running" ]]; then
    uptime=$(docker inspect --format='{{.State.StartedAt}}' "$container_name" 2>/dev/null | xargs -I{} date -d {} +%s 2>/dev/null || echo "")
    if [[ -n "$uptime" ]]; then
      now=$(date +%s)
      elapsed=$(( now - uptime ))
      if (( elapsed > 86400 )); then
        uptime="$((elapsed / 86400))d"
      elif (( elapsed > 3600 )); then
        uptime="$((elapsed / 3600))h"
      else
        uptime="$((elapsed / 60))m"
      fi
    else
      uptime="-"
    fi
    health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no check{{end}}' "$container_name" 2>/dev/null || echo "-")
    memory=$(docker stats --no-stream --format='{{.MemUsage}}' "$container_name" 2>/dev/null | awk '{print $1}' || echo "-")
  else
    uptime="-"
    health="-"
    memory="-"
  fi

  echo "$status|$uptime|$health|$memory"
}

if [[ "$JSON_MODE" == true ]]; then
  echo "["

  # Admin
  info=$(get_container_info "mtp-admin")
  IFS='|' read -r status uptime health memory <<< "$info"
  echo "  {\"name\":\"admin\",\"container\":\"mtp-admin\",\"port\":\"18789\",\"status\":\"$status\",\"uptime\":\"$uptime\",\"health\":\"$health\",\"memory\":\"$memory\"}"

  # Tenants
  if [[ -f "$TENANTS_FILE" ]]; then
    while IFS=' ' read -r name port; do
      [[ -z "$name" || "$name" == \#* ]] && continue
      info=$(get_container_info "mtp-${name}")
      IFS='|' read -r status uptime health memory <<< "$info"
      echo "  ,{\"name\":\"$name\",\"container\":\"mtp-${name}\",\"port\":\"$port\",\"status\":\"$status\",\"uptime\":\"$uptime\",\"health\":\"$health\",\"memory\":\"$memory\"}"
    done < "$TENANTS_FILE"
  fi

  echo "]"
  exit 0
fi

# ─── Table output ─────────────────────────────────────────────

printf "%-15s %-20s %-7s %-10s %-7s %-10s %s\n" \
  "TENANT" "CONTAINER" "PORT" "STATUS" "UPTIME" "HEALTH" "MEMORY"
printf "%-15s %-20s %-7s %-10s %-7s %-10s %s\n" \
  "───────────────" "────────────────────" "───────" "──────────" "───────" "──────────" "──────────"

# Admin
info=$(get_container_info "mtp-admin")
IFS='|' read -r status uptime health memory <<< "$info"
printf "%-15s %-20s %-7s %-10s %-7s %-10s %s\n" \
  "admin" "mtp-admin" "18789" "$status" "$uptime" "$health" "$memory"

# Tenants
if [[ -f "$TENANTS_FILE" ]]; then
  while IFS=' ' read -r name port; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    info=$(get_container_info "mtp-${name}")
    IFS='|' read -r status uptime health memory <<< "$info"
    printf "%-15s %-20s %-7s %-10s %-7s %-10s %s\n" \
      "$name" "mtp-${name}" "$port" "$status" "$uptime" "$health" "$memory"
  done < "$TENANTS_FILE"
fi

# ─── Summary ─────────────────────────────────────────────────

TOTAL=1  # admin
RUNNING=0
info=$(get_container_info "mtp-admin")
[[ "$info" == running* ]] && RUNNING=$((RUNNING + 1))

if [[ -f "$TENANTS_FILE" ]]; then
  while IFS=' ' read -r name port; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    TOTAL=$((TOTAL + 1))
    info=$(get_container_info "mtp-${name}")
    [[ "$info" == running* ]] && RUNNING=$((RUNNING + 1))
  done < "$TENANTS_FILE"
fi

echo ""
echo "Total: $TOTAL instances ($RUNNING running)"
