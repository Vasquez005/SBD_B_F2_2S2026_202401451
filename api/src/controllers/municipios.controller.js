const crudFactory = require('./crud.factory');

module.exports = crudFactory({
  label: 'Municipio',
  table: 'MUNICIPIO',
  keys: ['ID_MUN'],
  columns: ['NOMBRE_MUN', 'ID_DEP'],
});