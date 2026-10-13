const crudFactory = require('./crud.factory');

module.exports = crudFactory({
  label: 'Método de pago',
  table: 'METODO_PAGO',
  keys: ['ID_MET_PAG'],
  columns: ['NOMBRE_MET_PAG'],
});