import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/backend.dart';
import 'domain/entities/app_user.dart';
import 'domain/entities/menu_day.dart';
import 'domain/entities/pricing.dart';
import 'domain/entities/snack_slot.dart';
import 'domain/pricing/pricing_engine.dart';
import 'domain/repositories/repositories.dart';

/// Overridden in main() with the chosen backend (memory or firebase).
final repositoriesProvider = Provider<AppRepositories>(
  (ref) => throw UnimplementedError('repositoriesProvider must be overridden'),
);

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => ref.watch(repositoriesProvider).auth);
final menuRepositoryProvider =
    Provider<MenuRepository>((ref) => ref.watch(repositoriesProvider).menu);
final pricingRepositoryProvider = Provider<PricingRepository>(
    (ref) => ref.watch(repositoriesProvider).pricing);
final orderRepositoryProvider =
    Provider<OrderRepository>((ref) => ref.watch(repositoriesProvider).orders);
final couponRepositoryProvider = Provider<CouponRepository>(
    (ref) => ref.watch(repositoriesProvider).coupons);
final snackRepositoryProvider =
    Provider<SnackRepository>((ref) => ref.watch(repositoriesProvider).snacks);

/// Current authenticated user (null when signed out).
final authStateProvider = StreamProvider<AppUser?>(
    (ref) => ref.watch(authRepositoryProvider).authState());

/// Live pricing config.
final pricingProvider = StreamProvider<Pricing>(
    (ref) => ref.watch(pricingRepositoryProvider).watch());

/// Pricing engine built from the latest pricing (falls back to seed defaults).
final pricingEngineProvider = Provider<PricingEngine>((ref) {
  final pricing =
      ref.watch(pricingProvider).valueOrNull ?? Pricing.seedDefaults();
  return PricingEngine(pricing);
});

/// Weekly menu.
final weekProvider = StreamProvider<List<MenuDay>>(
    (ref) => ref.watch(menuRepositoryProvider).watchWeek());

/// Snack slots.
final snackSlotsProvider = StreamProvider<List<SnackSlot>>(
    (ref) => ref.watch(snackRepositoryProvider).watchSlots());
