#!/usr/bin/env bash
set -euo pipefail

# ─── backup.sh ────────────────────────────────────────────────
# Backup tenant data directories.
#
# Usage:
#   ./backup.sh                 # backup all tenants + admin
#   ./backup.sh <tenant-name>   # backup a specific tenant
#   ./backup.sh --list          # list existing backups

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TENANTS_FILE="$ROOT_DIR/tenants.conf"
BACKUP_DIR="$ROOT_DIR/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

# ─── List backups ─────────────────────────────────────────────

if [[ "${1:-}" == "--list" ]]; then
  echo "Backups in $BACKUP_DIR:"
  echo ""
  if ls "$BACKUP_DIR"/*.tar.gz 1>/dev/null 2>&1; then
    ls -lh "$BACKUP_DIR"/*.tar.gz | awk '{printf "  %-12s %s\n", $5, $NF}'
  else
    echo "  (none)"
  fi
  exit 0
fi

# ─── Backup function ─────────────────────────────────────────

backup_tenant() {
  local name="$1"
  local data_dir="$ROOT_DIR/data/$name"

  if [[ ! -d "$data_dir" ]]; then
    echo "  Skip: data/$name/ does not exist"
    return
  fi

  local backup_file="$BACKUP_DIR/${name}-${TIMESTAMP}.tar.gz"
  tar -czf "$backup_file" -C "$ROOT_DIR/data" "$name"

  local size
  size=$(du -h "$backup_file" | awk '{print $1}')
  echo "  $name → ${backup_file##*/} ($size)"
}

# ─── Run backups ──────────────────────────────────────────────

if [[ $# -ge 1 && "$1" != "--list" ]]; then
  # Backup specific tenant
  echo "==> Backing up tenant: $1"
  backup_tenant "$1"
else
  # Backup all
  echo "==> Backing up all tenants ($TIMESTAMP)"
  echo ""

  # Admin
  backup_tenant "admin"

  # Tenants
  if [[ -f "$TENANTS_FILE" ]]; then
    while IFS=' ' read -r name port; do
      [[ -z "$name" || "$name" == \#* ]] && continue
      backup_tenant "$name"
    done < "$TENANTS_FILE"
  fi
fi

echo ""
echo "Backups stored in: $BACKUP_DIR/"

# ─── Cleanup old backups (keep last 7 days) ──────────────────

OLD_COUNT=$(find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 2>/dev/null | wc -l)
if [[ "$OLD_COUNT" -gt 0 ]]; then
  echo ""
  echo "Found $OLD_COUNT backup(s) older than 7 days."
  echo "To clean up: find $BACKUP_DIR -name '*.tar.gz' -mtime +7 -delete"
fi
