-- Adds shop contact number and a shop storefront photo, alongside the
-- UPI QR image column that already existed but was never wired up to
-- a screen. IF NOT EXISTS keeps this safe to re-run, matching how
-- migrate.js re-applies every file with no separate "applied" tracking.
ALTER TABLE shops ADD COLUMN IF NOT EXISTS contact_phone VARCHAR(15);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS shop_image_url TEXT;
