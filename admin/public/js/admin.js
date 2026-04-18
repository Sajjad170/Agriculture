'use strict';

const savedTheme = localStorage.getItem('agritrack-theme') || 'light';
document.documentElement.setAttribute('data-theme', savedTheme);

function setTheme(t) {
  document.documentElement.setAttribute('data-theme', t);
  localStorage.setItem('agritrack-theme', t);
  document.getElementById('theme-toggle').textContent = t === 'dark' ? '☀️' : '🌙';
  document.querySelectorAll('.theme-option').forEach(el => el.classList.remove('active'));
  const el = document.getElementById('theme-' + t);
  if (el) el.classList.add('active');
}

const api = async (method, url, body) => {
  const opts = { method, credentials: 'include', headers: {} };
  if (body) { opts.body = JSON.stringify(body); opts.headers['Content-Type'] = 'application/json'; }
  const r = await fetch(url, opts);
  return r.json();
};

function toast(msg, type = '') {
  const t = document.getElementById('toast');
  t.textContent = msg; t.className = 'toast show ' + type;
  setTimeout(() => t.className = 'toast', 3000);
}

function fmtDate(d) { if (!d) return '—'; return new Date(d).toLocaleDateString('en-PK', { month: 'short', day: 'numeric', year: 'numeric' }); }
function fmtTime(d) { if (!d) return '—'; const dt = new Date(d); return dt.toLocaleDateString('en-PK', { month: 'short', day: 'numeric' }) + ' ' + dt.toLocaleTimeString('en-PK', { hour: '2-digit', minute: '2-digit' }); }
function badge(val, map) { const cls = map[val] || 'gray'; return `<span class="badge ${cls}">${val}</span>`; }
function pkr(n) { return 'PKR ' + (parseFloat(n)||0).toLocaleString('en-PK'); }

let modalSave = null;
function openModal(title, html, onSave) {
  document.getElementById('modal-title').textContent = title;
  document.getElementById('modal-body').innerHTML = html;
  document.getElementById('modal-overlay').classList.add('open');
  modalSave = onSave;
}
function closeModal() { document.getElementById('modal-overlay').classList.remove('open'); modalSave = null; }
document.getElementById('modal-close').onclick = closeModal;
document.getElementById('modal-cancel').onclick = closeModal;
document.getElementById('modal-overlay').onclick = e => { if (e.target === e.currentTarget) closeModal(); };
document.getElementById('modal-save').onclick = () => { if (modalSave) modalSave(); };

let currentPage = 'dashboard';
function navigate(page) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  const el = document.getElementById('page-' + page);
  if (el) el.classList.add('active');
  const nav = document.querySelector('[data-page="' + page + '"]');
  if (nav) nav.classList.add('active');
  const titles = { dashboard:'Dashboard', users:'User Management', farmers:'Farmer Management', products:'Products', orders:'Orders', market:'Market Rates', data:'Analytics', activity:'Activity Log', settings:'Settings' };
  document.getElementById('page-title').textContent = titles[page] || page;
  currentPage = page;
  loadPage(page);
  if (window.innerWidth < 900) document.getElementById('sidebar').classList.remove('open');
}

function loadPage(p) {
  if (p === 'dashboard') loadDashboard();
  else if (p === 'users') loadUsers();
  else if (p === 'farmers') loadFarmers();
  else if (p === 'products') loadProducts();
  else if (p === 'orders') loadOrders();
  else if (p === 'market') loadMarket();
  else if (p === 'data') loadAnalytics();
  else if (p === 'activity') loadActivity();
  else if (p === 'settings') loadSettings();
}

document.querySelectorAll('.nav-item').forEach(item => { item.onclick = e => { e.preventDefault(); navigate(item.dataset.page); }; });
document.querySelectorAll('.btn-link[data-page]').forEach(item => { item.onclick = () => navigate(item.dataset.page); });
document.getElementById('hamburger').onclick = () => {
  const s = document.getElementById('sidebar');
  if (window.innerWidth < 900) s.classList.toggle('open');
  else s.classList.toggle('hidden');
  document.querySelector('.main').classList.toggle('full', s.classList.contains('hidden'));
};
document.getElementById('theme-toggle').onclick = () => { const cur = document.documentElement.getAttribute('data-theme'); setTheme(cur === 'dark' ? 'light' : 'dark'); };
document.getElementById('logout-btn').onclick = async () => { await api('POST', '/api/auth/logout'); window.location.href = '/login.html'; };

// ── DASHBOARD ──
async function loadDashboard() {
  const data = await api('GET', '/api/stats');
  const orders = await api('GET', '/api/orders');
  document.getElementById('stat-users').textContent = data.totalUsers ?? '—';
  document.getElementById('stat-farmers').textContent = data.totalFarmers ?? '—';
  document.getElementById('stat-active-users').textContent = (data.activeUsers||0) + ' active';
  document.getElementById('stat-active-farmers').textContent = (data.activeFarmers||0) + ' active';
  const totalOrders = orders.length || 0;
  const pendingOrders = orders.filter(o => o.status === 'pending').length;
  const revenue = orders.filter(o => ['approved','shipped','delivered'].includes(o.status)).reduce((s, o) => s + (o.total_amount||0), 0);
  document.getElementById('stat-orders').textContent = totalOrders;
  document.getElementById('stat-pending-orders').textContent = pendingOrders + ' pending';
  document.getElementById('stat-revenue').textContent = 'PKR ' + revenue.toLocaleString('en-PK');

  if (pendingOrders > 0) {
    const badge = document.getElementById('pending-badge');
    badge.textContent = pendingOrders; badge.style.display = 'inline-flex';
  }

  document.getElementById('recent-orders-table').innerHTML = orders.slice(0, 8).map(o => `
    <tr>
      <td>#${o.id}</td>
      <td>${o.farmer_name||'—'}</td>
      <td>${pkr(o.total_amount)}</td>
      <td>${badge(o.status, {pending:'yellow',approved:'blue',shipped:'purple',delivered:'green',rejected:'red'})}</td>
      <td>${fmtDate(o.created_at)}</td>
    </tr>`).join('') || '<tr><td colspan="5" style="text-align:center;padding:24px;color:var(--text-muted)">No orders yet</td></tr>';

  document.getElementById('activity-list').innerHTML = (data.recentActivity||[]).map(a => `
    <div class="activity-item">
      <div class="activity-dot"></div>
      <div><div class="activity-text">${a.description}</div><div class="activity-time">${fmtTime(a.created_at)}</div></div>
    </div>`).join('');
}

// ── USERS ──
let allUsers = [];
async function loadUsers(search='') {
  const url = search ? `/api/users?search=${encodeURIComponent(search)}` : '/api/users';
  allUsers = await api('GET', url);
  document.getElementById('users-table').innerHTML = allUsers.map(u => `
    <tr>
      <td><strong>${u.name}</strong></td>
      <td>${u.email}</td>
      <td>${badge(u.role, {admin:'blue',farmer:'green',user:'gray'})}</td>
      <td>${badge(u.status||'active', {active:'green',inactive:'red'})}</td>
      <td>${fmtDate(u.created_at)}</td>
      <td><div class="actions">
        <button class="btn-icon" onclick="editUser(${u.id})">✏️</button>
        <button class="btn-icon" onclick="deleteUser(${u.id},'${u.email}')">🗑️</button>
      </div></td>
    </tr>`).join('') || '<tr><td colspan="6" style="text-align:center;padding:32px;color:var(--text-muted)">No users found</td></tr>';
}

document.getElementById('user-search').oninput = function() { loadUsers(this.value); };
document.getElementById('add-user-btn').onclick = () => openModal('Add User', `
  <div class="form-group"><label>Full Name</label><input id="m-name" type="text" placeholder="John Doe" /></div>
  <div class="form-group"><label>Email</label><input id="m-email" type="email" placeholder="john@example.com" /></div>
  <div class="form-group"><label>Password</label><input id="m-pass" type="password" placeholder="••••••••" /></div>
  <div class="form-group"><label>Role</label><select id="m-role"><option value="user">User</option><option value="farmer">Farmer</option><option value="admin">Admin</option></select></div>
`, async () => {
  const r = await api('POST', '/api/users', { name: document.getElementById('m-name').value.trim(), email: document.getElementById('m-email').value.trim(), password: document.getElementById('m-pass').value, role: document.getElementById('m-role').value });
  if (r.error) { toast(r.error, 'error'); return; }
  toast('User created', 'success'); closeModal(); loadUsers();
});
async function editUser(id) {
  const u = allUsers.find(x => x.id === id); if (!u) return;
  openModal('Edit User', `
    <div class="form-group"><label>Name</label><input id="m-name" type="text" value="${u.name}" /></div>
    <div class="form-group"><label>Email</label><input id="m-email" type="email" value="${u.email}" /></div>
    <div class="form-group"><label>New Password (blank = no change)</label><input id="m-pass" type="password" /></div>
    <div class="form-group"><label>Role</label><select id="m-role"><option ${u.role==='user'?'selected':''} value="user">User</option><option ${u.role==='farmer'?'selected':''} value="farmer">Farmer</option><option ${u.role==='admin'?'selected':''} value="admin">Admin</option></select></div>
    <div class="form-group"><label>Status</label><select id="m-status"><option ${u.status==='active'?'selected':''} value="active">Active</option><option ${u.status==='inactive'?'selected':''} value="inactive">Inactive</option></select></div>
  `, async () => {
    const body = { name: document.getElementById('m-name').value, email: document.getElementById('m-email').value, role: document.getElementById('m-role').value, status: document.getElementById('m-status').value };
    const pass = document.getElementById('m-pass').value; if (pass) body.password = pass;
    const r = await api('PUT', '/api/users/' + id, body);
    if (r.error) { toast(r.error, 'error'); return; }
    toast('User updated', 'success'); closeModal(); loadUsers();
  });
}
async function deleteUser(id, email) {
  if (!confirm(`Delete user "${email}"?`)) return;
  const r = await api('DELETE', '/api/users/' + id);
  if (r.error) { toast(r.error, 'error'); return; }
  toast('Deleted', 'success'); loadUsers();
}

// ── FARMERS ──
let allFarmers = [];
async function loadFarmers(search='') {
  allFarmers = await api('GET', search ? `/api/farmers?search=${encodeURIComponent(search)}` : '/api/farmers');
  document.getElementById('farmers-table').innerHTML = allFarmers.map(f => `
    <tr>
      <td><strong>${f.name}</strong></td>
      <td>${f.location||'—'}</td>
      <td>${f.crop_type ? `<span class="badge green">${f.crop_type}</span>` : '—'}</td>
      <td>${f.contact||'—'}</td>
      <td>${badge(f.status||'active',{active:'green',inactive:'red'})}</td>
      <td><div class="actions">
        <button class="btn-icon" onclick="editFarmer(${f.id})">✏️</button>
        <button class="btn-icon" onclick="deleteFarmer(${f.id},'${f.name}')">🗑️</button>
      </div></td>
    </tr>`).join('') || '<tr><td colspan="6" style="text-align:center;padding:32px;color:var(--text-muted)">No farmers</td></tr>';
}
document.getElementById('farmer-search').oninput = function() { loadFarmers(this.value); };
document.getElementById('add-farmer-btn').onclick = () => openModal('Add Farmer', `
  <div class="form-group"><label>Name</label><input id="m-name" type="text" /></div>
  <div class="form-group"><label>Location</label><input id="m-loc" type="text" placeholder="City, Province" /></div>
  <div class="form-group"><label>Crop Type</label><input id="m-crop" type="text" placeholder="Wheat, Rice..." /></div>
  <div class="form-group"><label>Contact</label><input id="m-contact" type="text" placeholder="+92 300 0000000" /></div>
`, async () => {
  const r = await api('POST', '/api/farmers', { name: document.getElementById('m-name').value.trim(), location: document.getElementById('m-loc').value, crop_type: document.getElementById('m-crop').value, contact: document.getElementById('m-contact').value });
  if (r.error) { toast(r.error, 'error'); return; }
  toast('Farmer added', 'success'); closeModal(); loadFarmers();
});
async function editFarmer(id) {
  const f = allFarmers.find(x => x.id === id); if (!f) return;
  openModal('Edit Farmer', `
    <div class="form-group"><label>Name</label><input id="m-name" type="text" value="${f.name}" /></div>
    <div class="form-group"><label>Location</label><input id="m-loc" type="text" value="${f.location||''}" /></div>
    <div class="form-group"><label>Crop</label><input id="m-crop" type="text" value="${f.crop_type||''}" /></div>
    <div class="form-group"><label>Contact</label><input id="m-contact" type="text" value="${f.contact||''}" /></div>
    <div class="form-group"><label>Status</label><select id="m-status"><option ${f.status==='active'?'selected':''} value="active">Active</option><option ${f.status==='inactive'?'selected':''} value="inactive">Inactive</option></select></div>
  `, async () => {
    const r = await api('PUT', '/api/farmers/' + id, { name: document.getElementById('m-name').value, location: document.getElementById('m-loc').value, crop_type: document.getElementById('m-crop').value, contact: document.getElementById('m-contact').value, status: document.getElementById('m-status').value });
    if (r.error) { toast(r.error, 'error'); return; }
    toast('Updated', 'success'); closeModal(); loadFarmers();
  });
}
async function deleteFarmer(id, name) {
  if (!confirm(`Remove "${name}"?`)) return;
  const r = await api('DELETE', '/api/farmers/' + id);
  if (r.error) { toast(r.error, 'error'); return; }
  toast('Removed', 'success'); loadFarmers();
}

// ── PRODUCTS ──
let allProducts = [], productFilter = 'all';
async function loadProducts() {
  allProducts = await api('GET', '/api/products/all');
  renderProducts();
}
function filterProducts(type, btn) {
  productFilter = type;
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active'); renderProducts();
}
function renderProducts() {
  const filtered = productFilter === 'all' ? allProducts : allProducts.filter(p => p.type === productFilter);
  document.getElementById('products-table').innerHTML = filtered.map(p => `
    <tr>
      <td><strong>${p.name}</strong></td>
      <td>${badge(p.type,{pesticide:'red',fertilizer:'green'})}</td>
      <td><strong>${pkr(p.price)}</strong> / ${p.unit}</td>
      <td>${p.stock}</td>
      <td style="max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${p.crop_compatibility||'—'}</td>
      <td>${badge(p.status,{active:'green',inactive:'red'})}</td>
      <td><div class="actions">
        <button class="btn-icon" onclick="editProduct(${p.id})">✏️</button>
        <button class="btn-icon" onclick="deleteProduct(${p.id},'${p.name}')">🗑️</button>
      </div></td>
    </tr>`).join('') || '<tr><td colspan="7" style="text-align:center;padding:32px;color:var(--text-muted)">No products</td></tr>';
}
document.getElementById('add-product-btn').onclick = () => openModal('Add Product', productForm(), async () => {
  const r = await api('POST', '/api/products', getProductFormData());
  if (r.error) { toast(r.error, 'error'); return; }
  toast('Product added', 'success'); closeModal(); loadProducts();
});
async function editProduct(id) {
  const p = allProducts.find(x => x.id === id); if (!p) return;
  openModal('Edit Product', productForm(p), async () => {
    const r = await api('PUT', '/api/products/' + id, { ...getProductFormData(), status: document.getElementById('m-status')?.value || p.status });
    if (r.error) { toast(r.error, 'error'); return; }
    toast('Updated', 'success'); closeModal(); loadProducts();
  });
}
async function deleteProduct(id, name) {
  if (!confirm(`Remove "${name}"?`)) return;
  const r = await api('DELETE', '/api/products/' + id);
  if (r.error) { toast(r.error, 'error'); return; }
  toast('Removed', 'success'); loadProducts();
}
function productForm(p) {
  return `
    <div class="form-group"><label>Name</label><input id="m-name" type="text" value="${p?.name||''}" /></div>
    <div class="form-group"><label>Type</label><select id="m-type"><option ${p?.type==='pesticide'?'selected':''} value="pesticide">🧪 Pesticide</option><option ${p?.type==='fertilizer'?'selected':''} value="fertilizer">🌿 Fertilizer</option></select></div>
    <div class="form-group"><label>Price (PKR)</label><input id="m-price" type="number" value="${p?.price||''}" /></div>
    <div class="form-group"><label>Unit</label><input id="m-unit" type="text" value="${p?.unit||'kg'}" placeholder="500ml bottle, 50kg bag..." /></div>
    <div class="form-group"><label>Stock</label><input id="m-stock" type="number" value="${p?.stock||100}" /></div>
    <div class="form-group"><label>Crop Compatibility</label><input id="m-compat" type="text" value="${p?.crop_compatibility||''}" placeholder="Wheat, Rice, Cotton..." /></div>
    <div class="form-group"><label>Description</label><input id="m-desc" type="text" value="${p?.description||''}" /></div>
    <div class="form-group"><label>Usage Guide</label><input id="m-usage" type="text" value="${p?.usage_guide||''}" /></div>
    <div class="form-group"><label>Effects / Warnings</label><input id="m-effects" type="text" value="${p?.effects||''}" /></div>
    ${p ? `<div class="form-group"><label>Status</label><select id="m-status"><option ${p.status==='active'?'selected':''} value="active">Active</option><option ${p.status==='inactive'?'selected':''} value="inactive">Inactive</option></select></div>` : ''}
  `;
}
function getProductFormData() {
  return {
    name: document.getElementById('m-name').value,
    type: document.getElementById('m-type').value,
    price: parseFloat(document.getElementById('m-price').value),
    unit: document.getElementById('m-unit').value,
    stock: parseInt(document.getElementById('m-stock').value),
    crop_compatibility: document.getElementById('m-compat').value,
    description: document.getElementById('m-desc').value,
    usage_guide: document.getElementById('m-usage').value,
    effects: document.getElementById('m-effects').value,
  };
}

// ── ORDERS ──
let allOrders = [], orderStatusFilter = '';
async function loadOrders(status) {
  if (status !== undefined) orderStatusFilter = status;
  const url = orderStatusFilter ? `/api/orders?status=${orderStatusFilter}` : '/api/orders';
  allOrders = await api('GET', url);
  renderOrders();
}
function filterOrders(status, btn) {
  document.querySelectorAll('#page-orders .tab-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active'); loadOrders(status);
}
function renderOrders() {
  const container = document.getElementById('orders-list');
  if (!allOrders.length) { container.innerHTML = '<div class="card" style="padding:48px;text-align:center;color:var(--text-muted)">No orders found</div>'; return; }
  container.innerHTML = allOrders.map(o => `
    <div class="card order-card">
      <div class="order-header">
        <div>
          <span class="order-id">Order #${o.id}</span>
          ${badge(o.status,{pending:'yellow',approved:'blue',shipped:'purple',delivered:'green',rejected:'red'})}
        </div>
        <div class="order-meta">
          <span>${fmtDate(o.created_at)}</span>
          <strong>${pkr(o.total_amount)}</strong>
          <span>${o.payment_method||'—'}</span>
        </div>
      </div>
      <div class="order-body">
        <div class="order-info">
          <div><strong>👤 Farmer:</strong> ${o.farmer_name||'—'} (${o.farmer_email||'—'})</div>
          <div><strong>📍 Shipping:</strong> ${o.shipping_address||'—'}, ${o.shipping_city||'—'}</div>
          <div><strong>📞 Phone:</strong> ${o.farmer_phone||'—'}</div>
          ${o.tracking_link ? `<div><strong>🚚 Tracking:</strong> <a href="${o.tracking_link}" target="_blank">${o.tracking_link}</a></div>` : ''}
          ${o.admin_notes ? `<div><strong>📝 Notes:</strong> ${o.admin_notes}</div>` : ''}
        </div>
        <div class="order-items">
          ${(o.items||[]).map(i => `<div class="order-item"><span>${i.product_name}</span><span>×${i.quantity}</span><span>${pkr(i.price * i.quantity)}</span></div>`).join('')}
        </div>
      </div>
      ${o.payment_screenshot ? `<div class="order-screenshot"><strong>💳 Payment Proof:</strong> <a href="${o.payment_screenshot}" target="_blank"><img src="${o.payment_screenshot}" alt="Payment screenshot" style="max-height:80px;border-radius:6px;margin-top:6px;display:block;cursor:pointer" onclick="window.open('${o.payment_screenshot}','_blank')" /></a></div>` : ''}
      <div class="order-actions">
        ${o.status==='pending' ? `
          <button class="btn btn-primary btn-sm" onclick="updateOrder(${o.id},'approved')">✅ Approve</button>
          <button class="btn btn-danger btn-sm" onclick="updateOrder(${o.id},'rejected')">❌ Reject</button>
        ` : ''}
        ${o.status==='approved' ? `<button class="btn btn-primary btn-sm" onclick="shipOrder(${o.id})">🚚 Mark Shipped</button>` : ''}
        ${o.status==='shipped' ? `<button class="btn btn-primary btn-sm" onclick="updateOrder(${o.id},'delivered')">📦 Mark Delivered</button>` : ''}
        <button class="btn btn-ghost btn-sm" onclick="editOrderNotes(${o.id},'${o.tracking_link||''}','${o.admin_notes||''}')">✏️ Edit Notes</button>
      </div>
    </div>`).join('');
}
async function updateOrder(id, status) {
  const r = await api('PUT', '/api/orders/' + id, { status });
  if (r.error) { toast(r.error, 'error'); return; }
  toast(`Order ${status}`, 'success'); loadOrders();
}
async function shipOrder(id) {
  const tracking = prompt('Enter tracking link or number (optional):') || '';
  await api('PUT', '/api/orders/' + id, { status: 'shipped', tracking_link: tracking });
  toast('Marked as shipped', 'success'); loadOrders();
}
function editOrderNotes(id, tracking, notes) {
  openModal('Edit Order Notes', `
    <div class="form-group"><label>Tracking Link/Number</label><input id="m-track" type="text" value="${tracking}" placeholder="https://courier.com/track/..." /></div>
    <div class="form-group"><label>Admin Notes</label><input id="m-notes" type="text" value="${notes}" placeholder="Additional notes..." /></div>
  `, async () => {
    const r = await api('PUT', '/api/orders/' + id, { tracking_link: document.getElementById('m-track').value, admin_notes: document.getElementById('m-notes').value });
    if (r.error) { toast(r.error, 'error'); return; }
    toast('Updated', 'success'); closeModal(); loadOrders();
  });
}

// ── MARKET RATES ──
let allRates = [];
async function loadMarket() {
  allRates = await api('GET', '/api/market');
  document.getElementById('market-table').innerHTML = allRates.map(r => `
    <tr>
      <td><strong>${r.crop_name}</strong></td>
      <td><strong>PKR ${parseFloat(r.price).toLocaleString('en-PK')}</strong></td>
      <td>${r.unit}</td>
      <td class="${r.change_pct>0?'text-green':r.change_pct<0?'text-red':''}">
        ${r.change_pct>0?'▲':''}${r.change_pct<0?'▼':''}${Math.abs(r.change_pct||0).toFixed(1)}%
      </td>
      <td>${fmtTime(r.updated_at)}</td>
      <td><div class="actions">
        <button class="btn-icon" onclick="editRate(${r.id})">✏️</button>
        <button class="btn-icon" onclick="deleteRate(${r.id},'${r.crop_name}')">🗑️</button>
      </div></td>
    </tr>`).join('');
}
document.getElementById('add-rate-btn').onclick = () => openModal('Update Market Rate', `
  <div class="form-group"><label>Crop Name (Urdu + English)</label><input id="m-crop" type="text" placeholder="Wheat (گندم)" /></div>
  <div class="form-group"><label>Price (PKR)</label><input id="m-price" type="number" placeholder="3800" /></div>
  <div class="form-group"><label>Unit</label><input id="m-unit" type="text" value="per 40kg" /></div>
  <div class="form-group"><label>Change % (+ up, - down)</label><input id="m-change" type="number" step="0.1" placeholder="2.5" /></div>
`, async () => {
  const r = await api('POST', '/api/market', { crop_name: document.getElementById('m-crop').value, price: document.getElementById('m-price').value, unit: document.getElementById('m-unit').value, change_pct: document.getElementById('m-change').value });
  if (r.error) { toast(r.error, 'error'); return; }
  toast('Rate updated', 'success'); closeModal(); loadMarket();
});
async function editRate(id) {
  const rate = allRates.find(r => r.id === id); if (!rate) return;
  openModal('Edit Rate', `
    <div class="form-group"><label>Crop Name</label><input id="m-crop" type="text" value="${rate.crop_name}" /></div>
    <div class="form-group"><label>Price (PKR)</label><input id="m-price" type="number" value="${rate.price}" /></div>
    <div class="form-group"><label>Unit</label><input id="m-unit" type="text" value="${rate.unit}" /></div>
    <div class="form-group"><label>Change %</label><input id="m-change" type="number" step="0.1" value="${rate.change_pct||0}" /></div>
  `, async () => {
    const r = await api('PUT', '/api/market/' + id, { crop_name: document.getElementById('m-crop').value, price: document.getElementById('m-price').value, unit: document.getElementById('m-unit').value, change_pct: document.getElementById('m-change').value });
    if (r.error) { toast(r.error, 'error'); return; }
    toast('Updated', 'success'); closeModal(); loadMarket();
  });
}
async function deleteRate(id, name) {
  if (!confirm(`Remove rate for "${name}"?`)) return;
  const r = await api('DELETE', '/api/market/' + id);
  if (r.error) { toast(r.error, 'error'); return; }
  toast('Removed', 'success'); loadMarket();
}

// ── ANALYTICS ──
async function loadAnalytics() {
  const data = await api('GET', '/api/stats');
  const orders = await api('GET', '/api/orders');
  const users = await api('GET', '/api/users');
  const products = await api('GET', '/api/products/all');

  const roles = {};
  users.forEach(u => { roles[u.role] = (roles[u.role]||0)+1; });
  const roleTotal = users.length || 1;
  document.getElementById('role-chart').innerHTML = Object.entries(roles).map(([r,c]) => `
    <div class="chart-bar">
      <div class="chart-label">${r}</div>
      <div class="chart-track"><div class="chart-fill" style="width:${Math.round(c/roleTotal*100)}%"></div></div>
      <div class="chart-count">${c}</div>
    </div>`).join('');

  const crops = data.cropStats||[];
  const maxC = crops[0]?.count||1;
  document.getElementById('crop-chart').innerHTML = crops.map(c => `
    <div class="chart-bar">
      <div class="chart-label">${c.crop_type}</div>
      <div class="chart-track"><div class="chart-fill" style="width:${Math.round(c.count/maxC*100)}%"></div></div>
      <div class="chart-count">${c.count}</div>
    </div>`).join('') || '<p style="padding:20px;color:var(--text-muted)">No data</p>';

  const orderStatuses = {};
  orders.forEach(o => { orderStatuses[o.status] = (orderStatuses[o.status]||0)+1; });
  const oTotal = orders.length||1;
  document.getElementById('order-chart').innerHTML = Object.entries(orderStatuses).map(([s,c]) => `
    <div class="chart-bar">
      <div class="chart-label">${s}</div>
      <div class="chart-track"><div class="chart-fill" style="width:${Math.round(c/oTotal*100)}%"></div></div>
      <div class="chart-count">${c}</div>
    </div>`).join('') || '<p style="padding:20px;color:var(--text-muted)">No orders yet</p>';

  const revenue = orders.filter(o=>['approved','shipped','delivered'].includes(o.status)).reduce((s,o)=>s+(o.total_amount||0),0);
  document.getElementById('system-overview').innerHTML = `
    <div class="overview-item"><div class="overview-value">${users.length}</div><div class="overview-label">Total Users</div></div>
    <div class="overview-item"><div class="overview-value">${data.totalFarmers}</div><div class="overview-label">Farmers</div></div>
    <div class="overview-item"><div class="overview-value">${products.length}</div><div class="overview-label">Products</div></div>
    <div class="overview-item"><div class="overview-value">${orders.length}</div><div class="overview-label">Orders</div></div>
    <div class="overview-item"><div class="overview-value">PKR ${revenue.toLocaleString('en-PK')}</div><div class="overview-label">Revenue</div></div>
    <div class="overview-item"><div class="overview-value">${orders.filter(o=>o.status==='pending').length}</div><div class="overview-label">Pending Orders</div></div>
  `;
}

// ── ACTIVITY ──
async function loadActivity() {
  const logs = await api('GET', '/api/stats/activity');
  document.getElementById('activity-table').innerHTML = logs.map(a => `
    <tr>
      <td>${fmtTime(a.created_at)}</td>
      <td>${badge(a.action.split('_')[0],{ORDER:'orange',USER:'blue',FARMER:'green',PRODUCT:'purple',MARKET:'yellow',LOGIN:'gray'})}</td>
      <td>${a.description}</td>
      <td>${a.user_email}</td>
    </tr>`).join('');
}

// ── SETTINGS ──
let currentUser = null;
function loadSettings() {
  if (!currentUser) return;
  document.getElementById('settings-name').value = currentUser.name||'';
  document.getElementById('settings-email').value = currentUser.email||'';
  const saved = JSON.parse(localStorage.getItem('payment-info')||'{}');
  document.getElementById('jazzcash-num').value = saved.jazzcash||'';
  document.getElementById('easypaisa-num').value = saved.easypaisa||'';
  document.getElementById('bank-acc').value = saved.bank||'';
  setTheme(localStorage.getItem('agritrack-theme')||'light');
}
document.getElementById('profile-form').onsubmit = async e => {
  e.preventDefault();
  const r = await api('PUT', '/api/users/' + currentUser.id, { name: document.getElementById('settings-name').value });
  if (r.error) { toast(r.error, 'error'); return; }
  currentUser.name = document.getElementById('settings-name').value;
  document.getElementById('admin-name').textContent = currentUser.name;
  toast('Profile updated', 'success');
};
document.getElementById('password-form').onsubmit = async e => {
  e.preventDefault();
  const p1 = document.getElementById('new-password').value, p2 = document.getElementById('confirm-password').value;
  if (!p1) { toast('Enter a password', 'error'); return; }
  if (p1 !== p2) { toast('Passwords do not match', 'error'); return; }
  const r = await api('PUT', '/api/users/' + currentUser.id, { password: p1 });
  if (r.error) { toast(r.error, 'error'); return; }
  toast('Password changed', 'success');
};
document.getElementById('payment-form').onsubmit = e => {
  e.preventDefault();
  localStorage.setItem('payment-info', JSON.stringify({ jazzcash: document.getElementById('jazzcash-num').value, easypaisa: document.getElementById('easypaisa-num').value, bank: document.getElementById('bank-acc').value }));
  toast('Payment info saved', 'success');
};

document.getElementById('global-search').oninput = function() {
  const q = this.value;
  if (currentPage==='users') loadUsers(q);
  else if (currentPage==='farmers') loadFarmers(q);
};

async function init() {
  setTheme(savedTheme);
  const me = await api('GET', '/api/auth/me');
  if (me.error) { window.location.href = '/login.html'; return; }
  currentUser = me.user;
  document.getElementById('admin-name').textContent = me.user.name;
  document.getElementById('app').style.display = 'flex';
  navigate('dashboard');
}
init();
