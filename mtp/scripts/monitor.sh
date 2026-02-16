#!/bin/bash
# monitor.sh — TaaS container health check
# Called by Tobias cron, outputs alerts or "OK"
set -euo pipefail

COMPOSE_DIR="/Users/franzuzz/.openclaw/workspace/oc-client/mtp"
ALERTS=""
REPORT=""

# --- 1. Container Health ---
CONTAINERS=$(docker ps --filter "name=mtp-" --format "{{.Names}}|{{.Status}}" 2>/dev/null)

if [ -z "$CONTAINERS" ]; then
  ALERTS="🔴 CRITICAL: No MTP containers running!"
else
  while IFS='|' read -r name status; do
    if [[ "$status" != *"healthy"* ]]; then
      ALERTS="${ALERTS}🔴 ${name}: ${status}\n"
    fi
    REPORT="${REPORT}${name}: ${status}\n"
  done <<< "$CONTAINERS"
fi

# --- 2. Resource Usage ---
STATS=$(docker stats --no-stream --format "{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}" 2>/dev/null | grep "mtp-")

while IFS='|' read -r name cpu mem memperc; do
  # Strip % for comparison
  mem_num=$(echo "$memperc" | tr -d '% ')
  cpu_num=$(echo "$cpu" | tr -d '% ')
  
  REPORT="${REPORT}${name}: CPU ${cpu}, RAM ${mem} (${memperc})\n"
  
  # Alert if RAM > 80% or CPU > 90%
  if (( $(echo "$mem_num > 80" | bc -l 2>/dev/null || echo 0) )); then
    ALERTS="${ALERTS}🟡 ${name}: RAM alta (${memperc})\n"
  fi
done <<< "$STATS"

# --- 3. Recent Errors (last 2 hours) ---
for container in $(docker ps --filter "name=mtp-" --format "{{.Names}}" 2>/dev/null); do
  ERROR_COUNT=$(docker logs --since 2h "$container" 2>&1 | grep -ci "error\|fatal\|crash\|ECONNREFUSED\|ENOMEM" || true)
  if [ "$ERROR_COUNT" -gt 5 ]; then
    ALERTS="${ALERTS}🟡 ${container}: ${ERROR_COUNT} errores en las últimas 2h\n"
    # Get last 3 errors
    LAST_ERRORS=$(docker logs --since 2h "$container" 2>&1 | grep -i "error\|fatal" | tail -3)
    REPORT="${REPORT}  Últimos errores:\n${LAST_ERRORS}\n"
  fi
done

# --- 4. Restart Count ---
for container in $(docker ps --filter "name=mtp-" --format "{{.Names}}" 2>/dev/null); do
  RESTARTS=$(docker inspect "$container" --format '{{.RestartCount}}' 2>/dev/null || echo 0)
  if [ "$RESTARTS" -gt 0 ]; then
    ALERTS="${ALERTS}🟡 ${container}: ${RESTARTS} restarts\n"
  fi
done

# --- 5. Disk Usage (workspace) ---
for tenant_dir in "$COMPOSE_DIR"/data/*/; do
  tenant=$(basename "$tenant_dir")
  SIZE=$(du -sh "$tenant_dir" 2>/dev/null | cut -f1)
  REPORT="${REPORT}Disk ${tenant}: ${SIZE}\n"
done

# --- Output ---
if [ -n "$ALERTS" ]; then
  echo "⚠️ ALERTAS TaaS:"
  echo -e "$ALERTS"
  echo ""
  echo "📊 Detalle:"
  echo -e "$REPORT"
  exit 1  # Non-zero = hay alertas
else
  echo "✅ TaaS OK — $(docker ps --filter 'name=mtp-' --format '{{.Names}}' | wc -l | tr -d ' ') containers healthy"
  echo -e "$REPORT"
  exit 0
fi
