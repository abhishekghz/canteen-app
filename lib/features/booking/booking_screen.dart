import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/widgets/qty_stepper.dart';
import '../../domain/entities/menu_day.dart';
import '../../providers.dart';
import '../cart/cart_controller.dart';

String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});
  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  MealType _type = MealType.breakfast;
  DateTime _date = DateTime.now();
  int _roti = 0;
  int _sabji = 0;
  bool _packed = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _addToCart() {
    ref.read(cartProvider.notifier).addMeal(
          type: _type,
          date: ymd(_date),
          extraRoti: _roti,
          extraSabji: _sabji,
          packed: _packed,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_type.label} added to cart')),
    );
    setState(() {
      _roti = 0;
      _sabji = 0;
      _packed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.watch(pricingEngineProvider);
    final pricing = engine.pricing;
    final lineTotal = engine.mealLineTotal(
      type: _type,
      extraRoti: _roti,
      extraSabji: _sabji,
      packed: _packed,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Choose meal', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final t in MealType.values)
              ChoiceChip(
                label: Text('${t.label} • ${formatRupees(engine.basePrice(t))}'),
                selected: _type == t,
                onSelected: (_) => setState(() => _type = t),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            subtitle: Text(ymd(_date)),
            trailing: TextButton(onPressed: _pickDate, child: const Text('Change')),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                QtyStepper(
                  label: 'Extra roti',
                  subtitle: '${formatRupees(pricing.roti)} each',
                  value: _roti,
                  onChanged: (v) => setState(() => _roti = v),
                ),
                const Divider(),
                QtyStepper(
                  label: 'Extra sabji',
                  subtitle: '${formatRupees(pricing.sabji)} each',
                  value: _sabji,
                  onChanged: (v) => setState(() => _sabji = v),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pack this meal'),
                  subtitle: Text('${formatRupees(pricing.packing)} packing charge'),
                  value: _packed,
                  onChanged: (v) => setState(() => _packed = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Line total', style: Theme.of(context).textTheme.titleMedium),
            Text(formatRupees(lineTotal),
                style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _addToCart,
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Add to cart'),
        ),
      ],
    );
  }
}
