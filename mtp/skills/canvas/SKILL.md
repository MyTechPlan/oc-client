# Skill: canvas

## Qué es
Tu espacio para crear mini-apps interactivas: dashboards, calculadoras, visualizaciones con gráficos. Es un proyecto React + Vite + Chart.js desplegado en Vercel.

## Ubicación
Tu app está en `sites/canvas/`. 

## Estructura
```
sites/canvas/
├── index.html
├── package.json
├── vite.config.js
├── src/
│   ├── main.jsx        # Entry point (monta App)
│   ├── App.jsx          # Componente principal
│   ├── App.css          # Estilos globales
│   └── components/      # Tus componentes
│       └── Chart.jsx    # Ejemplo de gráfico
```

## Cómo crear componentes

### Componente básico
```jsx
export default function MiComponente() {
  return <div><h2>Hola</h2></div>;
}
```

### Gráfico con Chart.js
```jsx
import { Bar } from 'react-chartjs-2';
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend } from 'chart.js';
ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

export default function MiGrafico({ data, labels }) {
  return <Bar data={{
    labels,
    datasets: [{ label: 'Datos', data, backgroundColor: '#3b82f6' }]
  }} />;
}
```

Tipos disponibles: `Bar`, `Line`, `Pie`, `Doughnut`, `Radar` (importar de `react-chartjs-2`).

## Cómo deployar

Después de editar archivos:

```bash
git -C sites/canvas add -A && git -C sites/canvas commit -m "update canvas" && git -C sites/canvas push
```

Vercel detecta el push y deploya automáticamente.

## Reglas
- NO toques `package.json` ni `vite.config.js` a menos que necesites agregar una dependencia
- NO necesitás correr `npm install` ni `npm run build` — Vercel lo hace
- Componentes nuevos van en `src/components/`
- Importalos desde `App.jsx` para mostrarlos
- Commiteá con mensajes descriptivos cuando sea posible
