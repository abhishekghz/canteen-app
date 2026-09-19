import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../domain/entities/order.dart';
import '../../providers.dart';
import '../cart/cart_screen.dart' show describeLine;

Color paymentColor(PaymentStatus s) => switch (s) {
      PaymentStatus.paid => Colors.green,
      PaymentStatus.unpaid => Colors.orange,
      PaymentStatus.refunded => Colors.blueGrey,
    };

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<Order>>(
      stream: ref.read(orderRepositoryProvider).watchForUser(user.uid),
      builder: (context, snap) {
        final orders = snap.data ?? const [];
        if (orders.isEmpty) {
          return const Center(child: Text('No orders yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          itemBuilder: (context, i) => _OrderCard(order: orders[i]),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text('${formatRupees(order.total)} • ${order.lines.length} item(s)'),
        subtitle: Text(order.createdAt.toString().split('.').first),
        leading: const Icon(Icons.receipt_long),
        trailing: Chip(
          label: Text(order.paymentStatus.label),
          backgroundColor:
              paymentColor(order.paymentStatus).withValues(alpha: 0.15),
        ),
        children: [
          for (final line in order.lines)
            ListTile(
              dense: true,
              title: Text(describeLine(line)),
              subtitle: Text('For ${line.date}'),
              trailing: Text(formatRupees(line.lineTotal)),
            ),
        ],
      ),
    );
  }
}
