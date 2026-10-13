const crudFactory = require('./crud.factory');

module.exports = crudFactory({
  label: 'Tipo de identificación',
  table: 'TIPO_IDENTIFICACION',
  keys: ['ID_TIP_IDE'],
  columns: ['NOMBRE_TIP_IDE'],
});