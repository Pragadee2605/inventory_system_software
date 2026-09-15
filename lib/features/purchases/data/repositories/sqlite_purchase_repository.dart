import 'package:drift/drift.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/purchases/domain/models/purchase_order.dart' as model;
import 'package:inventory_system_software/features/purchases/domain/repositories/purchase_repository.dart';

class SqlitePurchaseRepository implements PurchaseRepository {
  final AppDatabase _db;

  SqlitePurchaseRepository(this._db);

  @override
  Future<List<model.PurchaseOrder>> getAllPurchases() async {
    final query = _db.select(_db.purchaseOrders).join([
      innerJoin(_db.suppliers, _db.suppliers.id.equalsExp(_db.purchaseOrders.supplierId)),
    ]);

    final rows = await query.get();
    return rows.map((row) {
      final order = row.readTable(_db.purchaseOrders);
      final supplier = row.readTable(_db.suppliers);
      return model.PurchaseOrder(
        id: order.id,
        orderNumber: order.orderNumber,
        supplierId: order.supplierId,
        supplierName: supplier.name,
        orderDate: order.orderDate,
        status: order.status,
        totalAmount: order.totalAmount,
        createdBy: order.createdBy,
      );
    }).toList();
  }

  @override
  Future<model.PurchaseOrder?> getPurchaseById(int id) async {
    final orderRow = await (_db.select(_db.purchaseOrders).join([
      innerJoin(_db.suppliers, _db.suppliers.id.equalsExp(_db.purchaseOrders.supplierId)),
    ])..where(_db.purchaseOrders.id.equals(id))).getSingleOrNull();

    if (orderRow == null) return null;

    final order = orderRow.readTable(_db.purchaseOrders);
    final supplier = orderRow.readTable(_db.suppliers);

    final itemsQuery = _db.select(_db.purchaseItems).join([
      innerJoin(_db.products, _db.products.id.equalsExp(_db.purchaseItems.productId)),
    ])..where(_db.purchaseItems.purchaseOrderId.equals(id));

    final itemRows = await itemsQuery.get();
    final items = itemRows.map((row) {
      final item = row.readTable(_db.purchaseItems);
      final product = row.readTable(_db.products);
      return model.PurchaseItem(
        id: item.id,
        productId: item.productId,
        productName: product.name,
        quantity: item.quantity,
        receivedQuantity: item.receivedQuantity,
        unitPrice: item.unitPrice,
      );
    }).toList();

    return model.PurchaseOrder(
      id: order.id,
      orderNumber: order.orderNumber,
      supplierId: order.supplierId,
      supplierName: supplier.name,
      orderDate: order.orderDate,
      status: order.status,
      totalAmount: order.totalAmount,
      createdBy: order.createdBy,
      items: items,
    );
  }

  @override
  Future<int> createPurchase({
    required int supplierId,
    required List<PurchaseItemDraft> items,
    required int userId,
  }) async {
    return await _db.transaction(() async {
      final orderNumber = 'PO-${DateTime.now().millisecondsSinceEpoch}';
      double total = items.fold(0, (sum, item) => sum + (item.quantity * item.unitPrice));

      final orderId = await _db.into(_db.purchaseOrders).insert(
        PurchaseOrdersCompanion.insert(
          orderNumber: orderNumber,
          supplierId: supplierId,
          status: 'PENDING',
          totalAmount: Value(total),
          createdBy: userId,
        ),
      );

      for (final item in items) {
        await _db.into(_db.purchaseItems).insert(
          PurchaseItemsCompanion.insert(
            purchaseOrderId: orderId,
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
          ),
        );
      }
      return orderId;
    });
  }

  @override
  Future<void> receiveItems(int orderId, Map<int, int> receivedQuantities, int userId) async {
    await _db.transaction(() async {
      for (final entry in receivedQuantities.entries) {
        final itemId = entry.key;
        final newReceived = entry.value;

        final item = await (_db.select(_db.purchaseItems)..where((t) => t.id.equals(itemId))).getSingle();
        final totalReceived = item.receivedQuantity + newReceived;

        await (_db.update(_db.purchaseItems)..where((t) => t.id.equals(itemId))).write(
          PurchaseItemsCompanion(receivedQuantity: Value(totalReceived)),
        );

        // Update Product Stock
        final product = await (_db.select(_db.products)..where((t) => t.id.equals(item.productId))).getSingle();
        final prevStock = product.currentStock;
        final nextStock = prevStock + newReceived;

        await (_db.update(_db.products)..where((t) => t.id.equals(item.productId))).write(
          ProductsCompanion(currentStock: Value(nextStock)),
        );

        // Record Stock Transaction
        await _db.into(_db.stockTransactions).insert(
          StockTransactionsCompanion.insert(
            productId: item.productId,
            type: 'PURCHASE',
            quantity: newReceived,
            previousStock: prevStock,
            newStock: nextStock,
            userId: userId,
            reason: Value('Received from PO $orderId'),
          ),
        );
      }

      // Check if all received
      final allItems = await (_db.select(_db.purchaseItems)..where((t) => t.purchaseOrderId.equals(orderId))).get();
      bool allReceived = allItems.every((i) => i.receivedQuantity >= i.quantity);

      if (allReceived) {
        await (_db.update(_db.purchaseOrders)..where((t) => t.id.equals(orderId))).write(
          const PurchaseOrdersCompanion(status: Value('RECEIVED')),
        );
      }
    });
  }
}
