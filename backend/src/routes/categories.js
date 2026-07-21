const express = require('express');
const pool = require('../db/pool');

const router = express.Router();

// POST /categories — owner creates a category for their shop
router.post('/', async (req, res) => {
  const { shopId, name } = req.body;

  if (!shopId || !name) {
    return res.status(400).json({ error: 'shopId and name are required' });
  }

  const result = await pool.query(
    `INSERT INTO categories (shop_id, name) VALUES ($1, $2) RETURNING *`,
    [shopId, name.trim()]
  );

  res.status(201).json(result.rows[0]);
});

// GET /categories/:shopId — all categories for a shop, alphabetical
router.get('/:shopId', async (req, res) => {
  const result = await pool.query(
    `SELECT * FROM categories WHERE shop_id = $1 ORDER BY name ASC`,
    [req.params.shopId]
  );
  res.json(result.rows);
});

// DELETE /categories/:id — products in this category fall back to
// "uncategorised" (category_id set NULL) rather than being deleted,
// per the products table's ON DELETE SET NULL.
router.delete('/:id', async (req, res) => {
  await pool.query(`DELETE FROM categories WHERE id = $1`, [req.params.id]);
  res.status(204).send();
});

module.exports = router;
