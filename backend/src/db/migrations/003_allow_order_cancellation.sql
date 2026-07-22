-- Allows orders to be cancelled (by either the customer, before the
-- shop marks it ready, or the owner at any point) — previously the
-- status column's CHECK constraint only permitted the forward-only
-- placed -> ready -> completed progression with no way out.
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE orders
  ADD CONSTRAINT orders_status_check
  CHECK (status IN ('placed', 'ready', 'completed', 'cancelled'));
