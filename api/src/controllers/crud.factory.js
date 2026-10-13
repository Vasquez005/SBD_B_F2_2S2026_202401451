// Cada entidad declara su tabla, su(s) llave(s) primaria(s) y las columnas
// que acepta del JSON; esta fábrica genera list / getById / create / update / remove.
//
// - Llave simple:    keys: ['ID_PA']             rutas /:ID_PA
// - Llave compuesta: keys: ['ID_TI', 'ID_PRO']   rutas /:ID_TI/:ID_PRO  (Fase 9)
// - identity: true    el motor genera el id (IDENTITY); se lee con SCOPE_IDENTITY()
// - softDelete        DELETE lógico: { column, value }
// - prepare(data, modo, executor, ids)   validar o completar datos antes de guardar
// - beforeDelete(registro, executor)     validar antes de eliminar
//

const { sql, getPool } = require('../config/db');
const { HttpError } = require('../utils/httpError');

function crudFactory({
  label,
  table,
  keys,
  identity = true,
  columns,
  softDelete = null,
  prepare = null,
  beforeDelete = null,
}) {
  const keyList = Array.isArray(keys) ? keys : [keys];
  // Columnas permitidas en POST: si la llave es IDENTITY no se envía
  const insertable = identity
    ? columns.filter((c) => !keyList.includes(c))
    : [...new Set([...keyList, ...columns])];
  // Columnas permitidas en PUT: nunca la llave
  const updatable = columns.filter((c) => !keyList.includes(c));
  const filterable = [...new Set([...keyList, ...columns])];
  const idPath = '/' + keyList.map((k) => ':' + k).join('/');

  // ---------- utilidades ----------
  function parseKeys(params) {
    const ids = {};
    for (const k of keyList) {
      const n = Number(params[k]);
      if (!Number.isInteger(n) || n <= 0) {
        throw new HttpError(400, `${k} debe ser un número entero positivo`);
      }
      ids[k] = n;
    }
    return ids;
  }

  function whereKeys(request, ids) {
    return keyList
      .map((k) => {
        request.input(`k_${k}`, sql.Int, Number(ids[k]));
        return `${k} = @k_${k}`;
      })
      .join(' AND ');
  }

  function describe(ids) {
    return keyList.map((k) => `${k}=${ids[k]}`).join(', ');
  }

  function pick(body, allowed) {
    if (!body || typeof body !== 'object' || Array.isArray(body)) {
      throw new HttpError(400, 'El cuerpo de la petición debe ser un objeto JSON');
    }
    const data = {};
    for (const c of allowed) {
      if (Object.prototype.hasOwnProperty.call(body, c)) data[c] = body[c];
    }
    return data;
  }

  // executor = pool o transacción (ambos tienen .request())
  async function findByKeys(executor, ids) {
    const request = executor.request();
    const r = await request.query(`SELECT * FROM ${table} WHERE ${whereKeys(request, ids)}`);
    return r.recordset[0] || null;
  }

  async function insertRow(executor, body) {
    const data = pick(body, insertable);
    if (prepare) await prepare(data, 'create', executor);
    const cols = Object.keys(data);
    if (cols.length === 0) {
      throw new HttpError(400, `Debe enviar los campos: ${insertable.join(', ')}`);
    }
    const request = executor.request();
    cols.forEach((c) => request.input(c, data[c]));
    const insert = `INSERT INTO ${table} (${cols.join(', ')}) VALUES (${cols.map((c) => '@' + c).join(', ')});`;

    if (identity) {
      const r = await request.query(`${insert} SELECT * FROM ${table} WHERE ${keyList[0]} = SCOPE_IDENTITY();`);
      return r.recordset[0];
    }
    await request.query(insert);
    const ids = {};
    keyList.forEach((k) => { ids[k] = data[k]; });
    return findByKeys(executor, ids);
  }

  // ---------- manejadores HTTP ----------

  // GET /   (filtros opcionales: ?ID_DEP=1)
  const list = async (req, res, next) => {
    try {
      const pool = await getPool();
      const request = pool.request();
      const where = [];
      for (const [k, v] of Object.entries(req.query)) {
        if (filterable.includes(k)) {
          request.input(`f_${k}`, v);
          where.push(`${k} = @f_${k}`);
        }
      }
      const r = await request.query(
        `SELECT * FROM ${table}${where.length ? ' WHERE ' + where.join(' AND ') : ''} ORDER BY ${keyList.join(', ')}`
      );
      res.json(r.recordset);
    } catch (err) {
      next(err);
    }
  };

  // GET /:id
  const getById = async (req, res, next) => {
    try {
      const ids = parseKeys(req.params);
      const row = await findByKeys(await getPool(), ids);
      if (!row) throw new HttpError(404, `${label} (${describe(ids)}) no existe`);
      res.json(row);
    } catch (err) {
      next(err);
    }
  };

  // POST /   (objeto = un registro; arreglo = carga masiva en una transacción)
  const create = async (req, res, next) => {
    try {
      const pool = await getPool();

      if (Array.isArray(req.body)) {
        if (req.body.length === 0) throw new HttpError(400, 'El arreglo de registros está vacío');
        const tx = new sql.Transaction(pool);
        await tx.begin();
        try {
          const registros = [];
          for (const item of req.body) registros.push(await insertRow(tx, item));
          await tx.commit();
          return res.status(201).json({ insertados: registros.length, registros });
        } catch (err) {
          // Si un trigger ya hizo ROLLBACK, la transacción ya no existe
          try { await tx.rollback(); } catch (_) { /* ya revertida */ }
          throw err;
        }
      }

      res.status(201).json(await insertRow(pool, req.body));
    } catch (err) {
      next(err);
    }
  };

  // PUT /:id
  const update = async (req, res, next) => {
    try {
      const ids = parseKeys(req.params);
      const data = pick(req.body, updatable);
      const pool = await getPool();
      if (!(await findByKeys(pool, ids))) throw new HttpError(404, `${label} (${describe(ids)}) no existe`);
      if (prepare) await prepare(data, 'update', pool, ids);

      const cols = Object.keys(data);
      if (cols.length === 0) {
        throw new HttpError(400, `Debe enviar al menos uno de los campos: ${updatable.join(', ')}`);
      }
      const request = pool.request();
      cols.forEach((c) => request.input(c, data[c]));
      await request.query(
        `UPDATE ${table} SET ${cols.map((c) => `${c} = @${c}`).join(', ')} WHERE ${whereKeys(request, ids)}`
      );
      res.json(await findByKeys(pool, ids));
    } catch (err) {
      next(err);
    }
  };

  // DELETE /:id   (lógico si la entidad define softDelete; físico si no)
  const remove = async (req, res, next) => {
    try {
      const ids = parseKeys(req.params);
      const pool = await getPool();
      const existing = await findByKeys(pool, ids);
      if (!existing) throw new HttpError(404, `${label} (${describe(ids)}) no existe`);
      if (beforeDelete) await beforeDelete(existing, pool);

      const request = pool.request();
      const where = whereKeys(request, ids);

      if (softDelete) {
        request.input('valor', softDelete.value);
        await request.query(`UPDATE ${table} SET ${softDelete.column} = @valor WHERE ${where}`);
        return res.json({
          mensaje: `${label} (${describe(ids)}): eliminación lógica (${softDelete.column} = ${softDelete.value})`,
          registro: await findByKeys(pool, ids),
        });
      }

      await request.query(`DELETE FROM ${table} WHERE ${where}`);
      res.json({ mensaje: `${label} (${describe(ids)}) eliminado`, registro: existing });
    } catch (err) {
      next(err);
    }
  };

  return {
    list, getById, create, update, remove,
    findByKeys, parseKeys, insertRow,
    idPath, table, keys: keyList,
  };
}

module.exports = crudFactory;