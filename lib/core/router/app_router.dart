import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/app_user.dart';
import '../../features/admin/admin_dashboard.dart';
import '../../features/admin/charges_editor_screen.dart';
import '../../features/admin/menu_editor_screen.dart';
import '../../features/admin/orders_admin_screen.dart';
import '../../features/admin/snack_slots_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/payment/payment_screen.dart';
import '../../providers.dart';

/// Bridges a Stream to a [Listenable] so GoRouter re-evaluates redirects.
class _RefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;
  _RefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RefreshStream(
      ref.watch(authRepositoryProvider).authState());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(authRepositoryProvider).currentUser;
      final loggingIn =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (user == null) {
        return loggingIn ? null : '/login';
      }
      // Signed in but on an auth page → send to role home.
      if (loggingIn) {
        return user.isAdmin ? '/admin' : '/home';
      }
      // Guard admin area.
      final inAdmin = state.matchedLocation.startsWith('/admin');
      if (inAdmin && !user.isAdmin) return '/home';
      if (!inAdmin && user.isAdmin && state.matchedLocation == '/home') {
        return '/admin';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/payment', builder: (_, __) => const PaymentScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboard()),
      GoRoute(
          path: '/admin/charges',
          builder: (_, __) => const ChargesEditorScreen()),
      GoRoute(
          path: '/admin/menu', builder: (_, __) => const MenuEditorScreen()),
      GoRoute(
          path: '/admin/orders',
          builder: (_, __) => const OrdersAdminScreen()),
      GoRoute(
          path: '/admin/slots', builder: (_, __) => const SnackSlotsScreen()),
    ],
  );
});

/// Small helper for widgets that need the current user quickly.
extension AuthRefX on WidgetRef {
  AppUser? get currentUserOrNull => read(authStateProvider).valueOrNull;
}
