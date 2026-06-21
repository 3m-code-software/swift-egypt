# Swift Egypt - Shipping & Logistics Platform

منصة رقمية متكاملة لشركة شحن دولي (بري وبحري) وشحن داخلي

## System Architecture

```
swift_egypt/
├── apps/
│   ├── customer_app/          # Flutter - Customer Mobile App
│   └── driver_app/            # Flutter - Driver Mobile App
├── packages/
│   └── shared/                # Flutter - Shared Package (Models, API, Utils)
├── backend/
│   └── api/                   # FastAPI - Backend API
├── admin/                     # Next.js - Admin Web Dashboard
├── docs/                      # Documentation
├── docker-compose.yml         # Local development setup
└── railway.json               # Railway deployment config
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Customer App | Flutter 3.x |
| Driver App | Flutter 3.x |
| Admin Dashboard | Next.js 14 + Tailwind CSS |
| Backend API | FastAPI (Python 3.11) |
| Database | PostgreSQL 16 |
| Cache/Queue | Redis 7 |
| Push Notifications | Firebase Cloud Messaging |
| Maps | Google Maps / Mapbox |
| File Storage | AWS S3 / Local |

## Quick Start

### Prerequisites
- Flutter 3.11+
- Python 3.11+
- Node.js 20+
- Docker Desktop (optional)

### 1. Clone & Setup

```bash
git clone <repo-url> swift_egypt
cd swift_egypt
```

### 2. Backend API

```bash
cd backend/api
pip install -r requirements.txt
cp ../../.env.example .env
# Edit .env with your settings
python -m app.seed   # Seed admin user & initial data
uvicorn app.main:app --reload
```

API runs at `http://localhost:8000`
API Docs at `http://localhost:8000/docs`

### 3. Admin Dashboard

```bash
cd admin
npm install
cp ../../.env.example .env.local
npm run dev
```

Admin runs at `http://localhost:3000`

### 4. Customer App

```bash
cd apps/customer_app
flutter pub get
flutter run
```

### 5. Driver App

```bash
cd apps/driver_app
flutter pub get
flutter run
```

### 6. Docker (All Services)

```bash
docker-compose up -d
```

## Default Admin Credentials

- Email: admin@swiftegypt.com
- Password: admin123

## Project Components

### Customer App (apps/customer_app)
- Create & track shipments
- Pricing calculator
- Document upload
- Invoice & payment
- Support chatbot
- Real-time tracking

### Driver App (apps/driver_app)
- Daily task list
- Turn-by-turn navigation
- Status updates (offline-capable)
- Proof of delivery (photo + signature + GPS)
- Cash collection
- Activity log

### Admin Dashboard (admin/)
- Operations dashboard
- Shipment management
- Customer & driver management
- Branch & vehicle management
- Invoicing & payments
- AI alerts & analytics
- Reports

### Backend API (backend/api)
- RESTful API with JWT auth
- Role-based access (6 roles)
- Async PostgreSQL with SQLAlchemy
- Redis caching & queues
- AI service stubs (ETA, routing, OCR)
- File upload & management

## API Endpoints

| Group | Endpoints |
|-------|-----------|
| Auth | register, login, verify-otp, forgot-password, reset-password |
| Shipments | CRUD, assign driver/vehicle, approve, cancel, tracking |
| Tracking | events, live location, public tracking by number |
| Drivers | tasks, status updates, proof of delivery, location |
| Pricing | estimate, rules management |
| Documents | upload, list, OCR |
| Invoices | CRUD, payment recording |
| Support | tickets, chat |
| AI | ETA prediction, route optimization, alerts, suggestions |
| Dashboard | stats, recent shipments, alerts |

## AI Features

- **ETA Prediction**: Estimated time of arrival based on route, distance, and historical data
- **Route Optimization**: Suggested optimal routes and alternatives
- **Risk Detection**: Early warning for delayed or at-risk shipments
- **Pricing Suggestion**: Smart pricing recommendations
- **Performance Analytics**: Driver and branch performance analysis

## Deployment

### Railway
The project is configured for deployment on Railway:

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Deploy
railway up
```

Railway services:
- `api` - FastAPI backend
- `admin` - Next.js dashboard
- `worker` - Background tasks
- `postgres` - Database (Railway managed)
- `redis` - Cache (Railway managed)

### Environment Variables
Copy `.env.example` to `.env` and set your configuration:
- Database URL
- Secret keys
- API keys (Google Maps, Firebase, Stripe, etc.)
- Service URLs

## License
Private - Swift Egypt
