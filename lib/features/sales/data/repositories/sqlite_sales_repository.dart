import 'package:drift/drift.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/sales/domain/models/sales_order.dart' as model;
import 'package:inventory_system_software/features/sales/domain/repositories/sales_repository.dart';

class SqliteSalesRepository implements SalesRepository {
  final AppDatabase _db;

  SqliteSalesRepository(this._db);

  // We define these as constants to ensure identical SQL generation and reading
  static const _taxCol = CustomExpression<double>('sales_orders.tax_amount');
  static const _discountCol = CustomExpression<double>('sales_orders.discount_amount');
  static const _profitCol = CustomExpression<double>('sales_orders.profit_amount');
  static const _statusCol = CustomExpression<String>('sales_orders.status');
  static const _purchasePriceCol = CustomExpression<double>('sales_items.purchase_price');

  @override
  Future<List<model.SalesOrder>> getAllSales({String? status}) async {
    var query = _db.select(_db.salesOrders).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.salesOrders.customerId)),
    ]);

    // Force inclusion of columns that might be missing from stale generated code
    query.addColumns([_taxCol, _discountCol, _profitCol, _statusCol]);

    if (status != null) {
      query.where(_statusCol.equals(status));
    }

    final rows = await query.get();
    return rows.map((row) {
      final order = row.readTable(_db.salesOrders);
      final customer = row.readTableOrNull(_db.customers);
      
      return model.SalesOrder(
        id: order.id,
        invoiceNumber: order.invoiceNumber,
        customerId: order.customerId,
        customerName: customer?.name,
        customerPhone: customer?.phone,
        saleDate: order.saleDate,
        totalAmount: order.totalAmount,
        taxAmount: row.read<double>(_taxCol) ?? 0.0,
        discountAmount: row.read<double>(_discountCol) ?? 0.0,
        profitAmount: row.read<double>(_profitCol) ?? 0.0,
        status: row.read<String>(_statusCol) ?? 'COMPLETED',
        createdBy: order.createdBy,
      );
    }).toList();
  }

  @override
  Future<model.SalesOrder?> getSaleById(int id) async {
    final query = _db.select(_db.salesOrders).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.salesOrders.customerId)),
    ])..where(_db.salesOrders.id.equals(id));

    query.addColumns([_taxCol, _discountCol, _profitCol, _statusCol]);

    final orderRow = await query.getSingleOrNull();

    if (orderRow == null) return null;

    final order = orderRow.readTable(_db.salesOrders);
    final customer = orderRow.readTableOrNull(_db.customers);

    final itemsQuery = _db.select(_db.salesItems).join([
      innerJoin(_db.products, _db.products.id.equalsExp(_db.salesItems.productId)),
    ])..where(_db.salesItems.salesOrderId.equals(id));

    itemsQuery.addColumns([_purchasePriceCol]);

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
        purchasePrice: row.read<double>(_purchasePriceCol) ?? 0.0,
        subtotal: item.subtotal,
      );
    }).toList();

    return model.SalesOrder(
      id: order.id,
      invoiceNumber: order.invoiceNumber,
      customerId: order.customerId,
      customerName: customer?.name,
      customerPhone: customer?.phone,
      saleDate: order.saleDate,
      totalAmount: order.totalAmount,
      taxAmount: orderRow.read<double>(_taxCol) ?? 0.0,
      discountAmount: orderRow.read<double>(_discountCol) ?? 0.0,
      profitAmount: orderRow.read<double>(_profitCol) ?? 0.0,
      status: orderRow.read<String>(_statusCol) ?? 'COMPLETED',
      createdBy: order.createdBy,
      items: items,
    );
  }

  @override
  Future<int> createSale({
    int? customerId,
    required List<SalesItemDraft> items,
    required int userId,
    double taxAmount = 0.0,
    double discountAmount = 0.0,
    String status = 'COMPLETED',
  }) async {
    if (items.isEmpty) {
      throw Exception('Cannot create sale order without items.');
    }

    return await _db.transaction(() async {
      // 1. Stock Validation for ALL items prior to processing (only if status is COMPLETED)
      if (status == 'COMPLETED') {
        for (final item in items) {
          final product = await (_db.select(_db.products)..where((t) => t.id.equals(item.productId))).getSingleOrNull();
          if (product == null) throw Exception('Product ID ${item.productId} not found.');
          if (item.quantity <= 0) throw Exception('Sale quantity for product "${product.name}" must be greater than zero.');
          if (product.currentStock < item.quantity) {
            throw Exception('Insufficient stock for product "${product.name}". Available: ${product.currentStock}, Requested: ${item.quantity}.');
          }
        }
      }

      // 2. Calculate Totals & Profit
      double subtotal = items.fold<double>(0.0, (double sum, item) => sum + (item.quantity * item.unitPrice));
      double totalAmount = subtotal + taxAmount - discountAmount;
      double totalProfit = items.fold<double>(0.0, (double sum, item) => sum + ((item.unitPrice - item.purchasePrice) * item.quantity)) - discountAmount;

      // 3. Create Sale Order Record
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      
      final int orderId = await _db.into(_db.salesOrders).insert(
        RawValuesInsertable({
          'invoice_number': Variable<String>(invoiceNumber),
          'customer_id': Variable<int>(customerId),
          'sale_date': Variable<DateTime>(DateTime.now()),
          'total_amount': Variable<double>(totalAmount),
          'tax_amount': Variable<double>(taxAmount),
          'discount_amount': Variable<double>(discountAmount),
          'profit_amount': Variable<double>(totalProfit),
          'status': Variable<String>(status),
          'created_by': Variable<int>(userId),
        }),
      );

      // 4. Process items and deduct stock (if COMPLETED)
      for (final item in items) {
        await _db.into(_db.salesItems).insert(
          RawValuesInsertable({
            'sales_order_id': Variable<int>(orderId),
            'product_id': Variable<int>(item.productId),
            'quantity': Variable<int>(item.quantity),
            'unit_price': Variable<double>(item.unitPrice),
            'purchase_price': Variable<double>(item.purchasePrice),
            'subtotal': Variable<double>(item.quantity * item.unitPrice),
          }),
        );

        if (status == 'COMPLETED') {
          final product = await (_db.select(_db.products)..where((t) => t.id.equals(item.productId))).getSingle();
          final prevStock = product.currentStock;
          final nextStock = prevStock - item.quantity;

          await (_db.update(_db.products)..where((t) => t.id.equals(item.productId))).write(
            ProductsCompanion(currentStock: Value(nextStock)),
          );

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
      }

      // 5. Audit Log entry
      await _db.into(_db.auditLogs).insert(
        AuditLogsCompanion.insert(
          userId: userId,
          action: 'CREATE_SALE',
          details: Value('Created $status sale order $invoiceNumber (Total: ₹${totalAmount.toStringAsFixed(2)})'),
        ),
      );

      return orderId;
    });
  }

  @override
  Future<void> updateSaleStatus(int id, String status) async {
    final existing = await getSaleById(id);
    if (existing == null) return;
    if (existing.status == status) return;

    await _db.transaction(() async {
      // If moving from HOLD to COMPLETED, deduct stock
      if (existing.status == 'HOLD' && status == 'COMPLETED') {
        for (final item in existing.items) {
          final product = await (_db.select(_db.products)..where((t) => t.id.equals(item.productId))).getSingle();
          if (product.currentStock < item.quantity) {
             throw Exception('Insufficient stock for product "${product.name}" to complete the held sale.');
          }
          
          final prevStock = product.currentStock;
          final nextStock = prevStock - item.quantity;

          await (_db.update(_db.products)..where((t) => t.id.equals(item.productId))).write(
            ProductsCompanion(currentStock: Value(nextStock)),
          );

          await _db.into(_db.stockTransactions).insert(
            StockTransactionsCompanion.insert(
              productId: item.productId,
              type: 'SALE',
              quantity: item.quantity,
              previousStock: prevStock,
              newStock: nextStock,
              userId: existing.createdBy, // Ideally current user
              reason: Value('Completed held sale $id'),
            ),
          );
        }
      }

      await (_db.update(_db.salesOrders)..where((t) => t.id.equals(id))).write(
        RawValuesInsertable({
          'status': Variable<String>(status),
        }),
      );
    });
  }
}

// Helper class to handle inserts/updates for columns that aren't in the generated classes yet
class RawValuesInsertable<T> implements Insertable<T> {
  final Map<String, Expression> columns;
  RawValuesInsertable(this.columns);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) => columns;
}
