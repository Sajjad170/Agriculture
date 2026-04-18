const express = require('express');
const { db } = require('../db');
const router = express.Router();

const requireAdmin = (req, res, next) => {
  if (!req.session.user || req.session.user.role !== 'admin') return res.status(401).json({ error: 'Unauthorized' });
  next();
};

router.get('/', requireAdmin, (req, res) => {
  const totalUsers = db.prepare('SELECT COUNT(*) as cnt FROM users').get().cnt;
  const totalFarmers = db.prepare('SELECT COUNT(*) as cnt FROM farmers').get().cnt;
  const activeUsers = db.prepare("SELECT COUNT(*) as cnt FROM users WHERE status = 'active'").get().cnt;
  const activeFarmers = db.prepare("SELECT COUNT(*) as cnt FROM farmers WHERE status = 'active'").get().cnt;
  const recentActivity = db.prepare('SELECT * FROM activity_log ORDER BY created_at DESC LIMIT 10').all();
  const recentUsers = db.prepare('SELECT id, name, email, role, status, created_at FROM users ORDER BY created_at DESC LIMIT 5').all();
  const cropStats = db.prepare("SELECT crop_type, COUNT(*) as count FROM farmers WHERE crop_type != '' GROUP BY crop_type ORDER BY count DESC").all();

  res.json({ totalUsers, totalFarmers, activeUsers, activeFarmers, recentActivity, recentUsers, cropStats });
});

router.get('/activity', requireAdmin, (req, res) => {
  const logs = db.prepare('SELECT * FROM activity_log ORDER BY created_at DESC LIMIT 50').all();
  res.json(logs);
});

module.exports = router;
