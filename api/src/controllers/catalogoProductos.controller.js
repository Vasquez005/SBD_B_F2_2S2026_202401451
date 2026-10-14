const crudFactory = require('./crud.factory');

// CATALOGO_PRODUCTO: precio vigente y existencia de un producto en una tienda.

module.exports = crudFactory({
  label: 'Catálogo de producto',
  table: 'CATALOGO_PRODUCTO',
  keys: ['ID_TI', 'ID_PRO'],
  identity: false,
  columns: ['PRECIO_VIGENTE_CAT_PRO', 'EXISTENCIA_ACTUAL_CAT_PRO'],
});