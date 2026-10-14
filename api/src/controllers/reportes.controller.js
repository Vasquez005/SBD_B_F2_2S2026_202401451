// Reportes: el API solo consulta las vistas.
const { getPool } = require('../config/db');

const fromView = (query) => async (req, res, next) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(query);
    res.json(result.recordset);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  ventasUbicacion: fromView(
    'SELECT * FROM Vista_Ventas_Ubicacion ORDER BY TOTAL_FACTURADO DESC;'
  ),
  topProductos: fromView(
    'SELECT * FROM Vista_Top_Productos ORDER BY UNIDADES_VENDIDAS DESC, MONTO_TOTAL DESC;'
  ),
  saldosPendientes: fromView(
    'SELECT * FROM Vista_Saldos_Pendientes ORDER BY SALDO_PENDIENTE DESC;'
  ),
};