const { Pool } = require('pg');
const crypto = require('crypto');
require('dotenv').config();

const dbUrl = process.env.DATABASE_URL || '';
const isDummyUrl = !dbUrl || dbUrl.includes('user:password@host/db');

let realPool = null;
let useMemory = isDummyUrl;

if (!isDummyUrl) {
  try {
    realPool = new Pool({ connectionString: dbUrl });
  } catch (e) {
    useMemory = true;
  }
}

// In-memory data store for local dev/testing fallback
const store = {
  users: [],
  shops: [],
  categories: [],
  products: [],
  customer_shop_links: [],
  udhari_transactions: [],
  orders: [],
};

function mockQuery(text, params = []) {
  const sql = text.trim();

  // USERS
  if (sql.includes('INSERT INTO users')) {
    const [phone, role, name, language] = params;
    let user = store.users.find((u) => u.phone === phone);
    if (user) {
      user.role = role || user.role;
      if (name) user.name = name;
      if (language) user.language = language;
    } else {
      user = {
        id: crypto.randomUUID(),
        phone,
        role,
        name: name || null,
        language: language || 'mr',
        created_at: new Date().toISOString(),
      };
      store.users.push(user);
    }
    return { rows: [user] };
  }

  if (sql.includes('FROM users') && sql.includes('phone =')) {
    const phone = params[0];
    const user = store.users.find((u) => u.phone === phone);
    return { rows: user ? [user] : [] };
  }

  if (sql.includes('FROM users') && sql.includes('id =')) {
    const id = params[0];
    const user = store.users.find((u) => u.id === id);
    return { rows: user ? [user] : [] };
  }

  // SHOPS
  if (sql.includes('count(*) FROM shops')) {
    return { rows: [{ count: store.shops.length.toString() }] };
  }
  if (sql.includes('FROM shops') && sql.includes('owner_id =')) {
    const ownerId = params[0];
    const shop = store.shops.find((s) => s.owner_id === ownerId);
    return { rows: shop ? [shop] : [] };
  }

  if (sql.includes('FROM shops') && sql.includes('shop_code =')) {
    const code = params[0];
    const shop = store.shops.find((s) => s.shop_code === code);
    return { rows: shop ? [shop] : [] };
  }

  if (sql.includes('INSERT INTO shops')) {
    const [
      owner_id,
      shop_name,
      shop_code,
      address,
      business_upi_id,
      contact_phone,
      shop_image_url,
      upi_qr_image_url,
    ] = params;
    const shop = {
      id: crypto.randomUUID(),
      owner_id,
      shop_name,
      shop_code,
      address: address || null,
      business_upi_id: business_upi_id || null,
      upi_qr_image_url: upi_qr_image_url || null,
      contact_phone: contact_phone || null,
      shop_image_url: shop_image_url || null,
      created_at: new Date().toISOString(),
    };
    store.shops.push(shop);
    return { rows: [shop] };
  }

  if (sql.includes('UPDATE shops SET')) {
    const id = params[params.length - 1];
    const shop = store.shops.find((s) => s.id === id);
    if (shop) {
      if (params[0] !== undefined) shop.shop_name = params[0];
      if (params[1] !== undefined) shop.address = params[1];
      if (params[2] !== undefined) shop.business_upi_id = params[2];
      if (params[3] !== undefined) shop.contact_phone = params[3];
      if (params[4] !== undefined) shop.shop_image_url = params[4];
      if (params[5] !== undefined) shop.upi_qr_image_url = params[5];
    }
    return { rows: shop ? [shop] : [] };
  }

  // CUSTOMER SHOP LINKS
  if (sql.includes('INSERT INTO customer_shop_links')) {
    const [customer_id, shop_id] = params;
    let link = store.customer_shop_links.find(
      (l) => l.customer_id === customer_id && l.shop_id === shop_id
    );
    if (!link) {
      link = {
        id: crypto.randomUUID(),
        customer_id,
        shop_id,
        linked_at: new Date().toISOString(),
      };
      store.customer_shop_links.push(link);
    }
    return { rows: [link] };
  }

  if (sql.includes('FROM customer_shop_links') && sql.includes('JOIN shops')) {
    const customer_id = params[0];
    const link = store.customer_shop_links.find(
      (l) => l.customer_id === customer_id
    );
    if (!link) return { rows: [] };
    const shop = store.shops.find((s) => s.id === link.shop_id);
    return { rows: shop ? [shop] : [] };
  }

  // CATEGORIES
  if (sql.includes('FROM categories') && sql.includes('shop_id =')) {
    const shop_id = params[0];
    const cats = store.categories.filter((c) => c.shop_id === shop_id);
    return { rows: cats };
  }

  if (sql.includes('INSERT INTO categories')) {
    const [shop_id, name] = params;
    const cat = {
      id: crypto.randomUUID(),
      shop_id,
      name,
    };
    store.categories.push(cat);
    return { rows: [cat] };
  }

  if (sql.includes('DELETE FROM categories')) {
    const id = params[0];
    store.categories = store.categories.filter((c) => c.id !== id);
    return { rows: [] };
  }

  // PRODUCTS
  if (sql.includes('FROM products') && sql.includes('shop_id =')) {
    const shop_id = params[0];
    let prods = store.products.filter((p) => p.shop_id === shop_id);
    return { rows: prods };
  }

  if (sql.includes('INSERT INTO products')) {
    const [shop_id, category_id, name, price, unit, image_url, in_stock] = params;
    const prod = {
      id: crypto.randomUUID(),
      shop_id,
      category_id: category_id || null,
      name,
      price: parseFloat(price),
      unit,
      in_stock: in_stock !== false,
      image_url: image_url || null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    store.products.push(prod);
    return { rows: [prod] };
  }

  if (sql.includes('UPDATE products SET in_stock =')) {
    const [in_stock, id] = params;
    const prod = store.products.find((p) => p.id === id);
    if (prod) prod.in_stock = Boolean(in_stock);
    return { rows: prod ? [prod] : [] };
  }

  if (sql.includes('UPDATE products SET')) {
    const id = params[params.length - 1];
    const prod = store.products.find((p) => p.id === id);
    if (prod) {
      if (params[0]) prod.category_id = params[0];
      if (params[1]) prod.name = params[1];
      if (params[2]) prod.price = parseFloat(params[2]);
      if (params[3]) prod.unit = params[3];
      if (params[4]) prod.image_url = params[4];
    }
    return { rows: prod ? [prod] : [] };
  }

  if (sql.includes('DELETE FROM products')) {
    const id = params[0];
    store.products = store.products.filter((p) => p.id !== id);
    return { rows: [] };
  }

  // UDHARI
  if (sql.includes('udhari_transactions') && sql.includes('GROUP BY')) {
    const shop_id = params[0];
    const customerMap = {};
    for (const t of store.udhari_transactions.filter(
      (t) => t.shop_id === shop_id
    )) {
      if (!customerMap[t.customer_id]) {
        const u = store.users.find((user) => user.id === t.customer_id);
        customerMap[t.customer_id] = {
          customer_id: t.customer_id,
          name: u ? u.name : 'Customer',
          phone: u ? u.phone : '',
          balance: 0,
        };
      }
      if (t.type === 'credit') {
        customerMap[t.customer_id].balance += parseFloat(t.amount);
      } else {
        customerMap[t.customer_id].balance -= parseFloat(t.amount);
      }
    }
    return { rows: Object.values(customerMap) };
  }

  if (sql.includes('FROM udhari_transactions') && sql.includes('customer_id =')) {
    const [shop_id, customer_id] = params;
    const list = store.udhari_transactions.filter(
      (t) => t.shop_id === shop_id && t.customer_id === customer_id
    );
    return { rows: list };
  }

  if (sql.includes('INSERT INTO udhari_transactions')) {
    const [shop_id, customer_id, type, amount, note] = params;
    const item = {
      id: crypto.randomUUID(),
      shop_id,
      customer_id,
      type,
      amount: parseFloat(amount),
      note: note || null,
      created_at: new Date().toISOString(),
    };
    store.udhari_transactions.push(item);
    return { rows: [item] };
  }

  // ORDERS
  if (sql.includes('INSERT INTO orders')) {
    const [shop_id, customer_id, items, payment_mode, fulfillment_type] = params;
    const order = {
      id: crypto.randomUUID(),
      shop_id,
      customer_id,
      items: typeof items === 'string' ? JSON.parse(items) : items,
      payment_mode,
      payment_status: 'pending',
      fulfillment_type: fulfillment_type || 'pickup',
      status: 'placed',
      created_at: new Date().toISOString(),
    };
    store.orders.push(order);
    return { rows: [order] };
  }

  if (sql.includes('FROM orders') && sql.includes('shop_id =')) {
    const shop_id = params[0];
    let list = store.orders.filter((o) => o.shop_id === shop_id);
    if (params.length > 1 && params[1]) {
      list = list.filter((o) => o.status === params[1]);
    }
    return { rows: list };
  }

  if (sql.includes('FROM orders') && sql.includes('customer_id =')) {
    const customer_id = params[0];
    let list = store.orders.filter((o) => o.customer_id === customer_id);
    return { rows: list };
  }

  if (sql.includes('UPDATE orders SET status =')) {
    const [status, id] = params;
    const order = store.orders.find((o) => o.id === id);
    if (order) order.status = status;
    return { rows: order ? [order] : [] };
  }

  if (sql.includes('UPDATE orders SET payment_status =')) {
    const [payment_status, id] = params;
    const order = store.orders.find((o) => o.id === id);
    if (order) order.payment_status = payment_status;
    return { rows: order ? [order] : [] };
  }

  return { rows: [] };
}

module.exports = {
  async query(text, params) {
    if (!useMemory && realPool) {
      try {
        return await realPool.query(text, params);
      } catch (err) {
        console.warn('PostgreSQL query failed, using in-memory store:', err.message);
        useMemory = true;
      }
    }
    return mockQuery(text, params);
  },
  async end() {
    if (realPool) {
      try {
        await realPool.end();
      } catch (_) {}
    }
  },
};
