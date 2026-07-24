const express = require('express');
const pool = require('../db/pool');

const router = express.Router();

const ALLOWED_FREE_NUMBERS = [
  '8956824842',
  '8805707911',
  '8805779621',
  '9923185742',
  '9511689937',
];

/**
 * Generates a human-readable shop code from the shop name,
 * e.g. "Sharma Kirana Store" -> "SHARMA23".
 */
function deriveShopCode(shopName) {
  const base = shopName
    .split(' ')[0]
    .toUpperCase()
    .replace(/[^A-Z]/g, '');
  const suffix = Math.floor(10 + Math.random() * 90);
  return `${base}${suffix}`;
}

// POST /shops — create a shop
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

  // Check if owner already has a shop to prevent duplicate shops
  try {
    const existing = await pool.query('SELECT * FROM shops WHERE owner_id = $1', [ownerId]);
    if (existing.rows.length > 0) {
      return res.status(200).json(existing.rows[0]);
    }
  } catch (err) {
    console.error('Error checking existing shop:', err);
  }

  // Check if owner's phone is whitelisted
  let isWhitelisted = false;
  try {
    const userRes = await pool.query('SELECT phone FROM users WHERE id = $1', [ownerId]);
    if (userRes.rows.length > 0) {
      const userPhone = (userRes.rows[0].phone || '').replace(/\D/g, '');
      if (ALLOWED_FREE_NUMBERS.includes(userPhone)) {
        isWhitelisted = true;
      }
    }
  } catch (_) {}

  const cleanContact = (contactPhone || '').replace(/\D/g, '');
  if (ALLOWED_FREE_NUMBERS.includes(cleanContact)) {
    isWhitelisted = true;
  }

  // If not whitelisted, check the free shop count limit
  if (!isWhitelisted) {
    try {
      const countResult = await pool.query('SELECT count(*) FROM shops');
      const shopCount = countResult.rows && countResult.rows.length > 0 
        ? parseInt(countResult.rows[0].count || 0, 10) 
        : 0;

      if (shopCount >= 2) {
        return res.status(403).json({
          error: 'Free tier limit reached. A subscription of ₹500/month is required to register a new shop.',
          code: 'subscription_required',
        });
      }
    } catch (err) {
      console.error('Error checking shop count:', err);
    }
  }

  let shopCode;
  let attempts = 0;
  let created = null;

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
          address || null,
          businessUpiId || null,
          contactPhone || null,
          shopImageUrl || null,
          upiQrImageUrl || null,
        ]
      );
      created = result.rows[0];
    } catch (err) {
      attempts++;
      if (err.code !== '23505') {
        return res.status(500).json({ error: 'Failed to create shop: ' + err.message });
      }
    }
  }

  if (!created) {
    return res.status(500).json({ error: 'Could not generate a unique shop code. Try again.' });
  }

  res.status(201).json(created);
});

// GET /shops/by-owner/:ownerId
router.get('/by-owner/:ownerId', async (req, res) => {
  const result = await pool.query('SELECT * FROM shops WHERE owner_id = $1', [
    req.params.ownerId,
  ]);
  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Shop not found for this owner' });
  }
  res.json(result.rows[0]);
});

// GET /shops/by-code/:code
router.get('/by-code/:code', async (req, res) => {
  const result = await pool.query('SELECT * FROM shops WHERE shop_code = $1', [
    req.params.code,
  ]);
  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Shop not found' });
  }
  res.json(result.rows[0]);
});

// PUT /shops/:id
router.put('/:id', async (req, res) => {
  const {
    shopName,
    address,
    businessUpiId,
    contactPhone,
    shopImageUrl,
    upiQrImageUrl,
    shopCode,
  } = req.body;

  let cleanCode = null;
  if (shopCode !== undefined && shopCode !== null) {
    cleanCode = shopCode.trim().toUpperCase().replace(/[^A-Z0-9]/g, '');
    if (cleanCode.length < 3) {
      return res.status(400).json({ error: 'Shop code must be at least 3 characters long.' });
    }
    try {
      const conflict = await pool.query(
        'SELECT id FROM shops WHERE shop_code = $1 AND id <> $2',
        [cleanCode, req.params.id]
      );
      if (conflict.rows.length > 0) {
        return res.status(400).json({ error: 'Shop code is already in use.' });
      }
    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  }

  const result = await pool.query(
    `UPDATE shops
     SET shop_name = COALESCE($1, shop_name),
         address = COALESCE($2, address),
         business_upi_id = COALESCE($3, business_upi_id),
         contact_phone = COALESCE($4, contact_phone),
         shop_image_url = COALESCE($5, shop_image_url),
         upi_qr_image_url = COALESCE($6, upi_qr_image_url),
         shop_code = COALESCE($7, shop_code)
     WHERE id = $8
     RETURNING *`,
    [
      shopName || null,
      address || null,
      businessUpiId || null,
      contactPhone || null,
      shopImageUrl || null,
      upiQrImageUrl || null,
      cleanCode || null,
      req.params.id,
    ]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Shop not found' });
  }

  res.json(result.rows[0]);
});

module.exports = router;
