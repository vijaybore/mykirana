const express = require('express');
const pool = require('../db/pool');

const router = express.Router();

// POST /users — upsert by phone number. Called once when role
// selection completes (owner or customer), so shops/udhari/orders
// always have a real user row to reference.
router.post('/', async (req, res) => {
  const { phone, role, name, language } = req.body;

  if (!phone || !role) {
    return res.status(400).json({ error: 'phone and role are required' });
  }
  if (!['owner', 'customer'].includes(role)) {
    return res.status(400).json({ error: 'role must be "owner" or "customer"' });
  }

  const result = await pool.query(
    `INSERT INTO users (phone, role, name, language)
     VALUES ($1, $2, $3, COALESCE($4, 'mr'))
     ON CONFLICT (phone) DO UPDATE
       SET role = EXCLUDED.role,
           name = COALESCE(EXCLUDED.name, users.name),
           language = COALESCE(EXCLUDED.language, users.language)
     RETURNING *`,
    [phone, role, name || null, language || null]
  );

  res.status(201).json(result.rows[0]);
});

// GET /users/by-phone/:phone — used at app bootstrap to check
// whether this device's phone number already has an account.
router.get('/by-phone/:phone', async (req, res) => {
  const result = await pool.query('SELECT * FROM users WHERE phone = $1', [
    req.params.phone,
  ]);
  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'User not found' });
  }
  res.json(result.rows[0]);
});

// POST /users/clean-test-data — clean test data for the predefined whitelisted numbers
router.post('/clean-test-data', async (req, res) => {
  const testPhones = [
    '8956824842',
    '8805707911',
    '8805779621',
    '9923185742',
    '9511689937',
  ];
  try {
    await pool.cleanTestData(testPhones);
    res.json({ message: 'Test data cleaned successfully' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to clean test data: ' + err.message });
  }
});

module.exports = router;

