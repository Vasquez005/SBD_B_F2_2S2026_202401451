const crudFactory = require('./crud.factory');

module.exports = crudFactory({
  label: 'Tienda',
  table: 'TIENDA',
  keys: ['ID_TI'],
  columns: ['NOMBRE_TI', 'DIRECCION_TI', 'TELEFONO_TI', 'ID_MUN', 'ID_TIP_TIE'],
});