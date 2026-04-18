const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');
const path = require('path');

const db = new Database(path.join(__dirname, 'agritrack.db'));

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role TEXT DEFAULT 'user',
    status TEXT DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS farmers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    location TEXT,
    crop_type TEXT,
    contact TEXT,
    image_url TEXT,
    status TEXT DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    price REAL NOT NULL,
    description TEXT,
    usage_guide TEXT,
    effects TEXT,
    crop_compatibility TEXT,
    image_url TEXT,
    stock INTEGER DEFAULT 100,
    unit TEXT DEFAULT 'kg',
    status TEXT DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    farmer_name TEXT,
    farmer_email TEXT,
    farmer_phone TEXT,
    billing_name TEXT,
    billing_address TEXT,
    billing_city TEXT,
    shipping_address TEXT,
    shipping_city TEXT,
    payment_method TEXT,
    payment_screenshot TEXT,
    total_amount REAL,
    status TEXT DEFAULT 'pending',
    tracking_link TEXT,
    admin_notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id)
  );

  CREATE TABLE IF NOT EXISTS order_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER,
    product_id INTEGER,
    product_name TEXT,
    quantity INTEGER,
    price REAL,
    FOREIGN KEY(order_id) REFERENCES orders(id),
    FOREIGN KEY(product_id) REFERENCES products(id)
  );

  CREATE TABLE IF NOT EXISTS market_rates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    crop_name TEXT NOT NULL,
    price REAL NOT NULL,
    unit TEXT DEFAULT 'per 40kg',
    change_pct REAL DEFAULT 0,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS activity_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action TEXT NOT NULL,
    description TEXT,
    user_email TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
`);

// Seed admin user
const adminExists = db.prepare('SELECT id FROM users WHERE email = ?').get('user@gmail.com');
if (!adminExists) {
  const hash = bcrypt.hashSync('User123', 10);
  db.prepare('INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)').run('Admin User', 'user@gmail.com', hash, 'admin');
}

// Seed demo farmer user
const farmerExists = db.prepare('SELECT id FROM users WHERE email = ?').get('farmer@gmail.com');
if (!farmerExists) {
  const hash = bcrypt.hashSync('Farmer123', 10);
  db.prepare('INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)').run('Ahmed Khan', 'farmer@gmail.com', hash, 'farmer');
}

// Seed farmers
const seedFarmers = db.prepare('SELECT COUNT(*) as cnt FROM farmers').get();
if (seedFarmers.cnt === 0) {
  const stmt = db.prepare('INSERT INTO farmers (name, location, crop_type, contact) VALUES (?, ?, ?, ?)');
  stmt.run('Ahmed Khan', 'Lahore, Punjab', 'Wheat', '+92 312 3456789');
  stmt.run('Muhammad Ali', 'Faisalabad, Punjab', 'Rice', '+92 333 4567890');
  stmt.run('Fatima Bibi', 'Multan, Punjab', 'Cotton', '+92 300 5678901');
  stmt.run('Zafar Iqbal', 'Peshawar, KPK', 'Maize', '+92 321 6789012');
}

// Seed products
const seedProducts = db.prepare('SELECT COUNT(*) as cnt FROM products').get();
if (seedProducts.cnt === 0) {
  const stmt = db.prepare('INSERT INTO products (name, type, price, description, usage_guide, effects, crop_compatibility, stock, unit) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
  // Pesticides
  stmt.run('Chlorpyrifos 40EC', 'pesticide', 850, 'Broad-spectrum organophosphate insecticide', 'Mix 2ml per litre of water, spray every 14 days', '⚠️ Harmful if ingested. Keep away from water bodies.', 'Wheat, Rice, Cotton, Maize', 200, '500ml bottle');
  stmt.run('Imidacloprid 200SL', 'pesticide', 1200, 'Systemic insecticide for sucking pests', 'Mix 0.5ml per litre, apply at first sign of infestation', '⚠️ Toxic to bees. Do not apply during flowering.', 'Cotton, Vegetables, Fruit trees', 150, '250ml bottle');
  stmt.run('Mancozeb 80WP', 'pesticide', 650, 'Broad-spectrum fungicide for fungal diseases', 'Mix 2.5g per litre, apply every 7-10 days', '⚠️ Wear protective gear during application', 'Tomato, Potato, Wheat, Grapes', 300, '500g pack');
  stmt.run('Lambda-cyhalothrin', 'pesticide', 980, 'Pyrethroid insecticide for caterpillars and beetles', 'Mix 1ml per litre of water, spray in morning or evening', '⚠️ Moderately toxic. Avoid skin contact.', 'Cotton, Maize, Vegetables', 120, '250ml bottle');
  stmt.run('Glyphosate 41%', 'pesticide', 750, 'Non-selective systemic herbicide for weed control', 'Mix 5ml per litre, spray directly on weeds', '⚠️ Do not spray on crops. Weed control only.', 'All crops (weed management)', 180, '1 litre bottle');
  // Fertilizers
  stmt.run('Urea (46% N)', 'fertilizer', 2200, 'High nitrogen fertilizer for vegetative growth', 'Apply 100-150 kg/acre, broadcast and irrigate', '✅ Boosts leaf and stem growth, improves yield', 'Wheat, Rice, Maize, Cotton', 500, '50kg bag');
  stmt.run('DAP (18-46-0)', 'fertilizer', 3800, 'Di-ammonium phosphate for root development', 'Apply 50-75 kg/acre at sowing time', '✅ Strengthens roots, promotes flowering and fruiting', 'All crops', 400, '50kg bag');
  stmt.run('Potassium Sulphate', 'fertilizer', 4200, 'Potassium fertilizer for fruit quality', 'Apply 25-50 kg/acre, 4-6 weeks after sowing', '✅ Improves fruit size, color, and shelf life', 'Fruit trees, Cotton, Vegetables', 200, '50kg bag');
  stmt.run('Zinc Sulphate', 'fertilizer', 1800, 'Micronutrient fertilizer for zinc deficiency', 'Apply 5-10 kg/acre with soil or foliar spray', '✅ Prevents stunted growth, improves tillering', 'Wheat, Rice, Maize', 250, '25kg bag');
  stmt.run('Compost (Organic)', 'fertilizer', 800, 'Organic compost for soil health', 'Apply 2-4 tons per acre before cultivation', '✅ Improves soil structure, water retention, microbiome', 'All crops', 600, '40kg bag');
}

// Seed market rates
const seedRates = db.prepare('SELECT COUNT(*) as cnt FROM market_rates').get();
if (seedRates.cnt === 0) {
  const stmt = db.prepare('INSERT INTO market_rates (crop_name, price, unit, change_pct) VALUES (?, ?, ?, ?)');
  stmt.run('Wheat (گندم)', 3800, 'per 40kg', 2.5);
  stmt.run('Rice Basmati (باسمتی)', 5200, 'per 40kg', -1.2);
  stmt.run('Rice IRRI-6 (آئی آر آر آئی)', 2800, 'per 40kg', 0.8);
  stmt.run('Cotton (کپاس)', 6500, 'per 40kg', 3.1);
  stmt.run('Maize (مکئی)', 2200, 'per 40kg', -0.5);
  stmt.run('Sugarcane (گنا)', 450, 'per 40kg', 1.8);
  stmt.run('Sunflower (سورج مکھی)', 4200, 'per 40kg', 0.0);
  stmt.run('Onion (پیاز)', 1800, 'per 40kg', -4.2);
}

const logActivity = (action, description, userEmail = 'system') => {
  db.prepare('INSERT INTO activity_log (action, description, user_email) VALUES (?, ?, ?)').run(action, description, userEmail);
};

module.exports = { db, logActivity };
