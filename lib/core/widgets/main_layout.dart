import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_system_software/features/auth/presentation/providers/auth_provider.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              children: [
                const TopBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return NavigationRail(
      extended: true,
      minWidth: 180,
      minExtendedWidth: 220,
      labelType: NavigationRailLabelType.all,
      groupAlignment: -0.8,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: Text('Products'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.swap_horiz_outlined),
          selectedIcon: Icon(Icons.swap_horiz),
          label: Text('Inventory'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.location_on_outlined),
          selectedIcon: Icon(Icons.location_on),
          label: Text('Locations'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.local_shipping_outlined),
          selectedIcon: Icon(Icons.local_shipping),
          label: Text('Transfers'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shopping_bag_outlined),
          selectedIcon: Icon(Icons.shopping_bag),
          label: Text('Purchases'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart),
          label: Text('Sales'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.assignment_return_outlined),
          selectedIcon: Icon(Icons.assignment_return),
          label: Text('Returns'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: Text('Reports'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: Text('Audit Logs'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.category_outlined),
          selectedIcon: Icon(Icons.category),
          label: Text('Categories'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.branding_watermark_outlined),
          selectedIcon: Icon(Icons.branding_watermark),
          label: Text('Brands'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.local_shipping_outlined),
          selectedIcon: Icon(Icons.local_shipping),
          label: Text('Suppliers'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outlined),
          selectedIcon: Icon(Icons.people),
          label: Text('Customers'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
      selectedIndex: _getSelectedIndex(location),
      onDestinationSelected: (index) {
        if (index == 0) context.go('/');
        if (index == 1) context.go('/products');
        if (index == 2) context.go('/inventory');
        if (index == 3) context.go('/locations');
        if (index == 4) context.go('/transfers');
        if (index == 5) context.go('/purchases');
        if (index == 6) context.go('/sales');
        if (index == 7) context.go('/returns');
        if (index == 8) context.go('/reports');
        if (index == 9) context.go('/audit');
        if (index == 10) context.go('/categories');
        if (index == 11) context.go('/brands');
        if (index == 12) context.go('/suppliers');
        if (index == 13) context.go('/customers');
        if (index == 14) context.go('/settings');
      },
    );
  }

  int _getSelectedIndex(String location) {
    if (location == '/') return 0;
    if (location == '/products') return 1;
    if (location == '/inventory') return 2;
    if (location == '/locations') return 3;
    if (location == '/transfers') return 4;
    if (location == '/purchases') return 5;
    if (location == '/sales') return 6;
    if (location == '/returns') return 7;
    if (location == '/reports') return 8;
    if (location == '/audit') return 9;
    if (location == '/categories') return 10;
    if (location == '/brands') return 11;
    if (location == '/suppliers') return 12;
    if (location == '/customers') return 13;
    if (location == '/settings') return 14;
    return 0;
  }
}

class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Inventory System',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            child: Text(user?.fullName.substring(0, 1).toUpperCase() ?? 'U'),
          ),
          const SizedBox(width: 8),
          Text(user?.fullName ?? 'User'),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authStateProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
    );
  }
}
