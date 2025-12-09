import 'dart:typed_data';
import 'package:buy_app/services/addresses.dart';
import 'package:buy_app/models/models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

class PdfService {
  /// Generate PDF invoice for order
  static Future<Uint8List> generateInvoicePDF({
    required String customerName,
    required String customerEmail,
    required Address shippingAddress,
    required List<CartItem> orderedItems,
    required String orderId,
    required String paymentMethod,
    required String txnId,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // Load watermark and app icon images
    pw.ImageProvider? watermarkImage;
    pw.ImageProvider? appIconImage;

    try {
      final ByteData watermarkData = await rootBundle.load('Logo.png');
      watermarkImage = pw.MemoryImage(watermarkData.buffer.asUint8List());
    } catch (e) {
      // Watermark loading failed, continue without it
      print('Could not load watermark: $e');
    }

    try {
      final ByteData appIconData = await rootBundle.load('AppIcon.png');
      appIconImage = pw.MemoryImage(appIconData.buffer.asUint8List());
    } catch (e) {
      // App icon loading failed, continue without it
      print('Could not load app icon: $e');
    }

    // Calculate totals
    final subtotal = orderedItems.fold<double>(
      0,
      (sum, item) => sum + (item.effectivePrice) * (item.quantity),
    );
    final tax = 0.0; // No tax for now
    final deliveryFee = 0.0; // Free delivery
    final total = subtotal + tax + deliveryFee;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Background with watermark
            pw.Stack(
              children: [
                // Watermark (if available) - optimized smaller size
                if (watermarkImage != null)
                  pw.Positioned(
                    left: 200,
                    top: 300,
                    child: pw.Opacity(
                      opacity: 0.08,
                      child: pw.Image(watermarkImage, width: 200, height: 200),
                    ),
                  ),
                // Main content
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Invoice Header
                    pw.Container(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Row(
                                children: [
                                  // App Icon in top left
                                  if (appIconImage != null)
                                    pw.Container(
                                      width: 60,
                                      height: 60,
                                      decoration: pw.BoxDecoration(
                                        border: pw.Border.all(
                                          color: PdfColors.blue800,
                                          width: 2,
                                        ),
                                        borderRadius: pw.BorderRadius.circular(
                                          8,
                                        ),
                                      ),
                                      child: pw.ClipRRect(
                                        horizontalRadius: 6,
                                        verticalRadius: 6,
                                        child: pw.Image(
                                          appIconImage,
                                          fit: pw.BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  pw.SizedBox(width: 16),
                                  pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'INVOICE',
                                        style: pw.TextStyle(
                                          fontSize: 32,
                                          fontWeight: pw.FontWeight.bold,
                                          color: PdfColors.blue800,
                                        ),
                                      ),
                                      pw.SizedBox(height: 8),
                                      pw.Text(
                                        'Your Shopping App',
                                        style: pw.TextStyle(
                                          fontSize: 18,
                                          color: PdfColors.grey700,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.Text(
                                    'Invoice #: $orderId',
                                    style: pw.TextStyle(
                                      fontSize: 16,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    'Date: ${_formatInvoiceDate(now)}',
                                    style: const pw.TextStyle(fontSize: 12),
                                  ),
                                  pw.Text(
                                    'Due Date: ${_formatInvoiceDate(now.add(Duration(days: 4)))}',
                                    style: const pw.TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 40),

                          // Seller and Buyer Details Section
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              // Seller Details (Left)
                              pw.Expanded(
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.all(20),
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(
                                      color: PdfColors.blue800,
                                      width: 2,
                                    ),
                                    borderRadius: pw.BorderRadius.circular(12),
                                    color: PdfColors.blue50,
                                  ),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'SELLER DETAILS',
                                        style: pw.TextStyle(
                                          fontSize: 14,
                                          fontWeight: pw.FontWeight.bold,
                                          color: PdfColors.blue800,
                                        ),
                                      ),
                                      pw.SizedBox(height: 12),
                                      pw.Text(
                                        'Your Shopping App Pvt Ltd',
                                        style: pw.TextStyle(
                                          fontSize: 16,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.SizedBox(height: 6),
                                      pw.Text(
                                        'Business Address Line 1',
                                        style: const pw.TextStyle(fontSize: 12),
                                      ),
                                      pw.Text(
                                        'Business Address Line 2',
                                        style: const pw.TextStyle(fontSize: 12),
                                      ),
                                      pw.Text(
                                        'City, State - 123456',
                                        style: const pw.TextStyle(fontSize: 12),
                                      ),
                                      pw.SizedBox(height: 8),
                                      pw.Text(
                                        'Email: support@yourapp.com',
                                        style: const pw.TextStyle(fontSize: 11),
                                      ),
                                      pw.Text(
                                        'Phone: +91 12345 67890',
                                        style: const pw.TextStyle(fontSize: 11),
                                      ),
                                      pw.Text(
                                        'GSTIN: 12ABCDE3456F7G8',
                                        style: const pw.TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              pw.SizedBox(width: 20),

                              // Buyer Details (Right)
                              pw.Expanded(
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.all(20),
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(
                                      color: PdfColors.green800,
                                      width: 2,
                                    ),
                                    borderRadius: pw.BorderRadius.circular(12),
                                    color: PdfColors.green50,
                                  ),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'BUYER DETAILS',
                                        style: pw.TextStyle(
                                          fontSize: 14,
                                          fontWeight: pw.FontWeight.bold,
                                          color: PdfColors.green800,
                                        ),
                                      ),
                                      pw.SizedBox(height: 12),
                                      pw.Text(
                                        customerName,
                                        style: pw.TextStyle(
                                          fontSize: 16,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.SizedBox(height: 6),
                                      pw.Text(
                                        customerEmail,
                                        style: const pw.TextStyle(
                                          fontSize: 12,
                                          color: PdfColors.blue700,
                                        ),
                                      ),
                                      pw.SizedBox(height: 8),
                                      pw.Text(
                                        'SHIPPING ADDRESS:',
                                        style: pw.TextStyle(
                                          fontSize: 11,
                                          fontWeight: pw.FontWeight.bold,
                                          color: PdfColors.green800,
                                        ),
                                      ),
                                      pw.SizedBox(height: 4),
                                      pw.Text(
                                        '${shippingAddress.first} ${shippingAddress.last}',
                                        style: pw.TextStyle(
                                          fontSize: 12,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.Text(
                                        '${shippingAddress.line1}',
                                        style: const pw.TextStyle(fontSize: 11),
                                      ),
                                      if (shippingAddress.line2.isNotEmpty)
                                        pw.Text(
                                          '${shippingAddress.line2}',
                                          style: const pw.TextStyle(
                                            fontSize: 11,
                                          ),
                                        ),
                                      pw.Text(
                                        '${shippingAddress.city}, ${shippingAddress.state} - ${shippingAddress.pincode}',
                                        style: const pw.TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 30),

                          // Payment Information Banner
                          pw.Container(
                            width: double.infinity,
                            padding: const pw.EdgeInsets.all(16),
                            decoration: pw.BoxDecoration(
                              color:
                                  paymentMethod.toLowerCase().contains('cash')
                                  ? PdfColors.orange50
                                  : PdfColors.green50,
                              border: pw.Border.all(
                                color:
                                    paymentMethod.toLowerCase().contains('cash')
                                    ? PdfColors.orange
                                    : PdfColors.green,
                                width: 2,
                              ),
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'PAYMENT INFORMATION',
                                      style: pw.TextStyle(
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.bold,
                                        color:
                                            paymentMethod
                                                .toLowerCase()
                                                .contains('cash')
                                            ? PdfColors.orange800
                                            : PdfColors.green800,
                                      ),
                                    ),
                                    pw.SizedBox(height: 4),
                                    pw.Text(
                                      'Method: $paymentMethod',
                                      style: const pw.TextStyle(fontSize: 12),
                                    ),
                                    if (txnId != 'N/A')
                                      pw.Text(
                                        'Transaction ID: $txnId',
                                        style: const pw.TextStyle(fontSize: 11),
                                      ),
                                  ],
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    color:
                                        paymentMethod.toLowerCase().contains(
                                          'cash',
                                        )
                                        ? PdfColors.orange
                                        : PdfColors.green,
                                    borderRadius: pw.BorderRadius.circular(20),
                                  ),
                                  child: pw.Text(
                                    paymentMethod.toLowerCase().contains('cash')
                                        ? 'Pay on Delivery'
                                        : 'PAID',
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Product Information Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue800,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'PRODUCT INFORMATION',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 10),

            // Enhanced Items Table
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue800, width: 2),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Table(
                border: pw.TableBorder.symmetric(
                  inside: pw.BorderSide(color: PdfColors.grey300),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5), // S.No.
                  1: const pw.FlexColumnWidth(3.5), // Product Description
                  2: const pw.FlexColumnWidth(1), // Quantity
                  3: const pw.FlexColumnWidth(1.5), // Unit Price
                  4: const pw.FlexColumnWidth(1.5), // Total Amount
                },
                children: [
                  // Enhanced Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue800,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text(
                          'S.No.',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text(
                          'PRODUCT DESCRIPTION',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text(
                          'QTY',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text(
                          'UNIT PRICE',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text(
                          'TOTAL',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),

                  // Enhanced Items with serial numbers and better styling
                  ...orderedItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final itemTotal = (item.effectivePrice) * (item.quantity);
                    final isEvenRow = index % 2 == 0;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEvenRow ? PdfColors.blue50 : PdfColors.white,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Text(
                            '${index + 1}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                item.product.name,
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              if (item.product.brand.isNotEmpty)
                                pw.Text(
                                  'Brand: ${item.product.brand}',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              if (item.product.category.isNotEmpty)
                                pw.Text(
                                  'Category: ${item.product.category}',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              // Add variant details if selected
                              if (item.selectedVariantId != null &&
                                  item.selectedAttributes != null &&
                                  item.selectedAttributes!.isNotEmpty)
                                pw.Container(
                                  margin: const pw.EdgeInsets.only(top: 6),
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.orange50,
                                    borderRadius: pw.BorderRadius.circular(3),
                                    border: pw.Border.all(
                                      color: PdfColors.orange300,
                                    ),
                                  ),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'Variant Details:',
                                        style: pw.TextStyle(
                                          fontSize: 9,
                                          fontWeight: pw.FontWeight.bold,
                                          color: PdfColors.orange900,
                                        ),
                                      ),
                                      ...item.selectedAttributes!.entries.map((
                                        entry,
                                      ) {
                                        return pw.Text(
                                          '${entry.key}: ${entry.value}',
                                          style: pw.TextStyle(
                                            fontSize: 9,
                                            color: PdfColors.orange900,
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.blue100,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              '${item.quantity}',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Text(
                            'Rs. ${item.effectivePrice.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Text(
                            'Rs. ${itemTotal.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Enhanced Totals Section
            pw.Row(
              children: [
                pw.Expanded(child: pw.Container()),
                pw.Container(
                  width: 300,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue800, width: 2),
                    borderRadius: pw.BorderRadius.circular(12),
                    color: PdfColors.blue50,
                  ),
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'INVOICE SUMMARY',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      _buildInvoiceTotalRow(
                        'Subtotal:',
                        'Rs. ${subtotal.toStringAsFixed(2)}',
                      ),
                      _buildInvoiceTotalRow(
                        'Tax (GST):',
                        tax == 0 ? 'N/A' : 'Rs. ${tax.toStringAsFixed(2)}',
                      ),
                      _buildInvoiceTotalRow(
                        'Delivery Fee:',
                        deliveryFee == 0
                            ? 'FREE'
                            : 'Rs. ${deliveryFee.toStringAsFixed(2)}',
                        valueColor: PdfColors.green700,
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 8),
                        child: pw.Divider(
                          thickness: 2,
                          color: PdfColors.blue800,
                        ),
                      ),
                      _buildInvoiceTotalRow(
                        'GRAND TOTAL:',
                        'Rs. ${total.toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 40),

            // Terms and Notes
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TERMS & CONDITIONS',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  pw.Text(
                    '1) For COD orders, payment is collected at the time of delivery.',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '2) Returns are accepted within 7 days of delivery.',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Footer
            pw.Center(
              child: pw.Text(
                'Generated on ${_formatInvoiceDate(now)} | Invoice #$orderId',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Build a row for invoice totals section
  static pw.Widget _buildInvoiceTotalRow(
    String label,
    String value, {
    bool isTotal = false,
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 16 : 12,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isTotal ? PdfColors.blue800 : PdfColors.grey700,
            ),
          ),
          pw.Container(
            padding: isTotal
                ? const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                : const pw.EdgeInsets.all(0),
            decoration: isTotal
                ? pw.BoxDecoration(
                    color: PdfColors.blue800,
                    borderRadius: pw.BorderRadius.circular(8),
                  )
                : null,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: isTotal ? 16 : 12,
                fontWeight: pw.FontWeight.bold,
                color: isTotal
                    ? PdfColors.white
                    : valueColor ?? PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format date for invoice display
  static String _formatInvoiceDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
