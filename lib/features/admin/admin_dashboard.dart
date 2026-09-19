import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/contact.dart';
import '../../data/memory/seed.dart';
import '../../domain/entities/pricing.dart';
import '../../providers.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  Future<void> _seedData(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(pricingRepositoryProvider).save(Pricing.seedDefaults());
      for (final day in seedWeek()) {
        await ref.read(menuRepositoryProvider).saveDay(day);
      }
      await ref.read(snackRepositoryProvider).saveSlots(seedSnackSlots());
      messenger.showSnackBar(const SnackBar(
          content: Text('Seeded prices, weekly menu, and snack slots.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Seeding failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final tiles = [
      (
        'Weekly Menu',
        'Edit breakfast / lunch / dinner items',
        Icons.calendar_view_week,
        '/admin/menu'
      ),
      (
        'Charges',
        'Update all prices and packing charge',
        Icons.currency_rupee,
        '/admin/charges'
      ),
      (
        'Orders & Payments',
        'View all orders, set payment status',
        Icons.receipt_long,
        '/admin/orders'
      ),
      (
        'Snack Slots',
        'Configure snack times',
        Icons.emoji_food_beverage,
        '/admin/slots'
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Seed initial data',
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: () => _seedData(context, ref),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'logout') {
                await ref.read(authRepositoryProvider).signOut();
              } else if (v == 'help' && context.mounted) {
                showContactAdminDialog(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Text(user?.name ?? 'Admin')),
              const PopupMenuItem(value: 'help', child: Text('Contact admin')),
              const PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
        children: [
          for (final t in tiles)
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push(t.$4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(t.$3, size: 40,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(t.$1,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(t.$2,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
