import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../domain/entities/order.dart';
import '../../providers.dart';
import '../cart/cart_controller.dart';
import 'payment_gateway.dart';

/// Payment gateway provider. Swap [StubPaymentGateway] for a real one later.
final paymentGatewayProvider =
    Provider<PaymentGateway>((ref) => StubPaymentGateway());

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _pay() async {
    final user = ref.read(authStateProvider).valueOrNull;
    final lines = ref.read(cartProvider);
    final total = ref.read(cartTotalProvider);
    if (user == null || lines.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = await ref.read(paymentGatewayProvider).pay(
            amountPaise: total,
            orderRef: '${user.uid}-${DateTime.now().millisecondsSinceEpoch}',
          );
      if (!result.success) {
        setState(() => _error = result.error ?? 'Payment failed.');
        return;
      }
      // Payment ok → place the order as paid.
      final draft = Order(
        id: '',
        uid: user.uid,
        createdAt: DateTime.now(),
        lines: lines,
        total: total,
        paymentStatus: PaymentStatus.paid,
      );
      await ref.read(orderRepositoryProvider).place(draft);
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Payment successful'),
          content: Text('Paid ${formatRupees(total)}.\nYour order is confirmed.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = 'Something went wrong. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(cartTotalProvider);
    final lines = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Amount to pay',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(formatRupees(total),
                        style: Theme.of(context).textTheme.displaySmall),
                    Text('${lines.length} item(s)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Payment gateway is not integrated yet. This is a '
                        'placeholder that simulates a successful payment.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const Spacer(),
            FilledButton.icon(
              onPressed: _busy || lines.isEmpty ? null : _pay,
              icon: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.lock),
              label: Text('Pay ${formatRupees(total)}'),
            ),
          ],
        ),
      ),
    );
  }
}
