# Skill: web-app

## Qué es
Tu web app con base de datos y autenticación (login con Google).
Stack: React + Supabase (DB + Auth).

## URL de producción
**https://{{DOMAIN}}**

## Ubicación
Tu app está en `sites/app/`. Es un proyecto **React + Vite + TypeScript**.

## Estructura
```
sites/app/
├── src/
│   ├── components/       ← Tus componentes React
│   │   ├── Auth.tsx      ← Pantalla de login (NO TOCAR la lógica de auth)
│   │   └── Dashboard.tsx ← Dashboard principal (EDITABLE)
│   ├── pages/            ← Páginas/vistas (crear las que necesites)
│   ├── lib/
│   │   └── supabase.ts   ← ❌ NO TOCAR (cliente de DB)
│   ├── App.tsx           ← Router principal (editar con cuidado)
│   └── main.tsx          ← ❌ NO TOCAR
├── public/               ← Archivos estáticos (imágenes, favicon)
├── index.html            ← ❌ NO TOCAR (salvo <title>)
├── package.json          ← ❌ NO TOCAR
├── vite.config.ts        ← ❌ NO TOCAR
├── tsconfig.json         ← ❌ NO TOCAR
├── .env.local            ← ❌ NO TOCAR (keys de Supabase)
└── .vercel/              ← ❌ NO TOCAR
```

## 🚀 Cómo deployar

**SIEMPRE usá el script de deploy:**

```bash
bash skills/web-app/deploy.sh "descripción del cambio"
```

El sitio se actualiza en **~30-60 segundos**.

### ⚠️ NO hagas deploy manual
- NO corras `git push` directamente — usá el script
- NO corras `npm install`, `npm run build`, ni `npx`
- NO intentes configurar Vercel — no tenés acceso

## 🗄️ Base de Datos (Supabase)

El client está en `src/lib/supabase.ts`. Ya configurado.

### Cómo usar la DB en componentes
```tsx
import { supabase } from '../lib/supabase'

// Leer datos
const { data, error } = await supabase.from('mi_tabla').select('*')

// Insertar
const { data, error } = await supabase.from('mi_tabla').insert({ nombre: 'valor' })

// Actualizar
const { data, error } = await supabase.from('mi_tabla').update({ nombre: 'nuevo' }).eq('id', 1)

// Eliminar
const { data, error } = await supabase.from('mi_tabla').delete().eq('id', 1)
```

### ⚠️ Tablas — NO podés crearlas vos
Para pedir una tabla nueva, abrí un **ticket a MTP** con:
1. Nombre de la tabla
2. Columnas (nombre, tipo, nullable, default)
3. Quién puede ver/editar

Ejemplo:
```
Tabla: pacientes
- id: uuid (PK, auto)
- nombre: text (required)
- email: text (unique)
- telefono: text (nullable)
- created_at: timestamptz (auto)
Acceso: todos los usuarios autenticados
```

## 🔐 Auth (Login con Google)

Ya configurado. Usá así en componentes:

```tsx
import { supabase } from '../lib/supabase'

// Obtener usuario actual
const { data: { user } } = await supabase.auth.getUser()

// Cerrar sesión
await supabase.auth.signOut()

// Proteger contenido
if (!user) return <p>No autorizado</p>
```

## ✅ Lo que SÍ podés hacer

- Crear/editar componentes en `src/components/`
- Crear páginas en `src/pages/`
- Editar `Dashboard.tsx` libremente
- Editar `App.tsx` para agregar rutas (con cuidado)
- Agregar estilos CSS/Tailwind
- Agregar imágenes en `public/`
- Usar la API de Supabase (select, insert, update, delete)
- Usar `supabase.auth.getUser()` para datos del usuario

## ❌ Lo que NO debés hacer NUNCA

1. **NO tocar** `.env.local`, `.vercel/`, `vite.config.ts`, `tsconfig.json`, `main.tsx`
2. **NO tocar** `src/lib/supabase.ts`
3. **NO instalar paquetes** sin ticket aprobado por MTP
4. **NO correr** `npm install/build/dev`
5. **NO hardcodear** keys, tokens o secretos
6. **NO modificar** la lógica de auth en `Auth.tsx` (solo estilos)
7. **NO crear tablas** directamente — siempre via ticket

## 📦 Para agregar dependencias
Ticket a MTP con nombre del paquete y justificación.

Paquetes que normalmente se aprueban:
- `recharts` / `chart.js` — gráficos
- `date-fns` / `dayjs` — fechas
- `react-icons` — iconos
- `react-hook-form` — formularios
- `@tanstack/react-query` — data fetching

## 🆘 Problemas comunes

| Problema | Solución |
|----------|----------|
| Build falla | Corregí errores TS, NO toques configs |
| Login no funciona | Ticket a MTP (config de OAuth) |
| Necesito tabla nueva | Ticket con esquema detallado |
| Quiero paquete npm | Ticket con nombre y justificación |
| Error "permission denied" en DB | Ticket (falta policy RLS) |
| Sitio muestra versión vieja | Esperá 60 seg post-deploy |

## ✅ Good Practices

1. **Verificá antes de deployar:** revisá que no haya errores de TypeScript (`npx tsc --noEmit` si podés)
2. **Después de cada deploy:** hacé un fetch a la URL y confirmá HTTP 200
3. **No hardcodees datos:** usá la API de Supabase, no datos estáticos
4. **Mantené commits descriptivos:** "app: add patient list view" no "update"
5. **Testeá el auth flow:** verificá que login/logout funcionen después de cambios

## ⛔ NO uses branches

Trabajá **siempre en `main`**. No crees branches — genera conflictos con el deploy.
El flujo es simple: editar → verificar TS → deploy script → verificar URL.
