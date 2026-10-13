const crudFactory = require('./crud.factory');

module.exports = crudFactory({
  label: 'Marca',
  table: 'MARCA',
  keys: ['ID_MAR'],
  columns: ['NOMBRE_MAR'],
});