const crudFactory = require('./crud.factory');
const { sql, getPool } = require('../config/db');
const { HttpError } = require('../utils/httpError');

// Busca el id de un estado por su nombre (no depende de números fijos)
async function idEstado(executor, nombre) {
  const r = await executor.request()
    .input('nombre', sql.NVarChar, nombre)
    .query('SELECT ID_ES_VEN FROM ESTADO_VENTA WHERE NOMBRE_ES_VEN = @nombre');
  if (!r.recordset[0]) throw new HttpError(500, `No existe el estado ${nombre} en ESTADO_VENTA`);
  return r.recordset[0].ID_ES_VEN;
}

const ventas = crudFactory({
  label: 'Venta',
  table: 'VENTA',
  keys: ['ID_VEN'],
  columns: ['FECHA_VEN', 'ID_TI', 'ID_EMP', 'ID_CLI', 'ID_ES_VEN'],
  prepare: async (data, modo, executor, ids) => {
    if (modo === 'create') {
      // Toda venta nace REGISTRADA (DEFAULT de la tabla)
      delete data.ID_ES_VEN;
      return;
    }
    // PAGADA solo la asigna el motor (trigger Insert_Pago)
    if (data.ID_ES_VEN !== undefined && Number(data.ID_ES_VEN) === (await idEstado(executor, 'PAGADA'))) {
      throw new HttpError(400, 'El estado PAGADA lo asigna automáticamente el motor al completarse los pagos');
    }
    // El inventario se descontó de la tienda original: no se puede cambiar
    if (data.ID_TI !== undefined) {
      const r = await executor.request().input('id', sql.Int, ids.ID_VEN)
        .query('SELECT COUNT(*) AS N FROM DESGLOSE_VENTA WHERE ID_VEN = @id');
      if (r.recordset[0].N > 0) {
        throw new HttpError(400, 'No se puede cambiar la tienda de una venta que ya tiene productos');
      }
    }
  },
});

// Venta con nombre del estado, total (suma del desglose) y monto pagado
const SELECT_VENTA = `
  SELECT v.*, e.NOMBRE_ES_VEN AS ESTADO,
         CAST(ISNULL((SELECT SUM(d.SUBTOTAL_DES_VEN) FROM DESGLOSE_VENTA d WHERE d.ID_VEN = v.ID_VEN), 0) AS DECIMAL(12,2)) AS TOTAL,
         CAST(ISNULL((SELECT SUM(p.MONTO_PAG)        FROM PAGO p           WHERE p.ID_VEN = v.ID_VEN), 0) AS DECIMAL(12,2)) AS PAGADO
  FROM VENTA v
  INNER JOIN ESTADO_VENTA e ON e.ID_ES_VEN = v.ID_ES_VEN`;

async function buscarVenta(executor, id) {
  const r = await executor.request().input('id', sql.Int, id).query(`${SELECT_VENTA} WHERE v.ID_VEN = @id`);
  return r.recordset[0] || null;
}

// GET /api/ventas   (filtros: ?ID_TI=1, ?ID_CLI=2, ?ID_ES_VEN=1)
ventas.list = async (req, res, next) => {
  try {
    const pool = await getPool();
    const request = pool.request();
    const where = [];
    for (const [k, v] of Object.entries(req.query)) {
      if (['ID_TI', 'ID_EMP', 'ID_CLI', 'ID_ES_VEN'].includes(k)) {
        request.input(`f_${k}`, v);
        where.push(`v.${k} = @f_${k}`);
      }
    }
    const r = await request.query(`${SELECT_VENTA}${where.length ? ' WHERE ' + where.join(' AND ') : ''} ORDER BY v.ID_VEN`);
    res.json(r.recordset);
  } catch (err) {
    next(err);
  }
};

// GET /api/ventas/:ID_VEN
ventas.getById = async (req, res, next) => {
  try {
    const { ID_VEN } = ventas.parseKeys(req.params);
    const venta = await buscarVenta(await getPool(), ID_VEN);
    if (!venta) throw new HttpError(404, `Venta (ID_VEN=${ID_VEN}) no existe`);
    res.json(venta);
  } catch (err) {
    next(err);
  }
};

// GET /api/ventas/:ID_VEN/completa  → venta + desglose + pagos
ventas.completa = async (req, res, next) => {
  try {
    const { ID_VEN } = ventas.parseKeys(req.params);
    const pool = await getPool();
    const venta = await buscarVenta(pool, ID_VEN);
    if (!venta) throw new HttpError(404, `Venta (ID_VEN=${ID_VEN}) no existe`);
    const r = await pool.request().input('id', sql.Int, ID_VEN).query(`
      SELECT d.*, p.NOMBRE_PRO FROM DESGLOSE_VENTA d
      INNER JOIN PRODUCTO p ON p.ID_PRO = d.ID_PRO
      WHERE d.ID_VEN = @id ORDER BY d.ID_PRO;
      SELECT pg.*, m.NOMBRE_MET_PAG FROM PAGO pg
      INNER JOIN METODO_PAGO m ON m.ID_MET_PAG = pg.ID_MET_PAG
      WHERE pg.ID_VEN = @id ORDER BY pg.ID_PAG;`);
    res.json({ ...venta, desglose: r.recordsets[0], pagos: r.recordsets[1] });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/ventas/:ID_VEN  procede a la eliminación lógica: estado ANULADA.
// El trigger Anular_Venta devuelve el inventario a la tienda.
ventas.remove = async (req, res, next) => {
  try {
    const { ID_VEN } = ventas.parseKeys(req.params);
    const pool = await getPool();
    const venta = await buscarVenta(pool, ID_VEN);
    if (!venta) throw new HttpError(404, `Venta (ID_VEN=${ID_VEN}) no existe`);
    if (venta.ESTADO === 'ANULADA') throw new HttpError(400, 'La venta ya está ANULADA');

    const anulada = await idEstado(pool, 'ANULADA');
    await pool.request().input('id', sql.Int, ID_VEN).input('estado', sql.Int, anulada)
      .query('UPDATE VENTA SET ID_ES_VEN = @estado WHERE ID_VEN = @id');
    res.json({ mensaje: `Venta (ID_VEN=${ID_VEN}) anulada; el inventario se devolvió a la tienda`, registro: await buscarVenta(pool, ID_VEN) });
  } catch (err) {
    next(err);
  }
};

module.exports = ventas;