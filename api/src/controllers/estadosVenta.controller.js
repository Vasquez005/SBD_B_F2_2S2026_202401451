const crudFactory = require('./crud.factory');
const { HttpError } = require('../utils/httpError');

// Los triggers buscan estos estados por nombre: no se pueden renombrar ni eliminar.
const ESTADOS_BASE = ['REGISTRADA', 'PENDIENTE', 'PAGADA', 'ANULADA'];

const estadosVenta = crudFactory({
  label: 'Estado de venta',
  table: 'ESTADO_VENTA',
  keys: ['ID_ES_VEN'],
  columns: ['NOMBRE_ES_VEN'],
  prepare: async (data, modo, executor, ids) => {
    if (data.NOMBRE_ES_VEN !== undefined) {
      data.NOMBRE_ES_VEN = String(data.NOMBRE_ES_VEN).trim().toUpperCase();
    }
    if (modo === 'update') {
      const actual = await estadosVenta.findByKeys(executor, ids);
      if (actual && ESTADOS_BASE.includes(actual.NOMBRE_ES_VEN)) {
        throw new HttpError(400, `El estado ${actual.NOMBRE_ES_VEN} lo usan los triggers y no se puede modificar`);
      }
    }
  },
  beforeDelete: async (registro) => {
    if (ESTADOS_BASE.includes(registro.NOMBRE_ES_VEN)) {
      throw new HttpError(400, `El estado ${registro.NOMBRE_ES_VEN} lo usan los triggers y no se puede eliminar`);
    }
  },
});

module.exports = estadosVenta;