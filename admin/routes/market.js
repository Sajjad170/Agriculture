const express = require('express');
const { db, logActivity } = require('../db');
const router = express.Router();

const requireAdmin = (req, res, next) => {
  if (!req.session.user || req.session.user.role !== 'admin') return res.status(401).json({ error: 'Unauthorized' });
  next();
};

router.get('/', (req, res) => {
  res.json(db.prepare('SELECT * FROM market_rates ORDER BY crop_name').all());
});

router.post('/', requireAdmin, (req, res) => {
  const { crop_name, price, unit, change_pct } = req.body;
  if (!crop_name || !price) return res.status(400).json({ error: 'Crop name and price required' });
  const exists = db.prepare('SELECT id FROM market_rates WHERE crop_name = ?').get(crop_name);
  if (exists) {
    db.prepare('UPDATE market_rates SET price=?,unit=?,change_pct=?,updated_at=CURRENT_TIMESTAMP WHERE id=?').run(price, unit||'per 40kg', change_pct||0, exists.id);
    logActivity('MARKET_UPDATED', `Rate for ${crop_name} updated to PKR ${price}`, req.session.user.email);
    res.json({ success: true, id: exists.id });
  } else {
    const result = db.prepare('INSERT INTO market_rates (crop_name, price, unit, change_pct) VALUES (?,?,?,?)').run(crop_name, price, unit||'per 40kg', change_pct||0);
    logActivity('MARKET_ADDED', `Rate for ${crop_name} added: PKR ${price}`, req.session.user.email);
    res.json({ success: true, id: result.lastInsertRowid });
  }
});

router.put('/:id', requireAdmin, (req, res) => {
  const { crop_name, price, unit, change_pct } = req.body;
  const rate = db.prepare('SELECT * FROM market_rates WHERE id=?').get(req.params.id);
  if (!rate) return res.status(404).json({ error: 'Not found' });
  db.prepare('UPDATE market_rates SET crop_name=?,price=?,unit=?,change_pct=?,updated_at=CURRENT_TIMESTAMP WHERE id=?').run(
    crop_name||rate.crop_name, price??rate.price, unit||rate.unit, change_pct??rate.change_pct, req.params.id
  );
  logActivity('MARKET_UPDATED', `Rate for ${crop_name||rate.crop_name} → PKR ${price}`, req.session.user.email);
  res.json({ success: true });
});

router.delete('/:id', requireAdmin, (req, res) => {
  const rate = db.prepare('SELECT * FROM market_rates WHERE id=?').get(req.params.id);
  if (!rate) return res.status(404).json({ error: 'Not found' });
  db.prepare('DELETE FROM market_rates WHERE id=?').run(req.params.id);
  logActivity('MARKET_DELETED', `Rate for ${rate.crop_name} removed`, req.session.user.email);
  res.json({ success: true });
});

module.exports = router;
