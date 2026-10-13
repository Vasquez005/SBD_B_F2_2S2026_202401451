const express = require('express');
const cors = require('cors');
const routes = require('./routes');
const { errorHandler, notFound } = require('./middlewares/errorHandler');

const app = express();

app.use(cors());
app.use(express.json({ limit: '5mb' }));   // permite leer el body en JSON

// Log simple de cada petición: método, ruta, código y tiempo
app.use((req, res, next) => {
  const inicio = Date.now();
  res.on('finish', () => {
    console.log(`${req.method} ${req.originalUrl} -> ${res.statusCode} (${Date.now() - inicio} ms)`);
  });
  next();
});

app.get('/', (req, res) => res.json({ api: 'Comercial La Estrella', version: '1.0.0', endpoints: '/api' }));
app.use('/api', routes);

// Siempre al final: ruta no encontrada y manejo de errores
app.use(notFound);
app.use(errorHandler);

module.exports = app;