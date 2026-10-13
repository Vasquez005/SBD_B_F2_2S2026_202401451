const crudFactory = require('./crud.factory');

module.exports = crudFactory({
  label: 'Tipo de tienda',
  table: 'TIPO_TIENDA',
  keys: ['ID_TIP_TIE'],
  columns: ['NOMBRE_TIP_TIE'],
});