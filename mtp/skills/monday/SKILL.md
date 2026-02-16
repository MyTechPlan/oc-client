# Skill: monday

## Qué es
Integración con Monday.com para gestionar boards, items y tareas directamente desde el chat.

## Scope (para qué sirve)
- ✅ Leer boards, items, columnas y grupos
- ✅ Crear items (tareas) en boards existentes
- ✅ Actualizar estado, asignados y columnas de items
- ✅ Agregar updates (comentarios) a items
- ✅ Buscar items por nombre o filtros
- ❌ NO crear boards ni columnas (ticket a MTP)
- ❌ NO gestionar usuarios ni permisos
- ❌ NO eliminar boards

## Autenticación

Usa el API token personal de Monday.com del cliente.

**Variable de entorno:** `MONDAY_API_TOKEN`

El token se obtiene desde: Monday.com → Avatar → Developers → My Access Tokens

## API

Monday.com usa **GraphQL**. Un solo endpoint:

```
POST https://api.monday.com/v2
Headers:
  Authorization: MONDAY_API_TOKEN
  Content-Type: application/json
  API-Version: 2024-10
```

## Ejemplos de uso

### Leer boards
```bash
curl -s -X POST https://api.monday.com/v2 \
  -H "Authorization: $MONDAY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "API-Version: 2024-10" \
  -d '{"query": "{ boards(limit: 10) { id name state board_kind } }"}'
```

### Leer items de un board
```bash
curl -s -X POST https://api.monday.com/v2 \
  -H "Authorization: $MONDAY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "API-Version: 2024-10" \
  -d '{"query": "{ boards(ids: [BOARD_ID]) { items_page(limit: 50) { items { id name state column_values { id text } } } } }"}'
```

### Crear item
```bash
curl -s -X POST https://api.monday.com/v2 \
  -H "Authorization: $MONDAY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "API-Version: 2024-10" \
  -d '{"query": "mutation { create_item(board_id: BOARD_ID, item_name: \"Nueva tarea\") { id name } }"}'
```

### Crear item con columnas
```bash
curl -s -X POST https://api.monday.com/v2 \
  -H "Authorization: $MONDAY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "API-Version: 2024-10" \
  -d '{"query": "mutation { create_item(board_id: BOARD_ID, group_id: \"GROUP_ID\", item_name: \"Tarea\", column_values: \"{\\\"status\\\": {\\\"label\\\": \\\"Working on it\\\"}}\") { id name } }"}'
```

### Actualizar columna de un item
```bash
curl -s -X POST https://api.monday.com/v2 \
  -H "Authorization: $MONDAY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "API-Version: 2024-10" \
  -d '{"query": "mutation { change_column_value(board_id: BOARD_ID, item_id: ITEM_ID, column_id: \"status\", value: \"{\\\"label\\\": \\\"Done\\\"}\") { id name } }"}'
```

### Agregar update (comentario) a un item
```bash
curl -s -X POST https://api.monday.com/v2 \
  -H "Authorization: $MONDAY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "API-Version: 2024-10" \
  -d '{"query": "mutation { create_update(item_id: ITEM_ID, body: \"Comentario desde el bot\") { id } }"}'
```

## Notas importantes

- **IDs son strings numéricos** (board_id, item_id, user_id)
- **Column IDs son alfanuméricos** (ej: `color_mm09e48w`, `status`, `date4`)
- **Column values se pasan como JSON string escapado** dentro del query GraphQL
- **Paginación:** cursor-based con `items_page` (limit máximo 100)
- **Rate limit:** Monday.com limita requests por complejidad del query
- Tipos de columna comunes: `status`, `text`, `numbers`, `date`, `people`, `dropdown`, `checkbox`

## ❌ NO tocar
- No modificar esta skill
- No hardcodear el API token — siempre usar `$MONDAY_API_TOKEN`

## 🆘 Problemas comunes

| Problema | Solución |
|----------|----------|
| 401 Unauthorized | Token inválido o expirado — pedir nuevo al cliente |
| Campo no autorizado | El plan del cliente puede no incluir ese campo |
| Rate limited (429) | Esperar y reintentar, simplificar queries |
| Column value no funciona | Verificar formato JSON escapado y column_id correcto |
