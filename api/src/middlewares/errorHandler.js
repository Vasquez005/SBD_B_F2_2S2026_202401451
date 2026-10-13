// Traduce los errores (propios del API y de SQL Server) a respuestas HTTP.
//
// Cuando un trigger ejecuta RAISERROR + ROLLBACK, SQL Server envía DOS errores:
//   50000 -> el mensaje del RAISERROR (ej. "Stock insuficiente")
//   3609  -> "The transaction ended in the trigger..."

const { HttpError } = require('../utils/httpError');

function flattenErrors(err) {
  const out = [];
  const seen = new Set();
  (function visit(e) {
    if (!e || typeof e !== 'object' || seen.has(e)) return;
    seen.add(e);
    out.push(e);
    if (Array.isArray(e.precedingErrors)) e.precedingErrors.forEach(visit);
    if (e.originalError) visit(e.originalError);
    if (Array.isArray(e.errors)) e.errors.forEach(visit);
  })(err);
  return out;
}

const CONNECTION_CODES = ['ESOCKET', 'ELOGIN', 'ETIMEOUT', 'ECONNCLOSED', 'ECONNREFUSED', 'EINSTLOOKUP'];

function mapError(err) {
  // Errores de validación del propio API
  if (err instanceof HttpError) {
    return { status: err.status, body: { error: err.message } };
  }
  // JSON mal formado en el body
  if (err.type === 'entity.parse.failed') {
    return { status: 400, body: { error: 'JSON inválido en el cuerpo de la petición' } };
  }

  const all = flattenErrors(err);

  // 1) Reglas de negocio de los triggers (RAISERROR pasa a número 50000)
  const negocio = all.find((e) => Number(e.number) >= 50000);
  if (negocio) {
    return { status: 400, body: { error: negocio.message, origen: 'trigger' } };
  }

  // 2) Sin conexión con la base
  if (all.some((e) => CONNECTION_CODES.includes(e.code) || e.name === 'ConnectionError')) {
    return { status: 503, body: { error: 'No hay conexión con la base de datos', detalle: err.message } };
  }

  // 3) Errores del motor por número
  const sqlErr = all.find((e) => typeof e.number === 'number' && ![3609, 3616].includes(e.number));
  if (sqlErr) {
    const msg = sqlErr.message || '';
    switch (sqlErr.number) {
      case 547: // FOREIGN KEY o CHECK
        if (/REFERENCE/i.test(msg) && !/FOREIGN KEY/i.test(msg)) {
          return { status: 409, body: { error: 'No se puede eliminar: el registro está siendo usado por otros registros', detalle: msg } };
        }
        if (/FOREIGN KEY/i.test(msg)) {
          return { status: 400, body: { error: 'Referencia inválida: el registro relacionado no existe', detalle: msg } };
        }
        return { status: 400, body: { error: 'El dato no cumple una restricción CHECK', detalle: msg } };
      case 2627: // UNIQUE / PRIMARY KEY
      case 2601: // índice único
        return { status: 409, body: { error: 'Registro duplicado (valor único repetido)', detalle: msg } };
      case 515: // NOT NULL
        return { status: 400, body: { error: 'Falta un campo obligatorio', detalle: msg } };
      case 245: case 241: case 242: case 8114: case 8115: case 220: case 248: case 8152: case 2628:
        return { status: 400, body: { error: 'Tipo o tamaño de dato inválido', detalle: msg } };
      default:
        return { status: 500, body: { error: 'Error en la base de datos', detalle: msg } };
    }
  }

  return { status: 500, body: { error: 'Error interno del servidor', detalle: err.message } };
}

// Middleware de Express: recibe cualquier error lanzado con next(err)
function errorHandler(err, req, res, _next) {
  const { status, body } = mapError(err);
  if (status >= 500) console.error(err);
  res.status(status).json(body);
}

function notFound(req, res) {
  res.status(404).json({ error: `Ruta no encontrada: ${req.method} ${req.originalUrl}` });
}

module.exports = { errorHandler, notFound, mapError };