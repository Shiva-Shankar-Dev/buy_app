import 'package:flutter/material.dart';
import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:buy_app/services/simple_order_service.dart';
import 'package:intl/intl.dart';

class OrderDetailPage extends StatefulWidget {
  final SimpleOrder order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late SimpleOrder order;

  @override
  void initState() {
    super.initState();
    order = widget.order;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = order.details['items'] as List<dynamic>? ?? [];
    final shippingAddress =
        order.details['shippingAddress'] as Map<String, dynamic>? ?? {};
    final paymentMethod = order.details['paymentMethod'] ?? 'N/A';
    final txnId = order.details['txnId'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        backgroundColor: colorPallete.color1,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Order Status Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorPallete.color1,
                    colorPallete.color1.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(order.status),
                      color: _getStatusColor(order.status),
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Order ${order.status}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Order #${order.id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Placed on ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Order Items
            _buildSection(
              title: 'Order Items',
              icon: Icons.shopping_bag,
              child: Column(
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildOrderItem(item, index < items.length - 1);
                }).toList(),
              ),
            ),

            // Order Summary
            _buildSection(
              title: 'Order Summary',
              icon: Icons.receipt,
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Subtotal',
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                  ),
                  _buildSummaryRow('Delivery', 'Free'),
                  _buildSummaryRow('Tax', 'Included'),
                  Divider(thickness: 1),
                  _buildSummaryRow(
                    'Total Amount',
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),

            // Payment Information
            _buildSection(
              title: 'Payment Information',
              icon: Icons.payment,
              child: Column(
                children: [
                  _buildInfoRow('Payment Method', paymentMethod),
                  if (txnId != 'N/A') _buildInfoRow('Transaction ID', txnId),
                  _buildInfoRow('Payment Status', 'Completed'),
                ],
              ),
            ),

            // Shipping Address
            if (shippingAddress.isNotEmpty)
              _buildSection(
                title: 'Shipping Address',
                icon: Icons.location_on,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${shippingAddress['first'] ?? ''} ${shippingAddress['last'] ?? ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${shippingAddress['line1'] ?? ''}\n'
                      '${shippingAddress['line2'] ?? ''}\n'
                      '${shippingAddress['city'] ?? ''}, ${shippingAddress['state'] ?? ''}\n'
                      'PIN: ${shippingAddress['pincode'] ?? ''}',
                      style: TextStyle(color: Colors.grey[700], height: 1.5),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 20),

            // Action Buttons
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  if (order.status.toLowerCase() == 'confirmed' ||
                      order.status.toLowerCase() == 'processing')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showCancelOrderDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        _showOrderTrackingDialog();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorPallete.color1),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Track Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorPallete.color1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'processing':
        return Icons.sync;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorPallete.color1),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item, bool showDivider) {
    return Column(
      children: [
        Row(
          children: [
            // Product Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child:
                  item['images'] != null && (item['images'] as List).isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        (item['images'] as List)[0],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : Icon(Icons.shopping_bag, color: Colors.grey),
            ),

            SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'Product',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Quantity: ${item['quantity'] ?? 1}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '₹${(item['price'] ?? 0).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorPallete.color1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          SizedBox(height: 12),
          Divider(),
          SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? colorPallete.color1 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order'),
        content: Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Order'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await SimpleOrderService.updateOrderStatus(
                order.id,
                'Cancelled',
              );

              if (success) {
                setState(() {
                  order = SimpleOrder(
                    id: order.id,
                    customerEmail: order.customerEmail,
                    customerName: order.customerName,
                    totalAmount: order.totalAmount,
                    status: 'Cancelled',
                    createdAt: order.createdAt,
                    details: order.details,
                  );
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order cancelled successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Cancel Order', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showOrderTrackingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Tracking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Track your order with ID:'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                order.id.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Order tracking feature will be available soon!',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
