import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/features/auth/data/services/password_service.dart';

import 'native_database.dart' if (dart.library.js_interop) 'web_database.dart' as db_impl;

part 'database.g.dart';

@DriftDatabase(tables: [
  Users, Roles, Permissions, RolePermissions,
  Categories, Brands, Suppliers, Customers, Products,
  Locations, ProductBatches,
  StockTransactions,
  StockTransfers, StockTransferItems,
  PurchaseOrders, PurchaseItems,
  SalesOrders, SalesItems,
  Returns, ReturnItems,
  Payments, AuditLogs
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(db_impl.openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onCreate: (m) async {
        await m.createAll();
        await _seedDefaultRolesAndPermissions();
        await _seedDefaultMasterData();
      },
      onUpgrade: (m, from, to) async {
        if (from < 3) {
          // Robust migration to add missing columns if they don't exist.
          // We use a helper to check column existence to prevent "duplicate column" errors.
          await _addColumnIfNotExists('sales_orders', 'tax_amount', 'REAL NOT NULL DEFAULT 0.0');
          await _addColumnIfNotExists('sales_orders', 'discount_amount', 'REAL NOT NULL DEFAULT 0.0');
          await _addColumnIfNotExists('sales_orders', 'profit_amount', 'REAL NOT NULL DEFAULT 0.0');
          await _addColumnIfNotExists('sales_orders', 'status', 'TEXT NOT NULL DEFAULT "COMPLETED"');
          await _addColumnIfNotExists('sales_items', 'purchase_price', 'REAL NOT NULL DEFAULT 0.0');
        }
      },
    );
  }

  Future<void> _addColumnIfNotExists(String table, String column, String type) async {
    final result = await customSelect('PRAGMA table_info($table)').get();
    final columnExists = result.any((row) => row.read<String>('name') == column);
    
    if (!columnExists) {
      await customStatement('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<void> ensureDefaultAdmin() async {
    await _seedDefaultRolesAndPermissions();
    await _seedDefaultMasterData();

    final adminRole = await (select(roles)
          ..where((t) => t.name.equals('ADMIN')))
        .getSingleOrNull();

    if (adminRole == null) {
      return;
    }

    final existingUser = await (select(users)
          ..where((t) => t.username.equals('Pragadees')))
        .getSingleOrNull();

    if (existingUser != null) {
      return;
    }

    await into(users).insert(
      UsersCompanion.insert(
        username: 'Pragadees',
        fullName: 'Pragadees Admin',
        passwordHash: PasswordService().hashPassword('Pragadees'),
        roleId: adminRole.id,
        status: const Value(UserStatus.active),
      ),
    );
    if (kDebugMode) {
      print('Default admin created: Pragadees / Pragadees');
    }
  }

  Future<void> _seedDefaultRolesAndPermissions() async {
    final existingRoles = await select(roles).get();
    if (existingRoles.isEmpty) {
      await batch((batch) {
        batch.insertAll(roles, [
          RolesCompanion.insert(name: 'ADMIN', description: const Value('Administrator with full system access')),
          RolesCompanion.insert(name: 'MANAGER', description: const Value('Manager with operational and reporting access')),
          RolesCompanion.insert(name: 'STAFF', description: const Value('Staff with basic inventory and sales access')),
          RolesCompanion.insert(name: 'VIEWER', description: const Value('Read-only view access')),
        ]);
      });
    }

    final allRolesMap = {
      for (final r in await select(roles).get()) r.name: r.id
    };

    final existingPermissions = await select(permissions).get();
    final permissionsList = [
      'DASHBOARD_VIEW',
      'PRODUCT_VIEW',
      'PRODUCT_MANAGE',
      'CATEGORY_MANAGE',
      'BRAND_MANAGE',
      'SUPPLIER_MANAGE',
      'CUSTOMER_MANAGE',
      'INVENTORY_VIEW',
      'STOCK_MANAGE',
      'TRANSFERS_MANAGE',
      'PURCHASE_VIEW',
      'PURCHASE_MANAGE',
      'SALES_VIEW',
      'SALES_MANAGE',
      'RETURNS_MANAGE',
      'REPORT_VIEW',
      'REPORT_EXPORT',
      'AUDIT_VIEW',
      'USER_MANAGE',
      'SETTINGS_MANAGE',
    ];

    if (existingPermissions.isEmpty) {
      await batch((batch) {
        batch.insertAll(
          permissions,
          permissionsList.map((code) => PermissionsCompanion.insert(code: code, description: Value('Permission for $code'))).toList(),
        );
      });
    }

    // Refresh permissions list from DB to ensure FK-safe inserts
    final existingPermissionsNow = await select(permissions).get();
    final existingPermissionCodes = existingPermissionsNow.map((p) => p.code).toSet();

    final existingRolePerms = await select(rolePermissions).get();
    if (existingRolePerms.isEmpty) {
      final rolePermsToInsert = <RolePermissionsCompanion>[];

      // Helper: add only if permission code exists in DB
      void tryAdd(int roleId, String code) {
        if (existingPermissionCodes.contains(code)) {
          rolePermsToInsert.add(RolePermissionsCompanion.insert(roleId: roleId, permissionCode: code));
        } else {
          // permission not present — skip to avoid FK failure
          if (kDebugMode) {
            print('Warning: skipping role-permission insert, missing permission: $code');
          }
        }
      }

      // ADMIN gets all permissions
      final adminRoleId = allRolesMap['ADMIN'];
      if (adminRoleId != null) {
        for (final p in permissionsList) {
          tryAdd(adminRoleId, p);
        }
      }

      // MANAGER gets all operational + reporting permissions (except USER_MANAGE and SETTINGS_MANAGE)
      final managerRoleId = allRolesMap['MANAGER'];
      if (managerRoleId != null) {
        final managerPerms = permissionsList.where((p) => p != 'USER_MANAGE' && p != 'SETTINGS_MANAGE');
        for (final p in managerPerms) {
          tryAdd(managerRoleId, p);
        }
      }

      // STAFF gets basic view + stock + sales + purchases + transfers + reports
      final staffRoleId = allRolesMap['STAFF'];
      if (staffRoleId != null) {
        final staffPerms = [
          'DASHBOARD_VIEW',
          'PRODUCT_VIEW',
          'INVENTORY_VIEW',
          'STOCK_MANAGE',
          'TRANSFERS_MANAGE',
          'PURCHASE_VIEW',
          'SALES_VIEW',
          'SALES_MANAGE',
          'RETURNS_MANAGE',
          'REPORT_VIEW',
        ];
        for (final p in staffPerms) {
          tryAdd(staffRoleId, p);
        }
      }

      // VIEWER gets read-only access
      final viewerRoleId = allRolesMap['VIEWER'];
      if (viewerRoleId != null) {
        final viewerPerms = [
          'DASHBOARD_VIEW',
          'PRODUCT_VIEW',
          'INVENTORY_VIEW',
          'PURCHASE_VIEW',
          'SALES_VIEW',
          'REPORT_VIEW',
        ];
        for (final p in viewerPerms) {
          tryAdd(viewerRoleId, p);
        }
      }

      if (rolePermsToInsert.isNotEmpty) {
        await batch((batch) {
          batch.insertAll(rolePermissions, rolePermsToInsert);
        });
      }
    }
  }

  Future<void> _seedDefaultMasterData() async {
    final existingCategories = await select(categories).get();
    if (existingCategories.isEmpty) {
      await batch((batch) {
        batch.insertAll(categories, [
          CategoriesCompanion.insert(
            name: 'Electronics',
            description: const Value('Electronics items'),
          ),
          CategoriesCompanion.insert(
            name: 'Food',
            description: const Value('Food and grocery'),
          ),
          CategoriesCompanion.insert(
            name: 'Clothing',
            description: const Value('Apparel and clothing'),
          ),
        ]);
      });
    }

    final existingBrands = await select(brands).get();
    if (existingBrands.isEmpty) {
      await batch((batch) {
        batch.insertAll(brands, [
          BrandsCompanion.insert(name: 'Generic'),
          BrandsCompanion.insert(name: 'Samsung'),
          BrandsCompanion.insert(name: 'Apple'),
        ]);
      });
    }
  }
}

// AUTH TABLES
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 3, max: 50).unique()();
  TextColumn get fullName => text().withLength(min: 3, max: 100)();
  TextColumn get passwordHash => text()();
  IntColumn get roleId => integer().references(Roles, #id)();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  IntColumn get status => intEnum<UserStatus>().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();
}

enum UserStatus { active, inactive }

class Roles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get description => text().nullable()();
}

class Permissions extends Table {
  TextColumn get code => text()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {code};
}

class RolePermissions extends Table {
  IntColumn get roleId => integer().references(Roles, #id)();
  TextColumn get permissionCode => text().references(Permissions, #code)();
  @override
  Set<Column> get primaryKey => {roleId, permissionCode};
}

// MASTER DATA TABLES
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Brands extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sku => text().unique()();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get brandId => integer().nullable().references(Brands, #id)();
  RealColumn get purchasePrice => real().withDefault(const Constant(0.0))();
  RealColumn get sellingPrice => real().withDefault(const Constant(0.0))();
  IntColumn get currentStock => integer().withDefault(const Constant(0))();
  IntColumn get minStock => integer().withDefault(const Constant(5))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Locations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get code => text().unique()();
}

class ProductBatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get batchNumber => text()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  IntColumn get currentStock => integer().withDefault(const Constant(0))();
}

class StockTransfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('fromLocation')
  IntColumn get fromLocationId => integer().references(Locations, #id)();
  @ReferenceName('toLocation')
  IntColumn get toLocationId => integer().references(Locations, #id)();
  DateTimeColumn get transferDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text()(); // PENDING, COMPLETED
  IntColumn get createdBy => integer().references(Users, #id)();
}

class StockTransferItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transferId => integer().references(StockTransfers, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
}

// INVENTORY TABLES
class StockTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get type => text()();
  IntColumn get quantity => integer()();
  IntColumn get previousStock => integer()();
  IntColumn get newStock => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get reason => text().nullable()();
}

// PURCHASE TABLES
class PurchaseOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderNumber => text().unique()();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  DateTimeColumn get orderDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text()(); // DRAFT, PENDING, RECEIVED, CANCELLED
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  IntColumn get createdBy => integer().references(Users, #id)();
}

class PurchaseItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseOrderId => integer().references(PurchaseOrders, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
  IntColumn get receivedQuantity => integer().withDefault(const Constant(0))();
  RealColumn get unitPrice => real()();
}

// SALES TABLES
class SalesOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text().unique()();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  DateTimeColumn get saleDate => dateTime().withDefault(currentDateAndTime)();
  RealColumn get totalAmount => real()();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get profitAmount => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('COMPLETED'))(); // COMPLETED, HOLD, CANCELLED
  IntColumn get createdBy => integer().references(Users, #id)();
}

class SalesItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get salesOrderId => integer().references(SalesOrders, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get purchasePrice => real().withDefault(const Constant(0.0))(); // Cost price at time of sale
  RealColumn get subtotal => real()();
}

class Returns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get referenceType => text()(); // SALE, PURCHASE
  IntColumn get referenceId => integer()();
  DateTimeColumn get returnDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get reason => text().nullable()();
  IntColumn get createdBy => integer().references(Users, #id)();
}

class ReturnItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get returnId => integer().references(Returns, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
}

// OTHER TABLES
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get referenceType => text()(); // SALE, PURCHASE
  IntColumn get referenceId => integer()();
  RealColumn get amount => real()();
  TextColumn get method => text()();
  DateTimeColumn get paymentDate => dateTime().withDefault(currentDateAndTime)();
}

class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get action => text()();
  TextColumn get details => text().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError();
});
