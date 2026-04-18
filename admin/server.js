const express = require('express');
const session = require('express-session');
const cors = require('cors');
const path = require('path');

const app = express();

app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
const PORT = 3001;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(session({
  secret: 'agritrack-admin-secret-2024',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false, maxAge: 86400000 }
}));

app.use(express.static(path.join(__dirname, 'public')));

// Admin routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/farmers', require('./routes/farmers'));
app.use('/api/stats', require('./routes/stats'));

// New shared routes
app.use('/api/products', require('./routes/products'));
app.use('/api/orders', require('./routes/orders'));
app.use('/api/market', require('./routes/market'));
app.use('/api/ai', require('./routes/ai'));

app.get(/(.*)/, (req, res) => {
  const p = req.path;
  if (p === '/farmer' || p === '/farmer.html' || p.startsWith('/farmer/')) {
    res.sendFile(path.join(__dirname, 'public', 'farmer.html'));
  } else if (p === '/farmer-login' || p === '/farmer-login.html') {
    res.sendFile(path.join(__dirname, 'public', 'farmer-login.html'));
  } else if (p === '/' || p === '/index.html') {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
  } else {
    res.sendFile(path.join(__dirname, 'public', 'login.html'));
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`AgriTrack server running on port ${PORT}`);
  console.log(`  Admin panel: http://localhost:${PORT}/`);
  console.log(`  Farmer portal: http://localhost:${PORT}/farmer.html`);
});
