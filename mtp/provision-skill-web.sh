#!/bin/bash
set -e

TENANT="$1"
if [ -z "$TENANT" ]; then
  echo "Usage: $0 <tenant-name>"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="$SCRIPT_DIR/data/$TENANT/workspace"

echo "Provisioning web-deploy skill for tenant: $TENANT"

# Copy template to sites/web
mkdir -p "$BASE/sites/web"
cp -r "$SCRIPT_DIR/skills/web-deploy/template/"* "$BASE/sites/web/"

# Copy skill (SKILL.md + deploy.sh)
mkdir -p "$BASE/skills/web-deploy"
cp "$SCRIPT_DIR/skills/web-deploy/SKILL.md" "$BASE/skills/web-deploy/"
cp "$SCRIPT_DIR/skills/web-deploy/deploy.sh" "$BASE/skills/web-deploy/"

# Update TOOLS.md
TOOLS="$BASE/TOOLS.md"
if [ ! -f "$TOOLS" ]; then
  echo "# TOOLS.md" > "$TOOLS"
fi

if ! grep -q "web-deploy" "$TOOLS" 2>/dev/null; then
  cat >> "$TOOLS" << 'EOF'

## Web Deploy
- **Skill:** `skills/web-deploy/SKILL.md`
- **Site:** `sites/web/` (Astro)
- **Deploy:** `git -C sites/web add -A && git -C sites/web commit -m "msg" && git -C sites/web push`
- Vercel auto-deploys on push
EOF
fi

echo "Done! web-deploy provisioned for $TENANT"
