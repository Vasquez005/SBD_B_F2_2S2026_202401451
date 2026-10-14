const crudFactory = require('./crud.factory');
const { sql } = require('../config/db');
const { HttpError } = require('../utils/httpError');

// DESGLOSE_VENTA: líneas de la venta. Llave compuesta (ID_VEN, ID_PRO).
//
// Al insertar, el trigger Insert_Detalle valida el stock de la tienda
// ("Stock insuficiente", entonces el API responde 400) y se descuenta el inventario
//
const desglose = crudFactory({
  label: 'Desglose de venta',
  table: 'DESGLOSE_VENTA',
  keys: ['ID_VEN', 'ID_PRO'],
  identity: false,
  columns: ['CANTIDAD_DES_VEN', 'PRECIO_UNITARIO_DES_VEN', 'SUBTOTAL_DES_VEN'],
  prepare: async (data, modo, executor, ids) => {
    delete data.SUBTOTAL_DES_VEN; // nunca se acepta del cliente

    if (modo === 'create') {
      if (data.ID_VEN === undefined || data.ID_PRO === undefined || data.CANTIDAD_DES_VEN === undefined) {
        throw new HttpError(400, 'Debe enviar ID_VEN, ID_PRO y CANTIDAD_DES_VEN');
      }
      if (data.PRECIO_UNITARIO_DES_VEN === undefined) {
        const r = await executor.request()
          .input('ven', sql.Int, Number(data.ID_VEN))
          .input('pro', sql.Int, Number(data.ID_PRO))
          .query(`SELECT c.PRECIO_VIGENTE_CAT_PRO
                  FROM VENTA v
                  LEFT JOIN CATALOGO_PRODUCTO c ON c.ID_TI = v.ID_TI AND c.ID_PRO = @pro
                  WHERE v.ID_VEN = @ven`);
        if (!r.recordset[0]) throw new HttpError(400, `La venta ${data.ID_VEN} no existe`);
        if (r.recordset[0].PRECIO_VIGENTE_CAT_PRO == null) {
          throw new HttpError(400, 'Stock insuficiente (el producto no está en el catálogo de la tienda de la venta)');
        }
        data.PRECIO_UNITARIO_DES_VEN = r.recordset[0].PRECIO_VIGENTE_CAT_PRO;
      }
      data.SUBTOTAL_DES_VEN = Math.round(Number(data.CANTIDAD_DES_VEN) * Number(data.PRECIO_UNITARIO_DES_VEN) * 100) / 100;
      return;
    }

    // update: se recalcula el subtotal con los valores nuevos o los actuales
    if (data.CANTIDAD_DES_VEN === undefined && data.PRECIO_UNITARIO_DES_VEN === undefined) {
      throw new HttpError(400, 'Debe enviar CANTIDAD_DES_VEN y/o PRECIO_UNITARIO_DES_VEN');
    }
    const actual = await desglose.findByKeys(executor, ids);
    const cantidad = data.CANTIDAD_DES_VEN ?? actual.CANTIDAD_DES_VEN;
    const precio = data.PRECIO_UNITARIO_DES_VEN ?? actual.PRECIO_UNITARIO_DES_VEN;
    data.SUBTOTAL_DES_VEN = Math.round(Number(cantidad) * Number(precio) * 100) / 100;
  },
});

module.exports = desglose;