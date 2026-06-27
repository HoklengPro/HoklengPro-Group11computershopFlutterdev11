-- Nexus CSF — PostgreSQL catalog schema (run after init.sql)
-- podman exec -i nexus-postgres psql -U nexus -d nexus < db/002_postgres_catalog.sql

ALTER TABLE products
    ADD COLUMN IF NOT EXISTS product_role TEXT NOT NULL DEFAULT 'featured',
    ADD COLUMN IF NOT EXISTS config_options JSONB,
    ADD COLUMN IF NOT EXISTS sort_order INT NOT NULL DEFAULT 0;

ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS tracking_hints JSONB NOT NULL DEFAULT '[]'::jsonb;

CREATE TABLE IF NOT EXISTS catalog_sections (
    section_key TEXT PRIMARY KEY,
    payload       JSONB NOT NULL,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS builder_parts (
    id         TEXT PRIMARY KEY,
    part_type  TEXT NOT NULL,
    name       TEXT NOT NULL,
    brand      TEXT NOT NULL,
    price      NUMERIC(12, 2) NOT NULL,
    image_url  TEXT NOT NULL,
    attributes JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_products_role ON products(product_role);
CREATE INDEX IF NOT EXISTS idx_builder_parts_type ON builder_parts(part_type);
