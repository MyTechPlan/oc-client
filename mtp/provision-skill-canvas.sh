#!/bin/bash
set -e

TENANT="$1"
if [ -z "$TENANT" ]; then
  echo "Usage: $0 <tenant-name>"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="$SCRIPT_DIR/data/$TENANT/workspace"

echo "Provisioning canvas skill for tenant: $TENANT"

# Copy template to sites/canvas
mkdir -p "$BASE/sites/canvas"
cp -r "$SCRIPT_DIR/skills/canvas/template/"* "$BASE/sites/canvas/"

# Copy skill (SKILL.md + deploy.sh)
mkdir -p "$BASE/skills/canvas"
cp "$SCRIPT_DIR/skills/canvas/SKILL.md" "$BASE/skills/canvas/"
cp "$SCRIPT_DIR/skills/canvas/deploy.sh" "$BASE/skills/canvas/"

# Update TOOLS.md
TOOLS="$BASE/TOOLS.md"
if [ ! -f "$TOOLS" ]; then
  echo "# TOOLS.md" > "$TOOLS"
fi

if ! grep -q "canvas" "$TOOLS" 2>/dev/null; then
  cat >> "$TOOLS" << 'EOF'

## Canvas
- **Skill:** `skills/canvas/SKILL.md`
- **Site:** `sites/canvas/` (React + Vite + Chart.js)
- **Deploy:** `git -C sites/canvas add -A && git -C sites/canvas commit -m "msg" && git -C sites/canvas push`
- Vercel auto-deploys on push
EOF
fi

echo "Done! canvas provisioned for $TENANT"
