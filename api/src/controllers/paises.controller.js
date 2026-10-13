const crudFactory = require('./crud.factory');

module.exports = crudFactory({
  label: 'País',
  table: 'PAIS',
  keys: ['ID_PA'],
  columns: ['NOMBRE_PA'],
});