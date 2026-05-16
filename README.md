# TradeMLM - Trading Course + MLM Platform

A complete trading education platform with MLM binary tree, crypto payments, and a Flutter mobile/web app.

## Architecture

```
trading-course-mlm/
├── backend/          # Node.js + Express API
├── admin/            # React admin panel
└── app/              # Flutter mobile & web app
```

## Getting Started

### 1. Backend

```bash
cd backend
cp .env.example .env
# Edit .env with your values (MongoDB URI, JWT secret, NOWPayments API key, etc.)
npm install
npm run dev
```

Backend runs on http://localhost:5000

### 2. Admin Panel

```bash
cd admin
npm install
npm start
```

Admin panel runs on http://localhost:3000

Default admin: Create via `POST /api/auth/register` then update role to `admin` in MongoDB.

### 3. Flutter App

```bash
cd app
flutter pub get

# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

## Features

### Backend (Node.js + Express + MongoDB)
- JWT authentication with role-based access
- Course management (PDF, video, articles)
- Quiz system with grading
- **MLM Binary Tree** — auto-placement (BFS) or manual admin placement
- **Commission System** — direct referral (10%), level override (5 levels), binary matching
- **NOWPayments integration** — BTC, ETH, USDT, BNB, SOL, XRP, DOGE, LTC, TRX, USDC
- Withdrawal system with crypto address
- Real-time payment status via Socket.io

### Admin Panel (React + Ant Design)
- Dashboard with revenue analytics
- User management with MLM tree placement
- Course & quiz CRUD
- Commission approval/payment
- Withdrawal processing
- Full MLM settings configuration

### Flutter App
- Splash screen with animation
- Auth (login / register with referral code)
- Home dashboard with wallet balance
- Course listing with search & category filters
- Course detail with materials and quizzes
- Quiz taking with real-time scoring
- **Binary Tree Viewer** — interactive pinch/zoom tree
- MLM dashboard — earnings, team stats, referral link
- Crypto payment — currency selection, QR code, status polling
- Profile management & withdrawal request

## MLM Structure

- **Direct Referral Commission**: 10% of course price
- **Level Override**: Level 1: 10%, Level 2: 5%, Level 3: 3%, Level 4: 2%, Level 5: 1%
- **Binary Matching Bonus**: 10% on matched volume (configurable)
- **Minimum Payout**: $50

## Payment Flow

1. User selects a course → clicks "Buy"
2. Selects cryptocurrency (USDT, BTC, ETH, etc.)
3. App calls `POST /api/payments/initiate` → gets payment address + amount
4. QR code displayed; user sends payment
5. NOWPayments webhook → `POST /api/payments/callback`
6. On `finished` → course enrolled + commissions processed
7. App polls `GET /api/payments/status/:id` every 15 seconds

## Environment Variables

See `backend/.env.example` for all required variables.

Key variables:
- `NOWPAYMENTS_API_KEY` — Get from https://nowpayments.io
- `NOWPAYMENTS_IPN_SECRET` — IPN secret for webhook verification
- `JWT_SECRET` — Random string for JWT signing
- `MONGODB_URI` — MongoDB connection string
