import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pricing.dart';
import '../../providers.dart';

class ChargesEditorScreen extends ConsumerWidget {
  const ChargesEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricingAsync = ref.watch(pricingProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Charges')),
      body: pricingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pricing) => _ChargesForm(pricing: pricing),
      ),
    );
  }
}

class _ChargesForm extends ConsumerStatefulWidget {
  final Pricing pricing;
  const _ChargesForm({required this.pricing});
  @override
  ConsumerState<_ChargesForm> createState() => _ChargesFormState();
}

class _ChargesFormState extends ConsumerState<_ChargesForm> {
  late final Map<String, TextEditingController> _c;
  bool _busy = false;

  // rupees value from paise
  String _r(int paise) => (paise / 100).toStringAsFixed(
      paise % 100 == 0 ? 0 : 2);

  @override
  void initState() {
    super.initState();
    final p = widget.pricing;
    _c = {
      'breakfast': TextEditingController(text: _r(p.breakfast)),
      'lunch': TextEditingController(text: _r(p.lunch)),
      'dinner': TextEditingController(text: _r(p.dinner)),
      'roti': TextEditingController(text: _r(p.roti)),
      'sabji': TextEditingController(text: _r(p.sabji)),
      'packing': TextEditingController(text: _r(p.packing)),
      'teaCoffee': TextEditingController(text: _r(p.teaCoffee)),
      'snack': TextEditingController(text: _r(p.snack)),
      'earlyBookingDiscount':
          TextEditingController(text: _r(p.earlyBookingDiscount)),
    };
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _paise(String key) {
    final v = double.tryParse(_c[key]!.text.trim()) ?? 0;
    return (v * 100).round();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final updated = Pricing(
      breakfast: _paise('breakfast'),
      lunch: _paise('lunch'),
      dinner: _paise('dinner'),
      roti: _paise('roti'),
      sabji: _paise('sabji'),
      packing: _paise('packing'),
      teaCoffee: _paise('teaCoffee'),
      snack: _paise('snack'),
      earlyBookingDiscount: _paise('earlyBookingDiscount'),
    );
    try {
      await ref.read(pricingRepositoryProvider).save(updated);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Charges saved')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(String key, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: _c[key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
          ],
          decoration: InputDecoration(
            labelText: label,
            prefixText: '₹ ',
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Meals', style: Theme.of(context).textTheme.titleMedium),
        _field('breakfast', 'Breakfast'),
        _field('lunch', 'Lunch'),
        _field('dinner', 'Dinner'),
        const Divider(height: 32),
        Text('Extras', style: Theme.of(context).textTheme.titleMedium),
        _field('roti', 'Extra roti (each)'),
        _field('sabji', 'Extra sabji (each)'),
        _field('packing', 'Packing charge'),
        const Divider(height: 32),
        Text('Snacks', style: Theme.of(context).textTheme.titleMedium),
        _field('teaCoffee', 'Tea / Coffee (each)'),
        _field('snack', 'Snack item (each)'),
        _field('earlyBookingDiscount', 'Early-booking discount'),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy ? null : _save,
          icon: const Icon(Icons.save),
          label: const Text('Save charges'),
        ),
      ],
    );
  }
}
