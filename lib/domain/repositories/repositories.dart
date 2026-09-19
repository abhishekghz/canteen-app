import '../entities/app_user.dart';
import '../entities/coupon.dart';
import '../entities/menu_day.dart';
import '../entities/order.dart';
import '../entities/pricing.dart';
import '../entities/snack_slot.dart';

/// Thrown for expected auth failures (bad credentials, email in use, etc.).
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

abstract class AuthRepository {
  Stream<AppUser?> authState();
  AppUser? get currentUser;
  Future<AppUser> signIn(String email, String password);
  Future<AppUser> register(String name, String email, String password);
  Future<void> signOut();
}

abstract class MenuRepository {
  Stream<List<MenuDay>> watchWeek();
  Future<void> saveDay(MenuDay day);
}

abstract class PricingRepository {
  Stream<Pricing> watch();
  Future<void> save(Pricing pricing);
}

abstract class OrderRepository {
  Future<Order> place(Order draft);
  Stream<List<Order>> watchForUser(String uid);
  Stream<List<Order>> watchAll();
  Future<void> setPaymentStatus(String orderId, PaymentStatus status);
}

abstract class CouponRepository {
  Future<List<Coupon>> buy(String uid, MealType mealType, int qty);
  Stream<List<Coupon>> watchForUser(String uid);
  Future<void> redeem(String couponId, {String? orderId});
}

abstract class SnackRepository {
  Stream<List<SnackSlot>> watchSlots();
  Future<void> saveSlots(List<SnackSlot> slots);
}
