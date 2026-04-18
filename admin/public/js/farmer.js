'use strict';

const savedTheme = localStorage.getItem('agritrack-theme') || 'light';
document.documentElement.setAttribute('data-theme', savedTheme);

// Cart stored in localStorage
let cart = JSON.parse(localStorage.getItem('agritrack-cart') || '[]');
let currentUser = null;
let allProducts = [];

const api = async (method, url, body) => {
  const opts = { method, credentials: 'include', headers: {} };
  if (body && !(body instanceof FormData)) { opts.body = JSON.stringify(body); opts.headers['Content-Type'] = 'application/json'; }
  else if (body instanceof FormData) { opts.body = body; }
  const r = await fetch(url, opts);
  return r.json();
};

function toast(msg, type = '') {
  const t = document.getElementById('toast');
  t.textContent = msg; t.className = 'toast show ' + type;
  setTimeout(() => t.className = 'toast', 3000);
}

function pkr(n) { return 'PKR ' + (parseFloat(n)||0).toLocaleString('en-PK'); }
function fmtDate(d) { if (!d) return '—'; return new Date(d).toLocaleDateString('en-PK', { month: 'short', day: 'numeric', year: 'numeric' }); }
function badge(val, map) { const cls = map[val] || 'gray'; return `<span class="badge ${cls}">${val}</span>`; }

function setTheme(t) {
  document.documentElement.setAttribute('data-theme', t);
  localStorage.setItem('agritrack-theme', t);
  document.getElementById('theme-toggle').textContent = t === 'dark' ? '☀️' : '🌙';
}
document.getElementById('theme-toggle').onclick = () => setTheme(document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark');
setTheme(savedTheme);

// Cart functions
function saveCart() {
  localStorage.setItem('agritrack-cart', JSON.stringify(cart));
  updateCartBadge();
}
function updateCartBadge() {
  const count = cart.reduce((s, i) => s + i.qty, 0);
  const badges = document.querySelectorAll('.cart-badge');
  const topBadge = document.getElementById('cart-count-top');
  badges.forEach(b => { b.textContent = count; b.style.display = count > 0 ? 'inline' : 'none'; });
  if (topBadge) { topBadge.textContent = count; topBadge.style.display = count > 0 ? 'inline' : 'none'; }
  const dashCart = document.getElementById('dash-cart');
  if (dashCart) dashCart.textContent = count;
}
function addToCart(product) {
  const existing = cart.find(i => i.id === product.id);
  if (existing) { existing.qty += 1; }
  else { cart.push({ id: product.id, name: product.name, price: product.price, unit: product.unit, type: product.type, qty: 1 }); }
  saveCart(); toast(product.name + ' added to cart ✓', 'success');
}
function removeFromCart(id) { cart = cart.filter(i => i.id !== id); saveCart(); renderCart(); }
function updateQty(id, delta) {
  const item = cart.find(i => i.id === id);
  if (!item) return;
  item.qty = Math.max(1, item.qty + delta);
  saveCart(); renderCart();
}

// Navigation
let currentPage = 'dashboard';
function navigate(page) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  const el = document.getElementById('page-' + page);
  if (el) el.classList.add('active');
  const nav = document.querySelector('[data-page="' + page + '"]');
  if (nav) nav.classList.add('active');
  const titles = { dashboard:'Dashboard', shop:'Shop', pesticides:'Pesticides', fertilizers:'Fertilizers', cart:'Cart', checkout:'Checkout', orders:'My Orders', market:'Market Rates', ai:'AI Assistant' };
  document.getElementById('page-title').textContent = titles[page] || page;
  currentPage = page;
  loadPage(page);
  if (window.innerWidth < 900) document.getElementById('sidebar').classList.remove('open');
}
function loadPage(p) {
  if (p === 'dashboard') loadDashboard();
  else if (p === 'shop') loadShop();
  else if (p === 'pesticides') loadPesticides();
  else if (p === 'fertilizers') loadFertilizers();
  else if (p === 'cart') renderCart();
  else if (p === 'orders') loadMyOrders();
  else if (p === 'market') loadMarket();
}

document.querySelectorAll('.nav-item').forEach(item => { item.onclick = e => { e.preventDefault(); navigate(item.dataset.page); }; });
document.getElementById('hamburger').onclick = () => {
  const s = document.getElementById('sidebar');
  s.classList.toggle('open');
  s.classList.toggle('hidden', !s.classList.contains('open') && window.innerWidth >= 900);
};
document.getElementById('logout-btn').onclick = async () => { await api('POST', '/api/auth/logout'); window.location.href = '/farmer-login.html'; };

// ── DASHBOARD ──
async function loadDashboard() {
  const [orders, products, rates] = await Promise.all([api('GET', '/api/orders/my'), api('GET', '/api/products'), api('GET', '/api/market')]);
  document.getElementById('dash-orders').textContent = orders.length || 0;
  document.getElementById('dash-products').textContent = products.length || 0;
  document.getElementById('dash-rates').textContent = rates.length || 0;
  updateCartBadge();

  document.getElementById('mini-market').innerHTML = rates.slice(0, 5).map(r => `
    <div class="mini-rate">
      <span class="mini-rate-name">${r.crop_name}</span>
      <div style="text-align:right">
        <div class="mini-rate-price">${pkr(r.price)}</div>
        <div class="mini-rate-change ${r.change_pct>0?'text-green':r.change_pct<0?'text-red':''}">
          ${r.change_pct>0?'▲':r.change_pct<0?'▼':''}${Math.abs(r.change_pct||0).toFixed(1)}%
        </div>
      </div>
    </div>`).join('') || '<div style="padding:20px;text-align:center;color:var(--muted)">No rates available</div>';

  document.getElementById('mini-orders').innerHTML = orders.slice(0, 4).map(o => `
    <div class="mini-order">
      <div>
        <div style="font-size:13px;font-weight:600">Order #${o.id}</div>
        <div style="font-size:11px;color:var(--muted)">${fmtDate(o.created_at)}</div>
      </div>
      <div style="text-align:right">
        <div style="font-size:13px;font-weight:700">${pkr(o.total_amount)}</div>
        ${badge(o.status,{pending:'yellow',approved:'blue',shipped:'purple',delivered:'green',rejected:'red'})}
      </div>
    </div>`).join('') || '<div style="padding:20px;text-align:center;color:var(--muted)">No orders yet</div>';
}

// ── SHOP ──
let shopFilter = 'all', shopSearch = '';
async function loadShop() {
  if (!allProducts.length) allProducts = await api('GET', '/api/products');
  renderShop();
  document.getElementById('shop-search').oninput = function() { shopSearch = this.value; renderShop(); };
}
function setShopFilter(type, btn) {
  shopFilter = type;
  document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active'); renderShop();
}
function renderShop() {
  let filtered = allProducts.filter(p => {
    const matchType = shopFilter === 'all' || p.type === shopFilter;
    const matchSearch = !shopSearch || p.name.toLowerCase().includes(shopSearch.toLowerCase()) || (p.crop_compatibility||'').toLowerCase().includes(shopSearch.toLowerCase());
    return matchType && matchSearch;
  });
  document.getElementById('shop-grid').innerHTML = filtered.map(p => productCard(p)).join('') || '<div style="padding:48px;text-align:center;color:var(--muted);grid-column:1/-1">No products found</div>';
}

async function loadPesticides() {
  if (!allProducts.length) allProducts = await api('GET', '/api/products');
  document.getElementById('pesticides-grid').innerHTML = allProducts.filter(p => p.type === 'pesticide').map(productCard).join('');
}
async function loadFertilizers() {
  if (!allProducts.length) allProducts = await api('GET', '/api/products');
  document.getElementById('fertilizers-grid').innerHTML = allProducts.filter(p => p.type === 'fertilizer').map(productCard).join('');
}

function productCard(p) {
  const icon = p.type === 'pesticide' ? '🧪' : '🌿';
  return `
    <div class="product-card">
      <div class="product-header ${p.type}">${icon}</div>
      <div class="product-body">
        <div class="product-type ${p.type}">${p.type === 'pesticide' ? '🧪 Pesticide' : '🌿 Fertilizer'}</div>
        <div class="product-name">${p.name}</div>
        <div class="product-compat">🌾 ${p.crop_compatibility || 'All crops'}</div>
        <div class="product-footer">
          <div>
            <div class="product-price">${pkr(p.price)}</div>
            <div class="product-unit">/${p.unit}</div>
          </div>
          <div style="display:flex;flex-direction:column;gap:6px;align-items:flex-end">
            <button class="add-to-cart" onclick="addToCart(${JSON.stringify(p).replace(/"/g,'&quot;')})">+ Add</button>
            <button class="view-details" onclick="showProductModal(${p.id})">Details</button>
          </div>
        </div>
      </div>
    </div>`;
}

function showProductModal(id) {
  const p = allProducts.find(x => x.id === id); if (!p) return;
  const icon = p.type === 'pesticide' ? '🧪' : '🌿';
  document.getElementById('modal-content').innerHTML = `
    <div class="product-modal">
      <div class="product-modal-header">${icon}</div>
      <h3>${p.name}</h3>
      <p style="color:var(--muted);font-size:13px">${p.description || ''}</p>
      <div class="product-modal-info">
        <div class="info-row"><strong>Price</strong>${pkr(p.price)} / ${p.unit}</div>
        <div class="info-row"><strong>Crop Compatibility</strong>${p.crop_compatibility || 'All crops'}</div>
        ${p.usage_guide ? `<div class="info-row"><strong>Usage Guide</strong>${p.usage_guide}</div>` : ''}
        ${p.effects ? `<div class="info-row"><strong>Effects / Warnings</strong>${p.effects}</div>` : ''}
        <div class="info-row"><strong>Stock Available</strong>${p.stock} units</div>
      </div>
      <div class="modal-actions">
        <button class="btn btn-primary" style="flex:1" onclick="addToCart(${JSON.stringify(p).replace(/"/g,'&quot;')});closeModal()">🛒 Add to Cart</button>
        <button class="btn btn-ghost" onclick="closeModal()">Close</button>
      </div>
    </div>`;
  document.getElementById('modal-overlay').style.display = 'flex';
}
function closeModal() { document.getElementById('modal-overlay').style.display = 'none'; }

// ── CART ──
function renderCart() {
  updateCartBadge();
  const total = cart.reduce((s, i) => s + i.price * i.qty, 0);
  const container = document.getElementById('cart-items-list');
  if (!cart.length) {
    container.innerHTML = '<div class="empty-cart"><div class="empty-cart-icon">🛒</div><p>Your cart is empty</p><button class="btn btn-primary" onclick="navigate(\'shop\')" style="margin-top:12px">Browse Products →</button></div>';
    document.getElementById('cart-summary').innerHTML = '';
    return;
  }
  container.innerHTML = cart.map(item => `
    <div class="cart-item">
      <div class="cart-item-icon">${item.type === 'pesticide' ? '🧪' : '🌿'}</div>
      <div class="cart-item-details">
        <div class="cart-item-name">${item.name}</div>
        <div class="cart-item-price">${pkr(item.price)} / ${item.unit}</div>
        <div class="cart-item-controls">
          <button class="qty-btn" onclick="updateQty(${item.id},-1)">−</button>
          <span class="qty-val">${item.qty}</span>
          <button class="qty-btn" onclick="updateQty(${item.id},1)">+</button>
        </div>
      </div>
      <div style="display:flex;flex-direction:column;align-items:flex-end;gap:8px">
        <div class="cart-item-total">${pkr(item.price * item.qty)}</div>
        <button class="remove-btn" onclick="removeFromCart(${item.id})">🗑️</button>
      </div>
    </div>`).join('');

  document.getElementById('cart-summary').innerHTML = `
    <h3 class="section-title" style="font-size:15px">Order Summary</h3>
    <div class="summary-row"><span>Subtotal (${cart.reduce((s,i)=>s+i.qty,0)} items)</span><span>${pkr(total)}</span></div>
    <div class="summary-row"><span>Delivery</span><span style="color:var(--green)">Free</span></div>
    <div class="summary-row"><span><strong>Total</strong></span><span><strong>${pkr(total)}</strong></span></div>
    <button class="btn btn-primary btn-block" onclick="showCheckout()">Proceed to Checkout →</button>
    <button class="btn btn-ghost btn-block" onclick="navigate('shop')">Continue Shopping</button>`;
}

// ── CHECKOUT ──
const paymentInfo = JSON.parse(localStorage.getItem('payment-info') || '{"jazzcash":"0300-1234567","easypaisa":"0300-7654321","bank":"HBL - 0123456789012"}');

function showCheckout() {
  if (!cart.length) { toast('Cart is empty', 'error'); return; }
  navigate('checkout');
  // Pre-fill user info
  if (currentUser) {
    document.getElementById('billing-name').value = currentUser.name || '';
    document.getElementById('farmer-email').value = currentUser.email || '';
  }
  // Render checkout items
  const total = cart.reduce((s,i) => s+i.price*i.qty, 0);
  document.getElementById('checkout-items').innerHTML = cart.map(i => `
    <div class="checkout-item">
      <span>${i.name} ×${i.qty}</span>
      <span>${pkr(i.price * i.qty)}</span>
    </div>`).join('');
  document.getElementById('checkout-total').innerHTML = `<div style="display:flex;justify-content:space-between">Total <span>${pkr(total)}</span></div>`;

  // Payment instructions
  updatePaymentInstructions();
  document.querySelectorAll('input[name="payment"]').forEach(r => r.onchange = updatePaymentInstructions);
}

function updatePaymentInstructions() {
  const method = document.querySelector('input[name="payment"]:checked')?.value || 'JazzCash';
  const total = cart.reduce((s,i) => s+i.price*i.qty, 0);
  let html = `<strong>💳 Send ${pkr(total)} via ${method}:</strong>`;
  if (method === 'JazzCash') {
    html += `<div class="pay-detail">📱 JazzCash Number: <strong>${paymentInfo.jazzcash || '0300-XXXXXXX'}</strong></div>`;
    html += `<div style="font-size:12px;color:var(--muted);margin-top:6px">Open JazzCash app → Send Money → Enter number above → Enter amount → Screenshot</div>`;
  } else if (method === 'Easypaisa') {
    html += `<div class="pay-detail">📱 Easypaisa Number: <strong>${paymentInfo.easypaisa || '0300-XXXXXXX'}</strong></div>`;
    html += `<div style="font-size:12px;color:var(--muted);margin-top:6px">Open Easypaisa app → Send Money → Enter number above → Screenshot</div>`;
  } else {
    html += `<div class="pay-detail">🏦 Bank Account: <strong>${paymentInfo.bank || 'Contact admin for details'}</strong></div>`;
    html += `<div style="font-size:12px;color:var(--muted);margin-top:6px">Transfer amount to above account and take a screenshot of the transaction</div>`;
  }
  document.getElementById('payment-instructions').innerHTML = html;
}

async function placeOrder() {
  const name = document.getElementById('billing-name').value.trim();
  const phone = document.getElementById('farmer-phone').value.trim();
  const email = document.getElementById('farmer-email').value.trim();
  const address = document.getElementById('shipping-address').value.trim();
  const city = document.getElementById('shipping-city').value.trim();
  const screenshot = document.getElementById('payment-screenshot').files[0];
  const method = document.querySelector('input[name="payment"]:checked')?.value;

  if (!name || !phone || !address || !city) { toast('Please fill all required fields', 'error'); return; }
  if (!screenshot) { toast('Please upload payment screenshot', 'error'); return; }

  const btn = document.getElementById('place-order-btn');
  btn.disabled = true; btn.textContent = 'Placing order...';

  const total = cart.reduce((s,i) => s+i.price*i.qty, 0);
  const formData = new FormData();
  formData.append('farmer_name', name);
  formData.append('farmer_email', email);
  formData.append('farmer_phone', phone);
  formData.append('billing_name', name);
  formData.append('billing_address', address);
  formData.append('billing_city', city);
  formData.append('shipping_address', address);
  formData.append('shipping_city', city);
  formData.append('payment_method', method);
  formData.append('total_amount', total);
  formData.append('items', JSON.stringify(cart.map(i => ({ id: i.id, name: i.name, qty: i.qty, price: i.price }))));
  formData.append('payment_screenshot', screenshot);

  try {
    const r = await fetch('/api/orders', { method: 'POST', credentials: 'include', body: formData });
    const data = await r.json();
    if (data.success) {
      cart = []; saveCart();
      document.getElementById('order-id-msg').textContent = `Order ID: #${data.order_id}`;
      document.getElementById('success-overlay').style.display = 'flex';
    } else { toast(data.error || 'Order failed', 'error'); }
  } catch { toast('Connection error. Please try again.', 'error'); }
  finally { btn.disabled = false; btn.textContent = '🛒 Place Order'; }
}

// ── MY ORDERS ──
async function loadMyOrders() {
  const orders = await api('GET', '/api/orders/my');
  const container = document.getElementById('my-orders-list');
  if (!orders.length) {
    container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📦</div><p>No orders yet</p><button class="btn btn-primary" onclick="navigate(\'shop\')" style="margin-top:12px">Start Shopping →</button></div>';
    return;
  }
  container.innerHTML = orders.map(o => `
    <div class="order-card">
      <div class="order-card-header">
        <div style="display:flex;align-items:center;gap:10px">
          <span class="order-id-label">Order #${o.id}</span>
          ${badge(o.status,{pending:'yellow',approved:'blue',shipped:'purple',delivered:'green',rejected:'red'})}
        </div>
        <div style="font-size:13px;color:var(--muted)">${fmtDate(o.created_at)}</div>
      </div>
      <div class="order-card-body">
        <div class="order-items-list">
          ${(o.items||[]).map(i => `<div><span>${i.product_name} ×${i.quantity}</span><span style="float:right">${pkr(i.price*i.quantity)}</span></div>`).join('')}
        </div>
        <div style="display:flex;justify-content:space-between;margin-top:12px;font-weight:700;font-size:14px">
          <span>Total</span><span>${pkr(o.total_amount)}</span>
        </div>
        <div class="order-meta-row">
          <span>💳 ${o.payment_method}</span>
          <span>📍 ${o.shipping_city||'—'}</span>
          ${o.tracking_link ? `<span>🚚 <a href="${o.tracking_link}" target="_blank">Track Package</a></span>` : ''}
        </div>
        ${o.status === 'pending' ? '<div style="margin-top:8px;padding:8px;background:#fef9c3;border-radius:8px;font-size:12px;color:#854d0e">⏳ Your payment is being reviewed by admin. You will be notified once confirmed.</div>' : ''}
        ${o.status === 'approved' ? '<div style="margin-top:8px;padding:8px;background:#dbeafe;border-radius:8px;font-size:12px;color:#1e40af">✅ Order confirmed! Will be shipped soon.</div>' : ''}
        ${o.status === 'shipped' ? '<div style="margin-top:8px;padding:8px;background:#ede9fe;border-radius:8px;font-size:12px;color:#5b21b6">🚚 Your order is on its way!</div>' : ''}
        ${o.status === 'delivered' ? '<div style="margin-top:8px;padding:8px;background:#dcfce7;border-radius:8px;font-size:12px;color:#15803d">📦 Order delivered. Enjoy your products!</div>' : ''}
        ${o.status === 'rejected' ? `<div style="margin-top:8px;padding:8px;background:#fee2e2;border-radius:8px;font-size:12px;color:#991b1b">❌ Order rejected. ${o.admin_notes||'Contact support for details.'}</div>` : ''}
      </div>
    </div>`).join('');
}

// ── MARKET RATES ──
async function loadMarket() {
  const rates = await api('GET', '/api/market');
  document.getElementById('market-grid').innerHTML = rates.map(r => `
    <div class="market-card">
      <div class="market-crop">${r.crop_name}</div>
      <div class="market-price">PKR ${parseFloat(r.price).toLocaleString('en-PK')}</div>
      <div class="market-unit">${r.unit}</div>
      <div class="market-change ${r.change_pct>0?'up':r.change_pct<0?'down':'flat'}">
        ${r.change_pct>0?'▲ +':r.change_pct<0?'▼ ':''}${Math.abs(r.change_pct||0).toFixed(1)}%
        ${r.change_pct>0?' (Rising)':r.change_pct<0?' (Falling)':' (Stable)'}
      </div>
      <div class="market-updated">Updated: ${new Date(r.updated_at).toLocaleDateString('en-PK',{month:'short',day:'numeric'})}</div>
    </div>`).join('') || '<div style="padding:48px;text-align:center;color:var(--muted);grid-column:1/-1">No market data available</div>';
}

// ── AI ASSISTANT ──
async function getAIRecommendation() {
  const crop = document.getElementById('ai-crop').value;
  const problem = document.getElementById('ai-problem').value;
  const desc = document.getElementById('ai-desc').value;
  if (!crop) { toast('Please select a crop', 'error'); return; }

  const btn = document.querySelector('#page-ai .btn-primary');
  btn.disabled = true; btn.textContent = '🔍 Analyzing...';

  try {
    const r = await api('POST', '/api/ai/recommend', { crop, problem: problem + ' ' + desc });
    const result = document.getElementById('ai-result');
    result.style.display = 'block';

    document.getElementById('ai-confidence').textContent = r.confidence === 'high' ? '✅ High Confidence' : r.confidence === 'medium' ? '⚠️ Medium Confidence' : '💡 General Advice';
    document.getElementById('ai-confidence').className = 'ai-confidence ' + (r.confidence||'low');
    document.getElementById('ai-tip').innerHTML = '💡 <strong>Expert Tip:</strong> ' + (r.tip || 'Consult a local agricultural extension officer for personalized advice.');

    const pest = r.pesticide;
    const fert = r.fertilizer;
    document.getElementById('ai-pesticide').innerHTML = pest ? `
      <div class="ai-product-label">🧪 Recommended Pesticide</div>
      <div class="ai-product-name">${pest.name||'—'}</div>
      ${pest.price && pest.price !== 'See shop' ? `<div class="ai-product-price">${pkr(pest.price)} / ${pest.unit||'unit'}</div>` : '<div class="ai-product-price">Check Shop</div>'}
      ${pest.id ? `<button class="btn btn-sm btn-primary" onclick="addToCart(${JSON.stringify(pest).replace(/"/g,'&quot;')});toast('Added to cart','success')">+ Add to Cart</button>` : ''}
    ` : '<div class="ai-product-label">🧪 No pesticide needed for this issue</div>';

    document.getElementById('ai-fertilizer').innerHTML = fert ? `
      <div class="ai-product-label">🌿 Recommended Fertilizer</div>
      <div class="ai-product-name">${fert.name||'—'}</div>
      ${fert.price && fert.price !== 'See shop' ? `<div class="ai-product-price">${pkr(fert.price)} / ${fert.unit||'unit'}</div>` : '<div class="ai-product-price">Check Shop</div>'}
      ${fert.id ? `<button class="btn btn-sm btn-primary" onclick="addToCart(${JSON.stringify(fert).replace(/"/g,'&quot;')});toast('Added to cart','success')">+ Add to Cart</button>` : ''}
    ` : '<div class="ai-product-label">🌿 No specific fertilizer recommended</div>';

    result.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  } catch { toast('AI service unavailable', 'error'); }
  finally { btn.disabled = false; btn.textContent = '🔍 Get Recommendation'; }
}

// Init
async function init() {
  const me = await api('GET', '/api/auth/me');
  if (me.error) { window.location.href = '/farmer-login.html'; return; }
  currentUser = me.user;
  document.getElementById('user-name').textContent = me.user.name;
  document.getElementById('user-avatar').textContent = me.user.name.charAt(0).toUpperCase();
  document.getElementById('welcome-name').textContent = me.user.name;
  document.getElementById('app').style.display = 'flex';
  updateCartBadge();
  navigate('dashboard');
}
init();
