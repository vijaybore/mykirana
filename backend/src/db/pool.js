const { Pool } = require('pg');
require('dotenv').config();

// Single shared connection pool for the whole app.
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

module.exports = pool;
