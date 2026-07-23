require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const shopsRouter = require('./routes/shops');
const udhariRouter = require('./routes/udhari');
const usersRouter = require('./routes/users');
const customerShopLinksRouter = require('./routes/customer_shop_links');
const categoriesRouter = require('./routes/categories');
const productsRouter = require('./routes/products');
const ordersRouter = require('./routes/orders');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

const limiter = rateLimit({
  windowMs: Number(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: Number(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);


app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'mykirana-backend' });
});

app.use('/shops', shopsRouter);
app.use('/udhari', udhariRouter);
app.use('/users', usersRouter);
app.use('/customer-shop-links', customerShopLinksRouter);
app.use('/categories', categoriesRouter);
app.use('/products', productsRouter);
app.use('/orders', ordersRouter);

// Basic error handler — exposes stack traces and detailed messages in development
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({
    error: err.message || 'Something went wrong',
    stack: err.stack,
  });
});

module.exports = app;

