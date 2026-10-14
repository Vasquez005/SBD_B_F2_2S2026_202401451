const personaSubtipoFactory = require('./personaSubtipo.factory');

module.exports = personaSubtipoFactory({
  label: 'Cliente',
  table: 'CLIENTE',
  key: 'ID_CLI',
  columns: ['ID_TIP_IDE', 'NUMERO_IDENTIFICACION'],
});