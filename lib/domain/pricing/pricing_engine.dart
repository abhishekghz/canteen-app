import '../entities/menu_day.dart';
import '../entities/order.dart';
import '../entities/pricing.dart';

/// The single source of truth for computing prices. Pure + unit-tested.
/// The same formulas are mirrored in the Cloud Function for authoritative totals.
class PricingEngine {
  final Pricing pricing;
  const PricingEngine(this.pricing);

  int basePrice(MealType type) => switch (type) {
        MealType.breakfast => pricing.breakfast,
        MealType.lunch => pricing.lunch,
        MealType.dinner => pricing.dinner,
      };

  /// mealTotal = base + roti*qty + sabji*qty + (packed ? packing : 0)
  int mealLineTotal({
    required MealType type,
    int extraRoti = 0,
    int extraSabji = 0,
    bool packed = false,
  }) {
    return basePrice(type) +
        (extraRoti * pricing.roti) +
        (extraSabji * pricing.sabji) +
        (packed ? pricing.packing : 0);
  }

  /// snackTotal = tea*qty + snack*qty - (early ? discount : 0), clamped >= 0
  int snackLineTotal({
    int teaCoffeeQty = 0,
    int snackQty = 0,
    bool earlyBooking = false,
  }) {
    final gross =
        (teaCoffeeQty * pricing.teaCoffee) + (snackQty * pricing.snack);
    final net = gross - (earlyBooking ? pricing.earlyBookingDiscount : 0);
    return net < 0 ? 0 : net;
  }

  /// Recomputes a line's authoritative total (used when placing orders).
  int lineTotal(OrderLine line) => switch (line) {
        MealLine l => mealLineTotal(
            type: l.mealType,
            extraRoti: l.extraRoti,
            extraSabji: l.extraSabji,
            packed: l.packed,
          ),
        SnackLine l => snackLineTotal(
            teaCoffeeQty: l.teaCoffeeQty,
            snackQty: l.snackQty,
            earlyBooking: l.earlyBooking,
          ),
      };

  int orderTotal(List<OrderLine> lines) =>
      lines.fold(0, (sum, l) => sum + l.lineTotal);

  /// Price of buying [qty] coupons for [type].
  int couponBundleTotal(MealType type, int qty) => basePrice(type) * qty;
}
