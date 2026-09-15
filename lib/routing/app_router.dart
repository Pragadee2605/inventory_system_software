import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_system_software/features/dashboard/presentation/dashboard_screen.dart';
import 'package:inventory_system_software/features/settings/presentation/settings_screen.dart';
import 'package:inventory_system_software/features/categories/presentation/category_screen.dart';
import 'package:inventory_system_software/features/brands/presentation/brand_screen.dart';
import 'package:inventory_system_software/features/suppliers/presentation/supplier_screen.dart';
import 'package:inventory_system_software/features/customers/presentation/customer_screen.dart';
import 'package:inventory_system_software/features/products/presentation/product_screen.dart';
import 'package:inventory_system_software/features/inventory/presentation/inventory_screen.dart';
import 'package:inventory_system_software/features/inventory/presentation/locations_screen.dart';
import 'package:inventory_system_software/features/inventory/presentation/transfers_screen.dart';
import 'package:inventory_system_software/features/inventory/presentation/expiry_report_screen.dart';
import 'package:inventory_system_software/features/purchases/presentation/purchase_screen.dart';
import 'package:inventory_system_software/features/sales/presentation/sales_screen.dart';
import 'package:inventory_system_software/features/returns/presentation/returns_screen.dart';
import 'package:inventory_system_software/features/reports/presentation/reports_screen.dart';
import 'package:inventory_system_software/features/audit/presentation/audit_screen.dart';
import 'package:inventory_system_software/features/auth/presentation/login_screen.dart';
import 'package:inventory_system_software/features/auth/presentation/setup_screen.dart';
import 'package:inventory_system_software/features/auth/presentation/providers/auth_provider.dart';
import 'package:inventory_system_software/core/widgets/main_layout.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(hasUsersProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final hasUsersAsync = ref.read(hasUsersProvider);
      if (hasUsersAsync.isLoading || hasUsersAsync.hasError) return null;

      final hasUsers = hasUsersAsync.value ?? false;
      final authState = ref.read(authStateProvider);
      if (authState.isLoading || authState.hasError) return null;

      final isLoggedIn = authState.value != null;
      final isGoingToSetup = state.matchedLocation == '/setup';
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!hasUsers) {
        if (!isGoingToSetup) return '/setup';
        return null;
      }

      if (!isLoggedIn) {
        if (!isGoingToLogin) return '/login';
        return null;
      }

      if (isGoingToLogin || isGoingToSetup) return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/setup', builder: (context, state) => const SetupScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/products', builder: (context, state) => const ProductScreen()),
          GoRoute(path: '/inventory', builder: (context, state) => const InventoryScreen()),
          GoRoute(path: '/locations', builder: (context, state) => const LocationsScreen()),
          GoRoute(path: '/transfers', builder: (context, state) => const TransfersScreen()),
          GoRoute(path: '/expiry', builder: (context, state) => const ExpiryReportScreen()),
          GoRoute(path: '/purchases', builder: (context, state) => const PurchaseScreen()),
          GoRoute(path: '/sales', builder: (context, state) => const SalesScreen()),
          GoRoute(path: '/returns', builder: (context, state) => const ReturnsScreen()),
          GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
          GoRoute(path: '/audit', builder: (context, state) => const AuditScreen()),
          GoRoute(path: '/categories', builder: (context, state) => const CategoryScreen()),
          GoRoute(path: '/brands', builder: (context, state) => const BrandScreen()),
          GoRoute(path: '/suppliers', builder: (context, state) => const SupplierScreen()),
          GoRoute(path: '/customers', builder: (context, state) => const CustomerScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
