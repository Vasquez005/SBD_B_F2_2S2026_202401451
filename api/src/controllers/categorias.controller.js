const crudFactory = require('./crud.factory');

module.exports = crudFactory({
  label: 'Categoría',
  table: 'CATEGORIA',
  keys: ['ID_CAT'],
  columns: ['NOMBRE_CAT'],
});