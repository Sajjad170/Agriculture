const express = require('express');
const { db, logActivity } = require('../db');
const router = express.Router();

const requireAdmin = (req, res, next) => {
  if (!req.session.user || req.session.user.role !== 'admin') return res.status(401).json({ error: 'Unauthorized' });
  next();
};

// Public: farmers can browse products
router.get('/', (req, res) => {
  const { search, type } = req.query;
  let query = 'SELECT * FROM products WHERE status = ?';
  const params = ['active'];
  if (type) { query += ' AND type = ?'; params.push(type); }
  if (search) { query += ' AND (name LIKE ? OR description LIKE ? OR crop_compatibility LIKE ?)'; params.push(`%${search}%`, `%${search}%`, `%${search}%`); }
  query += ' ORDER BY type, name';
  res.json(db.prepare(query).all(...params));
});

router.get('/all', requireAdmin, (req, res) => {
  res.json(db.prepare('SELECT * FROM products ORDER BY type, name').all());
});

router.get('/:id', (req, res) => {
  const p = db.prepare('SELECT * FROM products WHERE id = ?').get(req.params.id);
  if (!p) return res.status(404).json({ error: 'Product not found' });
  res.json(p);
});

router.post('/', requireAdmin, (req, res) => {
  const { name, type, price, description, usage_guide, effects, crop_compatibility, image_url, stock, unit } = req.body;
  if (!name || !type || !price) return res.status(400).json({ error: 'Name, type, price required' });
  const result = db.prepare('INSERT INTO products (name, type, price, description, usage_guide, effects, crop_compatibility, image_url, stock, unit) VALUES (?,?,?,?,?,?,?,?,?,?)').run(name, type, price, description||'', usage_guide||'', effects||'', crop_compatibility||'', image_url||'', stock||100, unit||'kg');
  logActivity('PRODUCT_CREATED', `Product "${name}" (${type}) added`, req.session.user.email);
  res.json({ id: result.lastInsertRowid, ...req.body });
});

router.put('/:id', requireAdmin, (req, res) => {
  const { name, type, price, description, usage_guide, effects, crop_compatibility, image_url, stock, unit, status } = req.body;
  const p = db.prepare('SELECT * FROM products WHERE id = ?').get(req.params.id);
  if (!p) return res.status(404).json({ error: 'Not found' });
  db.prepare('UPDATE products SET name=?,type=?,price=?,description=?,usage_guide=?,effects=?,crop_compatibility=?,image_url=?,stock=?,unit=?,status=? WHERE id=?').run(
    name||p.name, type||p.type, price??p.price, description??p.description, usage_guide??p.usage_guide,
    effects??p.effects, crop_compatibility??p.crop_compatibility, image_url??p.image_url,
    stock??p.stock, unit??p.unit, status||p.status, req.params.id
  );
  logActivity('PRODUCT_UPDATED', `Product "${p.name}" updated`, req.session.user.email);
  res.json({ success: true });
});

router.delete('/:id', requireAdmin, (req, res) => {
  const p = db.prepare('SELECT * FROM products WHERE id = ?').get(req.params.id);
  if (!p) return res.status(404).json({ error: 'Not found' });
  db.prepare('UPDATE products SET status=? WHERE id=?').run('inactive', req.params.id);
  logActivity('PRODUCT_DELETED', `Product "${p.name}" removed`, req.session.user.email);
  res.json({ success: true });
});

module.exports = router;
