# AgriTrack — Smart Agriculture App (Pakistan)

## Architecture
- **Flutter Web** (port 5000): Mobile-style splash/onboarding UI served via `serve.dart`
- **Admin + Farmer Portal** (port 3001): Node.js/Express with SQLite, dual-portal

## Startup
```
bash start.sh
```
Runs both servers concurrently.

## Access

### Admin Panel
- URL: `http://localhost:3001/` or `/login.html`
- Login: `user@gmail.com` / `User123`

### Farmer Portal
- URL: `http://localhost:3001/farmer.html` or `/farmer-login.html`
- Demo login: `farmer@gmail.com` / `Farmer123`
- Farmers can also register new accounts

## Modules

### 1. 🌱 Farmer Dashboard
- Welcome banner with quick stats
- Recent market rates
- Recent order history
- Cart item count

### 2. 🧪 Sprays & Pesticides
- Dedicated pesticides section with details: usage, effects, crop compatibility
- Price in PKR with unit
- Search + filter
- Detail modal with full info

### 3. 🌿 Fertilizers
- Fertilizer listing with usage guide, benefits
- Full detail modal

### 4. 🛒 E-Commerce Shop
- All products grid (pesticides + fertilizers)
- Search by name, crop compatibility
- Filter by type (all / pesticide / fertilizer)
- Add to cart with qty controls
- Cart persisted in localStorage

### 5. 💳 Payment System (Pakistan)
- JazzCash (mobile wallet)
- Easypaisa (mobile wallet)
- Bank Transfer
- Flow: select payment → see instructions with account number → upload screenshot → submit
- Admin can configure payment numbers in Settings

### 6. 🛠 Admin Approval System
- Admin views all orders with payment screenshot
- Approve / Reject / Ship / Delivered status flow
- Add tracking link and admin notes
- Orders filtered by status tab

### 7. 📦 Order System
- Statuses: pending → approved → shipped → delivered (or rejected)
- Farmer sees colored status cards with real-time messages
- Tracking link shown when available

### 8. 📊 Live Market Rates (Pakistan)
- Crops: Wheat, Rice Basmati, Rice IRRI, Cotton, Maize, Sugarcane, Sunflower, Onion
- Urdu + English crop names
- Price change % (up/down/stable indicators)
- Admin can add/update/delete rates in real time

### 9. 🤖 AI Agriculture Assistant
- Rule-based AI for Wheat, Rice, Cotton, Maize
- Farmer selects crop type + describes problem
- System matches: rust, aphids, blast, stem borer, bollworm, weed, yellowing, etc.
- Returns: recommended pesticide + fertilizer with prices, expert tip
- Confidence level shown (high/medium/low)
- Direct "Add to Cart" from AI result

### 10. 📧 Email System
- nodemailer installed and ready
- Configure SMTP in settings for order confirmation emails

## Database (SQLite: admin/agritrack.db)
- `users` — admin + farmer accounts with role-based auth
- `farmers` — farmer profiles (name, location, crop, contact)
- `products` — pesticides + fertilizers (type, price, stock, usage, effects, compatibility)
- `orders` — full order with billing/shipping/payment details
- `order_items` — line items per order
- `market_rates` — live crop prices with change %
- `activity_log` — admin activity tracking

## File Structure
```
admin/
  server.js            — Express app (port 3001)
  db.js                — SQLite schema + seed data
  routes/
    auth.js            — Login (admin + farmer-login endpoints)
    users.js           — User CRUD
    farmers.js         — Farmer CRUD
    products.js        — Products CRUD (public browse + admin manage)
    orders.js          — Order placement + admin management
    market.js          — Market rates CRUD
    ai.js              — AI recommendation engine (rule-based)
    stats.js           — Dashboard analytics
  public/
    index.html         — Admin SPA
    login.html         — Admin login
    farmer.html        — Farmer portal SPA
    farmer-login.html  — Farmer login + register
    css/
      admin.css        — Admin panel styles
      farmer.css       — Farmer portal styles
    js/
      admin.js         — Admin panel logic
      farmer.js        — Farmer portal logic
    uploads/           — Payment screenshots
serve.dart             — Dart HTTP server for Flutter web
start.sh               — Startup script
```

## Credentials
| Role    | Email             | Password  |
|---------|-------------------|-----------|
| Admin   | user@gmail.com    | User123   |
| Farmer  | farmer@gmail.com  | Farmer123 |

## Flutter Mobile App (port 5000)

### Flutter Modules
- **Home Dashboard** — Weather, Farm Health, Upcoming Tasks, Market Prices (Firebase)
- **Agri Shop** — Tab: All / Sprays / Fertilizers / Seeds, 17 products from backend, search, 3D cards
- **Disease Detection** — AI camera-based crop disease scanner (Firebase)
- **Pakistan Market Rates** — Live grid from Node.js backend, trend indicators (+/-)
- **Profile** — User settings

### Flutter Navigation (5-tab CurvedNavigationBar)
1. Home
2. Shop (with cart badge count)
3. Disease Scanner
4. Market Rates
5. Profile

### Floating Action Buttons
- AI Farming Assistant (purple) — crop + problem → recommendation + add to cart
- Farm Chatbot (green) — SmartFarmAssistant chatbot
- Quick Actions menu — shortcut to Shop, Cart, Orders, AI, Market, Disease scan

### Flutter Key Files
```
lib/
  services/
    backend_service.dart   — HTTP client to Node.js backend (port 3001)
  providers/
    cart_provider.dart     — ChangeNotifier cart state singleton
  screens/
    shop/
      agri_shop_screen.dart     — Shop with tabs, search, product grid
      product_detail_screen.dart — Product hero view, qty selector, add to cart
      cart_screen.dart          — Cart with qty controls, clear, total
      checkout_screen.dart      — Billing form, JazzCash/Easypaisa/BankTransfer, screenshot upload
    market/
      pakistan_market_screen.dart — Market rates grid from backend
    ai/
      ai_farming_screen.dart    — AI crop recommendations from backend
    orders/
      my_orders_screen.dart     — Orders by Firebase email from backend
    dashboard/
      dashboard_screen.dart     — 5-tab nav + FABs
```

## Tech Stack
- **Flutter**: Firebase Auth, google_fonts, flutter_animate, curved_navigation_bar, image_picker, http
- **Node.js**: Express, better-sqlite3, bcryptjs, express-session, multer, cors
- Vanilla JS SPA (no framework) for fast admin loading
- Dark/Light mode support
- Mobile responsive
