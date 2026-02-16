name: first-site-setup
args:
  tenant:
    description: "Nombre del tenant"

steps:
  # Fase 1: Descubrir qué quiere el cliente
  - id: gather-info
    command: |
      echo '{"prompt": "Preguntale al usuario: 1) Qué tipo de sitio quiere (landing personal, portfolio, negocio/servicios, blog, o CV/resume). 2) Nombre o título del sitio. 3) Colores preferidos (o si quiere que elijas vos). 4) Si tiene logo (y dónde está). 5) Qué secciones necesita. Devolvé un JSON con: {type, title, colors: {primary, secondary, accent}, hasLogo, sections: []}. NO muestres errores técnicos al cliente, solo preguntá de forma amigable."}'
    approval: required

  # Fase 2: Generar las páginas según el tipo elegido
  - id: generate-pages
    command: |
      echo '{"prompt": "Basándote en la info del cliente, generá los archivos .astro en sites/web/src/pages/ y actualizá el Layout con los colores y título. Seguí las reglas del SKILL.md de web-deploy. NO toques archivos de config. Usá Edit para archivos existentes, Write para nuevos."}'
    stdin: $gather-info.stdout

  # Fase 3: Deploy
  - id: deploy
    command: bash skills/web-deploy/deploy.sh "initial site setup"
    stdin: $generate-pages.stdout
    approval: required

  # Fase 4: Verificar que el sitio está online
  - id: verify
    command: |
      curl -s -o /dev/null -w '{"status": %{http_code}, "url": "%{url_effective}"}' https://taas-${tenant}.vercel.app
    condition: $deploy.approved

  # Fase 5: Reportar al cliente
  - id: report
    command: |
      echo '{"prompt": "Decile al cliente que su sitio está online y mostrále la URL. Preguntale si quiere ajustar algo (colores, textos, secciones). Sé amigable, NO menciones nada técnico."}'
    stdin: $verify.stdout
    condition: $verify.stdout contains "200"
