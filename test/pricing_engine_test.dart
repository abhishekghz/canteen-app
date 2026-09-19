import 'package:canteen_app/domain/entities/menu_day.dart';
import 'package:canteen_app/domain/entities/order.dart';
import 'package:canteen_app/domain/entities/pricing.dart';
import 'package:canteen_app/domain/pricing/pricing_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final p = Pricing.seedDefaults(); // 5000/5000/5000/500/2000/1500/1000/2000/0
  final e = PricingEngine(p);

  test('plain lunch', () => expect(e.mealLineTotal(type: MealType.lunch), 5000));

  test('lunch +2 roti +1 sabji packed', () {
    expect(
      e.mealLineTotal(
          type: MealType.lunch, extraRoti: 2, extraSabji: 1, packed: true),
      5000 + 2 * 500 + 2000 + 1500, // 9500
    );
  });

  test('breakfast base', () => expect(e.basePrice(MealType.breakfast), 5000));

  test('snack: 1 tea + 1 snack',
      () => expect(e.snackLineTotal(teaCoffeeQty: 1, snackQty: 1), 1000 + 2000));

  test('early-booking discount applies', () {
    final e2 = PricingEngine(p.copyWith(earlyBookingDiscount: 500));
    expect(e2.snackLineTotal(teaCoffeeQty: 1, earlyBooking: true), 500);
  });

  test('early-booking discount clamps at 0', () {
    final e2 = PricingEngine(p.copyWith(earlyBookingDiscount: 99999));
    expect(e2.snackLineTotal(teaCoffeeQty: 1, earlyBooking: true), 0);
  });

  test('order total sums line totals', () {
    final lines = <OrderLine>[
      const MealLine(mealType: MealType.lunch, date: '2026-01-01', lineTotal: 5000),
      const SnackLine(slotId: 'morning', date: '2026-01-01', lineTotal: 1000),
    ];
    expect(e.orderTotal(lines), 6000);
  });

  test('coupon bundle total', () {
    expect(e.couponBundleTotal(MealType.dinner, 3), 15000);
  });

  test('copyWith keeps other fields', () {
    final updated = p.copyWith(lunch: 6000);
    expect(updated.lunch, 6000);
    expect(updated.breakfast, 5000);
    expect(updated.roti, 500);
  });
}
