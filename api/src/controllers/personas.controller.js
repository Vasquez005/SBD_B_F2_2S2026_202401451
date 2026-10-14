const crudFactory = require('./crud.factory');

// PERSONA: supertipo de CLIENTE y EMPLEADO.
module.exports = crudFactory({
  label: 'Persona',
  table: 'PERSONA',
  keys: ['ID_PER'],
  columns: ['NOMBRE_PER', 'APELLIDO_PER', 'TELEFONO', 'CORREO_PER', 'DIRECCION_PER', 'ID_MUN'],
});