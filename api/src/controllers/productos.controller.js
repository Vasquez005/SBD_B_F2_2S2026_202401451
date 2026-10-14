const crudFactory = require('./crud.factory');

// El precio y la existencia NO están aquí: son por tienda, en CATALOGO_PRODUCTO (Fase 9).
module.exports = crudFactory({
  label: 'Producto',
  table: 'PRODUCTO',
  keys: ['ID_PRO'],
  columns: ['NOMBRE_PRO', 'DESCRIPCION_PRO', 'ID_CAT', 'ID_MAR'],
});