import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../domain/entities/order.dart';
import '../../providers.dart';
import '../cart/cart_screen.dart' show describeLine;
import '../orders/orders_screen.dart' show paymentColor;

class OrdersAdminScreen extends ConsumerWidget {
  const OrdersAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders & Payments')),
      body: StreamBuilder<List<Order>>(
        stream: ref.read(orderRepositoryProvider).watchAll(),
        builder: (context, snap) {
          final orders = snap.data ?? const [];
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, i) => _AdminOrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _AdminOrderCard extends ConsumerWidget {
  final Order order;
  const _AdminOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
              paymentColor(order.paymentStatus).withValues(alpha: 0.2),
          child: Icon(Icons.person,
              color: paymentColor(order.paymentStatus)),
        ),
        title: Text('${formatRupees(order.total)} • ${order.uid}'),
        subtitle: Text(order.createdAt.toString().split('.').first),
        children: [
          for (final line in order.lines)
            ListTile(
              dense: true,
              title: Text(describeLine(line)),
              subtitle: Text('For ${line.date}'),
              trailing: Text(formatRupees(line.lineTotal)),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Payment status'),
                const Spacer(),
                DropdownButton<PaymentStatus>(
                  value: order.paymentStatus,
                  items: [
                    for (final s in PaymentStatus.values)
                      DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (s) {
                    if (s != null) {
                      ref
                          .read(orderRepositoryProvider)
                          .setPaymentStatus(order.id, s);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
