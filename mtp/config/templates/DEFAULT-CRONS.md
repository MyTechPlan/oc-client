# DEFAULT-CRONS.md — Cron jobs por defecto para tenants

Estos crons se deben crear después del onboarding exitoso.
El provision script o el admin los configura manualmente por ahora.

## 1. Resumen diario (Buenos días)
- **Schedule:** `0 9 * * 1-5` (Lunes a Viernes 9:00 AM, timezone del cliente)
- **Tipo:** agentTurn (isolated)
- **Prompt:** "Es un nuevo día. Revisá tus notas recientes en memory/ y si hay algo pendiente o relevante para hoy, mandá un mensaje breve a tu usuario con un resumen. Si no hay nada, no mandes nada."
- **Delivery:** announce

## 2. Mantenimiento de memoria (semanal)
- **Schedule:** `0 3 * * 0` (Domingos 3:00 AM)
- **Tipo:** agentTurn (isolated)
- **Prompt:** "Revisá tus archivos en memory/. Consolidá lo importante en MEMORY.md. Limpiá notas diarias de más de 14 días que ya estén consolidadas."
- **Delivery:** none

## 3. Health check (para admin)
- **Schedule:** `0 */6 * * *` (cada 6 horas)
- **Tipo:** systemEvent (main)
- **Prompt:** "Health check: respond with HEARTBEAT_OK if everything is fine."
- **Nota:** Esto permite al admin verificar que el bot está vivo via logs
