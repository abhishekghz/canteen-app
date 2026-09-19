import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/contact.dart';
import '../../core/money.dart';
import '../../providers.dart';
import '../booking/booking_screen.dart';
import '../cart/cart_controller.dart';
import '../coupons/coupons_screen.dart';
import '../menu/menu_screen.dart';
import '../orders/orders_screen.dart';
import '../snacks/snacks_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _titles = ['Menu', 'Book Meal', 'Snacks', 'Coupons', 'Orders'];
  static const _screens = [
    MenuScreen(),
    BookingScreen(),
    SnacksScreen(),
    CouponsScreen(),
    OrdersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final cartCount = ref.watch(cartProvider).length;
    final cartTotal = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => context.push('/cart'),
            ),
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
              PopupMenuItem(
                enabled: false,
                child: Text(user?.name ?? 'Account'),
              ),
              const PopupMenuItem(value: 'help', child: Text('Contact admin')),
              const PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.calendar_view_week), label: 'Menu'),
          NavigationDestination(
              icon: Icon(Icons.restaurant), label: 'Book'),
          NavigationDestination(
              icon: Icon(Icons.emoji_food_beverage), label: 'Snacks'),
          NavigationDestination(
              icon: Icon(Icons.confirmation_number), label: 'Coupons'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long), label: 'Orders'),
        ],
      ),
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/cart'),
              icon: const Icon(Icons.shopping_cart),
              label: Text('Cart • ${formatRupees(cartTotal)}'),
            )
          : null,
    );
  }
}
