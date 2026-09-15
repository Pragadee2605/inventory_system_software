import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/features/auth/presentation/providers/auth_provider.dart';

class PermissionGate extends ConsumerWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;

  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user != null && user.hasPermission(permission)) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}
