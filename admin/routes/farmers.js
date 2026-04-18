const express = require('express');
const { db, logActivity } = require('../db');
const router = express.Router();

const requireAdmin = (req, res, next) => {
  if (!req.session.user || req.session.user.role !== 'admin') return res.status(401).json({ error: 'Unauthorized' });
  next();
};

router.get('/', requireAdmin, (req, res) => {
  const { search } = req.query;
  let farmers;
  if (search) {
    farmers = db.prepare('SELECT * FROM farmers WHERE name LIKE ? OR location LIKE ? OR crop_type LIKE ?').all(`%${search}%`, `%${search}%`, `%${search}%`);
  } else {
    farmers = db.prepare('SELECT * FROM farmers').all();
  }
  res.json(farmers);
});

router.post('/', requireAdmin, (req, res) => {
  const { name, location, crop_type, contact, image_url } = req.body;
  if (!name) return res.status(400).json({ error: 'Name required' });
  const result = db.prepare('INSERT INTO farmers (name, location, crop_type, contact, image_url) VALUES (?, ?, ?, ?, ?)').run(name, location || '', crop_type || '', contact || '', image_url || '');
  logActivity('FARMER_CREATED', `Farmer ${name} added`, req.session.user.email);
  res.json({ id: result.lastInsertRowid, name, location, crop_type, contact, image_url, status: 'active' });
});

router.put('/:id', requireAdmin, (req, res) => {
  const { name, location, crop_type, contact, image_url, status } = req.body;
  const farmer = db.prepare('SELECT * FROM farmers WHERE id = ?').get(req.params.id);
  if (!farmer) return res.status(404).json({ error: 'Farmer not found' });
  db.prepare('UPDATE farmers SET name=?, location=?, crop_type=?, contact=?, image_url=?, status=? WHERE id=?').run(
    name || farmer.name, location || farmer.location, crop_type || farmer.crop_type,
    contact || farmer.contact, image_url || farmer.image_url, status || farmer.status, req.params.id
  );
  logActivity('FARMER_UPDATED', `Farmer ${farmer.name} updated`, req.session.user.email);
  res.json({ success: true });
});

router.delete('/:id', requireAdmin, (req, res) => {
  const farmer = db.prepare('SELECT * FROM farmers WHERE id = ?').get(req.params.id);
  if (!farmer) return res.status(404).json({ error: 'Farmer not found' });
  db.prepare('DELETE FROM farmers WHERE id = ?').run(req.params.id);
  logActivity('FARMER_DELETED', `Farmer ${farmer.name} removed`, req.session.user.email);
  res.json({ success: true });
});

module.exports = router;
