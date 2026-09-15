import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_system_software/features/auth/presentation/providers/auth_provider.dart';

final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(sidebarCollapsedProvider);

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: isCollapsed ? 72 : 260,
            child: const Sidebar(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isCollapsed = ref.watch(sidebarCollapsedProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        children: [
          // Header Logo & Branding
          _buildHeader(context, ref, isCollapsed, isDark),
          const Divider(height: 1),
          // Navigation Items List
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'OVERVIEW', isCollapsed),
                  _buildNavItem(
                    context: context,
                    route: '/',
                    currentPath: location,
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view_rounded,
                    label: 'Dashboard',
                    isCollapsed: isCollapsed,
                  ),
                  const SizedBox(height: 12),
                  _buildSectionHeader(context, 'INVENTORY & CATALOG', isCollapsed),
                  _buildNavItem(
                    context: context,
                    route: '/products',
                    currentPath: location,
                    icon: Icons.inventory_2_outlined,
                    activeIcon: Icons.inventory_2_rounded,
                    label: 'Products',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    route: '/inventory',
                    currentPath: location,
                    icon: Icons.warehouse_outlined,
                    activeIcon: Icons.warehouse_rounded,
                    label: 'Inventory',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    route: '/locations',
                    currentPath: location,
                    icon: Icons.location_on_outlined,
                    activeIcon: Icons.location_on_rounded,
                    label: 'Locations',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    route: '/transfers',
                    currentPath: location,
                    icon: Icons.swap_horiz_outlined,
                    activeIcon: Icons.swap_horiz_rounded,
                    label: 'Stock Transfers',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    route: '/expiry',
                    currentPath: location,
                    icon: Icons.event_busy_outlined,
                    activeIcon: Icons.event_busy_rounded,
                    label: 'Expiry Alerts',
                    isCollapsed: isCollapsed,
                  ),
                  const SizedBox(height: 12),
                  _buildSectionHeader(context, 'COMMERCE', isCollapsed),
                  _buildNavItem(
                    context: context,
                    route: '/purchases',
                    currentPath: location,
                    icon: Icons.shopping_bag_outlined,
                    activeIcon: Icons.shopping_bag_rounded,
                    label: 'Purchases',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    route: '/sales',
                    currentPath: location,
                    icon: Icons.point_of_sale_outlined,
                    activeIcon: Icons.point_of_sale_rounded,
                    label: 'Sales',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    route: '/returns',
                    currentPath: location,
                    icon: Icons.assignment_return_outlined,
                    activeIcon: Icons.assignment_return_rounded,
                    label: 'Returns',
                    isCollapsed: isCollapsed,
                  ),
                  const SizedBox(height: 12),
                  _buildSectionHeader(context, 'ANALYTICS & AUDIT', isCollapsed),
                  _buildNavItem(
                    context: context,
                    route: '/reports',
                    currentPath: location,
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart_rounded,
                    label: 'Reports & Analytics',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    route: '/audit',
                    currentPath: location,
                    icon: Icons.history_toggle_off_outlined,
                    activeIcon: Icons.history_toggle_off_rounded,
                    label: 'Audit Logs',
                    isCollapsed: isCollapsed,
                  ),
                  const SizedBox(height: 12),
                  _buildSectionHeader(context, 'MASTER DATA', isCollapsed),
                  _buildNavItem(
                    context: context,
                    route: '/categories',
                    currentPath: location,
                    icon: Icons.category_outlined,
                    activeIcon: Icons.category_rounded,
                    label: 'Categories',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    route: '/brands',
                    currentPath: location,
                    icon: Icons.branding_watermark_outlined,
                    activeIcon: Icons.branding_watermark_rounded,
                    label: 'Brands',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    route: '/suppliers',
                    currentPath: location,
                    icon: Icons.local_shipping_outlined,
                    activeIcon: Icons.local_shipping_rounded,
                    label: 'Suppliers',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    route: '/customers',
                    currentPath: location,
                    icon: Icons.people_outline_rounded,
                    activeIcon: Icons.people_rounded,
                    label: 'Customers',
                    isCollapsed: isCollapsed,
                  ),
                  const SizedBox(height: 12),
                  _buildSectionHeader(context, 'SYSTEM', isCollapsed),
                  _buildNavItem(
                    context: context,
                    route: '/users',
                    currentPath: location,
                    icon: Icons.manage_accounts_outlined,
                    activeIcon: Icons.manage_accounts_rounded,
                    label: 'User Accounts',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    route: '/settings',
                    currentPath: location,
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: 'Settings',
                    isCollapsed: isCollapsed,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Sidebar Collapse Toggle Button
          _buildFooterToggle(context, ref, isCollapsed),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isCollapsed, bool isDark) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.layers_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'NEXUS',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Inventory Enterprise',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isCollapsed) {
    if (isCollapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Divider(indent: 12, endIndent: 12, thickness: 0.5),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 10, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String route,
    required String currentPath,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isCollapsed,
  }) {
    final isActive = currentPath == route;
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;

    Widget tile = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go(route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 20,
                color: isActive
                    ? activeColor
                    : theme.brightness == Brightness.dark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? activeColor
                          : theme.brightness == Brightness.dark
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF334155),
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(
        message: label,
        preferBelow: false,
        child: tile,
      );
    }

    return tile;
  }

  Widget _buildFooterToggle(BuildContext context, WidgetRef ref, bool isCollapsed) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => ref.read(sidebarCollapsedProvider.notifier).state = !isCollapsed,
        child: Row(
          mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                isCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                color: const Color(0xFF64748B),
              ),
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 4),
              const Text(
                'Collapse Sidebar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final currentPath = GoRouterState.of(context).uri.path;
    final title = _getBreadcrumbTitle(currentPath);
    final category = _getBreadcrumbCategory(currentPath);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumb Title Section
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.chevron_right, size: 12, color: Color(0xFF94A3B8)),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 32),
          // Global Search Bar Trigger
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showQuickSearchModal(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Search products, orders, customers...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '⌘K',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Quick Action Dropdown Menu
          PopupMenuButton<String>(
            tooltip: 'Quick Actions',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            offset: const Offset(0, 48),
            onSelected: (route) => context.go(route),
            itemBuilder: (context) => [
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  'QUICK ACTIONS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                ),
              ),
              const PopupMenuItem(
                value: '/products',
                child: Row(
                  children: [
                    Icon(Icons.add_box_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('New Product', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: '/transfers',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 18),
                    SizedBox(width: 10),
                    Text('Stock Transfer', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: '/purchases',
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Create Purchase', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: '/sales',
                child: Row(
                  children: [
                    Icon(Icons.point_of_sale, size: 18),
                    SizedBox(width: 10),
                    Text('Create Sale Order', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Quick Action',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Notifications Bell Button
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 22),
                tooltip: 'Notifications',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No new notifications'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const VerticalDivider(indent: 16, endIndent: 16),
          const SizedBox(width: 8),
          // User Profile Menu Badge
          PopupMenuButton<String>(
            tooltip: 'User Account',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            offset: const Offset(0, 52),
            onSelected: (value) async {
              if (value == 'users') {
                context.go('/users');
              } else if (value == 'settings') {
                context.go('/settings');
              } else if (value == 'logout') {
                _confirmLogout(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'System User',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      user?.username != null ? '@${user!.username}' : 'Administrator',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (user?.roleName ?? 'ADMIN').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'users',
                child: Row(
                  children: [
                    Icon(Icons.manage_accounts_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('User Management', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('System Settings', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                    SizedBox(width: 10),
                    Text('Logout', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        user?.fullName.isNotEmpty == true
                            ? user!.fullName.substring(0, 1).toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'User',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user?.roleName.toUpperCase() ?? 'ADMIN',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getBreadcrumbCategory(String path) {
    if (path == '/') return 'Overview';
    if (['/products', '/inventory', '/locations', '/transfers', '/expiry'].contains(path)) {
      return 'Inventory & Catalog';
    }
    if (['/purchases', '/sales', '/returns'].contains(path)) return 'Commerce';
    if (['/reports', '/audit'].contains(path)) return 'Analytics';
    if (['/categories', '/brands', '/suppliers', '/customers'].contains(path)) return 'Master Data';
    if (['/users', '/settings'].contains(path)) return 'Configuration';
    return 'System';
  }

  String _getBreadcrumbTitle(String path) {
    switch (path) {
      case '/': return 'Dashboard';
      case '/products': return 'Product Catalog';
      case '/inventory': return 'Inventory Stock';
      case '/locations': return 'Warehouse Locations';
      case '/transfers': return 'Stock Transfers';
      case '/expiry': return 'Expiry Tracking';
      case '/purchases': return 'Purchase Orders';
      case '/sales': return 'Sales Orders';
      case '/returns': return 'Return Management';
      case '/reports': return 'Reports & Analytics';
      case '/audit': return 'Audit Logs';
      case '/categories': return 'Product Categories';
      case '/brands': return 'Product Brands';
      case '/suppliers': return 'Suppliers Directory';
      case '/customers': return 'Customers Directory';
      case '/users': return 'User Accounts';
      case '/settings': return 'System Settings';
      default: return 'Overview';
    }
  }

  void _showQuickSearchModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search features, products, or commands...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Quick Navigation',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.grid_view),
                  title: const Text('Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: const Text('Product Catalog'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/products');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.warehouse),
                  title: const Text('Stock Inventory'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/inventory');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts),
                  title: const Text('User Management'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/users');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of Nexus Enterprise Inventory?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authStateProvider.notifier).logout();
    }
  }
}
