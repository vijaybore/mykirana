/**
 * Simple migration runner — applies every .sql file in db/migrations
 * in filename order. Good enough at this pilot's scale; swap for a
 * proper migration tool (e.g. node-pg-migrate) if the schema grows.
 */
const fs = require('fs');
const path = require('path');
const pool = require('./pool');

async function migrate() {
  const migrationsDir = path.join(__dirname, 'migrations');
  const files = fs.readdirSync(migrationsDir).sort();

  for (const file of files) {
    if (!file.endsWith('.sql')) continue;
    const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
    console.log(`Applying migration: ${file}`);
    await pool.query(sql);
  }

  console.log('All migrations applied.');
  await pool.end();
}

migrate().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
