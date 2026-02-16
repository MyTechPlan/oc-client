import { Bar } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend
} from 'chart.js';

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

const data = {
  labels: ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'],
  datasets: [{
    label: 'Ventas',
    data: [12, 19, 3, 5, 2, 3],
    backgroundColor: '#3b82f6',
  }],
};

export default function ExampleChart() {
  return (
    <div style={{ maxWidth: 600 }}>
      <h2>Ejemplo de Gráfico</h2>
      <Bar data={data} options={{ responsive: true }} />
    </div>
  );
}
