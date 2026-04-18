const express = require('express');
const multer = require('multer');
const path = require('path');
const { db, logActivity } = require('../db');
const router = express.Router();

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, path.join(__dirname, '../public/uploads')),
  filename: (req, file, cb) => cb(null, Date.now() + '-' + file.originalname.replace(/[^a-zA-Z0-9.]/g, '_'))
});
const upload = multer({ storage, limits: { fileSize: 5 * 1024 * 1024 } });

const requireAdmin = (req, res, next) => {
  if (!req.session.user || req.session.user.role !== 'admin') return res.status(401).json({ error: 'Unauthorized' });
  next();
};

// Place order — works with or without session (for Flutter app)
router.post('/', upload.single('payment_screenshot'), (req, res) => {
  const { farmer_name, farmer_email, farmer_phone, billing_name, billing_address, billing_city,
    shipping_address, shipping_city, payment_method, items, total_amount } = req.body;
  if (!items) return res.status(400).json({ error: 'No items in order' });

  const screenshot = req.file ? '/uploads/' + req.file.filename : null;
  const userId = req.session?.user?.id || null;
  const senderEmail = farmer_email || req.session?.user?.email || '';

  const result = db.prepare(`INSERT INTO orders (user_id,farmer_name,farmer_email,farmer_phone,billing_name,billing_address,billing_city,shipping_address,shipping_city,payment_method,payment_screenshot,total_amount) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)`).run(
    userId, farmer_name || '', senderEmail, farmer_phone || '',
    billing_name || '', billing_address || '', billing_city || '',
    shipping_address || billing_address || '', shipping_city || billing_city || '',
    payment_method || '', screenshot, parseFloat(total_amount) || 0
  );
  const orderId = result.lastInsertRowid;

  let parsedItems = [];
  try { parsedItems = JSON.parse(items); } catch(e) {}
  const itemStmt = db.prepare('INSERT INTO order_items (order_id, product_id, product_name, quantity, price) VALUES (?,?,?,?,?)');
  parsedItems.forEach(item => itemStmt.run(orderId, item.id, item.name, item.qty || item.quantity, item.price));

  logActivity('ORDER_PLACED', `Order #${orderId} placed by ${senderEmail} — PKR ${total_amount}`, senderEmail || 'app-user');
  res.json({ success: true, order_id: orderId });
});

// Get orders by email (for Flutter app — no session needed)
router.get('/by-email/:email', (req, res) => {
  const orders = db.prepare('SELECT * FROM orders WHERE farmer_email=? ORDER BY created_at DESC').all(req.params.email);
  orders.forEach(o => { o.items = db.prepare('SELECT * FROM order_items WHERE order_id=?').all(o.id); });
  res.json(orders);
});

// Get my orders (session-based)
router.get('/my', (req, res) => {
  if (!req.session.user) return res.status(401).json({ error: 'Login required' });
  const orders = db.prepare('SELECT * FROM orders WHERE user_id=? ORDER BY created_at DESC').all(req.session.user.id);
  orders.forEach(o => { o.items = db.prepare('SELECT * FROM order_items WHERE order_id=?').all(o.id); });
  res.json(orders);
});

// Admin: get all orders
router.get('/', requireAdmin, (req, res) => {
  const { status } = req.query;
  let orders;
  if (status) {
    orders = db.prepare('SELECT * FROM orders WHERE status=? ORDER BY created_at DESC').all(status);
  } else {
    orders = db.prepare('SELECT * FROM orders ORDER BY created_at DESC').all();
  }
  orders.forEach(o => { o.items = db.prepare('SELECT * FROM order_items WHERE order_id=?').all(o.id); });
  res.json(orders);
});

// Admin: update order
router.put('/:id', requireAdmin, (req, res) => {
  const { status, tracking_link, admin_notes } = req.body;
  const order = db.prepare('SELECT * FROM orders WHERE id=?').get(req.params.id);
  if (!order) return res.status(404).json({ error: 'Order not found' });
  db.prepare('UPDATE orders SET status=?,tracking_link=?,admin_notes=? WHERE id=?').run(
    status || order.status, tracking_link || order.tracking_link || '', admin_notes || order.admin_notes || '', req.params.id
  );
  logActivity('ORDER_UPDATED', `Order #${req.params.id} → ${status}`, req.session.user.email);
  res.json({ success: true });
});

module.exports = router;
