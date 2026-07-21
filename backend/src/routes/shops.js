const express = require('express');
const pool = require('../db/pool');

const router = express.Router();

/**
 * Generates a human-readable shop code from the shop name,
 * e.g. "Sharma Kirana Store" -> "SHARMA23".
 * Retries with a new random suffix on the rare collision.
 */
function deriveShopCode(shopName) {
  const base = shopName
    .split(' ')[0]
    .toUpperCase()
    .replace(/[^A-Z]/g, '');
  const suffix = Math.floor(10 + Math.random() * 90); // 2-digit
  return `${base}${suffix}`;
}

// POST /shops — create a shop (used by admin during pilot onboarding,
// or by an owner's self-service registration screen later)
router.post('/', async (req, res) => {
  const { ownerId, shopName, address, businessUpiId } = req.body;

  if (!ownerId || !shopName) {
    return res.status(400).json({ error: 'ownerId and shopName are required' });
  }

  let shopCode;
  let attempts = 0;
  let created = null;

  // Retry on shop_code collision (rare, but the column is UNIQUE)
  while (!created && attempts < 5) {
    shopCode = deriveShopCode(shopName);
    try {
      const result = await pool.query(
        `INSERT INTO shops (owner_id, shop_name, shop_code, address, business_upi_id)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [ownerId, shopName, shopCode, address, businessUpiId]
      );
      created = result.rows[0];
    } catch (err) {
      if (err.code === '23505') {
        attempts += 1; // unique_violation on shop_code, retry
      } else {
        throw err;
      }
    }
  }

  if (!created) {
    return res.status(500).json({ error: 'Could not generate a unique shop code' });
  }

  res.status(201).json(created);
});

// GET /shops/by-owner/:ownerId — used at app bootstrap to check whether
// this owner already has a shop (so shop-setup can be skipped on relaunch)
router.get('/by-owner/:ownerId', async (req, res) => {
  const result = await pool.query('SELECT * FROM shops WHERE owner_id = $1', [
    req.params.ownerId,
  ]);

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'No shop found for this owner' });
  }

  res.json(result.rows[0]);
});

// GET /shops/by-code/:code — used by the customer shop-linking screen
router.get('/by-code/:code', async (req, res) => {
  const { code } = req.params;
  const result = await pool.query('SELECT * FROM shops WHERE shop_code = $1', [
    code.toUpperCase(),
  ]);

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Shop not found for this code' });
  }

  res.json(result.rows[0]);
});

module.exports = router;
