# Skill: web-deploy

## Qué es
Sitio web estático desplegado en Vercel. Escribís archivos Astro y con un script se publica.

## Scope (para qué sirve)
- ✅ Landing pages, portfolios, blogs, CVs, páginas informativas
- ✅ Contenido estático con estilos CSS
- ✅ Imágenes y archivos estáticos
- ❌ NO para apps con base de datos (eso es web-app)
- ❌ NO para apps con login/auth
- ❌ NO para instalar paquetes npm (ticket a MTP)

## Ubicación
Tu sitio está en `sites/web/`. Es un proyecto **Astro**.

## Estructura
```
sites/web/
├── src/
│   ├── layouts/
│   │   └── Layout.astro    ← Layout base (HTML head, nav, footer)
│   └── pages/
│       └── index.astro     ← Página principal
│       └── about.astro     ← /about (ejemplo)
├── public/                  ← Archivos estáticos (favicon, imágenes)
├── astro.config.mjs         ← ❌ NO TOCAR
├── package.json             ← ❌ NO TOCAR
├── package-lock.json        ← ❌ NO TOCAR
├── tsconfig.json            ← ❌ NO TOCAR
└── deploy.sh                ← Script de deploy (NO EDITAR)
```

## Cómo crear/editar páginas

Cada archivo `.astro` en `src/pages/` se convierte en una ruta:
- `src/pages/index.astro` → `/`
- `src/pages/about.astro` → `/about`
- `src/pages/products/list.astro` → `/products/list`

### Formato de una página
```astro
---
import Layout from '../layouts/Layout.astro';
---
<Layout title="Mi Página">
  <h1>Hola mundo</h1>
  <p>Contenido aquí.</p>
</Layout>
```

### Estilos
Usá `<style>` dentro de cualquier `.astro`:
```astro
<style>
  h1 { color: #333; font-family: system-ui; }
</style>
```
O editá el CSS global en `src/layouts/Layout.astro`.

### Imágenes
Poné imágenes en `public/`:
```astro
<img src="/mi-imagen.png" alt="descripción" />
```

## 🚀 Cómo deployar

**SIEMPRE usá el script de deploy:**
```bash
bash skills/web-deploy/deploy.sh "descripción del cambio"
```

El sitio se actualiza en **~30-60 segundos** después del deploy.

## ✅ Lo que SÍ podés hacer
- Crear/editar archivos `.astro` en `src/pages/`
- Editar el Layout en `src/layouts/Layout.astro`
- Agregar estilos CSS inline o en `<style>` tags
- Agregar imágenes/archivos estáticos en `public/`
- Crear componentes en `src/components/`

## ❌ Lo que NO debés hacer NUNCA
1. **NO tocar** `astro.config.mjs` — rompe el build
2. **NO tocar** `package.json` ni `package-lock.json` — rompe el build
3. **NO tocar** `tsconfig.json` — rompe el build
4. **NO tocar** `deploy.sh` — rompe el deploy
5. **NO instalar paquetes** (`npm install xxx`) — pedí un ticket a MTP
6. **NO correr** `npm run build` ni `npm run dev` — no es necesario
7. **NO hardcodear** keys, tokens o secretos en el código

## ⛔ NO uses branches
Trabajá **siempre en `main`**. No crees branches — genera conflictos con el deploy.
El flujo es simple: editar → deploy script → verificar.

## ✅ Good Practices
1. **Verificá antes de deployar:** revisá que no haya errores obvios de sintaxis
2. **Después de cada deploy:** hacé un fetch a la URL y confirmá HTTP 200
3. **No hardcodees datos:** si hay una API disponible, usala
4. **Mantené commits descriptivos:** "web: add about page" no "update"

## 🆘 Si algo se rompe
1. **El deploy falla**: revisá que no hayas tocado archivos de config. Ticket a MTP.
2. **La página da 404**: verificá que el archivo existe en `src/pages/` con formato correcto.
3. **Necesito un paquete npm**: ticket a MTP con nombre y justificación.
4. **Necesito cambiar config**: ticket a MTP.
