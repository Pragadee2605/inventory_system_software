import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inventory_system_software/features/sales/presentation/providers/sales_provider.dart';
import 'package:inventory_system_software/features/customers/presentation/providers/customer_provider.dart';
import 'package:inventory_system_software/features/products/presentation/providers/product_provider.dart';
import 'package:inventory_system_software/features/sales/domain/models/sales_order.dart';
import 'package:inventory_system_software/features/products/domain/models/product.dart';
import 'package:inventory_system_software/features/customers/domain/models/customer.dart';
import 'package:inventory_system_software/features/sales/domain/repositories/sales_repository.dart';
import 'package:inventory_system_software/core/services/barcode_scanner_service.dart';
import 'package:inventory_system_software/core/services/invoice_service.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesListProvider);
    final heldSalesAsync = ref.watch(heldSalesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales & Invoicing'),
        actions: [
          heldSalesAsync.when(
            data: (held) => held.isEmpty
                ? const SizedBox.shrink()
                : Badge(
                    label: Text('${held.length}'),
                    child: IconButton(
                      icon: const Icon(Icons.pause_circle_outline_rounded, color: Colors.orange),
                      tooltip: 'Recall Held Sales',
                      onPressed: () => _showRecallDialog(context, ref, held),
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showCreateSaleDialog(context, ref),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('New Sale'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: salesAsync.when(
        data: (List<SalesOrder> sales) => sales.isEmpty
            ? const Center(child: Text('No completed sales found.'))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: ListView.separated(
                    itemCount: sales.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final sale = sales[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade50,
                          child: const Icon(Icons.receipt_long_rounded, color: Colors.indigo),
                        ),
                        title: Text(sale.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${sale.customerName ?? "Walk-in"} | ${DateFormat('dd MMM yyyy HH:mm').format(sale.saleDate)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${sale.totalAmount.toStringAsFixed(2)}', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                                if (sale.profitAmount != 0)
                                  Text('Profit: ₹${sale.profitAmount.toStringAsFixed(2)}', 
                                    style: TextStyle(color: sale.profitAmount > 0 ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.print_rounded, size: 20, color: Colors.grey),
                              tooltip: 'Print Options',
                              onPressed: () => _showPrintOptions(context, sale),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showRecallDialog(BuildContext context, WidgetRef ref, List<SalesOrder> held) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Held Transactions'),
        content: SizedBox(
          width: 400,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: held.length,
            separatorBuilder: (context, _) => const Divider(),
            itemBuilder: (context, idx) {
              final sale = held[idx];
              return ListTile(
                title: Text(sale.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Items: ${sale.items.length} | Total: ₹${sale.totalAmount.toStringAsFixed(2)}'),
                trailing: FilledButton(
                  onPressed: () async {
                    await ref.read(salesListProvider.notifier).completeHeldSale(sale.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Checkout'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPrintOptions(BuildContext context, SalesOrder sale) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('INVOICE ACTIONS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: Colors.indigo),
                title: const Text('Generate A4 Invoice (PDF)', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  InvoiceService.printInvoice(sale, thermal: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.print_outlined, color: Colors.green),
                title: const Text('Print 80mm Thermal Receipt', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  InvoiceService.printInvoice(sale, thermal: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Colors.blue),
                title: const Text('Share via WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  InvoiceService.shareToWhatsApp(sale);
                },
              ),
              ListTile(
                leading: const Icon(Icons.send_to_mobile_rounded, color: Colors.teal),
                title: const Text('Send Directly to Customer WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Uses WhatsApp Business API', style: TextStyle(fontSize: 10)),
                enabled: sale.customerPhone != null,
                onTap: () async {
                  Navigator.pop(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Uploading invoice to WhatsApp...')));
                  
                  final success = await InvoiceService.sendDirectWhatsAppPdf(sale);
                  
                  if (success) {
                    scaffoldMessenger.showSnackBar(const SnackBar(
                      content: Text('Invoice sent directly to WhatsApp!'),
                      backgroundColor: Colors.green,
                    ));
                  } else {
                    scaffoldMessenger.showSnackBar(const SnackBar(
                      content: Text('Failed to send WhatsApp. Check API configuration.'),
                      backgroundColor: Colors.red,
                    ));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateSaleDialog(BuildContext context, WidgetRef ref) {
    int? selectedCustomerId;
    List<SalesItemDraft> cartItems = [];
    final formKey = GlobalKey<FormState>();
    final searchCustomerController = TextEditingController();
    final discountController = TextEditingController(text: '0');
    final taxController = TextEditingController(text: '0');
    final screenSize = MediaQuery.of(context).size;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final customersAsync = ref.watch(customerListProvider);
          final productsAsync = ref.watch(productListProvider);

          return customersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to load customers: $err'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
            ),
            data: (customers) => productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => AlertDialog(
                title: const Text('Error'),
                content: Text('Failed to load products: $err'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
              ),
              data: (products) => StatefulBuilder(
                builder: (context, setState) {
                  double subtotal = cartItems.fold(0, (sum, item) => sum + (item.quantity * item.unitPrice));
                  double discount = double.tryParse(discountController.text) ?? 0;
                  double taxPercent = double.tryParse(taxController.text) ?? 0;
                  double taxAmount = (subtotal - discount) * (taxPercent / 100);
                  double total = subtotal - discount + taxAmount;

                  final filteredCustomers = customers.where((c) {
                    final q = searchCustomerController.text.toLowerCase();
                    return c.name.toLowerCase().contains(q) || (c.phone?.contains(q) ?? false);
                  }).toList();

                  final selectedCustomer = selectedCustomerId != null 
                    ? customers.firstWhere((c) => c.id == selectedCustomerId) : null;

                  return AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.shopping_cart_checkout, color: Color(0xFF4F46E5)),
                        SizedBox(width: 12),
                        Text('New Sales Transaction'),
                      ],
                    ),
                    content: Container(
                      width: screenSize.width * 0.9,
                      height: screenSize.height * 0.9,
                      constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 850),
                      child: Form(
                        key: formKey,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT COLUMN: Cart Items
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('CART ITEMS',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: cartItems.isEmpty
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.add_shopping_cart_rounded, size: 64, color: Colors.grey.shade300),
                                                const SizedBox(height: 16),
                                                const Text('Cart is empty. Scan products to add.', style: TextStyle(color: Colors.grey)),
                                              ],
                                            ),
                                          )
                                        : ListView.separated(
                                            itemCount: cartItems.length,
                                            separatorBuilder: (context, index) => const Divider(height: 1),
                                            itemBuilder: (context, idx) {
                                              final item = cartItems[idx];
                                              final prod = products.firstWhere((p) => p.id == item.productId);
                                              return ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                subtitle:
                                                    Text('Unit Price: ₹${item.unitPrice.toStringAsFixed(2)} | Stock: ${prod.currentStock}'),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                                      onPressed: () {
                                                        setState(() {
                                                          if (item.quantity > 1) {
                                                            cartItems[idx] = SalesItemDraft(
                                                              productId: item.productId,
                                                              quantity: item.quantity - 1,
                                                              unitPrice: item.unitPrice,
                                                              purchasePrice: item.purchasePrice,
                                                            );
                                                          } else {
                                                            cartItems.removeAt(idx);
                                                          }
                                                        });
                                                      },
                                                    ),
                                                    SizedBox(
                                                      width: 40,
                                                      child: Text('${item.quantity}',
                                                          textAlign: TextAlign.center,
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                                      onPressed: () {
                                                        if (item.quantity < prod.currentStock) {
                                                          setState(() {
                                                            cartItems[idx] = SalesItemDraft(
                                                              productId: item.productId,
                                                              quantity: item.quantity + 1,
                                                              unitPrice: item.unitPrice,
                                                              purchasePrice: item.purchasePrice,
                                                            );
                                                          });
                                                        } else {
                                                          ScaffoldMessenger.of(context)
                                                              .showSnackBar(const SnackBar(content: Text('Cannot exceed available stock')));
                                                        }
                                                      },
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text('₹${(item.quantity * item.unitPrice).toStringAsFixed(2)}',
                                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                      onPressed: () => setState(() => cartItems.removeAt(idx)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  const Divider(height: 32),
                                  // SUMMARY & CONTROLS
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextFormField(
                                                    controller: discountController,
                                                    decoration: const InputDecoration(labelText: 'Discount (₹)', isDense: true, border: OutlineInputBorder()),
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (_) => setState(() {}),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: TextFormField(
                                                    controller: taxController,
                                                    decoration: const InputDecoration(labelText: 'Tax (%)', isDense: true, border: OutlineInputBorder()),
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (_) => setState(() {}),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.indigo.shade100),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('Subtotal: ₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                                            Text('Tax: ₹${taxAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                                            const Text('TOTAL PAYABLE',
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5), letterSpacing: 0.5)),
                                            Text('₹${total.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      FilledButton.icon(
                                        onPressed: () async {
                                          final messenger = ScaffoldMessenger.of(context);
                                          final scanned = await BarcodeScannerService.scanBarcode(context);
                                          if (scanned == null) return;
                                          final prod = await ref.read(productRepositoryProvider).getProductByBarcode(scanned);
                                          if (prod == null) {
                                            messenger.showSnackBar(const SnackBar(content: Text('Product not found in system.')));
                                            return;
                                          }
                                          if (context.mounted) {
                                            _updateCartWithProduct(prod, cartItems, setState, messenger);
                                          }
                                        },
                                        icon: const Icon(Icons.qr_code_scanner_rounded),
                                        label: const Text('Scan Product'),
                                        style: FilledButton.styleFrom(
                                            backgroundColor: const Color(0xFF4F46E5),
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20)),
                                      ),
                                      const Spacer(),
                                      OutlinedButton.icon(
                                        onPressed: cartItems.isEmpty ? null : () async {
                                          await ref.read(salesListProvider.notifier).createSale(
                                            customerId: selectedCustomerId,
                                            items: cartItems,
                                            taxAmount: taxAmount,
                                            discountAmount: discount,
                                            status: 'HOLD',
                                          );
                                          if (context.mounted) Navigator.pop(context);
                                        },
                                        icon: const Icon(Icons.pause_circle_outline_rounded),
                                        label: const Text('Hold Bill'),
                                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const VerticalDivider(width: 48),
                            // RIGHT COLUMN: Customer & Quick Search
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('CUSTOMER SELECTION',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
                                      IconButton(
                                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20, color: Color(0xFF4F46E5)),
                                        tooltip: 'Quick Add Customer',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showQuickAddCustomer(
                                          context, 
                                          ref, 
                                          (newId) {
                                            if (context.mounted) {
                                              setState(() => selectedCustomerId = newId);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (selectedCustomer != null)
                                    _buildCustomerIntelligence(selectedCustomer),
                                  TextField(
                                    controller: searchCustomerController,
                                    decoration: const InputDecoration(
                                      hintText: 'Search Name or Phone...',
                                      prefixIcon: Icon(Icons.search),
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade200),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListView(
                                        children: [
                                          RadioListTile<int?>(
                                            title: const Text('Walk-in Customer'),
                                            value: null,
                                            groupValue: selectedCustomerId,
                                            onChanged: (v) => setState(() => selectedCustomerId = v),
                                          ),
                                          ...filteredCustomers.map((c) => RadioListTile<int?>(
                                                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                subtitle: Text(c.phone ?? c.email ?? ''),
                                                value: c.id,
                                                groupValue: selectedCustomerId,
                                                onChanged: (v) => setState(() => selectedCustomerId = v),
                                              )),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text('QUICK PRODUCT ADD',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade200),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListView.separated(
                                        itemCount: products.length,
                                        separatorBuilder: (context, index) => const Divider(height: 1),
                                        itemBuilder: (context, idx) {
                                          final p = products[idx];
                                          return ListTile(
                                            dense: true,
                                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            subtitle: Text('Stock: ${p.currentStock}'),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF4F46E5)),
                                              onPressed: () =>
                                                  _updateCartWithProduct(p, cartItems, setState, ScaffoldMessenger.of(context)),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      FilledButton(
                        onPressed: cartItems.isEmpty
                            ? null
                            : () async {
                                final notifier = ref.read(salesListProvider.notifier);
                                final orderId = await notifier.createSale(
                                      customerId: selectedCustomerId,
                                      items: cartItems,
                                      taxAmount: taxAmount,
                                      discountAmount: discount,
                                      status: 'COMPLETED',
                                    );
                                
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  if (orderId != null) {
                                     final order = await ref.read(salesRepositoryProvider).getSaleById(orderId);
                                     if (order != null && context.mounted) {
                                       _showPrintOptions(context, order);
                                     }
                                  }
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        ),
                        child: const Text('Complete & Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerIntelligence(Customer customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, size: 14, color: Colors.indigo),
              const SizedBox(width: 6),
              Text('CUSTOMER INSIGHTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(customer.phone ?? "No phone recorded", style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  void _updateCartWithProduct(Product prod, List<SalesItemDraft> cartItems, StateSetter setState, ScaffoldMessengerState messenger) {
    final existingIndex = cartItems.indexWhere((c) => c.productId == prod.id);
    if (existingIndex >= 0) {
      final existing = cartItems[existingIndex];
      final newQty = existing.quantity + 1;
      if (newQty > prod.currentStock) {
        messenger.showSnackBar(SnackBar(content: Text('Insufficient stock for ${prod.name}. Available: ${prod.currentStock}')));
        return;
      }
      setState(() => cartItems[existingIndex] = SalesItemDraft(
        productId: existing.productId, 
        quantity: newQty, 
        unitPrice: existing.unitPrice,
        purchasePrice: existing.purchasePrice,
      ));
    } else {
      if (prod.currentStock <= 0) {
        messenger.showSnackBar(SnackBar(content: Text('Insufficient stock for ${prod.name}')));
        return;
      }
      setState(() => cartItems.add(SalesItemDraft(
        productId: prod.id, 
        quantity: 1, 
        unitPrice: prod.sellingPrice,
        purchasePrice: prod.purchasePrice,
      )));
    }
  }

  void _showQuickAddCustomer(BuildContext context, WidgetRef ref, Function(int) onCreated) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Customer'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Customer Name *', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final customerId = await ref.read(customerListProvider.notifier).addCustomer(
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                    );
                if (customerId != null) {
                  onCreated(customerId);
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            child: const Text('Create & Select'),
          ),
        ],
      ),
    );
  }
}
