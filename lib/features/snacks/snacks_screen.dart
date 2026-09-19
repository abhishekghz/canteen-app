import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/widgets/qty_stepper.dart';
import '../../providers.dart';
import '../booking/booking_screen.dart' show ymd;
import '../cart/cart_controller.dart';

class SnacksScreen extends ConsumerStatefulWidget {
  const SnacksScreen({super.key});
  @override
  ConsumerState<SnacksScreen> createState() => _SnacksScreenState();
}

class _SnacksScreenState extends ConsumerState<SnacksScreen> {
  String? _slotId;
  bool _earlyBooking = false;
  DateTime _date = DateTime.now();
  int _tea = 0;
  int _snack = 0;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(DateTime.now()) ? _date : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _add() {
    ref.read(cartProvider.notifier).addSnack(
          slotId: _slotId!,
          date: ymd(_earlyBooking ? _date : DateTime.now()),
          teaCoffeeQty: _tea,
          snackQty: _snack,
          earlyBooking: _earlyBooking,
        );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Snacks added to cart')));
    setState(() {
      _tea = 0;
      _snack = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(snackSlotsProvider);
    final engine = ref.watch(pricingEngineProvider);
    final pricing = engine.pricing;
    final lineTotal = engine.snackLineTotal(
      teaCoffeeQty: _tea,
      snackQty: _snack,
      earlyBooking: _earlyBooking,
    );

    return slotsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load slots: $e')),
      data: (slots) {
        _slotId ??= slots.isNotEmpty ? slots.first.id : null;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Snack time', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final s in slots)
                  ChoiceChip(
                    label: Text('${s.label} (${s.time})'),
                    selected: _slotId == s.id,
                    onSelected: (_) => setState(() => _slotId = s.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  RadioListTile<bool>(
                    value: false,
                    groupValue: _earlyBooking,
                    onChanged: (v) => setState(() => _earlyBooking = v!),
                    title: const Text('Book now (today)'),
                  ),
                  RadioListTile<bool>(
                    value: true,
                    groupValue: _earlyBooking,
                    onChanged: (v) => setState(() => _earlyBooking = v!),
                    title: const Text('Early booking (future date)'),
                    subtitle: _earlyBooking ? Text('For ${ymd(_date)}') : null,
                    secondary: _earlyBooking
                        ? TextButton(
                            onPressed: _pickDate, child: const Text('Date'))
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    QtyStepper(
                      label: 'Tea / Coffee',
                      subtitle: '${formatRupees(pricing.teaCoffee)} each',
                      value: _tea,
                      onChanged: (v) => setState(() => _tea = v),
                    ),
                    const Divider(),
                    QtyStepper(
                      label: 'Snacks',
                      subtitle: '${formatRupees(pricing.snack)} each',
                      value: _snack,
                      onChanged: (v) => setState(() => _snack = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Line total',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(formatRupees(lineTotal),
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: (_slotId != null && (_tea > 0 || _snack > 0))
                  ? _add
                  : null,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to cart'),
            ),
          ],
        );
      },
    );
  }
}
