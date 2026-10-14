// Controlador para los subtipos de PERSONA (CLIENTE y EMPLEADO).
//
// En el modelo, los datos personales (nombre, teléfono, correo, etc) viven en
// PERSONA, y CLIENTE / EMPLEADO solo guardan lo propio + ID_PER.
// Para el consumidor del API se exponen como un solo recurso "plano":
//
const { sql, getPool } = require('../config/db');
const { HttpError } = require('../utils/httpError');
const crudFactory = require('./crud.factory');
const personas = require('./personas.controller');

const PERSONA_COLS = ['NOMBRE_PER', 'APELLIDO_PER', 'TELEFONO', 'CORREO_PER', 'DIRECCION_PER', 'ID_MUN'];
const has = (obj, k) => Object.prototype.hasOwnProperty.call(obj, k);

function personaSubtipoFactory({ label, table, key, columns }) {
  // CRUD básico de la tabla del subtipo (se reutiliza insertRow y parseKeys)
  const base = crudFactory({ label, table, keys: [key], columns: [...columns, 'ID_PER'] });

  const selectCompleto =
    `SELECT s.*, ${PERSONA_COLS.map((c) => 'p.' + c).join(', ')} ` +
    `FROM ${table} s INNER JOIN PERSONA p ON p.ID_PER = s.ID_PER`;

  async function findCompleto(executor, id) {
    const r = await executor.request().input('id', sql.Int, id)
      .query(`${selectCompleto} WHERE s.${key} = @id`);
    return r.recordset[0] || null;
  }

  // Separa el body plano en datos de PERSONA y datos propios del subtipo
  function separar(body) {
    if (!body || typeof body !== 'object' || Array.isArray(body)) {
      throw new HttpError(400, 'Cada registro debe ser un objeto JSON');
    }
    const persona = {};
    const propio = {};
    PERSONA_COLS.forEach((c) => { if (has(body, c)) persona[c] = body[c]; });
    columns.forEach((c) => { if (has(body, c)) propio[c] = body[c]; });
    if (has(body, 'ID_PER')) propio.ID_PER = body.ID_PER;
    return { persona, propio };
  }

  async function crearUno(tx, body) {
    const { persona, propio } = separar(body);
    if (propio.ID_PER === undefined) {
      const nueva = await personas.insertRow(tx, persona);   // 1) PERSONA
      propio.ID_PER = nueva.ID_PER;
    }
    const creado = await base.insertRow(tx, propio);          // 2) CLIENTE / EMPLEADO
    return findCompleto(tx, creado[key]);
  }

  async function enTransaccion(pool, trabajo) {
    const tx = new sql.Transaction(pool);
    await tx.begin();
    try {
      const resultado = await trabajo(tx);
      await tx.commit();
      return resultado;
    } catch (err) {
      try { await tx.rollback(); } catch (_) { /* ya revertida */ }
      throw err;
    }
  }

  // GET /   (filtros por columnas propias: ?ID_TI=1)
  const list = async (req, res, next) => {
    try {
      const pool = await getPool();
      const request = pool.request();
      const where = [];
      for (const [k, v] of Object.entries(req.query)) {
        if ([key, 'ID_PER', ...columns].includes(k)) {
          request.input(`f_${k}`, v);
          where.push(`s.${k} = @f_${k}`);
        }
      }
      const r = await request.query(
        `${selectCompleto}${where.length ? ' WHERE ' + where.join(' AND ') : ''} ORDER BY s.${key}`
      );
      res.json(r.recordset);
    } catch (err) {
      next(err);
    }
  };

  // GET /:id
  const getById = async (req, res, next) => {
    try {
      const id = base.parseKeys(req.params)[key];
      const row = await findCompleto(await getPool(), id);
      if (!row) throw new HttpError(404, `${label} (${key}=${id}) no existe`);
      res.json(row);
    } catch (err) {
      next(err);
    }
  };

  // POST /   (objeto = uno; arreglo = carga masiva, todo en una transacción)
  const create = async (req, res, next) => {
    try {
      const pool = await getPool();
      const lote = Array.isArray(req.body);
      const items = lote ? req.body : [req.body];
      if (items.length === 0) throw new HttpError(400, 'El arreglo de registros está vacío');

      const registros = await enTransaccion(pool, async (tx) => {
        const out = [];
        for (const item of items) out.push(await crearUno(tx, item));
        return out;
      });
      res.status(201).json(lote ? { insertados: registros.length, registros } : registros[0]);
    } catch (err) {
      next(err);
    }
  };

  // PUT /:id   (puede traer campos de PERSONA y/o del subtipo)
  const update = async (req, res, next) => {
    try {
      const id = base.parseKeys(req.params)[key];
      const pool = await getPool();
      const actual = await findCompleto(pool, id);
      if (!actual) throw new HttpError(404, `${label} (${key}=${id}) no existe`);

      const { persona, propio } = separar(req.body);
      delete propio.ID_PER; // la persona asociada no se reasigna
      if (!Object.keys(persona).length && !Object.keys(propio).length) {
        throw new HttpError(400, `Debe enviar al menos uno de: ${[...PERSONA_COLS, ...columns].join(', ')}`);
      }

      await enTransaccion(pool, async (tx) => {
        if (Object.keys(propio).length) {
          const r = tx.request().input('id', sql.Int, id);
          Object.entries(propio).forEach(([c, v]) => r.input(c, v));
          await r.query(`UPDATE ${table} SET ${Object.keys(propio).map((c) => `${c} = @${c}`).join(', ')} WHERE ${key} = @id`);
        }
        if (Object.keys(persona).length) {
          const r = tx.request().input('idPer', sql.Int, actual.ID_PER);
          Object.entries(persona).forEach(([c, v]) => r.input(c, v));
          await r.query(`UPDATE PERSONA SET ${Object.keys(persona).map((c) => `${c} = @${c}`).join(', ')} WHERE ID_PER = @idPer`);
        }
      });
      res.json(await findCompleto(pool, id));
    } catch (err) {
      next(err);
    }
  };

  // DELETE /:id   (borra el subtipo y, si nadie más la usa, también su PERSONA)
  const remove = async (req, res, next) => {
    try {
      const id = base.parseKeys(req.params)[key];
      const pool = await getPool();
      const actual = await findCompleto(pool, id);
      if (!actual) throw new HttpError(404, `${label} (${key}=${id}) no existe`);

      await enTransaccion(pool, async (tx) => {
        await tx.request().input('id', sql.Int, id).query(`DELETE FROM ${table} WHERE ${key} = @id`);
        await tx.request().input('idPer', sql.Int, actual.ID_PER).query(`
          IF NOT EXISTS (SELECT 1 FROM CLIENTE  WHERE ID_PER = @idPer)
         AND NOT EXISTS (SELECT 1 FROM EMPLEADO WHERE ID_PER = @idPer)
              DELETE FROM PERSONA WHERE ID_PER = @idPer;`);
      });
      res.json({ mensaje: `${label} (${key}=${id}) eliminado`, registro: actual });
    } catch (err) {
      next(err);
    }
  };

  return { list, getById, create, update, remove, findCompleto, parseKeys: base.parseKeys, idPath: base.idPath };
}

module.exports = personaSubtipoFactory;