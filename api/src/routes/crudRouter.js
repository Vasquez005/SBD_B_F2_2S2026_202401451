// Crea las 5 rutas CRUD estándar para un controlador.
const express = require('express');

module.exports = function crudRouter(controller, extraRoutes) {
  const router = express.Router();
  if (extraRoutes) extraRoutes(router);                 // rutas propias de la entidad
  router.get('/', controller.list);                     // listar
  router.get(controller.idPath, controller.getById);    // buscar por llave
  router.post('/', controller.create);                  // crear / carga masiva
  router.put(controller.idPath, controller.update);     // actualizar
  router.delete(controller.idPath, controller.remove);  // eliminar
  return router;
};