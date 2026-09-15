import 'package:drift/drift.dart';
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
  int get schemaVersion => 1;

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
    );
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
        fullName: 'Pragadees',
        passwordHash: PasswordService().hashPassword('Pragadees'),
        roleId: adminRole.id,
        status: const Value(UserStatus.active),
      ),
    );
    print('Default admin created: Pragadees / Pragadees');
  }

  Future<void> _seedDefaultRolesAndPermissions() async {
    final existingRoles = await select(roles).get();
    if (existingRoles.isEmpty) {
      await batch((batch) {
        batch.insertAll(roles, [
          RolesCompanion.insert(name: 'ADMIN', description: const Value('Administrator with full access')),
          RolesCompanion.insert(name: 'MANAGER', description: const Value('Manager with operational access')),
          RolesCompanion.insert(name: 'STAFF', description: const Value('Staff with basic access')),
          RolesCompanion.insert(name: 'VIEWER', description: const Value('Read-only access')),
        ]);
      });
    }

    final existingPermissions = await select(permissions).get();
    if (existingPermissions.isEmpty) {
      await batch((batch) {
        batch.insertAll(permissions, [
          PermissionsCompanion.insert(code: 'PRODUCT_VIEW', description: const Value('View products')),
          PermissionsCompanion.insert(code: 'PRODUCT_MANAGE', description: const Value('Manage products')),
          PermissionsCompanion.insert(code: 'STOCK_MANAGE', description: const Value('Manage stock')),
          PermissionsCompanion.insert(code: 'REPORT_VIEW', description: const Value('View reports')),
          PermissionsCompanion.insert(code: 'PURCHASE_MANAGE', description: const Value('Manage purchases')),
          PermissionsCompanion.insert(code: 'SALES_MANAGE', description: const Value('Manage sales')),
        ]);
      });
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
  IntColumn get createdBy => integer().references(Users, #id)();
}

class SalesItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get salesOrderId => integer().references(SalesOrders, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
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
