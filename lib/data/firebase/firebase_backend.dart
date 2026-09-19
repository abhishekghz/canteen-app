import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/coupon.dart';
import '../../domain/entities/menu_day.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/pricing.dart';
import '../../domain/entities/snack_slot.dart';
import '../../domain/repositories/repositories.dart';
import '../../firebase_options.dart';
import '../backend.dart';

/// The default admin account. Signing in with this email grants admin
/// everywhere (web + APK), matched by the Firestore security rules too — no
/// per-user role edits needed.
const kDefaultAdminEmail = 'admin@canteen.app';

/// Initializes Firebase and returns Firestore/Auth-backed repositories.
Future<AppRepositories> buildFirebaseRepositories() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;
  final auth = fb.FirebaseAuth.instance;
  return AppRepositories(
    auth: FirebaseAuthRepository(auth, db),
    menu: FirebaseMenuRepository(db),
    pricing: FirebasePricingRepository(db),
    orders: FirebaseOrderRepository(db),
    coupons: FirebaseCouponRepository(db),
    snacks: FirebaseSnackRepository(db),
  );
}

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;
  AppUser? _cached;

  FirebaseAuthRepository(this._auth, this._db);

  @override
  AppUser? get currentUser => _cached;

  @override
  Stream<AppUser?> authState() async* {
    await for (final u in _auth.authStateChanges()) {
      if (u == null) {
        _cached = null;
        yield null;
      } else {
        _cached = await _toAppUser(u);
        yield _cached;
      }
    }
  }

  Future<AppUser> _toAppUser(fb.User u) async {
    final doc = await _db.collection('users').doc(u.uid).get();
    final data = doc.data();
    final email = u.email ?? '';
    final name = (data?['name'] as String?) ?? (email.isEmpty ? 'User' : email);
    // Admin is granted to the default admin email, or by a Firestore
    // `role: "admin"` field, or by a custom claim. (No Cloud Functions needed.)
    var isAdmin = email.toLowerCase() == kDefaultAdminEmail ||
        (data?['role'] as String?) == 'admin';
    if (!isAdmin) {
      try {
        final token = await u.getIdTokenResult(true);
        isAdmin = token.claims?['admin'] == true;
      } catch (_) {/* ignore */}
    }
    return AppUser(
      uid: u.uid,
      name: name,
      email: u.email ?? '',
      role: isAdmin ? UserRole.admin : UserRole.student,
    );
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return _cached = await _toAppUser(cred.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign in failed.');
    }
  }

  @override
  Future<AppUser> register(String name, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return _cached = await _toAppUser(cred.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Registration failed.');
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

class FirebaseMenuRepository implements MenuRepository {
  final FirebaseFirestore _db;
  FirebaseMenuRepository(this._db);

  @override
  Stream<List<MenuDay>> watchWeek() => _db.collection('menu').snapshots().map(
        (s) => s.docs.map((d) => MenuDay.fromMap(d.data())).toList()
          ..sort((a, b) =>
              kWeekdays.indexOf(a.weekday) - kWeekdays.indexOf(b.weekday)),
      );

  @override
  Future<void> saveDay(MenuDay day) =>
      _db.collection('menu').doc(day.weekday).set(day.toMap());
}

class FirebasePricingRepository implements PricingRepository {
  final FirebaseFirestore _db;
  FirebasePricingRepository(this._db);

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('config').doc('pricing');

  @override
  Stream<Pricing> watch() => _doc.snapshots().map(
      (s) => s.exists ? Pricing.fromMap(s.data()!) : Pricing.seedDefaults());

  @override
  Future<void> save(Pricing pricing) => _doc.set(pricing.toMap());
}

class FirebaseOrderRepository implements OrderRepository {
  final FirebaseFirestore _db;
  FirebaseOrderRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('orders');

  @override
  Future<Order> place(Order draft) async {
    // NOTE: in production the authoritative total is set by the `placeOrder`
    // Cloud Function. This client write is guarded by security rules.
    final ref = await _col.add(draft.toMap());
    final snap = await ref.get();
    return Order.fromMap(ref.id, snap.data()!);
  }

  @override
  Stream<List<Order>> watchForUser(String uid) => _col
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => Order.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  @override
  Stream<List<Order>> watchAll() => _col.snapshots().map((s) =>
      s.docs.map((d) => Order.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  @override
  Future<void> setPaymentStatus(String orderId, PaymentStatus status) =>
      _col.doc(orderId).update({'paymentStatus': status.name});
}

class FirebaseCouponRepository implements CouponRepository {
  final FirebaseFirestore _db;
  FirebaseCouponRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('coupons');

  @override
  Future<List<Coupon>> buy(String uid, MealType mealType, int qty) async {
    final now = DateTime.now();
    final batch = _db.batch();
    final created = <Coupon>[];
    for (var i = 0; i < qty; i++) {
      final ref = _col.doc();
      final coupon = Coupon(
        id: ref.id,
        uid: uid,
        mealType: mealType,
        code: ref.id.substring(0, 6).toUpperCase(),
        status: CouponStatus.active,
        purchasedAt: now,
        expiresAt: now.add(const Duration(days: 30)),
      );
      batch.set(ref, coupon.toMap());
      created.add(coupon);
    }
    await batch.commit();
    return created;
  }

  @override
  Stream<List<Coupon>> watchForUser(String uid) => _col
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => Coupon.fromMap(d.id, d.data())).toList());

  @override
  Future<void> redeem(String couponId, {String? orderId}) =>
      _col.doc(couponId).update({
        'status': CouponStatus.redeemed.name,
        'redeemedOrderId': orderId,
      });
}

class FirebaseSnackRepository implements SnackRepository {
  final FirebaseFirestore _db;
  FirebaseSnackRepository(this._db);

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('config').doc('snackSlots');

  @override
  Stream<List<SnackSlot>> watchSlots() => _doc.snapshots().map((s) {
        final list = (s.data()?['slots'] as List?) ?? const [];
        return list
            .map((e) => SnackSlot.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      });

  @override
  Future<void> saveSlots(List<SnackSlot> slots) =>
      _doc.set({'slots': slots.map((s) => s.toMap()).toList()});
}
