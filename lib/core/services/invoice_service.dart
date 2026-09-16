import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:inventory_system_software/features/sales/domain/models/sales_order.dart';
import 'package:url_launcher/url_launcher.dart';
import 'whatsapp_service.dart';

class InvoiceService {
  static const String businessName = "NEXUS PRO ENTERPRISE";
  static const String businessAddress = "123 Inventory St, Tech City, 56789";
  static const String businessPhone = "+91 98765 43210";

  /// Generates a professional A4 PDF Invoice
  static Future<Uint8List> generateA4Invoice(SalesOrder order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildHeader(order),
          pw.SizedBox(height: 20),
          _buildCustomerInfo(order),
          pw.SizedBox(height: 20),
          _buildInvoiceTable(order),
          pw.Divider(),
          _buildPriceTotals(order),
          pw.SizedBox(height: 40),
          _buildFooter(order),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generates a 80mm Thermal POS Receipt
  static Future<Uint8List> generateThermalReceipt(SalesOrder order) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(businessName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.Text(businessAddress, style: const pw.TextStyle(fontSize: 8)),
            pw.Text("Tel: $businessPhone", style: const pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 10),
            pw.Text("RECEIPT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.Divider(thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Inv: ${order.invoiceNumber}", style: const pw.TextStyle(fontSize: 8)),
                pw.Text(DateFormat('dd/MM/yy HH:mm').format(order.saleDate), style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Column(
              children: order.items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text("${item.productName} x${item.quantity}", style: const pw.TextStyle(fontSize: 9))),
                    pw.Text("₹${item.subtotal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              )).toList(),
            ),
            pw.Divider(thickness: 0.5),
            _buildThermalTotals(order),
            pw.SizedBox(height: 15),
            pw.Text("Thank you for your business!", style: const pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 5),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: "https://nexus-pro.com/verify/${order.invoiceNumber}",
              width: 40,
              height: 40,
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(SalesOrder order) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(businessName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: PdfColors.indigo900)),
            pw.Text(businessAddress),
            pw.Text("Contact: $businessPhone"),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text("INVOICE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 32, color: PdfColors.grey700)),
            pw.Text("Date: ${DateFormat('dd MMM yyyy').format(order.saleDate)}"),
            pw.Text("Invoice #: ${order.invoiceNumber}"),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildCustomerInfo(SalesOrder order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("BILL TO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey600, fontSize: 10)),
                pw.SizedBox(height: 4),
                pw.Text(order.customerName ?? "Walk-in Customer", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
               pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: "INV-${order.invoiceNumber}",
                width: 60,
                height: 60,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceTable(SalesOrder order) {
    return pw.TableHelper.fromTextArray(
      headers: ['Description', 'Qty', 'Unit Price', 'Total'],
      data: order.items.map((i) => [
        i.productName,
        i.quantity.toString(),
        "₹${i.unitPrice.toStringAsFixed(2)}",
        "₹${i.subtotal.toStringAsFixed(2)}"
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildPriceTotals(SalesOrder order) {
    final subtotal = order.totalAmount - order.taxAmount + order.discountAmount;
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 200,
        child: pw.Column(
          children: [
            _totalRow("Subtotal:", subtotal),
            _totalRow("Discount:", -order.discountAmount),
            _totalRow("Tax (GST):", order.taxAmount),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total Payable:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.Text("₹${order.totalAmount.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.indigo900)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildThermalTotals(SalesOrder order) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Tax:", style: const pw.TextStyle(fontSize: 9)),
            pw.Text("₹${order.taxAmount.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Discount:", style: const pw.TextStyle(fontSize: 9)),
            pw.Text("-₹${order.discountAmount.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("TOTAL:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.Text("₹${order.totalAmount.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _totalRow(String label, double amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text("₹${amount.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(SalesOrder order) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text("Terms and Conditions", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.Text("Goods once sold will not be taken back or exchanged. Warranty as per manufacturer policy.", 
          textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ],
    );
  }

  /// Sends a WhatsApp message with the order details
  static Future<void> shareToWhatsApp(SalesOrder order) async {
    final customerLabel = order.customerName != null ? "Customer: ${order.customerName}" : "Customer: Walk-in";
    
    final summary = "*Invoice: ${order.invoiceNumber}*\n"
        "$customerLabel\n"
        "Date: ${DateFormat('dd MMM yyyy').format(order.saleDate)}\n"
        "--------------------------\n"
        "Total Amount: *₹${order.totalAmount.toStringAsFixed(2)}*\n\n"
        "Thank you for shopping at Nexus Pro Enterprise!";
    
    final url = "https://wa.me/?text=${Uri.encodeComponent(summary)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  /// Sends the PDF directly using the WhatsApp Cloud API
  static Future<bool> sendDirectWhatsAppPdf(SalesOrder order) async {
    if (order.customerPhone == null || order.customerPhone!.isEmpty) {
      return false;
    }

    final pdfData = await generateA4Invoice(order);
    return await WhatsAppService.sendInvoicePdf(
      toNumber: order.customerPhone!,
      pdfBytes: pdfData,
      fileName: "${order.invoiceNumber}.pdf",
    );
  }

  /// Opens the print dialog for the generated document
  static Future<void> printInvoice(SalesOrder order, {bool thermal = false}) async {
    final data = thermal ? await generateThermalReceipt(order) : await generateA4Invoice(order);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => data);
  }
}
