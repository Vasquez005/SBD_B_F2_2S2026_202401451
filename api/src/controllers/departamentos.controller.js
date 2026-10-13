const crudFactory = require('./crud.factory');

module.exports = crudFactory({
  label: 'Departamento',
  table: 'DEPARTAMENTO',
  keys: ['ID_DEP'],
  columns: ['NOMBRE_DEP', 'ID_PA'],
});