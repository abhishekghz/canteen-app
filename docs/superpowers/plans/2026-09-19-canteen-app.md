# Canteen App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a student canteen booking app for Android, iOS, and Web from one Flutter codebase, backed by Firebase, with meal/snack/coupon booking, chargeable extras, a weekly menu, a stubbed payment step, and a default admin who manages menu/charges/payment status.

**Architecture:** Flutter client with a layered domain/data split and the repository pattern, so the app runs against an in-memory backend for demo/tests and against Firebase in production behind identical interfaces. Pricing is a pure, unit-tested engine reused on client and in a Cloud Function.

**Tech Stack:** Flutter, Dart, Riverpod (state/DI), go_router (routing), Firebase (Auth, Firestore, Cloud Functions in TypeScript), `intl` for ₹ formatting.

## Global Constraints

- Currency is **INR (₹)**; store money as **integer paise** internally, format for display only.
- Seeded default prices: breakfast 50, lunch 50, dinner 50, extra roti 5, extra sabji 20, packing 15, tea/coffee 10, snack 20 (all ₹). All are **admin-editable** via `config/pricing`.
- Two roles only: `student` (self-register) and `admin` (seeded default, login only). Admin power is granted by a Firebase Auth custom claim `admin:true`.
- Backend is selected at runtime by `--dart-define=BACKEND=memory|firebase` (default `memory`).
- Pricing logic exists in exactly one place (`PricingEngine`); never duplicate the formula.
- Payment is stubbed behind a `PaymentGateway` interface; no real gateway wired now.

---

### Task 1: Project scaffold + theme + money util

**Files:**
- Create: `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`, `lib/core/theme/app_theme.dart`, `lib/core/money.dart`
- Test: `test/money_test.dart`

**Interfaces:**
- Produces: `formatRupees(int paise) -> String` (e.g. `5000 -> "₹50"`, `550 -> "₹5.50"`); `CanteenApp` root widget.

- [ ] **Step 1: Write failing test** for `formatRupees`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/core/money.dart';
void main() {
  test('formats whole rupees', () => expect(formatRupees(5000), '₹50'));
  test('formats paise', () => expect(formatRupees(550), '₹5.50'));
  test('formats zero', () => expect(formatRupees(0), '₹0'));
}
```
- [ ] **Step 2: Run** `flutter test test/money_test.dart` — expect FAIL (undefined).
- [ ] **Step 3: Implement** `formatRupees` (divide by 100; drop `.00`).
- [ ] **Step 4: Run** test — expect PASS.
- [ ] **Step 5: Commit** `feat: scaffold app, theme, money formatting`.

---

### Task 2: Domain entities

**Files:**
- Create: `lib/domain/entities/{app_user.dart,pricing.dart,menu_day.dart,order.dart,coupon.dart,snack_slot.dart}`
- Test: `test/entities_test.dart`

**Interfaces:**
- Produces:
  - `enum UserRole { student, admin }`; `AppUser{uid,name,email,role}`
  - `Pricing{breakfast,lunch,dinner,roti,sabji,packing,teaCoffee,snack,earlyBookingDiscount}` (all `int` paise) with `copyWith`
  - `enum MealType { breakfast, lunch, dinner }`
  - `MenuDay{weekday,breakfast:List<String>,lunch:List<String>,dinner:List<String>}`
  - `OrderLine` sealed: `MealLine{mealType,date,extraRoti,extraSabji,packed,lineTotal}`, `SnackLine{slotId,date,teaCoffeeQty,snackQty,earlyBooking,lineTotal}`
  - `enum OrderStatus{pending,confirmed}`, `enum PaymentStatus{unpaid,paid,refunded}`
  - `Order{id,uid,createdAt,lines:List<OrderLine>,total,status,paymentStatus}`
  - `enum CouponStatus{active,redeemed,expired}`; `Coupon{id,uid,mealType,code,status,purchasedAt,expiresAt}`
  - `SnackSlot{id,label,time}`

- [ ] **Step 1: Write test** constructing each entity + `Pricing.copyWith(lunch: 6000)` keeps others.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** entities (immutable, `const` ctors, equality where useful).
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `feat: domain entities`.

---

### Task 3: Pricing engine (TDD core)

**Files:**
- Create: `lib/domain/pricing/pricing_engine.dart`
- Test: `test/pricing_engine_test.dart`

**Interfaces:**
- Consumes: `Pricing`, `MealLine`, `SnackLine` from Task 2.
- Produces: `class PricingEngine { int mealLineTotal({required MealType type,int extraRoti=0,int extraSabji=0,bool packed=false}); int snackLineTotal({int teaCoffeeQty=0,int snackQty=0,bool earlyBooking=false}); int orderTotal(List<OrderLine> lines); }` — constructed with a `Pricing`.

- [ ] **Step 1: Write failing tests:**
```dart
final p = Pricing.seedDefaults(); // 5000/5000/5000/500/2000/1500/1000/2000/0
final e = PricingEngine(p);
test('plain lunch', () => expect(e.mealLineTotal(type: MealType.lunch), 5000));
test('lunch +2 roti +1 sabji packed', () =>
  expect(e.mealLineTotal(type: MealType.lunch, extraRoti:2, extraSabji:1, packed:true),
         5000 + 2*500 + 2000 + 1500)); // 9500
test('snack 1 tea 1 snack', () =>
  expect(e.snackLineTotal(teaCoffeeQty:1, snackQty:1), 1000+2000));
test('early discount clamps at 0', () {
  final e2 = PricingEngine(p.copyWith(earlyBookingDiscount: 99999));
  expect(e2.snackLineTotal(teaCoffeeQty:1, earlyBooking:true), 0);
});
```
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** the two formulas from ARCHITECTURE §2.1; `orderTotal` sums `lineTotal`.
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `feat: pricing engine with tests`.

---

### Task 4: Repository interfaces + in-memory implementation + seed data

**Files:**
- Create: `lib/domain/repositories/{auth_repository.dart,menu_repository.dart,pricing_repository.dart,order_repository.dart,coupon_repository.dart,snack_repository.dart}`
- Create: `lib/data/memory/memory_backend.dart` (holds shared state + all in-memory repo impls), `lib/data/memory/seed.dart`
- Test: `test/memory_backend_test.dart`

**Interfaces:**
- Produces (abstract, all `Future`/`Stream`-based):
  - `AuthRepository`: `Stream<AppUser?> authState()`, `signIn(email,pw)`, `register(name,email,pw)`, `signOut()`, `currentUser`
  - `MenuRepository`: `Stream<List<MenuDay>> watchWeek()`, `saveDay(MenuDay)`
  - `PricingRepository`: `Stream<Pricing> watch()`, `save(Pricing)`
  - `OrderRepository`: `Future<Order> place(Order draft)`, `Stream<List<Order>> watchForUser(uid)`, `Stream<List<Order>> watchAll()`, `setPaymentStatus(orderId,PaymentStatus)`
  - `CouponRepository`: `Future<List<Coupon>> buy(uid,mealType,qty)`, `Stream<List<Coupon>> watchForUser(uid)`
  - `SnackRepository`: `Stream<List<SnackSlot>> watchSlots()`, `saveSlots(List<SnackSlot>)`
- Seed: default admin `admin@canteen.app`/`admin123`, seeded pricing, 7 menu days, 2 snack slots.

- [ ] **Step 1: Write test:** register a student then sign in; place an order and read it back via `watchForUser`; admin present in seed.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** in-memory backend (StreamControllers/BehaviorSubjects) + seed.
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `feat: repository interfaces + in-memory backend + seed`.

---

### Task 5: Riverpod wiring + router with role guard

**Files:**
- Create: `lib/providers.dart`, `lib/core/router/app_router.dart`
- Modify: `lib/main.dart`, `lib/app.dart`

**Interfaces:**
- Consumes: repositories (Task 4), `authState()`.
- Produces: providers `authRepositoryProvider`, `menuRepositoryProvider`, … `pricingProvider` (stream), `authStateProvider`; `appRouterProvider` redirecting unauthenticated→`/login`, admin→`/admin`, student→`/home`.

- [ ] **Step 1:** Write a widget test: unauthenticated app shows Login; after seeded admin sign-in, shows Admin Dashboard.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3:** Implement providers + go_router redirect using `authStateProvider`.
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `feat: DI + routing with role guard`.

---

### Task 6: Auth UI (login / register)

**Files:** Create `lib/features/auth/{login_screen.dart,register_screen.dart,auth_controller.dart}`. Test `test/auth_flow_test.dart`.

- [ ] **Step 1:** Widget test — invalid login shows error; valid student register lands on Home.
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3:** Build forms (email/password validation), call `AuthController`.
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `feat: auth screens`.

---

### Task 7: Weekly menu (view)

**Files:** Create `lib/features/menu/{menu_screen.dart,menu_controller.dart}`. Test `test/menu_view_test.dart`.

- [ ] **Step 1:** Widget test — seeded week renders 7 days with meal items.
- [ ] **Step 2: Run** — FAIL. **Step 3:** Build day cards from `watchWeek()`. **Step 4:** PASS.
- [ ] **Step 5: Commit** `feat: weekly menu view`.

---

### Task 8: Cart (state + live total)

**Files:** Create `lib/features/cart/{cart_controller.dart,cart_screen.dart}`. Test `test/cart_test.dart`.

**Interfaces:** Produces `CartController` (Riverpod `Notifier`) holding `List<OrderLine>`; `addMeal(...)`, `addSnack(...)`, `remove(i)`, `clear()`, `int total` (via `PricingEngine`).

- [ ] **Step 1:** Test — add a packed lunch +1 roti then a snack; `total` equals engine sum; remove updates total.
- [ ] **Step 2:** FAIL. **Step 3:** Implement using current `Pricing`. **Step 4:** PASS.
- [ ] **Step 5: Commit** `feat: cart with live totals`.

---

### Task 9: Meal booking UI (extras + packing)

**Files:** Create `lib/features/booking/booking_screen.dart`. Test `test/booking_screen_test.dart`.

- [ ] **Step 1:** Widget test — select Lunch, set roti=2, toggle packing, tap Add → cart total matches engine.
- [ ] **Step 2:** FAIL. **Step 3:** Build meal-type chips, date picker, steppers for roti/sabji, packing switch, live line preview. **Step 4:** PASS.
- [ ] **Step 5: Commit** `feat: meal booking screen`.

---

### Task 10: Snacks booking UI (slots + timing + items)

**Files:** Create `lib/features/snacks/snacks_screen.dart`. Test `test/snacks_screen_test.dart`.

- [ ] **Step 1:** Widget test — pick Evening slot, Early booking + future date, tea=1 snack=1 → cart line correct.
- [ ] **Step 2:** FAIL. **Step 3:** Slot selector (from `watchSlots`), timing toggle (Book now / Early), item steppers. **Step 4:** PASS.
- [ ] **Step 5: Commit** `feat: snacks booking screen`.

---

### Task 11: Coupons (buy + list + redeem)

**Files:** Create `lib/features/coupons/{coupons_screen.dart,coupon_controller.dart}`. Test `test/coupons_test.dart`.

- [ ] **Step 1:** Test — buy 3 lunch coupons → 3 active coupons for user; redeem one flips to `redeemed`.
- [ ] **Step 2:** FAIL. **Step 3:** Buy form (meal type + qty, priced via engine), list with status chips, redeem action. **Step 4:** PASS.
- [ ] **Step 5: Commit** `feat: coupons`.

---

### Task 12: Payment (stub) + checkout

**Files:** Create `lib/features/payment/{payment_gateway.dart,stub_payment_gateway.dart,payment_screen.dart}`. Test `test/checkout_test.dart`.

**Interfaces:** `abstract PaymentGateway { Future<PaymentResult> pay({required int amountPaise, required String orderId}); }`; `PaymentResult{success,reference}`.

- [ ] **Step 1:** Test — checkout a non-empty cart → order placed with `paymentStatus:paid` (stub success), cart cleared.
- [ ] **Step 2:** FAIL. **Step 3:** Payment screen shows total, "Pay" calls gateway then `OrderRepository.place`. **Step 4:** PASS.
- [ ] **Step 5: Commit** `feat: checkout + stub payment`.

---

### Task 13: Order history + status

**Files:** Create `lib/features/orders/orders_screen.dart`. Test `test/orders_view_test.dart`.

- [ ] **Step 1:** Test — placed order appears with total + payment status.
- [ ] **Step 2:** FAIL. **Step 3:** List from `watchForUser`, expandable line details. **Step 4:** PASS.
- [ ] **Step 5: Commit** `feat: order history`.

---

### Task 14: Student home shell (tabs)

**Files:** Create `lib/features/home/home_shell.dart`. Wire bottom nav: Menu / Book / Snacks / Coupons / Orders + profile/sign-out.

- [ ] **Step 1:** Widget test — tabs switch screens; sign-out returns to Login.
- [ ] **Step 2:** FAIL. **Step 3:** Build shell. **Step 4:** PASS. **Step 5: Commit** `feat: student home shell`.

---

### Task 15: Admin — charges editor

**Files:** Create `lib/features/admin/charges_editor_screen.dart`. Test `test/admin_charges_test.dart`.

- [ ] **Step 1:** Test — change lunch to ₹60 and save → `pricingProvider` emits 6000; a new cart lunch costs 6000.
- [ ] **Step 2:** FAIL. **Step 3:** Form bound to `Pricing`, saves via `PricingRepository`. **Step 4:** PASS.
- [ ] **Step 5: Commit** `feat: admin charges editor`.

---

### Task 16: Admin — weekly menu editor

**Files:** Create `lib/features/admin/menu_editor_screen.dart`. Test `test/admin_menu_test.dart`.

- [ ] **Step 1:** Test — edit Monday lunch items and save → student menu view reflects change.
- [ ] **Step 2:** FAIL. **Step 3:** Per-day editable item lists, save via `MenuRepository`. **Step 4:** PASS.
- [ ] **Step 5: Commit** `feat: admin menu editor`.

---

### Task 17: Admin — orders & payment-status manager + snack slots + dashboard

**Files:** Create `lib/features/admin/{admin_dashboard.dart,orders_admin_screen.dart,snack_slots_screen.dart}`. Test `test/admin_orders_test.dart`.

- [ ] **Step 1:** Test — admin sees all orders; set an order to `paid` → student sees `paid`.
- [ ] **Step 2:** FAIL. **Step 3:** Orders list (all users) with status dropdown via `setPaymentStatus`; snack-slot CRUD; dashboard links. **Step 4:** PASS.
- [ ] **Step 5: Commit** `feat: admin orders/payment + snack slots + dashboard`.

---

### Task 18: Firebase data layer

**Files:** Create `lib/data/firebase/*` (impls of every repository), `lib/data/dto/*` (mappers), `lib/firebase_options.dart` (via FlutterFire CLI). Modify `lib/main.dart` to select backend on `BACKEND=firebase`.

- [ ] **Step 1:** Implement Firestore-backed repositories mirroring in-memory behavior (collections per ARCHITECTURE §5).
- [ ] **Step 2:** Map Auth user + custom claim → `AppUser.role`.
- [ ] **Step 3:** Manual smoke test against a Firebase project (or emulator).
- [ ] **Step 4: Commit** `feat: firebase data layer`.

---

### Task 19: Cloud Functions + security rules + admin bootstrap

**Files:** Create `functions/src/index.ts` (placeOrder w/ authoritative pricing, setPaymentStatus admin-guard, buyCoupons, `setAdminClaim` callable + bootstrap), `firestore.rules`, `firebase.json`, `firestore.indexes.json`.

- [ ] **Step 1:** Port `PricingEngine` formula to TS; `placeOrder` recomputes totals server-side.
- [ ] **Step 2:** Rules per ARCHITECTURE §5.1 (admin claim gates `config/*`, `menu/*`, payment-status).
- [ ] **Step 3:** Bootstrap seeds default admin + sets claim + seeds pricing/menu/slots.
- [ ] **Step 4:** Emulator test of rules (student can't write pricing; admin can).
- [ ] **Step 5: Commit** `feat: cloud functions + security rules + admin bootstrap`.

---

### Task 20: Platform builds + run docs

**Files:** Create `README.md` (run instructions), ensure `web/` builds; document Android/iOS build prerequisites.

- [ ] **Step 1:** `flutter run -d chrome --dart-define=BACKEND=memory` works (demo).
- [ ] **Step 2:** `flutter analyze` clean; `flutter test` green.
- [ ] **Step 3:** Document `flutterfire configure`, emulator, and Android/iOS (needs Android Studio / Xcode) steps.
- [ ] **Step 4: Commit** `docs: run + build instructions`.

---

## Self-Review Notes

- **Spec coverage:** register/login (T6), B/L/D (T9), book meals (T9,T12), payment page later (T12 stub), coupons (T11), extra roti/sabji chargeable (T3,T9), weekly menu (T7,T16), two snack times + book-now/early (T10), packing ₹15 (T3,T9), all fixed charges (T2 seed, T3), admin default login + edit menu/payment/charges (T5,T15,T16,T17), two login types (T5). ✔ All mapped.
- **Type consistency:** `PricingEngine`, `Pricing` (paise ints), `OrderLine` (`MealLine`/`SnackLine`), repository method names are used identically across tasks.
- **Money:** integer paise everywhere; `formatRupees` only at display.
