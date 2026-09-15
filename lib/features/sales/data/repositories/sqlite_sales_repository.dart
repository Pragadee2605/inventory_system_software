import 'package:drift/drift.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/sales/domain/models/sales_order.dart' as model;
import 'package:inventory_system_software/features/sales/domain/repositories/sales_repository.dart';

class SqliteSalesRepository implements SalesRepository {
  final AppDatabase _db;

  SqliteSalesRepository(this._db);

  @override
  Future<List<model.SalesOrder>> getAllSales() async {
    final query = _db.select(_db.salesOrders).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.salesOrders.customerId)),
    ]);

    final rows = await query.get();
    return rows.map((row) {
      final order = row.readTable(_db.salesOrders);
      final customer = row.readTableOrNull(_db.customers);
      return model.SalesOrder(
        id: order.id,
        invoiceNumber: order.invoiceNumber,
        customerId: order.customerId,
        customerName: customer?.name,
        saleDate: order.saleDate,
        totalAmount: order.totalAmount,
        createdBy: order.createdBy,
      );
    }).toList();
  }

  @override
  Future<model.SalesOrder?> getSaleById(int id) async {
    final orderRow = await (_db.select(_db.salesOrders).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.salesOrders.customerId)),
    ])..where(_db.salesOrders.id.equals(id))).getSingleOrNull();

    if (orderRow == null) return null;

    final order = orderRow.readTable(_db.salesOrders);
    final customer = orderRow.readTableOrNull(_db.customers);

    final itemsQuery = _db.select(_db.salesItems).join([
      innerJoin(_db.products, _db.products.id.equalsExp(_db.salesItems.productId)),
    ])..where(_db.salesItems.salesOrderId.equals(id));

    final itemRows = await itemsQuery.get();
    final items = itemRows.map((row) {
      final item = row.readTable(_db.salesItems);
      final product = row.readTable(_db.products);
      return model.SalesItem(
        id: item.id,
        productId: item.productId,
        productName: product.name,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        subtotal: item.subtotal,
      );
    }).toList();

    return model.SalesOrder(
      id: order.id,
      invoiceNumber: order.invoiceNumber,
      customerId: order.customerId,
      customerName: customer?.name,
      saleDate: order.saleDate,
      totalAmount: order.totalAmount,
      createdBy: order.createdBy,
      items: items,
    );
  }

  @override
  Future<int> createSale({
    int? customerId,
    required List<SalesItemDraft> items,
    required int userId,
  }) async {
    if (items.isEmpty) {
      throw Exception('Cannot create sale order without items.');
    }

    return await _db.transaction(() async {
      // 1. Stock Validation for ALL items prior to processing
      for (final item in items) {
        final product = await (_db.select(_db.products)..where((t) => t.id.equals(item.productId))).getSingleOrNull();
        if (product == null) {
          throw Exception('Product ID ${item.productId} not found.');
        }

        if (item.quantity <= 0) {
          throw Exception('Sale quantity for product "${product.name}" must be greater than zero.');
        }

        if (product.currentStock < item.quantity) {
          throw Exception('Insufficient stock for product "${product.name}". Available: ${product.currentStock}, Requested: ${item.quantity}.');
        }
      }

      // 2. Create Sale Order Record
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      double total = items.fold(0, (sum, item) => sum + (item.quantity * item.unitPrice));

      final orderId = await _db.into(_db.salesOrders).insert(
        SalesOrdersCompanion.insert(
          invoiceNumber: invoiceNumber,
          customerId: Value(customerId),
          saleDate: Value(DateTime.now()),
          totalAmount: total,
          createdBy: userId,
        ),
      );

      // 3. Process items and deduct stock
      for (final item in items) {
        await _db.into(_db.salesItems).insert(
          SalesItemsCompanion.insert(
            salesOrderId: orderId,
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            subtotal: item.quantity * item.unitPrice,
          ),
        );

        final product = await (_db.select(_db.products)..where((t) => t.id.equals(item.productId))).getSingle();
        final prevStock = product.currentStock;
        final nextStock = prevStock - item.quantity;

        await (_db.update(_db.products)..where((t) => t.id.equals(item.productId))).write(
          ProductsCompanion(currentStock: Value(nextStock)),
        );

        // Record Stock Transaction
        await _db.into(_db.stockTransactions).insert(
          StockTransactionsCompanion.insert(
            productId: item.productId,
            type: 'SALE',
            quantity: item.quantity,
            previousStock: prevStock,
            newStock: nextStock,
            userId: userId,
            reason: Value('Sale invoice $invoiceNumber'),
          ),
        );
      }

      // 4. Audit Log entry
      await _db.into(_db.auditLogs).insert(
        AuditLogsCompanion.insert(
          userId: userId,
          action: 'CREATE_SALE',
          details: Value('Created sale order $invoiceNumber (Total: \$${total.toStringAsFixed(2)})'),
        ),
      );

      return orderId;
    });
  }
}
