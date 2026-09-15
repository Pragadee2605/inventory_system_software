import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/features/auth/domain/models/auth_user.dart';

final authorizationServiceProvider = Provider<AuthorizationService>((ref) {
  return AuthorizationService();
});

class AuthorizationService {
  bool hasPermission(AuthUser? user, String permission) {
    if (user == null) return false;
    return user.hasPermission(permission);
  }

  bool hasAnyPermission(AuthUser? user, List<String> permissions) {
    if (user == null) return false;
    return permissions.any((p) => user.hasPermission(p));
  }

  bool hasAllPermissions(AuthUser? user, List<String> permissions) {
    if (user == null) return false;
    return permissions.every((p) => user.hasPermission(p));
  }

  String? getRequiredPermissionForRoute(String path) {
    switch (path) {
      case '/':
        return 'DASHBOARD_VIEW';
      case '/products':
        return 'PRODUCT_VIEW';
      case '/categories':
        return 'CATEGORY_MANAGE';
      case '/brands':
        return 'BRAND_MANAGE';
      case '/suppliers':
        return 'SUPPLIER_MANAGE';
      case '/customers':
        return 'CUSTOMER_MANAGE';
      case '/inventory':
      case '/locations':
      case '/expiry':
        return 'INVENTORY_VIEW';
      case '/transfers':
        return 'TRANSFERS_MANAGE';
      case '/purchases':
        return 'PURCHASE_VIEW';
      case '/sales':
        return 'SALES_VIEW';
      case '/returns':
        return 'RETURNS_MANAGE';
      case '/reports':
        return 'REPORT_VIEW';
      case '/audit':
        return 'AUDIT_VIEW';
      case '/users':
        return 'USER_MANAGE';
      case '/settings':
        return 'SETTINGS_MANAGE';
      default:
        return null;
    }
  }

  bool canAccessRoute(AuthUser? user, String routePath) {
    if (user == null) return false;
    final requiredPerm = getRequiredPermissionForRoute(routePath);
    if (requiredPerm == null) return true;
    return hasPermission(user, requiredPerm);
  }

  void checkPermission(AuthUser? user, String permission) {
    if (!hasPermission(user, permission)) {
      throw Exception('Access Denied: You lack the "$permission" permission to perform this action.');
    }
  }
}
