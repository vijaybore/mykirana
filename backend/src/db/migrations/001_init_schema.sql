-- MyKirana initial schema
-- Matches the data model from project planning: users, shops, categories,
-- products, customer-shop links, udhari transactions, and orders.

-- gen_random_uuid() (used as the default for every id column below)
-- comes from pgcrypto, not core Postgres — must be enabled first.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone         VARCHAR(15) UNIQUE NOT NULL,
  name          VARCHAR(120),
  role          VARCHAR(10) NOT NULL CHECK (role IN ('owner', 'customer')),
  language      VARCHAR(5) NOT NULL DEFAULT 'mr',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS shops (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  shop_name         VARCHAR(150) NOT NULL,
  shop_code         VARCHAR(30) UNIQUE NOT NULL, -- e.g. SHARMA23, derived from shop_name
  address           TEXT,
  business_upi_id   VARCHAR(100),
  upi_qr_image_url  TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Supports the "owner 2" case (co-owned shops, e.g. Shivprasad Kirana Store)
CREATE TABLE IF NOT EXISTS shop_owners (
  shop_id   UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  user_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  PRIMARY KEY (shop_id, user_id)
);

CREATE TABLE IF NOT EXISTS categories (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id   UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  name      VARCHAR(80) NOT NULL
);

CREATE TABLE IF NOT EXISTS products (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id       UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  category_id   UUID REFERENCES categories(id) ON DELETE SET NULL,
  name          VARCHAR(150) NOT NULL,
  price         NUMERIC(10, 2) NOT NULL,
  unit          VARCHAR(20) NOT NULL, -- kg, piece, litre, etc.
  in_stock      BOOLEAN NOT NULL DEFAULT true,
  image_url     TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS customer_shop_links (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  shop_id       UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  linked_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (customer_id, shop_id)
);

CREATE TABLE IF NOT EXISTS udhari_transactions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id       UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  customer_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type          VARCHAR(10) NOT NULL CHECK (type IN ('credit', 'payment')),
  amount        NUMERIC(10, 2) NOT NULL,
  note          TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS orders (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id             UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  customer_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  items               JSONB NOT NULL, -- [{ product_id, name, price, quantity }]
  payment_mode        VARCHAR(10) NOT NULL CHECK (payment_mode IN ('cash', 'upi', 'udhari')),
  payment_status      VARCHAR(10) NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'confirmed')),
  fulfillment_type    VARCHAR(10) NOT NULL DEFAULT 'pickup' CHECK (fulfillment_type IN ('pickup', 'delivery')),
  status              VARCHAR(15) NOT NULL DEFAULT 'placed' CHECK (status IN ('placed', 'ready', 'completed')),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Helpful indexes for the lookups the app does most often
CREATE INDEX IF NOT EXISTS idx_products_shop ON products(shop_id);
CREATE INDEX IF NOT EXISTS idx_udhari_shop_customer ON udhari_transactions(shop_id, customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_shop_status ON orders(shop_id, status);

