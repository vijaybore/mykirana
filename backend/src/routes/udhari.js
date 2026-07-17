const express = require('express');
const pool = require('../db/pool');

const router = express.Router();

// POST /udhari — add a credit or payment entry
router.post('/', async (req, res) => {
  const { shopId, customerId, type, amount, note } = req.body;

  if (!shopId || !customerId || !type || !amount) {
    return res.status(400).json({ error: 'shopId, customerId, type, amount are required' });
  }
  if (!['credit', 'payment'].includes(type)) {
    return res.status(400).json({ error: 'type must be "credit" or "payment"' });
  }

  const result = await pool.query(
    `INSERT INTO udhari_transactions (shop_id, customer_id, type, amount, note)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [shopId, customerId, type, amount, note || null]
  );

  res.status(201).json(result.rows[0]);
});

// GET /udhari/balance/:shopId/:customerId — running balance for one customer
router.get('/balance/:shopId/:customerId', async (req, res) => {
  const { shopId, customerId } = req.params;

  const result = await pool.query(
    `SELECT
       COALESCE(SUM(CASE WHEN type = 'credit' THEN amount ELSE -amount END), 0) AS balance
     FROM udhari_transactions
     WHERE shop_id = $1 AND customer_id = $2`,
    [shopId, customerId]
  );

  res.json({ balance: Number(result.rows[0].balance) });
});

// GET /udhari/history/:shopId/:customerId — full transaction history
router.get('/history/:shopId/:customerId', async (req, res) => {
  const { shopId, customerId } = req.params;

  const result = await pool.query(
    `SELECT * FROM udhari_transactions
     WHERE shop_id = $1 AND customer_id = $2
     ORDER BY created_at DESC`,
    [shopId, customerId]
  );

  res.json(result.rows);
});

// GET /udhari/customers/:shopId — all customers of a shop sorted by balance owed
// (owner's "उधार यादी" list)
router.get('/customers/:shopId', async (req, res) => {
  const { shopId } = req.params;

  const result = await pool.query(
    `SELECT
       u.id AS customer_id,
       u.name,
       u.phone,
       COALESCE(SUM(CASE WHEN t.type = 'credit' THEN t.amount ELSE -t.amount END), 0) AS balance
     FROM customer_shop_links l
     JOIN users u ON u.id = l.customer_id
     LEFT JOIN udhari_transactions t ON t.customer_id = u.id AND t.shop_id = l.shop_id
     WHERE l.shop_id = $1
     GROUP BY u.id, u.name, u.phone
     ORDER BY balance DESC`,
    [shopId]
  );

  res.json(result.rows);
});

module.exports = router;
