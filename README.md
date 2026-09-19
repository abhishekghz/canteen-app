# Canteen App 🍽️

Student canteen booking app for **Android, iOS, and Web** — one Flutter codebase,
Firebase backend. Book breakfast/lunch/dinner with extras, snacks, coupons, a
weekly menu, a (stubbed) payment step, and a default admin who manages menu,
charges, and payment status.

- Architecture & flows: [`docs/architecture/ARCHITECTURE.md`](docs/architecture/ARCHITECTURE.md)
- Implementation plan: [`docs/superpowers/plans/2026-09-19-canteen-app.md`](docs/superpowers/plans/2026-09-19-canteen-app.md)

---

## Run it now (zero setup — in-memory demo)

The app ships with an in-memory backend so it runs instantly with no Firebase.

```bash
export PATH="$HOME/flutter-sdk/bin:$PATH"   # if flutter isn't on PATH
flutter pub get
flutter run -d chrome                        # Web
# or: flutter run -d macos / <android emulator> / <ios simulator>
```

Default backend is `memory`. Demo accounts (seeded):

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@canteen.app` | `admin123` |
| Student | `student@canteen.app` | `student123` |

Or register a new student from the login screen. The login screen has
one-tap "Fill demo" buttons.

### Build web (static)

```bash
flutter build web --dart-define=BACKEND=memory
# output in build/web/ — serve with any static server
```

---

## Run against Firebase (production backend)

1. Install tooling: `npm i -g firebase-tools` and `dart pub global activate flutterfire_cli`.
2. Create a Firebase project; enable **Authentication → Email/Password** and **Firestore**.
3. Generate config: `flutterfire configure` (overwrites `lib/firebase_options.dart`).
4. Deploy rules, indexes, functions:
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,functions
   ```
5. Seed data + create the default admin (one-time): set a secret and call the
   `bootstrap` callable.
   ```bash
   firebase functions:secrets:set SETUP_SECRET   # or set env SETUP_SECRET
   # then call the `bootstrap` callable with { setupSecret, email, password }
   # e.g. from the Firebase console, a small script, or the emulator UI.
   ```
6. Run the app against Firebase:
   ```bash
   flutter run -d chrome --dart-define=BACKEND=firebase
   ```

### Local emulators

```bash
cd functions && npm install && npm run build
firebase emulators:start --only auth,firestore,functions
```

---

## Pricing (admin-editable, defaults from spec)

| Item | Default |
|------|---------|
| Breakfast / Lunch / Dinner | ₹50 each |
| Extra roti | ₹5 each |
| Extra sabji | ₹20 each |
| Packing | ₹15 per meal |
| Tea/Coffee | ₹10 |
| Snack | ₹20 |

All prices live in `config/pricing` and are editable from **Admin → Charges**.
The **same pricing formula** is implemented in `lib/domain/pricing/pricing_engine.dart`
(client) and `functions/src/pricing.ts` (authoritative server). Money is stored
as integer paise everywhere.

---

## Project layout

```
lib/
  core/            theme, money, router, shared widgets
  domain/          entities, pricing engine, repository interfaces
  data/            memory backend (demo/tests) + firebase backend (prod)
  features/        auth, menu, booking, snacks, coupons, cart, payment, orders, admin
functions/         Cloud Functions (TypeScript): authoritative pricing, admin bootstrap
firestore.rules    security rules
test/              unit + widget tests
```

## Test & analyze

```bash
flutter test
flutter analyze
```

## Payment integration (later)

Payments go through the `PaymentGateway` interface
(`lib/features/payment/payment_gateway.dart`). `StubPaymentGateway` simulates
success today. To integrate Razorpay/Stripe, implement the same interface and
swap it in `paymentGatewayProvider` — no UI changes needed.

## Platform notes

- **Web**: works out of the box after `flutter pub get`.
- **Android**: needs Android Studio / Android SDK to build & run.
- **iOS**: needs Xcode (macOS) to build & run.
