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
  const {
    ownerId,
    shopName,
    address,
    businessUpiId,
    contactPhone,
    shopImageUrl,
    upiQrImageUrl,
  } = req.body;

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
        `INSERT INTO shops
           (owner_id, shop_name, shop_code, address, business_upi_id,
            contact_phone, shop_image_url, upi_qr_image_url)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [
          ownerId,
          shopName,
          shopCode,
          address,
          businessUpiId,
          contactPhone || null,
          shopImageUrl || null,
          upiQrImageUrl || null,
        ]
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

// PUT /shops/:id — edit shop details (name/address/UPI/contact/images).
// The setup screen already tells the owner "you can edit it later" —
// this is what makes that true.
router.put('/:id', async (req, res) => {
  const { shopName, address, businessUpiId, contactPhone, shopImageUrl, upiQrImageUrl } =
    req.body;

  const result = await pool.query(
    `UPDATE shops
     SET shop_name = COALESCE($1, shop_name),
         address = COALESCE($2, address),
         business_upi_id = COALESCE($3, business_upi_id),
         contact_phone = COALESCE($4, contact_phone),
         shop_image_url = COALESCE($5, shop_image_url),
         upi_qr_image_url = COALESCE($6, upi_qr_image_url)
     WHERE id = $7
     RETURNING *`,
    [shopName, address, businessUpiId, contactPhone, shopImageUrl, upiQrImageUrl, req.params.id]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Shop not found' });
  }

  res.json(result.rows[0]);
});

module.exports = router;
