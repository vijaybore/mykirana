const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const shopsRouter = require('./routes/shops');
const udhariRouter = require('./routes/udhari');
const usersRouter = require('./routes/users');
const customerShopLinksRouter = require('./routes/customer_shop_links');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'mykirana-backend' });
});

app.use('/shops', shopsRouter);
app.use('/udhari', udhariRouter);
app.use('/users', usersRouter);
app.use('/customer-shop-links', customerShopLinksRouter);
// TODO: mount /products, /orders, /categories routers as those
// features are built (see project build order, Steps 5 and 8).

// Basic error handler — keeps stack traces out of API responses
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Something went wrong' });
});

module.exports = app;

