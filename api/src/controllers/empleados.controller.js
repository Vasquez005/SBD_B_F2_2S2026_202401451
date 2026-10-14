const personaSubtipoFactory = require('./personaSubtipo.factory');

module.exports = personaSubtipoFactory({
  label: 'Empleado',
  table: 'EMPLEADO',
  key: 'ID_EMP',
  columns: ['FECHA_CONTRATACION', 'ID_TI', 'ID_CAR'],
});