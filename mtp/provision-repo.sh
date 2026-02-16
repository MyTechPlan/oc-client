#!/usr/bin/env bash
set -euo pipefail

# ─── provision-repo.sh ───────────────────────────────────────
# Create a GitHub repo for a tenant and initialize with their data.
# Migrates existing data/{tenant}/ into a versioned repo.
#
# Usage:
#   ./provision-repo.sh <tenant-name>
#
# Requires:
#   - MTP_GITHUB_PAT in .env (fine-grained PAT with Admin + Contents RW)
#   - Tenant already provisioned (data/{tenant}/ exists)
#
# Creates:
#   - GitHub repo: MyTechPlan/taas-{tenant}
#   - Initializes git in data/{tenant}/
#   - Adds auto-commit cron suggestion

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$ROOT_DIR/.env"
ORG="MyTechPlan"

# ─── Args ─────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <tenant-name>"
  exit 1
fi

TENANT_NAME="$1"
REPO_NAME="taas-${TENANT_NAME}"
TENANT_DATA="$ROOT_DIR/data/$TENANT_NAME"

# ─── Validate ─────────────────────────────────────────────────

if [[ ! -d "$TENANT_DATA" ]]; then
  echo "Error: Tenant data directory not found: $TENANT_DATA" >&2
  echo "Run provision-tenant.sh first." >&2
  exit 1
fi

# Load .env
if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

GITHUB_PAT="${MTP_GITHUB_PAT:-}"
if [[ -z "$GITHUB_PAT" ]]; then
  echo "Error: MTP_GITHUB_PAT not found in .env" >&2
  exit 1
fi

# ─── Check if repo already exists ────────────────────────────

echo "==> Checking if repo ${ORG}/${REPO_NAME} exists..."
if gh repo view "${ORG}/${REPO_NAME}" --json name &>/dev/null; then
  echo "  Repo already exists. Skipping creation."
else
  echo "==> Creating repo ${ORG}/${REPO_NAME}..."
  gh repo create "${ORG}/${REPO_NAME}" \
    --private \
    --description "TaaS tenant data for ${TENANT_NAME} — managed by MTP" \
    2>&1
  echo "  Created: https://github.com/${ORG}/${REPO_NAME}"
fi

# ─── Initialize git in tenant data ───────────────────────────

echo "==> Initializing git in ${TENANT_DATA}..."

cd "$TENANT_DATA"

# Create .gitignore
cat > .gitignore << 'GITIGNORE'
# Secrets — NEVER commit
.openclaw/credentials/
.openclaw/openclaw.json.bak
.openclaw/exec-approvals.json

# Logs & temp
.openclaw/logs/
.openclaw/canvas/
workspace/.openclaw/

# Large/binary files
*.ogg
*.mp3
*.wav
*.mp4

# Node
node_modules/
GITIGNORE

if [[ ! -d .git ]]; then
  git init -b main
  git remote add origin "https://x-access-token:${GITHUB_PAT}@github.com/${ORG}/${REPO_NAME}.git"
else
  echo "  Git already initialized."
  # Update remote URL with token
  git remote set-url origin "https://x-access-token:${GITHUB_PAT}@github.com/${ORG}/${REPO_NAME}.git" 2>/dev/null || \
    git remote add origin "https://x-access-token:${GITHUB_PAT}@github.com/${ORG}/${REPO_NAME}.git" 2>/dev/null || true
fi

# Configure git user
git config user.email "tobias@mytechplan.com"
git config user.name "Tobias (MTP TaaS)"

# Initial commit
git add -A
git commit -m "Initial commit: tenant ${TENANT_NAME} provisioned by MTP TaaS" --allow-empty 2>/dev/null || \
  git commit -m "Initial commit: tenant ${TENANT_NAME} provisioned by MTP TaaS" 2>/dev/null || \
  echo "  Nothing to commit."

# Push
echo "==> Pushing to ${ORG}/${REPO_NAME}..."
git push -u origin main 2>&1 || git push --set-upstream origin main 2>&1

echo ""
echo "════════════════════════════════════════════════════"
echo "  Repo provisioned: ${ORG}/${REPO_NAME}"
echo "  URL: https://github.com/${ORG}/${REPO_NAME}"
echo "  Local: ${TENANT_DATA}"
echo ""
echo "  Next steps:"
echo "    1. Add auto-commit cron (recommended)"
echo "    2. Run provision-skill-web.sh for web deploy"
echo "    3. Run provision-skill-canvas.sh for canvas"
echo "════════════════════════════════════════════════════"
