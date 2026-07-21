const express = require('express');
const pool = require('../db/pool');

const router = express.Router();

const VALID_STATUSES = ['placed', 'ready', 'completed'];

// POST /orders — customer places an order.
// items is a snapshot at order time: [{ product_id, name, price, quantity }]
// so later price/name edits on the product never change a past order.
router.post('/', async (req, res) => {
  const { shopId, customerId, items, paymentMode, fulfillmentType } = req.body;

  if (!shopId || !customerId || !Array.isArray(items) || items.length === 0) {
    return res
      .status(400)
      .json({ error: 'shopId, customerId and a non-empty items array are required' });
  }
  if (!['cash', 'upi', 'udhari'].includes(paymentMode)) {
    return res
      .status(400)
      .json({ error: 'paymentMode must be "cash", "upi" or "udhari"' });
  }

  const result = await pool.query(
    `INSERT INTO orders (shop_id, customer_id, items, payment_mode, fulfillment_type)
     VALUES ($1, $2, $3, $4, COALESCE($5, 'pickup'))
     RETURNING *`,
    [shopId, customerId, JSON.stringify(items), paymentMode, fulfillmentType || null]
  );

  const order = result.rows[0];

  // Ordering with "udhari" as the payment mode is, functionally, taking
  // goods on credit — so it must also create the matching udhari_transactions
  // row, or the owner's udhari book and the order total silently disagree.
  if (paymentMode === 'udhari') {
    const total = items.reduce(
      (sum, item) => sum + Number(item.price) * Number(item.quantity),
      0
    );
    await pool.query(
      `INSERT INTO udhari_transactions (shop_id, customer_id, type, amount, note)
       VALUES ($1, $2, 'credit', $3, $4)`,
      [shopId, customerId, total, `Order #${order.id.slice(0, 8)}`]
    );
  }

  res.status(201).json(order);
});

// GET /orders/shop/:shopId — owner's incoming orders, newest first.
// ?status=placed to filter (e.g. the "needs action" queue).
router.get('/shop/:shopId', async (req, res) => {
  const { shopId } = req.params;
  const { status } = req.query;

  const conditions = ['shop_id = $1'];
  const params = [shopId];
  if (status) {
    params.push(status);
    conditions.push(`status = $${params.length}`);
  }

  const result = await pool.query(
    `SELECT * FROM orders WHERE ${conditions.join(' AND ')} ORDER BY created_at DESC`,
    params
  );

  res.json(result.rows);
});

// GET /orders/customer/:customerId — a customer's own order history
// (optionally scoped to one shop, since a customer could in theory
// link to more than one over time even though the pilot is 1:1)
router.get('/customer/:customerId', async (req, res) => {
  const { customerId } = req.params;
  const { shopId } = req.query;

  const conditions = ['customer_id = $1'];
  const params = [customerId];
  if (shopId) {
    params.push(shopId);
    conditions.push(`shop_id = $${params.length}`);
  }

  const result = await pool.query(
    `SELECT * FROM orders WHERE ${conditions.join(' AND ')} ORDER BY created_at DESC`,
    params
  );

  res.json(result.rows);
});

// PATCH /orders/:id/status — owner moves an order through
// placed -> ready -> completed
router.patch('/:id/status', async (req, res) => {
  const { status } = req.body;

  if (!VALID_STATUSES.includes(status)) {
    return res
      .status(400)
      .json({ error: `status must be one of: ${VALID_STATUSES.join(', ')}` });
  }

  const result = await pool.query(
    `UPDATE orders SET status = $1 WHERE id = $2 RETURNING *`,
    [status, req.params.id]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Order not found' });
  }

  res.json(result.rows[0]);
});

// PATCH /orders/:id/payment-status — owner marks cash/UPI as confirmed
// once they've actually received it (udhari orders don't need this —
// the udhari ledger itself is the record)
router.patch('/:id/payment-status', async (req, res) => {
  const { paymentStatus } = req.body;

  if (!['pending', 'confirmed'].includes(paymentStatus)) {
    return res.status(400).json({ error: 'paymentStatus must be "pending" or "confirmed"' });
  }

  const result = await pool.query(
    `UPDATE orders SET payment_status = $1 WHERE id = $2 RETURNING *`,
    [paymentStatus, req.params.id]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Order not found' });
  }

  res.json(result.rows[0]);
});

module.exports = router;
