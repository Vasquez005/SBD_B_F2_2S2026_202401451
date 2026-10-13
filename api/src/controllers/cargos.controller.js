const crudFactory = require('./crud.factory');

module.exports = crudFactory({
  label: 'Cargo',
  table: 'CARGO',
  keys: ['ID_CAR'],
  columns: ['NOMBRE_CAR'],
});