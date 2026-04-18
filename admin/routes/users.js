const express = require('express');
const bcrypt = require('bcryptjs');
const { db, logActivity } = require('../db');
const router = express.Router();

const requireAdmin = (req, res, next) => {
  if (!req.session.user || req.session.user.role !== 'admin') {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
};

router.get('/', requireAdmin, (req, res) => {
  const { search } = req.query;
  let users;
  if (search) {
    users = db.prepare('SELECT id, name, email, role, status, created_at FROM users WHERE name LIKE ? OR email LIKE ?').all(`%${search}%`, `%${search}%`);
  } else {
    users = db.prepare('SELECT id, name, email, role, status, created_at FROM users').all();
  }
  res.json(users);
});

router.post('/', requireAdmin, (req, res) => {
  const { name, email, password, role } = req.body;
  if (!name || !email || !password) return res.status(400).json({ error: 'Name, email, password required' });
  const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
  if (existing) return res.status(409).json({ error: 'Email already exists' });
  const hash = bcrypt.hashSync(password, 10);
  const result = db.prepare('INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)').run(name, email, hash, role || 'user');
  logActivity('USER_CREATED', `User ${email} created`, req.session.user.email);
  res.json({ id: result.lastInsertRowid, name, email, role: role || 'user', status: 'active' });
});

router.put('/:id', requireAdmin, (req, res) => {
  const { name, email, role, status, password } = req.body;
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: 'User not found' });
  if (password) {
    const hash = bcrypt.hashSync(password, 10);
    db.prepare('UPDATE users SET name=?, email=?, role=?, status=?, password=? WHERE id=?').run(name || user.name, email || user.email, role || user.role, status || user.status, hash, req.params.id);
  } else {
    db.prepare('UPDATE users SET name=?, email=?, role=?, status=? WHERE id=?').run(name || user.name, email || user.email, role || user.role, status || user.status, req.params.id);
  }
  logActivity('USER_UPDATED', `User ${user.email} updated`, req.session.user.email);
  res.json({ success: true });
});

router.delete('/:id', requireAdmin, (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: 'User not found' });
  if (user.email === req.session.user.email) return res.status(400).json({ error: 'Cannot delete your own account' });
  db.prepare('DELETE FROM users WHERE id = ?').run(req.params.id);
  logActivity('USER_DELETED', `User ${user.email} deleted`, req.session.user.email);
  res.json({ success: true });
});

module.exports = router;
