import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../domain/entities/menu_day.dart';
import '../../domain/entities/order.dart';
import 'cart_controller.dart';

String describeLine(OrderLine line) => switch (line) {
      MealLine l => [
          l.mealType.label,
          if (l.extraRoti > 0) '+${l.extraRoti} roti',
          if (l.extraSabji > 0) '+${l.extraSabji} sabji',
          if (l.packed) 'packed',
        ].join(' · '),
      SnackLine l => [
          'Snacks (${l.slotId})',
          if (l.teaCoffeeQty > 0) '${l.teaCoffeeQty} tea/coffee',
          if (l.snackQty > 0) '${l.snackQty} snack',
          if (l.earlyBooking) 'early',
        ].join(' · '),
    };

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: lines.isEmpty
          ? const Center(child: Text('Your cart is empty.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: lines.length,
              itemBuilder: (context, i) {
                final l = lines[i];
                return Card(
                  child: ListTile(
                    title: Text(describeLine(l)),
                    subtitle: Text('For ${l.date}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatRupees(l.lineTotal)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              ref.read(cartProvider.notifier).removeAt(i),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: lines.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(formatRupees(total),
                            style: Theme.of(context).textTheme.headlineSmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.push('/payment'),
                      icon: const Icon(Icons.payment),
                      label: const Text('Proceed to payment'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
