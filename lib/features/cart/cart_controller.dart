import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/menu_day.dart';
import '../../domain/entities/order.dart';
import '../../providers.dart';

/// Holds the current cart lines. Totals are computed via the pricing engine.
class CartController extends Notifier<List<OrderLine>> {
  @override
  List<OrderLine> build() => const [];

  void addMeal({
    required MealType type,
    required String date,
    int extraRoti = 0,
    int extraSabji = 0,
    bool packed = false,
  }) {
    final engine = ref.read(pricingEngineProvider);
    final total = engine.mealLineTotal(
      type: type,
      extraRoti: extraRoti,
      extraSabji: extraSabji,
      packed: packed,
    );
    state = [
      ...state,
      MealLine(
        mealType: type,
        date: date,
        extraRoti: extraRoti,
        extraSabji: extraSabji,
        packed: packed,
        lineTotal: total,
      ),
    ];
  }

  void addSnack({
    required String slotId,
    required String date,
    int teaCoffeeQty = 0,
    int snackQty = 0,
    bool earlyBooking = false,
  }) {
    final engine = ref.read(pricingEngineProvider);
    final total = engine.snackLineTotal(
      teaCoffeeQty: teaCoffeeQty,
      snackQty: snackQty,
      earlyBooking: earlyBooking,
    );
    state = [
      ...state,
      SnackLine(
        slotId: slotId,
        date: date,
        teaCoffeeQty: teaCoffeeQty,
        snackQty: snackQty,
        earlyBooking: earlyBooking,
        lineTotal: total,
      ),
    ];
  }

  void removeAt(int index) {
    final next = [...state]..removeAt(index);
    state = next;
  }

  void clear() => state = const [];

  int get total => ref.read(pricingEngineProvider).orderTotal(state);
}

final cartProvider =
    NotifierProvider<CartController, List<OrderLine>>(CartController.new);

/// Live cart total (recomputes when cart or pricing changes).
final cartTotalProvider = Provider<int>((ref) {
  final lines = ref.watch(cartProvider);
  return ref.watch(pricingEngineProvider).orderTotal(lines);
});
