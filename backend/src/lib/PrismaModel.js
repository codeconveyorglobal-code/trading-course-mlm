/**
 * PrismaModel.js
 * Mongoose-compatible API wrapper around Prisma + SQLite.
 * Lets controllers use Model.findOne(), find(), findById(), create(), etc.
 * without changes.
 */
const prisma = require('./prismaClient');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

// ─── Filter translation: MongoDB → Prisma WHERE ──────────────────────────────
function toWhere(filter) {
  if (!filter || Object.keys(filter).length === 0) return {};
  const where = {};
  for (const [key, val] of Object.entries(filter)) {
    if (key === '$or') {
      where.OR = val.map(toWhere);
    } else if (key === '$and') {
      where.AND = val.map(toWhere);
    } else if (val !== null && val !== undefined && typeof val === 'object' && !Array.isArray(val)) {
      const ops = Object.keys(val);
      if (ops.some(k => k.startsWith('$'))) {
        const cond = {};
        if ('$regex' in val) cond.contains = String(val.$regex);
        if ('$in' in val) cond.in = val.$in;
        if ('$nin' in val) cond.notIn = val.$nin;
        if ('$ne' in val) cond.not = val.$ne;
        if ('$gte' in val) cond.gte = val.$gte;
        if ('$lte' in val) cond.lte = val.$lte;
        if ('$gt' in val) cond.gt = val.$gt;
        if ('$lt' in val) cond.lt = val.$lt;
        where[key] = cond;
      } else {
        where[key] = val;
      }
    } else {
      where[key] = val;
    }
  }
  return where;
}

// ─── Sort translation: MongoDB → Prisma ORDERBY ──────────────────────────────
function toOrderBy(sort) {
  if (!sort) return [{ createdAt: 'desc' }];
  if (typeof sort === 'string') {
    const desc = sort.startsWith('-');
    const field = desc ? sort.slice(1) : sort;
    return [{ [field]: desc ? 'desc' : 'asc' }];
  }
  if (typeof sort === 'object') {
    return Object.entries(sort).map(([k, v]) => ({ [k]: v === -1 ? 'desc' : 'asc' }));
  }
  return [{ createdAt: 'desc' }];
}

// ─── JSON field helpers ───────────────────────────────────────────────────────
function deserialize(raw, jsonFields) {
  if (!raw) return raw;
  const result = { ...raw };
  for (const field of jsonFields) {
    if (typeof result[field] === 'string') {
      try { result[field] = JSON.parse(result[field]); } catch { result[field] = []; }
    }
  }
  if (result.id) result._id = result.id;
  return result;
}

function serialize(data, jsonFields) {
  const result = { ...data };
  delete result._id;
  delete result.__modelDef;
  for (const field of jsonFields) {
    if (Array.isArray(result[field])) {
      result[field] = JSON.stringify(result[field]);
    } else if (result[field] && typeof result[field] === 'object' && !Array.isArray(result[field])) {
      result[field] = JSON.stringify(result[field]);
    }
  }
  return result;
}

// ─── Update operator translation ─────────────────────────────────────────────
function extractUpdateData(update) {
  if (!update || typeof update !== 'object') return { plain: {} };
  if ('$set' in update) return extractUpdateData(update.$set);
  if ('$inc' in update) return { inc: update.$inc };
  if ('$addToSet' in update) return { addToSet: update.$addToSet };
  // Could have nested operators mixed — handle common combos
  const plain = {};
  const inc = {};
  const addToSet = {};
  let hasInc = false;
  let hasAddToSet = false;
  for (const [k, v] of Object.entries(update)) {
    if (k === '$inc') { Object.assign(inc, v); hasInc = true; }
    else if (k === '$addToSet') { Object.assign(addToSet, v); hasAddToSet = true; }
    else if (k === '$set') { Object.assign(plain, v); }
    else if (!k.startsWith('$')) plain[k] = v;
  }
  return { plain, ...(hasInc && { inc }), ...(hasAddToSet && { addToSet }) };
}

// ─── Document instance (behaves like a Mongoose document) ────────────────────
class Document {
  constructor(data, modelDef) {
    // Store modelDef as non-enumerable so JSON.stringify never touches it
    Object.defineProperty(this, '__modelDef', {
      value: modelDef,
      enumerable: false,
      writable: true,
      configurable: true,
    });
    for (const [k, v] of Object.entries(data)) {
      this[k] = v;
    }
    if (data.id && !this._id) this._id = data.id;
  }

  async save() {
    const id = this.id || this._id;
    if (!id) throw new Error('Cannot save document without id');
    const raw = {};
    for (const [k, v] of Object.entries(this)) {
      if (!k.startsWith('__') && k !== '_id') raw[k] = v;
    }
    // Run pre-save hook if defined
    if (this.__modelDef.preSave) await this.__modelDef.preSave(raw);
    const data = serialize(raw, this.__modelDef.jsonFields || []);
    delete data.id; // don't update primary key
    const updated = await this.__modelDef.prismaModel.update({ where: { id }, data });
    const deserialized = deserialize(updated, this.__modelDef.jsonFields || []);
    for (const [k, v] of Object.entries(deserialized)) {
      this[k] = v;
    }
    return this;
  }

  async populate(field, select) {
    if (this.__modelDef.populateField) {
      await this.__modelDef.populateField(this, field, select);
    }
    return this;
  }

  toObject() {
    const obj = {};
    for (const [k, v] of Object.entries(this)) {
      if (!k.startsWith('__')) obj[k] = v;
    }
    if (this.id) obj._id = this.id;
    return obj;
  }

  toSafeObject() {
    const obj = this.toObject();
    delete obj.password;
    delete obj.emailVerificationToken;
    delete obj.resetPasswordToken;
    return obj;
  }

  // Called by JSON.stringify / res.json() — returns plain data without internals
  toJSON() {
    const obj = {};
    for (const [k, v] of Object.entries(this)) {
      if (!k.startsWith('__')) obj[k] = v;
    }
    if (this.id) obj._id = this.id;
    return obj;
  }

  async matchPassword(enteredPassword) {
    return bcrypt.compare(enteredPassword, this.password);
  }
}

// ─── QueryBuilder (chainable, lazy, thenable) ────────────────────────────────
class QueryBuilder {
  constructor(modelDef, filter, singleId) {
    this._modelDef = modelDef;
    this._where = toWhere(filter);
    if (singleId) this._where = { id: String(singleId) };
    this._single = !!singleId;
    this._orderBy = undefined;
    this._skip = undefined;
    this._take = undefined;
    this._populateList = [];
  }

  sort(spec) { this._orderBy = toOrderBy(spec); return this; }
  skip(n) { this._skip = n; return this; }
  limit(n) { this._take = n; return this; }
  select() { return this; } // no-op — Prisma always returns all fields; drop password in toSafeObject
  populate(field, sel) { this._populateList.push({ field, sel }); return this; }

  then(resolve, reject) { return this._execute().then(resolve, reject); }
  catch(reject) { return this._execute().catch(reject); }

  async _execute() {
    const { prismaModel, jsonFields = [], populateField } = this._modelDef;
    const params = {
      where: this._where,
      orderBy: this._orderBy || [{ createdAt: 'desc' }],
    };
    if (this._skip !== undefined) params.skip = this._skip;
    if (this._take !== undefined) params.take = this._take;

    if (this._single) {
      const raw = await prismaModel.findFirst({ where: params.where });
      if (!raw) return null;
      const doc = new Document(deserialize(raw, jsonFields), this._modelDef);
      for (const { field, sel } of this._populateList) {
        if (populateField) await populateField(doc, field, sel);
      }
      return doc;
    }

    const rows = await prismaModel.findMany(params);
    const docs = rows.map(r => new Document(deserialize(r, jsonFields), this._modelDef));
    for (const doc of docs) {
      for (const { field, sel } of this._populateList) {
        if (populateField) await populateField(doc, field, sel);
      }
    }
    return docs;
  }
}

// ─── Model factory ────────────────────────────────────────────────────────────
/**
 * @param {string} modelName  - Prisma model name (lowercase, e.g. 'user')
 * @param {string[]} jsonFields - fields stored as JSON strings
 * @param {Object} populateMap  - { fieldName: { model, foreignKey?, type? } }
 * @param {Function} preSave    - optional async hook(data) before create/save
 */
function createModel(modelName, jsonFields = [], populateMap = {}, preSave = null) {
  const prismaModel = prisma[modelName];

  async function populateField(doc, fieldPath, selectHint) {
    const field = fieldPath.trim().split(' ')[0];
    const mapping = populateMap[field];
    if (!mapping) return;

    if (mapping.type === 'array') {
      // field holds a JSON array of IDs — load all related docs
      const ids = Array.isArray(doc[field]) ? doc[field] : [];
      if (!ids.length) { doc[field] = []; return; }
      const rows = await prisma[mapping.model].findMany({ where: { id: { in: ids.map(String) } } });
      doc[field] = rows.map(r => { const d = deserialize(r, mapping.jsonFields || []); d._id = r.id; return d; });
    } else {
      // single FK
      const fk = mapping.foreignKey || field + 'Id';
      const id = doc[fk] ? String(doc[fk]) : null;
      if (!id) { doc[field] = null; return; }
      const row = await prisma[mapping.model].findUnique({ where: { id } });
      if (row) { const d = deserialize(row, mapping.jsonFields || []); d._id = row.id; doc[field] = d; }
      else { doc[field] = null; }
    }
  }

  const modelDef = { prismaModel, jsonFields, populateField, preSave };

  const Model = {
    // ── findOne ──────────────────────────────────────────────────────────────
    async findOne(filter) {
      const qb = new QueryBuilder(modelDef, filter);
      qb._single = true;
      return qb;
    },

    // ── find ─────────────────────────────────────────────────────────────────
    find(filter = {}) {
      return new QueryBuilder(modelDef, filter);
    },

    // ── findById ─────────────────────────────────────────────────────────────
    findById(id) {
      if (!id) return Promise.resolve(null);
      return new QueryBuilder(modelDef, null, id);
    },

    // ── create ───────────────────────────────────────────────────────────────
    async create(data) {
      const d = { ...data };
      if (!d.id) d.id = uuidv4();
      if (preSave) await preSave(d);
      // Ensure _id isn't passed to Prisma
      delete d._id;
      const serialized = serialize(d, jsonFields);
      const result = await prismaModel.create({ data: serialized });
      return new Document(deserialize(result, jsonFields), modelDef);
    },

    // ── countDocuments ───────────────────────────────────────────────────────
    async countDocuments(filter = {}) {
      return prismaModel.count({ where: toWhere(filter) });
    },

    // ── findByIdAndUpdate ────────────────────────────────────────────────────
    async findByIdAndUpdate(id, update, opts = {}) {
      if (!id) return null;
      const where = { id: String(id) };
      const { plain = {}, inc, addToSet } = extractUpdateData(update);

      let data = {};

      if (inc) {
        for (const [k, v] of Object.entries(inc)) {
          data[k] = { increment: v };
        }
      } else if (addToSet) {
        const current = await prismaModel.findUnique({ where });
        if (!current) return null;
        for (const [k, v] of Object.entries(addToSet)) {
          const arr = (() => { try { return JSON.parse(current[k] || '[]'); } catch { return []; } })();
          const val = String(v);
          if (!arr.includes(val)) arr.push(val);
          data[k] = JSON.stringify(arr);
        }
      } else {
        data = serialize(plain, jsonFields);
        delete data.id;
      }

      try {
        const result = await prismaModel.update({ where, data });
        if (opts.new === false) return null;
        return new Document(deserialize(result, jsonFields), modelDef);
      } catch (e) {
        if (e.code === 'P2025') return null; // record not found
        throw e;
      }
    },

    // ── findOneAndUpdate ─────────────────────────────────────────────────────
    async findOneAndUpdate(filter, update, opts = {}) {
      const where = toWhere(filter);
      let existing = await prismaModel.findFirst({ where });

      const { plain = {}, inc, addToSet } = extractUpdateData(update);
      let data = inc ? {} : serialize({ ...plain }, jsonFields);
      if (inc) for (const [k, v] of Object.entries(inc)) data[k] = { increment: v };

      if (!existing) {
        if (!opts.upsert) return null;
        const createData = { id: uuidv4(), ...serialize({ ...filter, ...plain }, jsonFields) };
        const result = await prismaModel.create({ data: createData });
        return opts.new ? new Document(deserialize(result, jsonFields), modelDef) : null;
      }

      delete data.id;
      const result = await prismaModel.update({ where: { id: existing.id }, data });
      return opts.new ? new Document(deserialize(result, jsonFields), modelDef) : null;
    },

    // ── updateOne ────────────────────────────────────────────────────────────
    async updateOne(filter, update) {
      const where = toWhere(filter);
      const existing = await prismaModel.findFirst({ where });
      if (!existing) return { modifiedCount: 0 };

      const { plain = {}, inc, addToSet } = extractUpdateData(update);
      let data = {};

      if (inc) {
        for (const [k, v] of Object.entries(inc)) data[k] = { increment: v };
      } else if (addToSet) {
        for (const [k, v] of Object.entries(addToSet)) {
          const arr = (() => { try { return JSON.parse(existing[k] || '[]'); } catch { return []; } })();
          const val = String(v);
          if (!arr.includes(val)) arr.push(val);
          data[k] = JSON.stringify(arr);
        }
      } else {
        data = serialize(plain, jsonFields);
        delete data.id;
      }

      await prismaModel.update({ where: { id: existing.id }, data });
      return { modifiedCount: 1 };
    },

    // ── deleteOne ────────────────────────────────────────────────────────────
    async deleteOne(filter) {
      const where = toWhere(filter);
      const existing = await prismaModel.findFirst({ where });
      if (!existing) return { deletedCount: 0 };
      await prismaModel.delete({ where: { id: existing.id } });
      return { deletedCount: 1 };
    },

    // ── insertMany ───────────────────────────────────────────────────────────
    async insertMany(docs) {
      const results = [];
      for (const doc of docs) {
        const d = { ...doc };
        if (!d.id) d.id = uuidv4();
        if (preSave) await preSave(d);
        delete d._id;
        const serialized = serialize(d, jsonFields);
        const result = await prismaModel.create({ data: serialized });
        results.push(new Document(deserialize(result, jsonFields), modelDef));
      }
      return results;
    },

    // ── aggregate (simplified) ───────────────────────────────────────────────
    async aggregate(pipeline) {
      const matchStage = pipeline.find(s => s.$match);
      const groupStage = pipeline.find(s => s.$group);
      const limitStage = pipeline.find(s => s.$limit);
      if (!groupStage) return [];

      const group = groupStage.$group;
      const where = matchStage ? toWhere(matchStage.$match) : {};

      // Simple sum: { _id: null, total: { $sum: '$field' } }
      if (group._id === null) {
        const result = { _id: null };
        for (const [key, val] of Object.entries(group)) {
          if (key === '_id') continue;
          if (val.$sum) {
            const field = String(val.$sum).replace('$', '');
            const agg = await prismaModel.aggregate({ where, _sum: { [field]: true } });
            result[key] = agg._sum[field] || 0;
          }
          if (val.$count !== undefined) {
            result[key] = await prismaModel.count({ where });
          }
        }
        return [result];
      }

      // Date-based groupBy: { _id: { month: {$month:'$createdAt'}, year: {$year:'$createdAt'} }, ... }
      if (group._id && typeof group._id === 'object' && (group._id.month || group._id.year)) {
        const tableMap = {
          user: 'User', course: 'Course', enrollment: 'Enrollment',
          transaction: 'Transaction', commission: 'Commission',
          withdrawal: 'Withdrawal', mLMNode: 'MLMNode',
          mLMSettings: 'MLMSettings', quiz: 'Quiz', quizAttempt: 'QuizAttempt',
        };
        const tableName = tableMap[modelName] || modelName;
        const whereClauses = [];
        if (matchStage?.$match?.status) whereClauses.push(`status = '${matchStage.$match.status}'`);
        if (matchStage?.$match?.type) whereClauses.push(`type = '${matchStage.$match.type}'`);
        const whereSQL = whereClauses.length ? `WHERE ${whereClauses.join(' AND ')}` : '';
        const lim = limitStage ? limitStage.$limit : 12;
        try {
          const rows = await prisma.$queryRawUnsafe(`
            SELECT
              CAST(strftime('%m', createdAt) AS INTEGER) as month,
              CAST(strftime('%Y', createdAt) AS INTEGER) as year,
              SUM(amount) as total,
              COUNT(*) as count
            FROM "${tableName}"
            ${whereSQL}
            GROUP BY year, month
            ORDER BY year DESC, month DESC
            LIMIT ${lim}
          `);
          return rows.map(r => ({
            _id: { month: Number(r.month), year: Number(r.year) },
            total: Number(r.total) || 0,
            count: Number(r.count) || 0,
          }));
        } catch (e) {
          console.error('aggregate raw SQL error:', e.message);
          return [];
        }
      }

      return [];
    },
  };

  return Model;
}

module.exports = { createModel };
