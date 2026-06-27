-- Nexus CSF — PostgreSQL schema (optional, for future migration)
-- Started automatically when you use: podman compose --profile with-db up -d
-- The Drogon API still reads catalog.json today; this DB is ready for later.

CREATE TABLE IF NOT EXISTS products (
    id          TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    category    TEXT NOT NULL,
    price       NUMERIC(12, 2) NOT NULL,
    image_url   TEXT NOT NULL,
    specs       JSONB NOT NULL DEFAULT '{}',
    benchmarks  JSONB,
    is_new      BOOLEAN DEFAULT FALSE,
    is_deal     BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
    id          TEXT PRIMARY KEY,
    order_date  DATE NOT NULL,
    total       NUMERIC(12, 2) NOT NULL,
    status      TEXT NOT NULL CHECK (status IN ('processing', 'shipped', 'delivered', 'cancelled')),
    item_count  INTEGER NOT NULL DEFAULT 1,
    carrier     TEXT,
    eta_note    TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_lines (
    id          SERIAL PRIMARY KEY,
    order_id    TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    title       TEXT NOT NULL,
    qty         INTEGER NOT NULL DEFAULT 1,
    unit_price  NUMERIC(12, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
    id          SERIAL PRIMARY KEY,
    email       TEXT UNIQUE NOT NULL,
    password_hash TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Sample rows (mirror catalog.json — optional seed)
INSERT INTO products (id, name, category, price, image_url, specs, benchmarks, is_new, is_deal)
VALUES
  ('p1', 'Nebula X9 - Creator Pro', 'Desktops', 2499.99,
   'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?fm=jpg&fit=crop&q=80&w=800',
   '{"cpu":"Intel Core i9-14900K","gpu":"NVIDIA RTX 4080 Super","ram":"64GB DDR5-6000","storage":"2TB NVMe Gen4"}',
   '{"gaming":95,"productivity":98}', TRUE, FALSE),
  ('p2', 'Blade 16 Gaming Laptop', 'Laptops', 1899.99,
   'https://images.unsplash.com/photo-1603302576837-37561b2e2302?fm=jpg&fit=crop&q=80&w=800',
   '{"cpu":"AMD Ryzen 9 7945HX","gpu":"NVIDIA RTX 4070","ram":"32GB DDR5","storage":"1TB NVMe","display":"16\" QHD+ 240Hz Mini-LED"}',
   '{"gaming":88,"productivity":90}', FALSE, TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO orders (id, order_date, total, status, item_count, carrier, eta_note)
VALUES
  ('NX-9021', '2026-05-18', 2649.12, 'delivered', 2, 'NeoShip Apex', 'Signed at kiosk · Building A'),
  ('NX-9014', '2026-05-02', 1899.99, 'shipped', 1, 'NeoShip Apex', 'Arriving Tue · before 17:00')
ON CONFLICT (id) DO NOTHING;
