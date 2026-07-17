# MyKirana

A digital udhari (credit) book and simple ordering app for village kirana shops —
built for a 2-shop pilot before wider public launch.

## What it does
- **Shop owners** manage products, track customer udhari (credit), and receive orders.
- **Customers** link to their shop via QR/code, browse products, check their own
  udhari balance, and place simple pickup orders — paying by cash, UPI (shop's own
  QR, no payment gateway), or udhari.
- Full support for **English, Hindi, and Marathi**, kept simple and shopkeeper-toned.

## Structure
```
/mobile    Flutter app (Owner + Customer, single codebase, role-based)
/backend   Node.js + Express + PostgreSQL API
```

## Getting Started

### Mobile (Flutter)
```
cd mobile
flutter pub get
flutter run
```

### Backend (Node.js)
```
cd backend
npm install
cp .env.example .env   # fill in your DB connection string
npm run dev
```

## Build Status
- [x] Auth (phone + OTP), role selection — owner/customer
- [x] Localization scaffolding (en / hi / mr) — 72 keys, full parity across all three
- [x] Udhari core (add/view credit & payments) — offline-first, owner + customer views
- [ ] Shop profile setup + QR/code generation
- [ ] Product management (categories, images, stock)
- [ ] Customer shop-linking (scan/enter code)
- [ ] Product browsing (category tabs + search)
- [ ] Ordering flow (cash / UPI / udhari)
- [ ] Order status tracking
- [ ] Full offline sync (background push of pending_sync rows on reconnect)

### Known gaps to wire up next
- `session_provider.dart` currently holds no real user/shop IDs — needs
  connecting to Firebase Auth UID + a `POST /users` call once role
  selection completes, and to the shop-linking screen for customers.
- `ApiService` base URL defaults to the Android emulator's localhost
  alias (`10.0.2.2:4000`) — point it at your LAN IP or deployed backend
  as needed.
- Backend has no auth middleware yet — routes are open. Add Firebase
  Admin ID-token verification before this goes past the pilot.

See project planning docs for full requirement analysis, data model, and rollout plan.
