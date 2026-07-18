const express = require('express');
const pool = require('../db/pool');

const router = express.Router();

// POST /customer-shop-links — called when a customer scans/enters a
// shop code. Idempotent: linking the same customer+shop twice is a
// no-op rather than an error, since the customer might scan the QR
// again later without it being a mistake.
router.post('/', async (req, res) => {
  const { customerId, shopId } = req.body;

  if (!customerId || !shopId) {
    return res.status(400).json({ error: 'customerId and shopId are required' });
  }

  const result = await pool.query(
    `INSERT INTO customer_shop_links (customer_id, shop_id)
     VALUES ($1, $2)
     ON CONFLICT (customer_id, shop_id) DO UPDATE SET linked_at = customer_shop_links.linked_at
     RETURNING *`,
    [customerId, shopId]
  );

  res.status(201).json(result.rows[0]);
});

// GET /customer-shop-links/:customerId — this pilot links a customer
// to exactly one shop, so return that shop's details directly (not
// just the link row) — this is what the app calls at bootstrap to
// decide whether to skip the shop-linking screen entirely.
router.get('/:customerId', async (req, res) => {
  const result = await pool.query(
    `SELECT s.*
     FROM customer_shop_links l
     JOIN shops s ON s.id = l.shop_id
     WHERE l.customer_id = $1
     ORDER BY l.linked_at DESC
     LIMIT 1`,
    [req.params.customerId]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'No linked shop for this customer' });
  }

  res.json(result.rows[0]);
});

module.exports = router;

