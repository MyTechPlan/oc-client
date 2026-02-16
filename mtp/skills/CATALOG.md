# MTP Skills Catalog — TaaS

Skills disponibles para tenants del servicio TaaS de My Tech Plan.
Cada skill es auditada e instalada por MTP. Los tenants no pueden instalar skills por su cuenta.

Para solicitar una nueva skill → generá un ticket (ver MTP-SERVICE.md).

---

## 🟢 Incluidas por defecto (todos los tenants)

### Web Search
- **Qué hace:** Búsqueda en internet via Brave API
- **Herramienta:** `web_search`
- **Requiere:** BRAVE_API_KEY (provista por MTP)

### Web Fetch
- **Qué hace:** Lee y extrae contenido de páginas web
- **Herramienta:** `web_fetch`
- **Requiere:** nada

### Audio Transcription (STT)
- **Qué hace:** Transcribe notas de voz y audios
- **Provider:** Google Gemini
- **Requiere:** GEMINI_API_KEY (provista por MTP)

### Text-to-Speech (TTS)
- **Qué hace:** Convierte texto a audio para respuestas en voz
- **Provider:** edge-tts (voces Microsoft)
- **Voces disponibles:** masculinas y femeninas en ES, EN, y más
- **Requiere:** nada (edge-tts es gratuito)

### Weather
- **Qué hace:** Consulta del clima actual y pronóstico
- **Herramienta:** skill `weather`
- **Requiere:** nada (usa wttr.in)

### Python Sandbox 🆕
- **Qué hace:** Ejecuta código Python de forma segura para cálculos, análisis de datos, estadísticas
- **Script:** `python3 skills/python-sandbox/sandbox.py --code '<código>'`
- **Seguridad:** Sin acceso a filesystem, red, subprocess. Solo módulos matemáticos/datos.
- **Módulos:** math, statistics, decimal, fractions, datetime, json, re, collections, itertools, csv
- **Límites:** 10s timeout, 50KB output
- **Requiere:** exec en modo allowlist (solo python3)

---

## 🟡 Disponibles bajo demanda (instalación por MTP)

### Email (SMTP)
- **Qué hace:** Enviar emails desde una dirección personalizada
- **Requiere:** Credenciales SMTP del cliente, configuración por MTP
- **Ticket:** Especificar dominio, servidor SMTP, y uso esperado

### Notion Integration
- **Qué hace:** Crear/leer/editar páginas y bases de datos en Notion
- **Requiere:** Notion API key del cliente, configuración por MTP
- **Ticket:** Compartir workspace ID y permisos deseados

### Google Workspace (Calendar, Gmail, Drive)
- **Qué hace:** Gestionar calendario, emails y archivos de Google
- **Requiere:** OAuth setup, configuración por MTP
- **Ticket:** Especificar qué servicios necesita

### Slack Integration
- **Qué hace:** Enviar/recibir mensajes en canales de Slack
- **Requiere:** Slack bot token, configuración por MTP
- **Ticket:** Workspace y canales deseados

### HubSpot CRM
- **Qué hace:** Gestionar contactos, deals y pipeline de ventas
- **Requiere:** HubSpot API key, configuración por MTP
- **Ticket:** Especificar acceso y permisos

### GitHub
- **Qué hace:** Gestionar repos, issues, PRs, CI/CD
- **Requiere:** GitHub token, configuración por MTP
- **Ticket:** Repos y permisos deseados

---

## 🔴 No disponibles (por seguridad)

- **Shell commands generales** — solo Python sandbox
- **Instalación de packages** — no pip, no npm
- **Acceso a filesystem fuera del workspace** — bloqueado
- **Acceso a otros tenants** — aislamiento total

---

_Última actualización: 2026-02-16_
_Para sugerir nuevas skills: hola@mytechplan.com o ticket via tu asistente_
