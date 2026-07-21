const express = require('express');
const pool = require('../db/pool');

const router = express.Router();

// POST /products — owner adds a product
router.post('/', async (req, res) => {
  const { shopId, categoryId, name, price, unit, imageUrl, inStock } = req.body;

  if (!shopId || !name || price === undefined || !unit) {
    return res
      .status(400)
      .json({ error: 'shopId, name, price and unit are required' });
  }

  const result = await pool.query(
    `INSERT INTO products (shop_id, category_id, name, price, unit, image_url, in_stock)
     VALUES ($1, $2, $3, $4, $5, $6, COALESCE($7, true))
     RETURNING *`,
    [shopId, categoryId || null, name.trim(), price, unit, imageUrl || null, inStock]
  );

  res.status(201).json(result.rows[0]);
});

// GET /products/:shopId — product catalog for a shop.
// Optional query params:
//   ?categoryId=...   filter to one category
//   ?search=...       case-insensitive name match (for the customer search bar)
//   ?inStockOnly=true owner sees everything by default; the customer
//                     browse screen passes this to hide out-of-stock items
router.get('/:shopId', async (req, res) => {
  const { shopId } = req.params;
  const { categoryId, search, inStockOnly } = req.query;

  const conditions = ['shop_id = $1'];
  const params = [shopId];

  if (categoryId) {
    params.push(categoryId);
    conditions.push(`category_id = $${params.length}`);
  }
  if (search) {
    params.push(`%${search}%`);
    conditions.push(`name ILIKE $${params.length}`);
  }
  if (inStockOnly === 'true') {
    conditions.push('in_stock = true');
  }

  const result = await pool.query(
    `SELECT * FROM products WHERE ${conditions.join(' AND ')} ORDER BY name ASC`,
    params
  );

  res.json(result.rows);
});

// PUT /products/:id — edit a product (name/price/unit/category/image)
router.put('/:id', async (req, res) => {
  const { categoryId, name, price, unit, imageUrl } = req.body;

  const result = await pool.query(
    `UPDATE products
     SET category_id = COALESCE($1, category_id),
         name = COALESCE($2, name),
         price = COALESCE($3, price),
         unit = COALESCE($4, unit),
         image_url = COALESCE($5, image_url),
         updated_at = now()
     WHERE id = $6
     RETURNING *`,
    [categoryId || null, name, price, unit, imageUrl, req.params.id]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Product not found' });
  }

  res.json(result.rows[0]);
});

// PATCH /products/:id/stock — quick in-stock toggle from the product list
router.patch('/:id/stock', async (req, res) => {
  const { inStock } = req.body;

  if (typeof inStock !== 'boolean') {
    return res.status(400).json({ error: 'inStock (boolean) is required' });
  }

  const result = await pool.query(
    `UPDATE products SET in_stock = $1, updated_at = now() WHERE id = $2 RETURNING *`,
    [inStock, req.params.id]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Product not found' });
  }

  res.json(result.rows[0]);
});

// DELETE /products/:id
router.delete('/:id', async (req, res) => {
  await pool.query(`DELETE FROM products WHERE id = $1`, [req.params.id]);
  res.status(204).send();
});

module.exports = router;
