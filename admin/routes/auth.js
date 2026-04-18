const express = require('express');
const bcrypt = require('bcryptjs');
const { db, logActivity } = require('../db');
const router = express.Router();

// Admin login (role must be admin)
router.post('/login', (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'Email and password required' });

  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
  if (!user) return res.status(401).json({ error: 'Invalid credentials' });

  const valid = bcrypt.compareSync(password, user.password);
  if (!valid) return res.status(401).json({ error: 'Invalid credentials' });

  if (user.role !== 'admin') return res.status(403).json({ error: 'Admin access required. Use the Farmer Portal to log in.' });

  req.session.user = { id: user.id, name: user.name, email: user.email, role: user.role };
  logActivity('LOGIN', `Admin ${user.email} logged in`, user.email);
  res.json({ success: true, user: req.session.user });
});

// Farmer portal login (any registered user)
router.post('/farmer-login', (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'Email and password required' });

  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
  if (!user) return res.status(401).json({ error: 'No account found. Please register first.' });

  const valid = bcrypt.compareSync(password, user.password);
  if (!valid) return res.status(401).json({ error: 'Incorrect password. Please try again.' });

  if (user.status === 'inactive') return res.status(403).json({ error: 'Your account has been suspended. Contact admin.' });

  req.session.user = { id: user.id, name: user.name, email: user.email, role: user.role };
  logActivity('LOGIN', `${user.role} ${user.email} logged in via farmer portal`, user.email);
  res.json({ success: true, user: req.session.user });
});

router.post('/logout', (req, res) => {
  req.session.destroy();
  res.json({ success: true });
});

router.get('/me', (req, res) => {
  if (!req.session.user) return res.status(401).json({ error: 'Not authenticated' });
  res.json({ user: req.session.user });
});

module.exports = router;
