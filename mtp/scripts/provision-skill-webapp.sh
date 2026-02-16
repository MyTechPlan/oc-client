#!/bin/bash
# provision-skill-webapp.sh — Provision web-app skill for a TaaS tenant
# Usage: ./provision-skill-webapp.sh <tenant_id> [display_name]
# Example: ./provision-skill-webapp.sh enki "Dashboard Clínica"

set -euo pipefail

TENANT_ID="${1:?Usage: $0 <tenant_id> [display_name]}"
DISPLAY_NAME="${2:-$TENANT_ID web app}"

# Paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MTP_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$MTP_DIR/data/$TENANT_ID"
WORKSPACE="$DATA_DIR/workspace"
SITES_DIR="$WORKSPACE/sites"
APP_DIR="$SITES_DIR/app"
TEMPLATES_DIR="$MTP_DIR/config/templates/webapp"
ENV_FILE="$MTP_DIR/.env"

# Load env
if [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
fi

SUPABASE_URL="${SUPABASE_URL:?SUPABASE_URL not set in .env}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY not set in .env}"
SUPABASE_ACCESS_TOKEN="${SUPABASE_ACCESS_TOKEN:?SUPABASE_ACCESS_TOKEN not set in .env}"
SUPABASE_PROJECT_REF="${SUPABASE_PROJECT_REF:?SUPABASE_PROJECT_REF not set in .env}"

VERCEL_PROJECT="taas-${TENANT_ID}-app"
DOMAIN="${TENANT_ID}.fran-ai.dev"

echo "🚀 Provisioning web-app skill for tenant: $TENANT_ID"
echo "   Vercel project: $VERCEL_PROJECT"
echo "   Domain: $DOMAIN"

# 1. Create Supabase schema for tenant (if not exists)
echo "📦 Creating Supabase schema tenant_${TENANT_ID}..."
curl -s -X POST "https://api.supabase.com/v1/projects/${SUPABASE_PROJECT_REF}/database/query" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"CREATE SCHEMA IF NOT EXISTS tenant_${TENANT_ID};\"}" > /dev/null

# 2. Create app directory from template
echo "📁 Creating app directory..."
mkdir -p "$APP_DIR"

if [[ -d "$TEMPLATES_DIR" ]]; then
  cp -r "$TEMPLATES_DIR/"* "$APP_DIR/"
  # Substitute placeholders
  find "$APP_DIR" -type f \( -name "*.json" -o -name "*.ts" -o -name "*.tsx" -o -name "*.md" -o -name "*.env*" -o -name "*.html" \) -exec sed -i '' \
    -e "s|{{TENANT_ID}}|${TENANT_ID}|g" \
    -e "s|{{DISPLAY_NAME}}|${DISPLAY_NAME}|g" \
    -e "s|{{SUPABASE_URL}}|${SUPABASE_URL}|g" \
    -e "s|{{SUPABASE_ANON_KEY}}|${SUPABASE_ANON_KEY}|g" \
    -e "s|{{DOMAIN}}|${DOMAIN}|g" \
    {} \;
  echo "   ✅ Template copied and configured"
else
  echo "   ⚠️  No template found at $TEMPLATES_DIR — creating minimal structure"
  # Create minimal React + Vite + Supabase app
  cat > "$APP_DIR/package.json" << EOJSON
{
  "name": "taas-${TENANT_ID}-app",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.49.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "react-router-dom": "^7.2.0"
  },
  "devDependencies": {
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "@vitejs/plugin-react": "^4.3.0",
    "typescript": "^5.7.0",
    "vite": "^6.1.0"
  }
}
EOJSON
  echo "   ✅ Minimal package.json created"
fi

# 3. Create .env.local for the app
cat > "$APP_DIR/.env.local" << EOENV
VITE_SUPABASE_URL=${SUPABASE_URL}
VITE_SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
VITE_TENANT_ID=${TENANT_ID}
EOENV
echo "   ✅ .env.local created"

# 4. Create/link Vercel project (if vercel CLI available)
if command -v vercel &> /dev/null; then
  echo "🔗 Creating Vercel project: $VERCEL_PROJECT..."
  cd "$APP_DIR"
  
  # Link to Vercel (creates project if not exists)
  # Note: may need manual confirmation first time
  echo "   Run 'cd $APP_DIR && vercel link' to connect to Vercel"
  echo "   Then: vercel domains add $DOMAIN"
else
  echo "⚠️  Vercel CLI not found — skip Vercel setup"
fi

# 5. Update tenant's TOOLS.md with web-app info
TOOLS_FILE="$WORKSPACE/TOOLS.md"
if [[ -f "$TOOLS_FILE" ]] && ! grep -q "Web App" "$TOOLS_FILE"; then
  cat >> "$TOOLS_FILE" << EOTOOLS

## Web App
- **Directorio:** workspace/sites/app/
- **Documentación COMPLETA:** lee \`sites/app/SKILL.md\` ANTES de hacer cualquier cambio
- **Dominio:** https://${DOMAIN}
- **Stack:** React + Vite + Supabase (auth con Google)
- **Deploy:** \`git add . && git commit -m "msg" && git push\` (auto-deploy, ~30 seg)
- **⚠️ NO tocar:** \`.env.local\`, \`.vercel/\`, \`vite.config.ts\`, \`tsconfig.json\`, \`main.tsx\`
- **⚠️ NO instalar paquetes** sin ticket aprobado por MTP
- **Tablas nuevas:** pedir via ticket con esquema detallado
- **Si el build falla:** corregir TS errors, NO tocar configs
EOTOOLS
  echo "   ✅ TOOLS.md updated"
fi

echo ""
echo "✅ Web-app skill provisioned for $TENANT_ID"
echo ""
echo "Next steps:"
echo "  1. cd $APP_DIR && npm install"
echo "  2. vercel link (connect to Vercel)"
echo "  3. vercel domains add $DOMAIN"
echo "  4. vercel env add VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY / VITE_TENANT_ID"
echo "  5. git add . && git commit -m 'feat: web-app skill' && git push"
echo "  6. Create app-specific tables in schema tenant_${TENANT_ID}"
