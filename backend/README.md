# Nexus CSF — Drogon C++ Backend

REST API for the Flutter CSF app. Replaces static mock data with HTTP endpoints backed by `data/catalog.json`.

## Source layout

```
backend/
├── include/nexus/
│   ├── middleware/cors.h           # CORS headers
│   ├── routes/route_registry.h     # Route registration entry
│   ├── services/catalog_service.h  # Catalog load + queries
│   └── utils/json_response.h       # JSON + error helpers
├── src/
│   ├── main.cpp                    # Server bootstrap
│   ├── routes/route_registry.cpp   # All /api/* handlers
│   └── services/catalog_service.cpp
├── data/catalog.json               # Seed data (same shape as React mockData)
├── db/init.sql                     # PostgreSQL schema (optional profile)
├── scripts/podman-up.sh
├── Dockerfile
└── podman-compose.yml
```

## Run with Podman (recommended)

### What you need

| Service | Required? | Purpose |
|---------|-----------|---------|
| **nexus-api** | Yes | Drogon C++ REST API (reads `data/catalog.json`) |
| **postgres** | Optional (`--profile with-db`) | Database for future — products, orders, users |
| **redis** | Optional (`--profile with-cache`) | Future — cart cache, sessions |

Today the API uses **catalog.json**. PostgreSQL is included so you can migrate to SQL later.

### Quick start — API only

```bash
cd backend
cp .env.example .env
podman compose -f podman-compose.yml up -d --build
```

Or use the helper script:

```bash
chmod +x scripts/podman-up.sh
./scripts/podman-up.sh
```

Test:

```bash
curl http://127.0.0.1:8848/api/health
curl http://127.0.0.1:8848/api/catalog
```

### API + PostgreSQL database

```bash
podman compose -f podman-compose.yml --profile with-db up -d --build
```

Connect to DB:

```bash
podman exec -it nexus-postgres psql -U nexus -d nexus -c "SELECT id, name, price FROM products;"
```

### Full stack (API + DB + Redis)

```bash
podman compose -f podman-compose.yml --profile with-db --profile with-cache up -d --build
```

### Stop / remove

```bash
podman compose -f podman-compose.yml down
# Remove volumes too:
podman compose -f podman-compose.yml down -v
```

### Flutter after Podman

| Device | URL |
|--------|-----|
| iOS Simulator | `http://127.0.0.1:8848` |
| Android Emulator | `http://10.0.2.2:8848` |

```bash
cd ../CSF
flutter run
```

### Files

| File | Role |
|------|------|
| `podman-compose.yml` | Podman/Docker Compose stack |
| `compose.yaml` | Same as above (alternate name) |
| `Dockerfile` | Builds Drogon API container |
| `.env.example` | Ports and DB passwords |
| `data/catalog.json` | Product data (mounted into container) |
| `db/init.sql` | PostgreSQL schema + sample rows |

---

## Run locally without Podman (macOS)

```bash
brew install drogon
```

Or build from source: https://github.com/drogonframework/drogon

## Build & run

```bash
cd backend
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
./build/nexus_server
```

Server starts at **http://127.0.0.1:8848**

## API documentation (Swagger)

After the server is running, open:

| URL | Description |
|-----|-------------|
| **http://127.0.0.1:8848/api/docs** | Interactive Swagger UI — browse and try all endpoints |
| **http://127.0.0.1:8848/api/openapi.yaml** | OpenAPI 3 spec (auto-generated from live routes) |

**Auto-sync:** When you add a new `registerHandler(...)` route in C++ and restart/rebuild the API,
Swagger picks it up automatically. You do **not** need to edit `openapi.yaml` manually.

Optional reference file: `backend/openapi.yaml` (detailed schemas — not required for docs to work).

## API endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/catalog` | Full catalog (used by Flutter on startup) |
| GET | `/api/home` | Hero, categories, brands, featured |
| GET | `/api/categories` | Product category tiles |
| GET | `/api/search?q=rtx&limit=20` | Search products and builder parts |
| GET | `/api/products` | All products |
| GET | `/api/products/featured` | Featured grid products |
| GET | `/api/products/botm` | Build of the month |
| GET | `/api/products/{id}` | Single product |
| GET | `/api/builder/parts` | All builder parts |
| GET | `/api/builder/parts?type=cpu` | Parts by type |
| GET | `/api/orders` | Order list |
| GET | `/api/orders/{id}` | Order detail |
| POST | `/api/auth/login` | Mock login `{ "email": "..." }` |

## Flutter connection

| Device | Base URL |
|--------|----------|
| iOS Simulator | `http://127.0.0.1:8848` |
| Android Emulator | `http://10.0.2.2:8848` |
| Physical phone | `http://<your-computer-LAN-IP>:8848` |

Set in `CSF/lib/config/api_config.dart` or pass:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8848
```

## Data file

Edit `backend/data/catalog.json` to change products, builder parts, and orders.
