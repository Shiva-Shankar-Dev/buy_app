import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../services/order_service.dart';
import '../../colorPallete/color_pallete.dart';

class OrderDetailsPage extends StatefulWidget {
  final Order order;

  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late Order currentOrder;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order;
    print('Order Details - Order ID: ${currentOrder.orderId}'); // Debug log
    print('Order Details - Status: ${currentOrder.status}'); // Debug log
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: ColorPallete.color1,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ColorPallete.color1, ColorPallete.color1.withAlpha(204)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ColorPallete.color1.withAlpha(13), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderHeader(),
              const SizedBox(height: 20),
              _buildOrderStatus(),
              const SizedBox(height: 20),
              _buildOrderActions(),
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
      ),
    );
  }

  Widget _buildOrderActions() {
    final status = currentOrder.status.toLowerCase();
    final canCancel = ['confirmed', 'packed'].contains(status);
    final canCancelWithFee = status == 'shipped';
    final canReturnReplace = status == 'delivered';

    if (!canCancel && !canCancelWithFee && !canReturnReplace) {
      return SizedBox.shrink();
    }

    return Card(
      elevation: 6,
      shadowColor: Colors.red.withAlpha(51),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.red.shade50.withAlpha(77)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.manage_accounts,
                    color: Colors.red.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Order Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cancellation Options
            if (canCancel || canCancelWithFee) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isProcessing
                        ? null
                        : () => _showCancellationDialog(canCancelWithFee),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isProcessing) ...[
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ] else ...[
                            Icon(
                              Icons.cancel_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            canCancelWithFee
                                ? 'Cancel Order (Charges Apply)'
                                : 'Cancel Order (Free)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Return/Replace Options
            if (canReturnReplace) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showReturnDialog(),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.keyboard_return,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Return',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showReplacementDialog(),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.swap_horizontal_circle,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Replace',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    // Use persisted order status directly (fallback to Confirmed)
    final String currentStatus = (currentOrder.status.isNotEmpty
        ? currentOrder.status
        : 'Confirmed');

    return Card(
      elevation: 8,
      shadowColor: ColorPallete.color1.withAlpha(77),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, ColorPallete.color1.withAlpha(5)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorPallete.color1.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: ColorPallete.color1,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Order Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorPallete.color1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Order ID', '#${currentOrder.orderId}'),
            _buildInfoRow(
              'Order Date',
              _formatDateTime(currentOrder.orderDate),
            ),
            _buildInfoRow('Total Items', '${currentOrder.items.length}'),
            _buildInfoRow('Customer', currentOrder.customerName),
            _buildInfoRow('Email', currentOrder.customerEmail),
            if (currentOrder.lastUpdated != null)
              _buildInfoRow(
                'Last Updated',
                _formatDateTime(currentOrder.lastUpdated!),
              ),
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
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(currentStatus),
                        _getStatusColor(currentStatus).withAlpha(204),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor(currentStatus).withAlpha(77),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    currentStatus.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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
      elevation: 6,
      shadowColor: Colors.grey.withAlpha(51),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorPallete.color1.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    color: ColorPallete.color1,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Order Status Timeline',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorPallete.color1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildOrderProgress(),
            const SizedBox(height: 20),
            _buildStatusTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderProgress() {
    final status = currentOrder.status.toLowerCase();
    final isDelivered = [
      'delivered',
      'request for return',
      'request for replacement',
    ].contains(status);

    String progressText;
    double progressValue;
    Color progressColor;

    switch (status) {
      case 'confirmed':
      case 'placed':
        progressText = 'Order Confirmed - Preparing for packing';
        progressValue = 0.25;
        progressColor = Colors.orange;
        break;
      case 'packed':
        progressText = 'Order Packed - Ready for shipment';
        progressValue = 0.5;
        progressColor = Colors.blue;
        break;
      case 'shipped':
        progressText = 'Order Shipped - On the way to you';
        progressValue = 0.75;
        progressColor = Colors.indigo;
        break;
      case 'delivered':
        progressText = 'Order Delivered Successfully';
        progressValue = 1.0;
        progressColor = Colors.green;
        break;
      case 'request for return':
        progressText = 'Return Request Submitted';
        progressValue = 1.0;
        progressColor = Colors.purple;
        break;
      case 'request for replacement':
        progressText = 'Replacement Request Submitted';
        progressValue = 1.0;
        progressColor = Colors.indigo;
        break;
      case 'cancelled':
        progressText = 'Order Cancelled';
        progressValue = 0.0;
        progressColor = Colors.red;
        break;
      default:
        progressText = 'Processing Order';
        progressValue = 0.1;
        progressColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [progressColor.withAlpha(25), Colors.white],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: progressColor.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: progressColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progressText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: progressColor,
                  ),
                ),
              ),
              Text(
                '${(progressValue * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    // Check current order status
    final status =
        (currentOrder.status.isEmpty ? 'confirmed' : currentOrder.status)
            .toLowerCase();
    bool hasReturnRequest = status == 'request for return';
    bool hasReplacementRequest = status == 'request for replacement';
    bool isDelivered = [
      'delivered',
      'request for return',
      'request for replacement',
    ].contains(status);

    // Build timeline based on order status
    List<Map<String, dynamic>> statuses = [];
    int currentStatusIndex = 0;

    if (!isDelivered) {
      // Case 1: Until delivered - Show full progression
      statuses = [
        {
          'name': 'Order Placed',
          'icon': Icons.shopping_cart,
          'description': 'Your order has been confirmed',
        },
        {
          'name': 'Order Packed',
          'icon': Icons.inventory_2,
          'description': 'Your order is being packed',
        },
        {
          'name': 'Order Shipped',
          'icon': Icons.local_shipping,
          'description': 'Your order is on the way',
        },
        {
          'name': 'Order Delivered',
          'icon': Icons.home,
          'description': 'Package delivered successfully',
        },
      ];

      // Determine current step based on status
      switch (status) {
        case 'confirmed':
        case 'placed':
          currentStatusIndex = 0;
          break;
        case 'packed':
          currentStatusIndex = 1;
          break;
        case 'shipped':
          currentStatusIndex = 2;
          break;
        case 'delivered':
          currentStatusIndex = 3;
          break;
        case 'cancelled':
          currentStatusIndex = 0;
          break;
        default:
          currentStatusIndex = 0;
      }
    } else if (hasReturnRequest || hasReplacementRequest) {
      // Case 3: Return/Replacement - Show Placed->Delivered->Request
      statuses = [
        {
          'name': 'Order Placed',
          'icon': Icons.shopping_cart,
          'description': 'Your order has been confirmed',
        },
        {
          'name': 'Order Delivered',
          'icon': Icons.home,
          'description': 'Package delivered successfully',
        },
        {
          'name': hasReturnRequest
              ? 'Request for Return'
              : 'Request for Replacement',
          'icon': hasReturnRequest
              ? Icons.keyboard_return
              : Icons.swap_horizontal_circle,
          'description': hasReturnRequest
              ? 'Return request submitted'
              : 'Replacement request submitted',
        },
      ];
      currentStatusIndex = 2; // All three steps completed
    } else {
      // Case 2: After delivered - Show simplified Placed->Delivered
      statuses = [
        {
          'name': 'Order Placed',
          'icon': Icons.shopping_cart,
          'description': 'Your order has been confirmed',
        },
        {
          'name': 'Order Delivered',
          'icon': Icons.home,
          'description': 'Package delivered successfully',
        },
      ];
      currentStatusIndex = 1; // Both steps completed
    }

    return Column(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isCompleted = index <= currentStatusIndex;
        final isCurrent = index == currentStatusIndex;
        final isLast = index == statuses.length - 1;
        final isDelivered = currentStatusIndex >= 1 && index == 1;
        final isRequestStatus =
            (hasReturnRequest || hasReplacementRequest) &&
            index == statuses.length - 1;

        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline indicator column
                  Column(
                    children: [
                      // Circle with icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isCompleted
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isRequestStatus
                                      ? (hasReturnRequest
                                            ? [
                                                Colors.purple.shade400,
                                                Colors.purple.shade600,
                                              ]
                                            : [
                                                Colors.indigo.shade400,
                                                Colors.indigo.shade600,
                                              ])
                                      : (isCurrent && index == 0)
                                      ? [
                                          Colors.orange.shade400,
                                          Colors.orange.shade600,
                                        ]
                                      : [
                                          Colors.green.shade400,
                                          Colors.green.shade600,
                                        ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.shade300,
                                    Colors.grey.shade400,
                                  ],
                                ),
                          border: Border.all(
                            color: isCompleted
                                ? (isRequestStatus
                                      ? (hasReturnRequest
                                            ? Colors.purple.shade200
                                            : Colors.indigo.shade200)
                                      : (isCurrent && index == 0)
                                      ? Colors.orange.shade200
                                      : Colors.green.shade200)
                                : Colors.grey.shade300,
                            width: 3,
                          ),
                          boxShadow: isCompleted
                              ? [
                                  BoxShadow(
                                    color:
                                        (isRequestStatus
                                                ? (hasReturnRequest
                                                      ? Colors.purple
                                                      : Colors.indigo)
                                                : (isCurrent && index < 3)
                                                ? Colors.orange
                                                : Colors.green)
                                            .withAlpha(77),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          status['icon'] as IconData,
                          size: 24,
                          color: isCompleted
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                      // Connecting line (except for last item)
                      if (!isLast)
                        Container(
                          width: 3,
                          height: 30,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isCompleted
                                  ? [
                                      isCurrent
                                          ? Colors.orange.shade300
                                          : Colors.green.shade300,
                                      index + 1 <= currentStatusIndex
                                          ? Colors.green.shade300
                                          : Colors.grey.shade300,
                                    ]
                                  : [
                                      Colors.grey.shade300,
                                      Colors.grey.shade300,
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Content column
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isCompleted
                              ? (isRequestStatus
                                    ? (hasReturnRequest
                                          ? [
                                              Colors.purple.shade50,
                                              Colors.white,
                                            ]
                                          : [
                                              Colors.indigo.shade50,
                                              Colors.white,
                                            ])
                                    : (isCurrent && index == 0)
                                    ? [Colors.orange.shade50, Colors.white]
                                    : [Colors.green.shade50, Colors.white])
                              : [Colors.grey.shade50, Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCompleted
                              ? (isRequestStatus
                                    ? (hasReturnRequest
                                          ? Colors.purple.shade200
                                          : Colors.indigo.shade200)
                                    : (isCurrent && index == 0)
                                    ? Colors.orange.shade200
                                    : Colors.green.shade200)
                              : Colors.grey.shade200,
                          width: 1.5,
                        ),
                        boxShadow: isCompleted
                            ? [
                                BoxShadow(
                                  color:
                                      (isRequestStatus
                                              ? (hasReturnRequest
                                                    ? Colors.purple
                                                    : Colors.indigo)
                                              : (isCurrent && index == 0)
                                              ? Colors.orange
                                              : Colors.green)
                                          .withAlpha(25),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  status['name'] as String,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted
                                        ? (isCurrent && !isDelivered)
                                              ? Colors.orange.shade700
                                              : Colors.green.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              if (isCompleted)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (isCurrent && !isDelivered)
                                        ? Colors.orange
                                        : Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    (isCurrent && !isDelivered)
                                        ? 'CURRENT'
                                        : 'DONE',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status['description'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: isCompleted
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade500,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 13,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Updated: ${_formatDateTime(currentOrder.lastUpdated)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast) const SizedBox(height: 6),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDeliveryInfo() {
    return Card(
      elevation: 6,
      shadowColor: Colors.blue.withAlpha(51),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.blue.shade50.withAlpha(77)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.blue.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Delivery Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withAlpha(25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${currentOrder.shippingAddress['first'] ?? ''} ${currentOrder.shippingAddress['last'] ?? ''}'
                        .trim(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currentOrder.shippingAddress['line1'] ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (currentOrder.shippingAddress['line2']?.isNotEmpty ==
                      true) ...[
                    Text(
                      '${currentOrder.shippingAddress['line2']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${currentOrder.shippingAddress['city'] ?? ''}, ${currentOrder.shippingAddress['state'] ?? ''} - ${currentOrder.shippingAddress['pincode'] ?? ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Only show expected delivery if order is not yet delivered
            if (![
              'delivered',
              'request for return',
              'request for replacement',
            ].contains(currentOrder.status.toLowerCase()))
              FutureBuilder<String>(
                future: _fetchExpectedDeliveryDate(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildInfoRow('Expected Delivery', 'Calculating...');
                  } else if (snapshot.hasError) {
                    return _buildInfoRow(
                      'Expected Delivery',
                      'Error loading date',
                    );
                  } else {
                    return _buildInfoRow(
                      'Expected Delivery',
                      snapshot.data ?? 'Unknown',
                    );
                  }
                },
              ),
            // Show actual delivery date if delivered
            if ([
              'delivered',
              'request for return',
              'request for replacement',
            ].contains(currentOrder.status.toLowerCase()))
              _buildInfoRow(
                'Delivered On',
                currentOrder.lastUpdated != null
                    ? _formatDateTime(currentOrder.lastUpdated!)
                    : _formatDateTime(
                        currentOrder.orderDate.add(const Duration(days: 4)),
                      ),
              ),
            // Show tracking information
            if ([
              'packed',
              'shipped',
            ].contains(currentOrder.status.toLowerCase()))
              _buildInfoRow(
                'Tracking ID',
                'TRK${currentOrder.orderId.substring(0, 8).toUpperCase()}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    // Determine if order is delivered based on order status
    final isDelivered = [
      'delivered',
      'request for return',
      'request for replacement',
    ].contains(currentOrder.status.toLowerCase());

    return Card(
      elevation: 6,
      shadowColor: Colors.green.withAlpha(51),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.green.shade50.withAlpha(77)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.payment,
                    color: Colors.green.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Payment Method', currentOrder.paymentMethod),
            _buildInfoRow(
              'Payment Status',
              currentOrder.paymentMethod.toLowerCase().contains('cash')
                  ? (isDelivered ? 'Paid' : 'Pay on Delivery')
                  : 'Paid',
            ),
            if (!currentOrder.paymentMethod.toLowerCase().contains('cash'))
              _buildInfoRow(
                'Transaction ID',
                'TXN${currentOrder.orderId.substring(4)}',
              ),
            _buildInfoRow(
              'Payment Date',
              currentOrder.paymentMethod.toLowerCase().contains('cash')
                  ? (isDelivered ? 'On Delivery Date' : 'On Delivery')
                  : _formatDateTime(currentOrder.orderDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    return Card(
      elevation: 6,
      shadowColor: Colors.orange.withAlpha(51),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.orange.shade50.withAlpha(77)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    color: Colors.orange.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Order Items',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...currentOrder.items.map((item) => _buildItemCard(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorPallete.color1.withAlpha(25),
                  ColorPallete.color1.withAlpha(13),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorPallete.color1.withAlpha(51),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: ColorPallete.color1,
              size: 28,
            ),
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
                // Display variant details if available
                if (item.variantId != null &&
                    item.variantAttributes != null &&
                    item.variantAttributes!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ColorPallete.color1.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: ColorPallete.color1.withAlpha(77),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Variant Details:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ColorPallete.color1,
                          ),
                        ),
                        ...item.variantAttributes!.entries.map((entry) {
                          return Text(
                            '${entry.key}: ${entry.value}',
                            style: TextStyle(
                              fontSize: 11,
                              color: ColorPallete.color1,
                            ),
                          );
                        }),
                      ],
                    ),
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
    final subtotal = currentOrder.items.fold<double>(
      0,
      (sum, item) => sum + (item.productPrice * item.quantity),
    );

    return Card(
      elevation: 8,
      shadowColor: ColorPallete.color1.withAlpha(77),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, ColorPallete.color1.withAlpha(13)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorPallete.color1.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt,
                    color: ColorPallete.color1,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Price Details',
                  style: TextStyle(
                    fontSize: 20,
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
              '₹${currentOrder.totalAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
            if (currentOrder.paymentMethod != 'COD') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade50,
                      Colors.green.shade100.withAlpha(128),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withAlpha(51),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Payment Completed',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
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
      case 'request for return':
        return Colors.purple;
      case 'request for replacement':
        return Colors.indigo;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<String> _fetchExpectedDeliveryDate() async {
    try {
      print('=== Delivery Date Debug ===');
      int? maxDeliveryDays;
      bool foundValidDeliveryTime = false;

      // Get all unique product IDs from order items
      final productIds = currentOrder.items
          .map((item) => item.productId)
          .toSet();
      print('Product IDs: $productIds');

      // Fetch delivery times for all products
      for (final productId in productIds) {
        print('Fetching product with productId: $productId');
        final productQuery = await FirebaseFirestore.instance
            .collection('products')
            .where('pid', isEqualTo: productId)
            .limit(1)
            .get();

        if (productQuery.docs.isNotEmpty) {
          final productDoc = productQuery.docs.first;
          final data = productDoc.data();
          print('Product found. Firebase ID: ${productDoc.id}');
          print('Product exists. All fields: ${data.keys.toList()}');

          // Get the delivery time from the correct field
          String? deliveryTimeStr = data['deliveryTime'] as String?;
          print('deliveryTime field value: $deliveryTimeStr');

          if (deliveryTimeStr != null && deliveryTimeStr.isNotEmpty) {
            // Parse delivery time string (e.g., "3days", "5days")
            final daysMatch = RegExp(r'(\d+)').firstMatch(deliveryTimeStr);
            if (daysMatch != null) {
              final days = int.tryParse(daysMatch.group(1)!);
              if (days != null) {
                print('Parsed $days days from "$deliveryTimeStr"');
                foundValidDeliveryTime = true;
                // Use the maximum delivery time among all products
                if (maxDeliveryDays == null || days > maxDeliveryDays) {
                  maxDeliveryDays = days;
                }
              } else {
                print('Failed to parse number from: ${daysMatch.group(1)}');
              }
            } else {
              print(
                'No number found in delivery time string: $deliveryTimeStr',
              );
            }
          } else {
            print('deliveryTime field is null or empty for product $productId');
          }
        } else {
          print('Product document does not exist: $productId');
        }
      }

      print('Found valid delivery time: $foundValidDeliveryTime');
      print('Max delivery days: $maxDeliveryDays');

      if (foundValidDeliveryTime && maxDeliveryDays != null) {
        final expectedDate = currentOrder.orderDate.add(
          Duration(days: maxDeliveryDays),
        );
        final formattedDate = _formatDateOnly(expectedDate);
        print('Calculated expected delivery: $formattedDate');
        return formattedDate;
      } else {
        print('No valid delivery time found in any product');
        return 'Delivery time not available';
      }
    } catch (e, stackTrace) {
      print('Error fetching delivery dates: $e');
      print('Stack trace: $stackTrace');
      return 'Error calculating delivery date';
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

  String _formatDateOnly(DateTime dateTime) {
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

    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  void _showCancellationDialog(bool hasCharges) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Order',
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel this order?'),
            const SizedBox(height: 8),
            if (hasCharges) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cancellation charges will apply as the order is already shipped.',
                        style: TextStyle(color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No cancellation charges will apply.',
                        style: TextStyle(color: Colors.green.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (hasCharges) {
                _showPaymentForCancellation();
              } else {
                _cancelOrder();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(hasCharges ? 'Pay & Cancel' : 'Cancel Order'),
          ),
        ],
      ),
    );
  }

  void _showPaymentForCancellation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Required'),
        content: const Text(
          'Please select a payment method to pay the cancellation charges.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPaymentOptions();
            },
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }

  void _showPaymentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.account_balance_wallet, color: Colors.blue),
              title: const Text('UPI Payment'),
              onTap: () {
                Navigator.pop(context);
                _processCancellationPayment('UPI');
              },
            ),
            ListTile(
              leading: Icon(Icons.credit_card, color: Colors.green),
              title: const Text('Card Payment'),
              onTap: () {
                Navigator.pop(context);
                _processCancellationPayment('Card');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _processCancellationPayment(String paymentMethod) {
    setState(() {
      isProcessing = true;
    });

    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () {
      _cancelOrder();
    });
  }

  void _showReturnDialog() {
    String reason = '';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Return Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for the return:'),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) {
                  setState(() {
                    reason = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Return Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: reason.trim().isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      _submitReturnRequest(reason);
                    },
              child: const Text('Submit Return Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReplacementDialog() {
    String reason = '';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Replacement Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for the replacement:'),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) {
                  setState(() {
                    reason = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Replacement Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: reason.trim().isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      _submitReplacementRequest(reason);
                    },
              child: const Text('Submit Replacement Request'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelOrder() async {
    setState(() {
      isProcessing = true;
    });

    try {
      // Validate order ID
      if (currentOrder.orderId.isEmpty) {
        throw Exception('Invalid order ID');
      }

      print(
        'Attempting to cancel order with ID: ${currentOrder.orderId}',
      ); // Debug log

      // Update order status to cancelled in Firestore
      await FirebaseFirestore.instance
          .collection('user_orders')
          .doc(currentOrder.orderId)
          .update({'status': 'cancelled', 'lastUpdated': Timestamp.now()});

      // Increment stock for all items in the order
      for (final item in currentOrder.items) {
        final productRef = FirebaseFirestore.instance
            .collection('products')
            .doc(item.productId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final productDoc = await transaction.get(productRef);

          if (productDoc.exists) {
            final data = productDoc.data()!;

            if (item.variantId != null && item.variantId!.isNotEmpty) {
              // Handle variant stock
              final variants = List<dynamic>.from(data['variants'] ?? []);
              for (int i = 0; i < variants.length; i++) {
                if (variants[i]['variantId'] == item.variantId) {
                  variants[i]['stockQuantity'] =
                      (variants[i]['stockQuantity'] ?? 0) + item.quantity;
                  break;
                }
              }
              transaction.update(productRef, {'variants': variants});
            } else {
              // Handle base product stock
              final currentStock = data['stockQuantity'] ?? 0;
              transaction.update(productRef, {
                'stockQuantity': currentStock + item.quantity,
              });
            }
          }
        });
      }

      setState(() {
        currentOrder = Order(
          orderId: currentOrder.orderId,
          userId: currentOrder.userId,
          customerEmail: currentOrder.customerEmail,
          customerName: currentOrder.customerName,
          items: currentOrder.items,
          totalAmount: currentOrder.totalAmount,
          paymentMethod: currentOrder.paymentMethod,
          orderDate: currentOrder.orderDate,
          status: 'cancelled',
          shippingAddress: currentOrder.shippingAddress,
          sellerIds: currentOrder.sellerIds,
          lastUpdated: DateTime.now(),
        );
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error cancelling order: $e'); // Debug logging
      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel order: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _submitReturnRequest(String reason) async {
    try {
      // Validate order ID
      if (currentOrder.orderId.isEmpty) {
        throw Exception('Invalid order ID');
      }

      print(
        'Submitting return request for order: ${currentOrder.orderId}',
      ); // Debug log

      // Add return request document
      await FirebaseFirestore.instance.collection('return_requests').add({
        'orderId': currentOrder.orderId,
        'customerEmail': currentOrder.customerEmail,
        'reason': reason,
        'requestType': 'return',
        'status': 'pending',
        'requestDate': Timestamp.now(),
        'items': currentOrder.items
            .map(
              (item) => {
                'productId': item.productId,
                'productTitle': item.productTitle,
                'quantity': item.quantity,
                'price': item.productPrice,
                'variantId': item.variantId,
                'variantAttributes': item.variantAttributes,
              },
            )
            .toList(),
      });

      // Update order status to 'Request for Return'
      await FirebaseFirestore.instance
          .collection('user_orders')
          .doc(currentOrder.orderId)
          .update({
            'status': 'Request for Return',
            'lastUpdated': Timestamp.now(),
          });

      // Update local state
      setState(() {
        currentOrder = Order(
          orderId: currentOrder.orderId,
          userId: currentOrder.userId,
          customerEmail: currentOrder.customerEmail,
          customerName: currentOrder.customerName,
          items: currentOrder.items,
          totalAmount: currentOrder.totalAmount,
          paymentMethod: currentOrder.paymentMethod,
          orderDate: currentOrder.orderDate,
          status: 'Request for Return',
          shippingAddress: currentOrder.shippingAddress,
          sellerIds: currentOrder.sellerIds,
          lastUpdated: DateTime.now(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error submitting return request: $e'); // Debug logging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit return request: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _submitReplacementRequest(String reason) async {
    try {
      // Validate order ID
      if (currentOrder.orderId.isEmpty) {
        throw Exception('Invalid order ID');
      }

      print(
        'Submitting replacement request for order: ${currentOrder.orderId}',
      ); // Debug log

      // Add replacement request document
      await FirebaseFirestore.instance.collection('replacement_requests').add({
        'orderId': currentOrder.orderId,
        'customerEmail': currentOrder.customerEmail,
        'reason': reason,
        'requestType': 'replacement',
        'status': 'pending',
        'requestDate': Timestamp.now(),
        'items': currentOrder.items
            .map(
              (item) => {
                'productId': item.productId,
                'productTitle': item.productTitle,
                'quantity': item.quantity,
                'price': item.productPrice,
                'variantId': item.variantId,
                'variantAttributes': item.variantAttributes,
              },
            )
            .toList(),
      });

      // Update order status to 'Request for Replacement'
      await FirebaseFirestore.instance
          .collection('user_orders')
          .doc(currentOrder.orderId)
          .update({
            'status': 'Request for Replacement',
            'lastUpdated': Timestamp.now(),
          });

      // Update local state
      setState(() {
        currentOrder = Order(
          orderId: currentOrder.orderId,
          userId: currentOrder.userId,
          customerEmail: currentOrder.customerEmail,
          customerName: currentOrder.customerName,
          items: currentOrder.items,
          totalAmount: currentOrder.totalAmount,
          paymentMethod: currentOrder.paymentMethod,
          orderDate: currentOrder.orderDate,
          status: 'Request for Replacement',
          shippingAddress: currentOrder.shippingAddress,
          sellerIds: currentOrder.sellerIds,
          lastUpdated: DateTime.now(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Replacement request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error submitting replacement request: $e'); // Debug logging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit replacement request: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildInvoiceInfo() {
    return Card(
      elevation: 6,
      shadowColor: Colors.purple.withAlpha(51),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.purple.shade50.withAlpha(77)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Colors.purple.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Invoice Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.purple.shade50, Colors.white],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withAlpha(25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
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
            _buildInfoRow('Invoice ID', 'INV-${currentOrder.orderId}'),
            _buildInfoRow('Sent to Email', currentOrder.customerEmail),
            _buildInfoRow(
              'Invoice Date',
              _formatDateTime(currentOrder.orderDate),
            ),
          ],
        ),
      ),
    );
  }
}
