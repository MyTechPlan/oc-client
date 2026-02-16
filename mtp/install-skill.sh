#!/usr/bin/env bash
set -euo pipefail

# ─── install-skill.sh ────────────────────────────────────────
# Install a skill into a TaaS tenant workspace.
#
# Usage:
#   ./install-skill.sh <tenant> [skill]
#
# If skill is omitted, shows interactive menu.
#
# Examples:
#   ./install-skill.sh vesta              # interactive
#   ./install-skill.sh vesta web-deploy   # direct
#   ./install-skill.sh vesta web-app      # direct
#   ./install-skill.sh enki python-sandbox # direct

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$ROOT_DIR/.env"
SKILLS_DIR="$ROOT_DIR/skills"
TEMPLATES_DIR="$ROOT_DIR/config/templates"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}" >&2; }
info() { echo -e "${CYAN}ℹ️  $1${NC}"; }

# ─── Skill registry (bash 3 compatible) ──────────────────────

skill_desc() {
  case "$1" in
    web-deploy)      echo "Sitio web estático (Astro + Vercel)" ;;
    web-app)         echo "Web app con DB y auth (React + Supabase + Vercel)" ;;
    python-sandbox)  echo "Ejecución segura de código Python" ;;
    monday)          echo "Gestión de boards y tareas en Monday.com (GraphQL)" ;;
    *) echo "Skill desconocida" ;;
  esac
}

skill_scope() {
  case "$1" in
    web-deploy)      echo "Landing pages, portfolios, blogs, CVs. El bot edita archivos .astro y deploya con un script. NO puede instalar paquetes ni tocar configs." ;;
    web-app)         echo "Apps interactivas con base de datos y login Google. CRUD, dashboards, formularios. El bot edita React/TS y deploya. NO puede crear tablas (ticket a MTP)." ;;
    python-sandbox)  echo "Cálculos, estadísticas, análisis de datos, conversiones. Ejecuta Python en sandbox seguro. SIN acceso a archivos, red, o sistema." ;;
    monday)          echo "Leer boards/items, crear tareas, actualizar estados, agregar comentarios en Monday.com. Requiere API token del cliente." ;;
    *) echo "" ;;
  esac
}

is_valid_skill() {
  case "$1" in
    web-deploy|web-app|python-sandbox|monday) return 0 ;;
    *) return 1 ;;
  esac
}

AVAILABLE_SKILLS="web-deploy web-app python-sandbox monday"

# ─── Args ─────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <tenant> [skill]"
  echo ""
  echo "Available skills:"
  for s in $AVAILABLE_SKILLS; do
    echo "  $s — $(skill_desc "$s")"
  done
  exit 1
fi

TENANT="$1"
SKILL="${2:-}"

DATA_DIR="$ROOT_DIR/data/$TENANT"
WORKSPACE="$DATA_DIR/workspace"
TOOLS_FILE="$WORKSPACE/TOOLS.md"

# ─── Validate tenant ─────────────────────────────────────────

if [[ ! -d "$WORKSPACE" ]]; then
  err "Tenant '$TENANT' not found (no workspace at data/$TENANT/workspace)"
  exit 1
fi

info "Tenant: $TENANT"

# ─── Interactive menu if no skill specified ───────────────────

if [[ -z "$SKILL" ]]; then
  echo ""
  echo "Skills disponibles para $TENANT:"
  echo ""
  idx=1
  for s in $AVAILABLE_SKILLS; do
    installed=""
    if [[ -f "$WORKSPACE/skills/$s/SKILL.md" ]]; then
      installed=" ${GREEN}[INSTALADA]${NC}"
    fi
    echo -e "  ${idx}. ${CYAN}$s${NC} — $(skill_desc "$s")${installed}"
    echo -e "     Scope: $(skill_scope "$s")"
    echo ""
    idx=$((idx + 1))
  done
  
  read -p "¿Cuál instalar? (número o nombre, 'q' para salir): " choice
  
  if [[ "$choice" == "q" ]]; then
    exit 0
  fi
  
  # Accept number or name
  if [[ "$choice" =~ ^[0-9]+$ ]]; then
    idx=1
    for s in $AVAILABLE_SKILLS; do
      if [[ $idx -eq $choice ]]; then
        SKILL="$s"
        break
      fi
      idx=$((idx + 1))
    done
    if [[ -z "$SKILL" ]]; then
      err "Opción inválida"
      exit 1
    fi
  else
    SKILL="$choice"
  fi
fi

# ─── Validate skill ──────────────────────────────────────────

if ! is_valid_skill "$SKILL"; then
  err "Skill '$SKILL' no existe. Disponibles: $AVAILABLE_SKILLS"
  exit 1
fi

# ─── Check if already installed ──────────────────────────────

if [[ -f "$WORKSPACE/skills/$SKILL/SKILL.md" ]]; then
  warn "Skill '$SKILL' ya está instalada en $TENANT"
  read -p "¿Reinstalar? (y/N): " reinstall
  if [[ "$reinstall" != "y" && "$reinstall" != "Y" ]]; then
    exit 0
  fi
fi

echo ""
info "Instalando skill: $SKILL → $TENANT"
echo "  Scope: $(skill_scope "$SKILL")"
echo ""

# ─── Load env ─────────────────────────────────────────────────

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# ─── Ensure git repo exists ──────────────────────────────────

ensure_git_repo() {
  if [[ ! -d "$WORKSPACE/.git" ]]; then
    info "Creando repo Git para $TENANT..."
    
    # Check if remote repo exists
    REPO_NAME="taas-${TENANT}"
    if ! gh repo view "MyTechPlan/$REPO_NAME" &>/dev/null; then
      info "Creando repo MyTechPlan/$REPO_NAME en GitHub..."
      gh repo create "MyTechPlan/$REPO_NAME" --private --description "TaaS workspace for $TENANT" 2>/dev/null
      sleep 2
    fi
    
    cd "$WORKSPACE"
    git init
    git remote add origin "https://github.com/MyTechPlan/$REPO_NAME.git"
    
    # .gitignore
    cat > .gitignore << 'GITEOF'
node_modules/
.env
.env.local
.vercel/
dist/
.openclaw/
*.log
GITEOF
    
    git add -A
    git commit -m "initial: TaaS workspace for $TENANT"
    git branch -M main
    git push -u origin main 2>/dev/null || git push -u origin main --force 2>/dev/null
    cd "$ROOT_DIR"
    log "Repo Git creado: MyTechPlan/$REPO_NAME"
  fi
}

# ─── Ensure Vercel project + deploy hook ──────────────────────

VERCEL_TOKEN="${VERCEL_TOKEN:-}"

ensure_vercel_project() {
  local project_name="$1"
  local root_dir="$2"      # e.g. "sites/web" or "sites/app"
  local framework="$3"     # e.g. "astro" or "vite"
  local repo_name="taas-${TENANT}"
  
  if [[ -z "$VERCEL_TOKEN" ]]; then
    # Try to get from auth file
    VERCEL_TOKEN=$(python3 -c '
import json, os
for p in [
    os.path.expanduser("~/.config/com.vercel.cli/auth.json"),
    os.path.expanduser("~/Library/Application Support/com.vercel.cli/auth.json"),
]:
    if os.path.exists(p):
        print(json.load(open(p))["token"])
        break
' 2>/dev/null || true)
  fi
  
  if [[ -z "$VERCEL_TOKEN" ]]; then
    err "No VERCEL_TOKEN found. Set it in .env or login with 'vercel login'"
    exit 1
  fi
  
  # Check if project exists
  local project_check
  project_check=$(curl -s -o /dev/null -w "%{http_code}" \
    "https://api.vercel.com/v9/projects/$project_name" \
    -H "Authorization: Bearer $VERCEL_TOKEN")
  
  if [[ "$project_check" == "200" ]]; then
    info "Proyecto Vercel '$project_name' ya existe"
  else
    info "Creando proyecto Vercel '$project_name'..."
    
    local create_resp
    create_resp=$(curl -s -X POST "https://api.vercel.com/v10/projects" \
      -H "Authorization: Bearer $VERCEL_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"name\": \"$project_name\",
        \"framework\": \"$framework\",
        \"gitRepository\": {
          \"repo\": \"MyTechPlan/$repo_name\",
          \"type\": \"github\"
        },
        \"rootDirectory\": \"$root_dir\",
        \"buildCommand\": \"npm run build\",
        \"installCommand\": \"npm install\"
      }")
    
    local project_id
    project_id=$(echo "$create_resp" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
    
    if [[ -z "$project_id" ]]; then
      warn "No se pudo crear proyecto via API. Crealo manualmente en Vercel dashboard:"
      echo "  1. https://vercel.com/new"
      echo "  2. Import MyTechPlan/$repo_name"
      echo "  3. Root directory: $root_dir"
      echo "  4. Framework: $framework"
      read -p "Presiona Enter cuando esté creado..."
    else
      log "Proyecto Vercel creado: $project_name (id: $project_id)"
    fi
  fi
  
  # Get or create deploy hook (hooks are nested in project.link.deployHooks)
  info "Obteniendo deploy hooks..."
  local project_resp
  project_resp=$(curl -s "https://api.vercel.com/v9/projects/$project_name" \
    -H "Authorization: Bearer $VERCEL_TOKEN")
  
  DEPLOY_HOOK_URL=$(echo "$project_resp" | python3 -c '
import json,sys
d = json.load(sys.stdin)
hooks = d.get("link",{}).get("deployHooks",[])
for h in hooks:
  if h.get("ref") == "main":
    print(h.get("url",""))
    break
' 2>/dev/null)
  
  if [[ -n "$DEPLOY_HOOK_URL" ]]; then
    info "Deploy hook existente: ...${DEPLOY_HOOK_URL: -20}"
  else
    info "Creando deploy hook..."
    # POST to project deploy-hooks creates hook AND returns full project
    local hook_resp
    hook_resp=$(curl -s -X POST "https://api.vercel.com/v1/projects/$project_name/deploy-hooks" \
      -H "Authorization: Bearer $VERCEL_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"name\": \"taas-$TENANT-deploy\", \"ref\": \"main\"}")
    
    DEPLOY_HOOK_URL=$(echo "$hook_resp" | python3 -c '
import json,sys
d = json.load(sys.stdin)
hooks = d.get("link",{}).get("deployHooks",[])
for h in hooks:
  if h.get("ref") == "main":
    print(h.get("url",""))
    break
' 2>/dev/null)
    
    if [[ -z "$DEPLOY_HOOK_URL" ]]; then
      warn "No se pudo crear deploy hook via API."
      echo "  Crealo manualmente: Vercel → $project_name → Settings → Git → Deploy Hooks"
      read -p "Pega la URL del deploy hook: " DEPLOY_HOOK_URL
    else
      log "Deploy hook creado"
    fi
  fi
}

# ─── Install: python-sandbox ─────────────────────────────────

install_python_sandbox() {
  mkdir -p "$WORKSPACE/skills/python-sandbox"
  cp "$SKILLS_DIR/python-sandbox/SKILL.md" "$WORKSPACE/skills/python-sandbox/"
  cp "$SKILLS_DIR/python-sandbox/sandbox.py" "$WORKSPACE/skills/python-sandbox/"
  
  # Update TOOLS.md
  if ! grep -q "Python Sandbox" "$TOOLS_FILE" 2>/dev/null; then
    cat >> "$TOOLS_FILE" << 'EOF'

## Python Sandbox (code execution)
- **Skill:** `skills/python-sandbox/SKILL.md`
- **Script:** `python3 skills/python-sandbox/sandbox.py --code '<código>'`
- **Uso:** Cálculos, análisis de datos, estadísticas, conversiones
- **Bloqueado:** filesystem, network, subprocess, imports peligrosos
- **Permitido:** math, statistics, decimal, datetime, json, re, collections, csv
- **Timeout:** 10s | **Output max:** 50KB
EOF
  fi
  
  log "python-sandbox instalada"
}

# ─── Install: web-deploy ──────────────────────────────────────

install_web_deploy() {
  ensure_git_repo
  
  local project_name="taas-${TENANT}"
  ensure_vercel_project "$project_name" "sites/web" "astro"
  
  # Copy site template
  mkdir -p "$WORKSPACE/sites/web"
  if [[ -d "$SKILLS_DIR/web-deploy/template" ]]; then
    cp -rn "$SKILLS_DIR/web-deploy/template/"* "$WORKSPACE/sites/web/" 2>/dev/null || true
    # Install node_modules in the build (Vercel does this, but we need package-lock for reproducibility)
  fi
  
  # Copy skill files
  mkdir -p "$WORKSPACE/skills/web-deploy"
  cp "$SKILLS_DIR/web-deploy/SKILL.md" "$WORKSPACE/skills/web-deploy/"
  cp "$SKILLS_DIR/web-deploy/deploy.sh" "$WORKSPACE/skills/web-deploy/"
  
  # Update SKILL.md with tenant-specific URLs
  sed -i '' "s|https://taas-enki.vercel.app|https://${project_name}.vercel.app|g" "$WORKSPACE/skills/web-deploy/SKILL.md" 2>/dev/null || true
  
  # Remove branch workflow if present, add no-branches rule
  # (templates should already have this, but ensure it)
  if grep -q "Branch Workflow" "$WORKSPACE/skills/web-deploy/SKILL.md" 2>/dev/null; then
    warn "SKILL.md tiene branch workflow viejo — actualizar template"
  fi
  
  # Update deploy.sh with deploy hook
  if [[ -n "${DEPLOY_HOOK_URL:-}" ]]; then
    sed -i '' "s|DEPLOY_HOOK=.*|DEPLOY_HOOK=\"$DEPLOY_HOOK_URL\"|g" "$WORKSPACE/skills/web-deploy/deploy.sh" 2>/dev/null || true
    # Also try the curl pattern
    sed -i '' "s|https://api.vercel.com/v1/integrations/deploy/[^\"]*|$DEPLOY_HOOK_URL|g" "$WORKSPACE/skills/web-deploy/deploy.sh" 2>/dev/null || true
  fi
  
  # Update TOOLS.md
  if ! grep -q "web-deploy" "$TOOLS_FILE" 2>/dev/null; then
    cat >> "$TOOLS_FILE" << EOF

## Web Deploy (sitio web)
- **Skill:** \`skills/web-deploy/SKILL.md\`
- **Site:** \`sites/web/\` (Astro)
- **URL:** https://${project_name}.vercel.app
- **Deploy:** \`bash skills/web-deploy/deploy.sh "mensaje del cambio"\`
- NO tocar configs (astro.config, package.json, tsconfig)
- NO instalar paquetes — ticket a MTP
EOF
  fi
  
  # Expand exec allowlist for git commands
  update_exec_allowlist
  
  log "web-deploy instalada → https://${project_name}.vercel.app"
}

# ─── Install: web-app ────────────────────────────────────────

install_web_app() {
  ensure_git_repo
  
  # Supabase setup
  SUPABASE_URL="${SUPABASE_URL:-}"
  SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
  SUPABASE_ACCESS_TOKEN="${SUPABASE_ACCESS_TOKEN:-}"
  SUPABASE_PROJECT_REF="${SUPABASE_PROJECT_REF:-}"
  
  if [[ -z "$SUPABASE_URL" || -z "$SUPABASE_ANON_KEY" ]]; then
    err "Supabase env vars not set in .env (SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_ACCESS_TOKEN, SUPABASE_PROJECT_REF)"
    exit 1
  fi
  
  # Create schema
  info "Creando schema tenant_${TENANT} en Supabase..."
  curl -s -X POST "https://api.supabase.com/v1/projects/${SUPABASE_PROJECT_REF}/database/query" \
    -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"CREATE SCHEMA IF NOT EXISTS tenant_${TENANT};\"}" > /dev/null
  
  # Expose schema in PostgREST (APPEND, don't replace — other tenants may already be exposed)
  info "Exponiendo schema en PostgREST..."
  curl -s -X POST "https://api.supabase.com/v1/projects/${SUPABASE_PROJECT_REF}/database/query" \
    -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"DO \\$\\$ DECLARE current_schemas text; BEGIN SELECT setting INTO current_schemas FROM pg_catalog.pg_db_role_setting rs JOIN pg_catalog.pg_roles r ON r.oid = rs.setrole WHERE r.rolname = 'authenticator' LIMIT 1; IF current_schemas IS NULL OR current_schemas NOT LIKE '%tenant_${TENANT}%' THEN IF current_schemas IS NULL THEN EXECUTE format('ALTER ROLE authenticator SET pgrst.db_schemas TO %L', 'public, tenant_${TENANT}'); ELSE EXECUTE format('ALTER ROLE authenticator SET pgrst.db_schemas TO %L', regexp_replace(current_schemas, 'pgrst.db_schemas=', '') || ', tenant_${TENANT}'); END IF; END IF; END \\$\\$;\"}" > /dev/null
  
  # Simpler fallback: just SET with all known schemas (read current + add new)
  # Get current schemas and append
  local current_schemas
  current_schemas=$(curl -s -X POST "https://api.supabase.com/v1/projects/${SUPABASE_PROJECT_REF}/database/query" \
    -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"query": "SELECT string_agg(nspname, '\'', '\'') FROM pg_namespace WHERE nspname LIKE '\''tenant_%'\''"}' | python3 -c 'import json,sys;rows=json.load(sys.stdin);print(rows[0].get("string_agg","") if rows else "")' 2>/dev/null)
  
  local all_schemas="public"
  if [[ -n "$current_schemas" ]]; then
    all_schemas="public, $current_schemas"
  fi
  # Ensure current tenant is included
  if [[ "$all_schemas" != *"tenant_${TENANT}"* ]]; then
    all_schemas="$all_schemas, tenant_${TENANT}"
  fi
  
  curl -s -X POST "https://api.supabase.com/v1/projects/${SUPABASE_PROJECT_REF}/database/query" \
    -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"ALTER ROLE authenticator SET pgrst.db_schemas TO '${all_schemas}';\"}" > /dev/null
  
  # Notify PostgREST to reload config
  curl -s -X POST "https://api.supabase.com/v1/projects/${SUPABASE_PROJECT_REF}/database/query" \
    -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"query": "NOTIFY pgrst, '\''reload config'\''"}' > /dev/null
  
  log "Schema tenant_${TENANT} creado en Supabase"
  
  # Vercel project for app
  local app_project="taas-${TENANT}-app"
  local domain="${TENANT}.fran-ai.dev"
  ensure_vercel_project "$app_project" "sites/app" "vite"
  
  # Add domain to Vercel project
  info "Configurando dominio $domain..."
  curl -s -X POST "https://api.vercel.com/v10/projects/$app_project/domains" \
    -H "Authorization: Bearer $VERCEL_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$domain\"}" > /dev/null 2>&1 || true
  
  # Set env vars on Vercel
  info "Configurando env vars en Vercel..."
  for env_name in VITE_SUPABASE_URL VITE_SUPABASE_ANON_KEY VITE_TENANT_ID; do
    case "$env_name" in
      VITE_SUPABASE_URL)    env_val="$SUPABASE_URL" ;;
      VITE_SUPABASE_ANON_KEY) env_val="$SUPABASE_ANON_KEY" ;;
      VITE_TENANT_ID)       env_val="$TENANT" ;;
    esac
    
    curl -s -X POST "https://api.vercel.com/v10/projects/$app_project/env" \
      -H "Authorization: Bearer $VERCEL_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"key\": \"$env_name\", \"value\": \"$env_val\", \"type\": \"plain\", \"target\": [\"production\", \"preview\"]}" > /dev/null 2>&1 || true
  done
  
  # Copy app template
  mkdir -p "$WORKSPACE/sites/app/src/lib" "$WORKSPACE/sites/app/src/components" "$WORKSPACE/sites/app/src/pages"
  if [[ -d "$TEMPLATES_DIR/webapp" ]]; then
    # Copy all template files
    cp -rn "$TEMPLATES_DIR/webapp/"* "$WORKSPACE/sites/app/" 2>/dev/null || true
    
    # Replace placeholders
    find "$WORKSPACE/sites/app" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.json" -o -name "*.html" \) -exec \
      sed -i '' "s/{{TENANT_ID}}/$TENANT/g" {} \; 2>/dev/null || true
    
    # Create vite-env.d.ts (prevents TS errors)
    cat > "$WORKSPACE/sites/app/src/vite-env.d.ts" << 'VITEEOF'
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SUPABASE_URL: string
  readonly VITE_SUPABASE_ANON_KEY: string
  readonly VITE_TENANT_ID: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
VITEEOF
    
    # Create .env.local for the app
    cat > "$WORKSPACE/sites/app/.env.local" << ENVEOF
VITE_SUPABASE_URL=$SUPABASE_URL
VITE_SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
VITE_TENANT_ID=$TENANT
ENVEOF
  fi
  
  # Copy skill files
  mkdir -p "$WORKSPACE/skills/web-app"
  
  # Use template SKILL.md and customize
  cp "$TEMPLATES_DIR/webapp/SKILL.md" "$WORKSPACE/skills/web-app/" 2>/dev/null || \
    cp "$SKILLS_DIR/canvas/SKILL.md" "$WORKSPACE/skills/web-app/" 2>/dev/null || true
  
  # Create deploy.sh for web-app
  cat > "$WORKSPACE/skills/web-app/deploy.sh" << DEPLOYEOF
#!/bin/bash
set -e
MSG="\${1:-update}"
cd /home/node/.openclaw/workspace

# Verify TypeScript
echo "🔍 Checking TypeScript..."
cd sites/app && npx tsc --noEmit 2>&1 && cd ../.. || { echo "❌ TS errors — fix before deploying"; exit 1; }

# Commit and push
git add sites/app/
git commit -m "app: \$MSG" 2>/dev/null || { echo "ℹ️ Nothing to commit"; }
git push origin main 2>/dev/null || { echo "⚠️ Push failed"; exit 1; }

# Trigger deploy
curl -s -X POST "${DEPLOY_HOOK_URL:-https://DEPLOY_HOOK_NOT_SET}" > /dev/null

echo "🚀 Deploy triggered! Check https://${domain} in ~60s"

# Verify
sleep 30
STATUS=\$(curl -s -o /dev/null -w "%{http_code}" "https://${domain}")
if [ "\$STATUS" = "200" ]; then
  echo "✅ Site is live (HTTP \$STATUS)"
else
  echo "⚠️ Site returned HTTP \$STATUS — check Vercel dashboard"
fi
DEPLOYEOF
  chmod +x "$WORKSPACE/skills/web-app/deploy.sh"
  
  # Update TOOLS.md
  if ! grep -q "web-app" "$TOOLS_FILE" 2>/dev/null; then
    cat >> "$TOOLS_FILE" << EOF

## Web App (app con DB)
- **Skill:** \`skills/web-app/SKILL.md\`
- **App:** \`sites/app/\` (React + Vite + TypeScript)
- **URL:** https://${domain}
- **DB:** Schema \`tenant_${TENANT}\` en Supabase
- **Auth:** Google OAuth (cualquier cuenta)
- **Deploy:** \`bash skills/web-app/deploy.sh "mensaje del cambio"\`
- Para pedir tablas nuevas → ticket a MTP
- NO tocar: supabase.ts, .env.local, vite.config.ts, tsconfig.json, main.tsx
EOF
  fi
  
  # Expand exec allowlist for git commands
  update_exec_allowlist
  
  log "web-app instalada → https://${domain}"
}

# ─── Update exec allowlist ────────────────────────────────────

update_exec_allowlist() {
  local approvals_file="$DATA_DIR/.openclaw/exec-approvals.json"
  
  if [[ -f "$approvals_file" ]]; then
    # Check if git is already there
    if ! grep -q "/usr/bin/git" "$approvals_file" 2>/dev/null; then
      info "Expandiendo exec allowlist con git + bash..."
      python3 -c "
import json
with open('$approvals_file') as f:
    d = json.load(f)
al = d.get('allowlist', [])
for cmd in ['/usr/bin/git', '/bin/bash', '/usr/bin/npx']:
    if cmd not in al:
        al.append(cmd)
d['allowlist'] = al
with open('$approvals_file', 'w') as f:
    json.dump(d, f, indent=2)
print('Updated')
"
    fi
  else
    info "Creando exec-approvals.json..."
    cat > "$approvals_file" << 'EOF'
{
  "allowlist": ["/usr/bin/python3", "/usr/bin/git", "/bin/bash", "/usr/bin/npx"]
}
EOF
  fi
}

# ─── Install: monday ──────────────────────────────────────────

install_monday() {
  # Copy skill
  mkdir -p "$WORKSPACE/skills/monday"
  cp "$SKILLS_DIR/monday/SKILL.md" "$WORKSPACE/skills/monday/"
  
  # Check if API token is configured
  local config_file="$DATA_DIR/.openclaw/openclaw.json"
  
  # Prompt for API token if not set
  echo ""
  info "Monday.com necesita el API token personal del cliente."
  echo "  El cliente lo obtiene desde: Monday.com → Avatar → Developers → My Access Tokens"
  echo ""
  read -p "¿Tenés el API token? (pégalo, o 'skip' para configurar después): " monday_token
  
  if [[ -n "$monday_token" && "$monday_token" != "skip" ]]; then
    # Add to docker-compose env for this tenant
    info "Guardando token..."
    
    # Add MONDAY_API_TOKEN to the tenant's env in docker-compose override
    local override_file="$ROOT_DIR/docker-compose.override.yml"
    if [[ -f "$override_file" ]]; then
      # Add env var to tenant service
      local env_prefix
      env_prefix=$(echo "$TENANT" | tr '[:lower:]-' '[:upper:]_')
      
      # Store in .env
      local env_file="$ROOT_DIR/.env"
      if ! grep -q "${env_prefix}_MONDAY_TOKEN" "$env_file" 2>/dev/null; then
        echo "${env_prefix}_MONDAY_TOKEN=$monday_token" >> "$env_file"
      fi
      
      # Note: Need to add MONDAY_API_TOKEN to docker-compose override manually
      warn "Agregá MONDAY_API_TOKEN al docker-compose.override.yml del tenant $TENANT:"
      echo "    environment:"
      echo "      - MONDAY_API_TOKEN=\${${env_prefix}_MONDAY_TOKEN}"
      echo ""
      echo "  Y luego: docker compose restart $TENANT"
    fi
    
    # Verify token works
    info "Verificando conexión a Monday.com..."
    local test_resp
    test_resp=$(curl -s -X POST https://api.monday.com/v2 \
      -H "Authorization: $monday_token" \
      -H "Content-Type: application/json" \
      -H "API-Version: 2024-10" \
      -d '{"query": "{ me { id name email } }"}')
    
    local user_name
    user_name=$(echo "$test_resp" | python3 -c 'import json,sys;d=json.load(sys.stdin);print(d.get("data",{}).get("me",{}).get("name",""))' 2>/dev/null)
    
    if [[ -n "$user_name" ]]; then
      log "Conexión exitosa! Usuario: $user_name"
    else
      warn "No se pudo verificar el token. Revisá que sea correcto."
    fi
  else
    info "Token no configurado. El cliente deberá proporcionarlo durante el onboarding."
    echo "  Vesta le pedirá el token cuando intente usar Monday."
  fi
  
  # Update TOOLS.md
  if ! grep -q "Monday" "$TOOLS_FILE" 2>/dev/null; then
    cat >> "$TOOLS_FILE" << 'EOF'

## Monday.com (project management)
- **Skill:** `skills/monday/SKILL.md`
- **API:** GraphQL → https://api.monday.com/v2
- **Auth:** Token personal del cliente ($MONDAY_API_TOKEN)
- **Uso:** Leer boards, crear items, actualizar estados, agregar comentarios
- NO crear/eliminar boards — ticket a MTP
EOF
  fi
  
  log "monday instalada"
}

# ─── Commit and push ─────────────────────────────────────────

commit_and_push() {
  if [[ -d "$WORKSPACE/.git" ]]; then
    cd "$WORKSPACE"
    git add -A
    if git diff --cached --quiet; then
      info "Nada nuevo que commitear"
    else
      git commit -m "skill: install $SKILL via install-skill.sh"
      git push origin main 2>/dev/null && log "Cambios pusheados a GitHub" || warn "Push falló — hacelo manual"
    fi
    cd "$ROOT_DIR"
  fi
}

# ─── Execute ──────────────────────────────────────────────────

case "$SKILL" in
  python-sandbox)
    install_python_sandbox
    ;;
  web-deploy)
    install_web_deploy
    ;;
  web-app)
    install_web_app
    ;;
  monday)
    install_monday
    ;;
  *)
    err "Skill '$SKILL' no tiene instalador implementado"
    exit 1
    ;;
esac

# Commit changes to tenant repo
commit_and_push

# Update CATALOG.md in tenant workspace
cp "$SKILLS_DIR/CATALOG.md" "$WORKSPACE/skills/CATALOG.md" 2>/dev/null || true

echo ""
echo "════════════════════════════════════════════════════"
echo -e "  ${GREEN}Skill '$SKILL' instalada para tenant '$TENANT'${NC}"
echo ""
echo "  Scope: $(skill_scope "$SKILL")"
echo ""
echo "  Archivos:"
echo "    Skill:  skills/$SKILL/SKILL.md"
if [[ "$SKILL" == "web-deploy" ]]; then
  echo "    Site:   sites/web/"
  echo "    URL:    https://taas-${TENANT}.vercel.app"
elif [[ "$SKILL" == "web-app" ]]; then
  echo "    App:    sites/app/"
  echo "    URL:    https://${TENANT}.fran-ai.dev"
  echo "    DB:     tenant_${TENANT} (Supabase)"
fi
echo ""
echo "  Próximo paso: reiniciar container"
echo "    docker compose restart $TENANT"
echo "════════════════════════════════════════════════════"
