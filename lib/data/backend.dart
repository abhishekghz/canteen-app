import '../domain/repositories/repositories.dart';
import 'memory/memory_backend.dart';

/// A bundle of all repository implementations for a chosen backend.
class AppRepositories {
  final AuthRepository auth;
  final MenuRepository menu;
  final PricingRepository pricing;
  final OrderRepository orders;
  final CouponRepository coupons;
  final SnackRepository snacks;

  AppRepositories({
    required this.auth,
    required this.menu,
    required this.pricing,
    required this.orders,
    required this.coupons,
    required this.snacks,
  });

  /// In-memory backend: runs instantly with no Firebase configuration.
  factory AppRepositories.memory() {
    final b = MemoryBackend();
    return AppRepositories(
      auth: MemoryAuthRepository(b),
      menu: MemoryMenuRepository(b),
      pricing: MemoryPricingRepository(b),
      orders: MemoryOrderRepository(b),
      coupons: MemoryCouponRepository(b),
      snacks: MemorySnackRepository(b),
    );
  }
}
