# Skill: web-deploy

## Qué es
Tu sitio web personal desplegado automáticamente. Escribís archivos Astro y con un push se publica en Vercel.

## Ubicación
Tu sitio está en `sites/web/`. Es un proyecto Astro.

## Estructura
```
sites/web/
├── astro.config.mjs
├── package.json
├── public/           # Archivos estáticos (favicon, imágenes)
├── src/
│   ├── layouts/
│   │   └── Layout.astro    # Layout base (HTML head, nav, footer)
│   └── pages/
│       └── index.astro     # Página principal
```

## Cómo crear/editar páginas

Cada archivo `.astro` en `src/pages/` se convierte en una ruta:
- `src/pages/index.astro` → `/`
- `src/pages/about.astro` → `/about`
- `src/pages/blog/post-1.astro` → `/blog/post-1`

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
  h1 { color: #333; }
</style>
```

O editá el CSS global en `src/layouts/Layout.astro`.

## Cómo deployar

Después de editar archivos, ejecutá el script de deploy:

```bash
git -C sites/web add -A && git -C sites/web commit -m "update site" && git -C sites/web push
```

Vercel detecta el push y deploya automáticamente. En ~30 segundos el sitio está actualizado.

## Reglas
- NO toques `package.json` ni `astro.config.mjs` a menos que sea necesario
- NO necesitás correr `npm install` ni `npm run build` — Vercel lo hace
- Siempre usá el Layout base para mantener consistencia
- Commiteá con mensajes descriptivos cuando sea posible
