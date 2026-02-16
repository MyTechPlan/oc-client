# TaaS Admin Dashboard — Diseño

## Resumen

Un servidor web ligero que corre en el VPS junto a los containers TaaS. Permite ver/editar archivos de configuración de cada tenant, ver logs en tiempo real, y reiniciar containers. Single-file server + static frontend.

## Tech Stack

- **Backend:** Node.js (Express) — un solo archivo `server.mjs` (~300 líneas)
- **Frontend:** HTML + vanilla JS + CSS (un solo archivo `index.html`, sin build step)
- **Docker:** usa `dockerode` (npm) para logs y restart
- **Auth:** HTTP Basic Auth (suficiente para acceso local/SSH tunnel)
- **No DB.** Todo es filesystem + Docker API.

## Arquitectura

```
┌─────────────────────────────────────┐
│  VPS (Hetzner)                      │
│                                     │
│  ┌─────────────┐  ┌──────────────┐  │
│  │ taas-admin   │  │ Docker       │  │
│  │ :9090        │──│ /var/run/    │  │
│  │ (Node.js)   │  │ docker.sock  │  │
│  └──────┬──────┘  └──────────────┘  │
│         │                           │
│  ┌──────┴──────────────────┐        │
│  │ mtp/data/{tenant}/      │        │
│  │  ├── .openclaw/         │        │
│  │  └── workspace/         │        │
│  │      ├── SOUL.md        │        │
│  │      ├── MEMORY.md      │        │
│  │      ├── TOOLS.md       │        │
│  │      ├── memory/*.md    │        │
│  │      └── ...            │        │
│  └─────────────────────────┘        │
└─────────────────────────────────────┘
       ↑ SSH tunnel :9090
    Admin (laptop)
```

## API Endpoints

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/tenants` | Lista tenants (lee dirs en `mtp/data/`) |
| GET | `/api/tenants/:id/files` | Lista archivos editables del tenant |
| GET | `/api/tenants/:id/files/*` | Lee contenido de un archivo |
| PUT | `/api/tenants/:id/files/*` | Guarda archivo |
| POST | `/api/tenants/:id/restart` | Reinicia container del tenant |
| GET | `/api/tenants/:id/logs` | Logs recientes (query: `lines=200`) |
| GET | `/api/tenants/:id/logs/stream` | SSE stream de logs en tiempo real |
| GET | `/api/tenants/:id/status` | Estado del container (running/stopped/etc) |
| GET | `/` | Sirve `index.html` |

## Cómo funciona cada cosa

### Archivos .md

Lee directo del filesystem. El server conoce el base path (`MTP_DATA_DIR=./mtp/data`).

Archivos expuestos por tenant:
- `workspace/SOUL.md`
- `workspace/MEMORY.md`
- `workspace/TOOLS.md`
- `workspace/USER.md`
- `workspace/AGENTS.md`
- `workspace/HEARTBEAT.md`
- `workspace/memory/*.md`
- `.openclaw/openclaw.json` (read-only, para referencia)

**Seguridad:** path traversal protection — validar que el path resuelto quede dentro de `mtp/data/{tenant}/`.

### Logs

Usa `dockerode` conectado a `/var/run/docker.sock`:

```js
const container = docker.getContainer(`mtp-${tenantId}`);
// Logs recientes
const logs = await container.logs({ stdout: true, stderr: true, tail: 200 });
// Stream tiempo real (SSE al browser)
const stream = await container.logs({ follow: true, stdout: true, stderr: true, tail: 50 });
```

### Restart

```js
await container.restart({ t: 10 }); // 10s graceful timeout
```

### Historial de conversaciones

Los archivos de sesión de OpenClaw están en `mtp/data/{tenant}/.openclaw/sessions/`. Son JSON/JSONL. El dashboard puede listarlos y mostrar el contenido formateado (mensajes user/assistant, tool calls). Esto es read-only, fase 2.

## UI — Pantallas

### 1. Dashboard (home)

- Lista de tenants como cards
- Cada card muestra: nombre, estado (🟢 running / 🔴 stopped), botón restart
- Click en tenant → vista de tenant

### 2. Vista de Tenant

Tabs:

**Tab: Archivos**
- Sidebar izquierda: lista de archivos editables
- Panel derecho: editor de texto (textarea con monospace font, o CodeMirror lite si queremos)
- Botón "Save" → PUT al API → auto-restart del container
- Botón "Save without restart" también disponible

**Tab: Logs**
- Terminal-style div con logs en tiempo real (SSE)
- Botón para pausar/reanudar el stream
- Filtro básico (texto)

**Tab: Sessions** (fase 2)
- Lista de sesiones recientes
- Click → ver mensajes formateados (user/assistant/tool)

## Plan de Implementación

### Fase 1 — MVP (1-2 horas)

1. `server.mjs` con Express + dockerode
2. Endpoints: tenants, files (read/write), restart, logs
3. `index.html` con UI básica (vanilla JS)
4. Basic auth
5. Correr con `node server.mjs` o como container adicional en el compose

### Fase 2 — Polish (cuando haga falta)

- Viewer de sesiones/conversaciones
- CodeMirror para edición de markdown
- Diff view antes de guardar
- Notificaciones de estado post-restart
- Health check periódico de containers

### Fase 3 — Nice to have

- Métricas básicas (uptime, restarts count)
- Webhook notifications (Telegram) on container crash
- Multi-file edit/commit

## Seguridad

- **Auth:** HTTP Basic Auth con user/pass en env vars (`ADMIN_USER`, `ADMIN_PASS`)
- **Acceso:** bind a `127.0.0.1:9090` — solo accesible via SSH tunnel (`ssh -L 9090:localhost:9090 vps`)
- **Path traversal:** resolver paths con `path.resolve()` y validar que estén dentro del data dir
- **Docker socket:** el server necesita acceso a `/var/run/docker.sock` — correrlo como usuario del grupo `docker` o como container con socket mounted
- **Read-only files:** `openclaw.json` y sessions son read-only en la UI
- **No secrets en frontend:** tokens y API keys nunca se exponen al browser

## Deployment

Opción A — **Proceso directo** (más simple):
```bash
cd /path/to/mtp
node admin/server.mjs
# Acceso: ssh -L 9090:localhost:9090 vps
```

Opción B — **Container en el compose**:
```yaml
taas-admin:
  image: node:22-alpine
  working_dir: /app
  volumes:
    - ./admin:/app
    - ./data:/data:rw
    - /var/run/docker.sock:/var/run/docker.sock
  ports:
    - "127.0.0.1:9090:9090"
  environment:
    - MTP_DATA_DIR=/data
    - ADMIN_USER=admin
    - ADMIN_PASS=${TAAS_ADMIN_PASS}
  command: node server.mjs
```

**Recomendación:** Opción A para empezar. Opción B cuando esté estable.

## Estructura de archivos

```
mtp/admin/
├── server.mjs      # Express server (~300 líneas)
├── index.html       # Frontend completo (~500 líneas)
├── package.json     # { express, dockerode }
└── README.md
```

Total: 3-4 archivos. Eso es todo.
