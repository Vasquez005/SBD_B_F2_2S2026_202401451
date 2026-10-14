const express = require('express');
const crudRouter = require('./crudRouter');
const { getPool } = require('../config/db');

// Catálogos (Fase 7)
const paises = require('../controllers/paises.controller');
const departamentos = require('../controllers/departamentos.controller');
const municipios = require('../controllers/municipios.controller');
const tiposTienda = require('../controllers/tiposTienda.controller');
const tiposIdentificacion = require('../controllers/tiposIdentificacion.controller');
const cargos = require('../controllers/cargos.controller');
const categorias = require('../controllers/categorias.controller');
const marcas = require('../controllers/marcas.controller');
const estadosVenta = require('../controllers/estadosVenta.controller');
const metodosPago = require('../controllers/metodosPago.controller');
const tiendas = require('../controllers/tiendas.controller');
const productos = require('../controllers/productos.controller');
const personas = require('../controllers/personas.controller');
const clientes = require('../controllers/clientes.controller');
const empleados = require('../controllers/empleados.controller');
const catalogoProductos = require('../controllers/catalogoProductos.controller');
const ventas = require('../controllers/ventas.controller');
const desgloseVenta = require('../controllers/desgloseVenta.controller');
const pagos = require('../controllers/pagos.controller');
const reportes = require('../controllers/reportes.controller');

const router = express.Router();

// Estado del API y de la conexión a la base
router.get('/health', async (req, res) => {
  try {
    const pool = await getPool();
    const r = await pool.request().query(
      'SELECT DB_NAME() AS base_datos, SUSER_SNAME() AS usuario, SYSDATETIME() AS hora_servidor'
    );
    res.json({ api: 'ok', db: 'ok', ...r.recordset[0] });
  } catch (err) {
    res.status(503).json({ api: 'ok', db: 'sin conexión', detalle: err.message });
  }
});

// ---------- CRUD: catálogos ----------
router.use('/paises', crudRouter(paises));
router.use('/departamentos', crudRouter(departamentos));
router.use('/municipios', crudRouter(municipios));
router.use('/tipos-tienda', crudRouter(tiposTienda));
router.use('/tipos-identificacion', crudRouter(tiposIdentificacion));
router.use('/cargos', crudRouter(cargos));
router.use('/categorias', crudRouter(categorias));
router.use('/marcas', crudRouter(marcas));
router.use('/estados-venta', crudRouter(estadosVenta));
router.use('/metodos-pago', crudRouter(metodosPago));
router.use('/tiendas', crudRouter(tiendas));
router.use('/productos', crudRouter(productos));
router.use('/personas', crudRouter(personas));
router.use('/clientes', crudRouter(clientes));     // PERSONA + CLIENTE en transacción
router.use('/empleados', crudRouter(empleados));   // PERSONA + EMPLEADO en transacción
router.use('/catalogo-productos', crudRouter(catalogoProductos));   // /:ID_TI/:ID_PRO
router.use('/ventas', crudRouter(ventas, (r) => r.get('/:ID_VEN/completa', ventas.completa)));
router.use('/desglose-venta', crudRouter(desgloseVenta));           // /:ID_VEN/:ID_PRO -> trigger Insert_Detalle
router.use('/pagos', crudRouter(pagos));                            // trigger Insert_Pago
router.get('/reportes/ventas-ubicacion', reportes.ventasUbicacion);
router.get('/reportes/top-productos', reportes.topProductos);
router.get('/reportes/saldos-pendientes', reportes.saldosPendientes);

// Índice de endpoints (útil para la revisión)
router.get('/', (req, res) => {
  res.json({
    salud: '/api/health',
    catalogos: ['/api/paises', '/api/departamentos', '/api/municipios', '/api/tipos-tienda',
      '/api/tipos-identificacion', '/api/cargos', '/api/categorias', '/api/marcas',
      '/api/estados-venta', '/api/metodos-pago'],
    principales: ['/api/tiendas', '/api/productos', '/api/personas', '/api/clientes', '/api/empleados'],
    transaccionales: ['/api/catalogo-productos/:ID_TI/:ID_PRO', '/api/ventas',
      '/api/ventas/:ID_VEN/completa', '/api/desglose-venta/:ID_VEN/:ID_PRO', '/api/pagos'],
    reportes: ['/api/reportes/ventas-ubicacion', '/api/reportes/top-productos',
      '/api/reportes/saldos-pendientes'],
  });
});

module.exports = router;