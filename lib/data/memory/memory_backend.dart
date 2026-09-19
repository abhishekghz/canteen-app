import 'dart:async';
import 'dart:math';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/coupon.dart';
import '../../domain/entities/menu_day.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/pricing.dart';
import '../../domain/entities/snack_slot.dart';
import '../../domain/pricing/pricing_engine.dart';
import '../../domain/repositories/repositories.dart';
import 'seed.dart';

/// A broadcast stream that re-emits the latest value to new subscribers.
class _State<T> {
  T _value;
  final _controller = StreamController<T>.broadcast();
  _State(this._value);

  T get value => _value;

  set value(T v) {
    _value = v;
    _controller.add(v);
  }

  Stream<T> get stream async* {
    yield _value;
    yield* _controller.stream;
  }
}

/// Holds all in-memory app state, shared across the repository implementations.
class MemoryBackend {
  final _State<Pricing> pricing = _State(Pricing.seedDefaults());
  final _State<List<MenuDay>> week = _State(seedWeek());
  final _State<List<SnackSlot>> slots = _State(seedSnackSlots());
  final _State<List<Order>> orders = _State(<Order>[]);
  final _State<List<Coupon>> coupons = _State(<Coupon>[]);

  /// email -> (password, user)
  final Map<String, ({String password, AppUser user})> _accounts = {};
  final _State<AppUser?> _authUser = _State<AppUser?>(null);
  final _rng = Random();
  int _seq = 0;

  MemoryBackend() {
    for (final acc in seedAccounts()) {
      _accounts[acc.user.email.toLowerCase()] =
          (password: acc.password, user: acc.user);
    }
    _seedDemoOrders();
  }

  /// A couple of sample orders for the demo student so the order history and
  /// the admin orders/payments screen have data to show out of the box.
  void _seedDemoOrders() {
    final engine = this.engine;
    final today = DateTime.now();
    String d(int addDays) {
      final x = today.add(Duration(days: addDays));
      return '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    }

    final line1 = MealLine(
      mealType: MealType.lunch,
      date: d(0),
      extraRoti: 2,
      extraSabji: 1,
      packed: true,
      lineTotal: engine.mealLineTotal(
          type: MealType.lunch, extraRoti: 2, extraSabji: 1, packed: true),
    );
    final line2 = SnackLine(
      slotId: 'evening',
      date: d(0),
      teaCoffeeQty: 1,
      snackQty: 1,
      lineTotal: engine.snackLineTotal(teaCoffeeQty: 1, snackQty: 1),
    );
    final line3 = MealLine(
      mealType: MealType.dinner,
      date: d(1),
      lineTotal: engine.mealLineTotal(type: MealType.dinner),
    );

    orders.value = [
      Order(
        id: 'demo-o2',
        uid: 'student-seed',
        createdAt: today.subtract(const Duration(hours: 2)),
        lines: [line3],
        total: engine.orderTotal([line3]),
        paymentStatus: PaymentStatus.unpaid,
      ),
      Order(
        id: 'demo-o1',
        uid: 'student-seed',
        createdAt: today.subtract(const Duration(days: 1)),
        lines: [line1, line2],
        total: engine.orderTotal([line1, line2]),
        paymentStatus: PaymentStatus.paid,
      ),
    ];
  }

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  String _couponCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  PricingEngine get engine => PricingEngine(pricing.value);
}

class MemoryAuthRepository implements AuthRepository {
  final MemoryBackend b;
  MemoryAuthRepository(this.b);

  @override
  Stream<AppUser?> authState() => b._authUser.stream;

  @override
  AppUser? get currentUser => b._authUser.value;

  @override
  Future<AppUser> signIn(String email, String password) async {
    final acc = b._accounts[email.trim().toLowerCase()];
    if (acc == null || acc.password != password) {
      throw AuthException('Invalid email or password.');
    }
    b._authUser.value = acc.user;
    return acc.user;
  }

  @override
  Future<AppUser> register(String name, String email, String password) async {
    final key = email.trim().toLowerCase();
    if (b._accounts.containsKey(key)) {
      throw AuthException('An account with this email already exists.');
    }
    if (password.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }
    final user = AppUser(
      uid: b._id('u'),
      name: name.trim(),
      email: email.trim(),
      role: UserRole.student,
    );
    b._accounts[key] = (password: password, user: user);
    b._authUser.value = user;
    return user;
  }

  @override
  Future<void> signOut() async => b._authUser.value = null;
}

class MemoryMenuRepository implements MenuRepository {
  final MemoryBackend b;
  MemoryMenuRepository(this.b);

  @override
  Stream<List<MenuDay>> watchWeek() => b.week.stream;

  @override
  Future<void> saveDay(MenuDay day) async {
    final list = [...b.week.value];
    final i = list.indexWhere((d) => d.weekday == day.weekday);
    if (i >= 0) {
      list[i] = day;
    } else {
      list.add(day);
    }
    b.week.value = list;
  }
}

class MemoryPricingRepository implements PricingRepository {
  final MemoryBackend b;
  MemoryPricingRepository(this.b);

  @override
  Stream<Pricing> watch() => b.pricing.stream;

  @override
  Future<void> save(Pricing pricing) async => b.pricing.value = pricing;
}

class MemoryOrderRepository implements OrderRepository {
  final MemoryBackend b;
  MemoryOrderRepository(this.b);

  @override
  Future<Order> place(Order draft) async {
    // Recompute totals authoritatively from the pricing engine.
    final engine = b.engine;
    final lines = draft.lines.map((l) {
      final total = engine.lineTotal(l);
      return switch (l) {
        MealLine m => MealLine(
            mealType: m.mealType,
            date: m.date,
            extraRoti: m.extraRoti,
            extraSabji: m.extraSabji,
            packed: m.packed,
            lineTotal: total,
          ),
        SnackLine s => SnackLine(
            slotId: s.slotId,
            date: s.date,
            teaCoffeeQty: s.teaCoffeeQty,
            snackQty: s.snackQty,
            earlyBooking: s.earlyBooking,
            lineTotal: total,
          ),
      };
    }).toList();

    final order = Order(
      id: b._id('o'),
      uid: draft.uid,
      createdAt: DateTime.now(),
      lines: lines,
      total: engine.orderTotal(lines),
      status: OrderStatus.confirmed,
      paymentStatus: draft.paymentStatus,
    );
    b.orders.value = [order, ...b.orders.value];
    return order;
  }

  @override
  Stream<List<Order>> watchForUser(String uid) =>
      b.orders.stream.map((all) => all.where((o) => o.uid == uid).toList());

  @override
  Stream<List<Order>> watchAll() => b.orders.stream;

  @override
  Future<void> setPaymentStatus(String orderId, PaymentStatus status) async {
    b.orders.value = b.orders.value
        .map((o) => o.id == orderId ? o.copyWith(paymentStatus: status) : o)
        .toList();
  }
}

class MemoryCouponRepository implements CouponRepository {
  final MemoryBackend b;
  MemoryCouponRepository(this.b);

  @override
  Future<List<Coupon>> buy(String uid, MealType mealType, int qty) async {
    final now = DateTime.now();
    final created = List.generate(
      qty,
      (_) => Coupon(
        id: b._id('c'),
        uid: uid,
        mealType: mealType,
        code: b._couponCode(),
        status: CouponStatus.active,
        purchasedAt: now,
        expiresAt: now.add(const Duration(days: 30)),
      ),
    );
    b.coupons.value = [...created, ...b.coupons.value];
    return created;
  }

  @override
  Stream<List<Coupon>> watchForUser(String uid) =>
      b.coupons.stream.map((all) => all.where((c) => c.uid == uid).toList());

  @override
  Future<void> redeem(String couponId, {String? orderId}) async {
    b.coupons.value = b.coupons.value
        .map((c) => c.id == couponId
            ? c.copyWith(
                status: CouponStatus.redeemed, redeemedOrderId: orderId)
            : c)
        .toList();
  }
}

class MemorySnackRepository implements SnackRepository {
  final MemoryBackend b;
  MemorySnackRepository(this.b);

  @override
  Stream<List<SnackSlot>> watchSlots() => b.slots.stream;

  @override
  Future<void> saveSlots(List<SnackSlot> slots) async => b.slots.value = slots;
}
