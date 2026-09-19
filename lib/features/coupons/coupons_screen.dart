import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../domain/entities/coupon.dart';
import '../../domain/entities/menu_day.dart';
import '../../providers.dart';

class CouponsScreen extends ConsumerStatefulWidget {
  const CouponsScreen({super.key});
  @override
  ConsumerState<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends ConsumerState<CouponsScreen> {
  MealType _type = MealType.lunch;
  int _qty = 1;
  bool _busy = false;

  Future<void> _buy(String uid) async {
    setState(() => _busy = true);
    try {
      await ref.read(couponRepositoryProvider).buy(uid, _type, _qty);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_qty ${_type.label} coupon(s) purchased')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final engine = ref.watch(pricingEngineProvider);
    if (user == null) return const SizedBox.shrink();
    final bundleTotal = engine.couponBundleTotal(_type, _qty);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buy meal coupons',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final t in MealType.values)
                      ChoiceChip(
                        label: Text(t.label),
                        selected: _type == t,
                        onSelected: (_) => setState(() => _type = t),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Quantity'),
                    const Spacer(),
                    IconButton.outlined(
                      onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(
                        width: 36,
                        child: Text('$_qty', textAlign: TextAlign.center)),
                    IconButton.outlined(
                      onPressed: () => setState(() => _qty++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _buy(user.uid),
                  icon: const Icon(Icons.confirmation_number),
                  label: Text('Buy for ${formatRupees(bundleTotal)}'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('My coupons', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<List<Coupon>>(
          stream: ref.read(couponRepositoryProvider).watchForUser(user.uid),
          builder: (context, snap) {
            final coupons = snap.data ?? const [];
            if (coupons.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No coupons yet.')),
              );
            }
            return Column(
              children: [
                for (final c in coupons) _CouponTile(coupon: c),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CouponTile extends ConsumerWidget {
  final Coupon coupon;
  const _CouponTile({required this.coupon});

  Color _statusColor(BuildContext context) => switch (coupon.status) {
        CouponStatus.active => Colors.green,
        CouponStatus.redeemed => Colors.grey,
        CouponStatus.expired => Colors.red,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.confirmation_number),
        title: Text('${coupon.mealType.label} • ${coupon.code}'),
        subtitle: Text('Expires ${coupon.expiresAt.toString().split(' ').first}'),
        trailing: coupon.status == CouponStatus.active
            ? TextButton(
                onPressed: () =>
                    ref.read(couponRepositoryProvider).redeem(coupon.id),
                child: const Text('Redeem'),
              )
            : Chip(
                label: Text(coupon.status.label),
                backgroundColor: _statusColor(context).withValues(alpha: 0.15),
              ),
      ),
    );
  }
}
