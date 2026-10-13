const express = require('express');
const { getPool } = require('../config/db');

const router = express.Router();

// Estado del API y de la conexión a la base
router.get('/health', async (req, res) => {
  try {
    const pool = await getPool();
    const r = await pool.request().query(
      'SELECT DB_NAME() AS base_datos, SUSER_SNAME() AS usuario, SYSDATETIME() AS hora_servidor'
    );
    res.json({ api: 'ok', db: 'ok', ...r.recordset[0] });
  } catch (err) {
    res.status(503).json({ api: 'ok', db: 'sin conexión', detalle: err.message });
  }
});


module.exports = router;