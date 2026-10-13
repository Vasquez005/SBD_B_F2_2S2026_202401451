require('dotenv').config();
const app = require('./app');
const { getPool, config } = require('./config/db');

const PORT = process.env.PORT || 3000;

// Intenta conectar varias veces (SQL Server puede tardar en estar listo)
async function conectarConReintentos(intentos = 10, esperaMs = 3000) {
  for (let i = 1; i <= intentos; i++) {
    try {
      await getPool();
      console.log(`Conectado a SQL Server ${config.server}:${config.port} / ${config.database}`);
      return;
    } catch (err) {
      console.error(`Intento ${i}/${intentos} de conexión fallido: ${err.message}`);
      await new Promise((r) => setTimeout(r, esperaMs));
    }
  }
  console.error('No se pudo conectar a la base de datos; se reintentará en cada petición.');
}

app.listen(PORT, () => {
  console.log(`API Comercial La Estrella escuchando en http://localhost:${PORT}`);
  conectarConReintentos();
});