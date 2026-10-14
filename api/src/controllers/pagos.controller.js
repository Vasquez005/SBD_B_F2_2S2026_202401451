const crudFactory = require('./crud.factory');

// Al insertar, el trigger Insert_Pago suma los pagos de la venta y, si
// cubren el total, cambia la venta a PAGADA automáticamente
module.exports = crudFactory({
  label: 'Pago',
  table: 'PAGO',
  keys: ['ID_PAG'],
  columns: ['MONTO_PAG', 'ID_MET_PAG', 'ID_VEN'],
});