import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../colorPallete/color_pallete.dart';

class OrderDetailsPage extends StatelessWidget {
  final Order order;

  const OrderDetailsPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        backgroundColor: ColorPallete.color1,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(),
            const SizedBox(height: 20),
            _buildOrderStatus(),
            const SizedBox(height: 20),
            _buildDeliveryInfo(),
            const SizedBox(height: 20),
            _buildPaymentInfo(),
            const SizedBox(height: 20),
            _buildOrderItems(),
            const SizedBox(height: 20),
            _buildPricingSummary(),
            const SizedBox(height: 30),
            _buildInvoiceInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: ColorPallete.color1),
                const SizedBox(width: 8),
                Text(
                  'Order Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPallete.color1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Order ID', order.orderId),
            _buildInfoRow('Order Date', _formatDateTime(order.orderDate)),
            _buildInfoRow('Total Items', '${order.items.length}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: ColorPallete.color1),
                const SizedBox(width: 8),
                Text(
                  'Order Status Timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPallete.color1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final statuses = ['Confirmed', 'Packed', 'Shipped', 'Delivered'];
    // Determine current status based on days since order date
    final now = DateTime.now();
    final daysSinceOrder = now.difference(order.orderDate).inDays;

    int currentStatusIndex;
    if (daysSinceOrder >= 4) {
      currentStatusIndex = 3; // Delivered on/after day 4
    } else if (daysSinceOrder >= 2) {
      currentStatusIndex = 2; // Shipped on/after day 2
    } else if (daysSinceOrder >= 1) {
      currentStatusIndex = 1; // Packed on/after day 1
    } else {
      currentStatusIndex = 0; // Confirmed same day
    }

    return Column(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isCompleted = index <= currentStatusIndex;
        final isCurrent = index == currentStatusIndex;

        return Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? (isCurrent ? Colors.orange : Colors.green)
                    : Colors.grey.shade300,
                border: Border.all(
                  color: isCompleted
                      ? (isCurrent ? Colors.orange : Colors.green)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? Icon(
                      isCurrent ? Icons.access_time : Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                  color: isCompleted ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ),
            if (isCompleted && index < statuses.length - 1)
              Text(
                // Show expected dates: Confirmed(0), Packed(+1), Shipped(+2), Delivered(+4)
                _formatDateTime(
                  order.orderDate.add(Duration(days: [0, 1, 2, 4][index])),
                ),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDeliveryInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: ColorPallete.color1),
                const SizedBox(width: 8),
                Text(
                  'Delivery Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPallete.color1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${order.shippingAddress['first'] ?? ''} ${order.shippingAddress['last'] ?? ''}'
                        .trim(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.shippingAddress['line1'] ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (order.shippingAddress['line2']?.isNotEmpty == true) ...[
                    Text(
                      '${order.shippingAddress['line2']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${order.shippingAddress['city'] ?? ''}, ${order.shippingAddress['state'] ?? ''} - ${order.shippingAddress['pincode'] ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Expected Delivery',
              _formatDateTime(order.orderDate.add(const Duration(days: 4))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    // Determine if order is delivered based on days since order
    final now = DateTime.now();
    final daysSinceOrder = now.difference(order.orderDate).inDays;
    final isDelivered = daysSinceOrder >= 4;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: ColorPallete.color1),
                const SizedBox(width: 8),
                Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPallete.color1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Payment Method', order.paymentMethod),
            _buildInfoRow(
              'Payment Status',
              order.paymentMethod.toLowerCase().contains('cash')
                  ? (isDelivered ? 'Paid' : 'Pay on Delivery')
                  : 'Paid',
            ),
            if (!order.paymentMethod.toLowerCase().contains('cash'))
              _buildInfoRow(
                'Transaction ID',
                'TXN${order.orderId.substring(4)}',
              ),
            _buildInfoRow(
              'Payment Date',
              order.paymentMethod.toLowerCase().contains('cash')
                  ? (isDelivered
                        ? _formatDateTime(
                            order.orderDate.add(Duration(days: 4)),
                          )
                        : 'On Delivery')
                  : _formatDateTime(order.orderDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_bag, color: ColorPallete.color1),
                const SizedBox(width: 8),
                Text(
                  'Order Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPallete.color1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...order.items.map((item) => _buildItemCard(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: ${item.quantity}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.productPrice.toStringAsFixed(2)} each',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${(item.productPrice * item.quantity).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorPallete.color1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSummary() {
    final subtotal = order.items.fold<double>(
      0,
      (sum, item) => sum + (item.productPrice * item.quantity),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: ColorPallete.color1),
                const SizedBox(width: 8),
                Text(
                  'Price Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPallete.color1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
            _buildPriceRow('Delivery Charges', 'FREE'),
            _buildPriceRow('Taxes & Fees', '₹0.00'),
            const Divider(thickness: 1),
            _buildPriceRow(
              'Total Amount',
              '₹${order.totalAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
            if (order.paymentMethod != 'COD') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Completed',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? ColorPallete.color1 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'packed':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
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

    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInvoiceInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: ColorPallete.color1),
                const SizedBox(width: 8),
                Text(
                  'Invoice Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPallete.color1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice Sent Automatically',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A detailed PDF invoice was automatically sent to your registered email address when this order was placed.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Invoice ID', 'INV-${order.orderId}'),
            _buildInfoRow('Sent to Email', order.customerEmail),
            _buildInfoRow('Invoice Date', _formatDateTime(order.orderDate)),
          ],
        ),
      ),
    );
  }
}
