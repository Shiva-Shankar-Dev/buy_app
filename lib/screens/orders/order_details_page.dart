import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../services/order_service.dart';
import '../../colorPallete/color_pallete.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OrderDetailsPage extends StatefulWidget {
  final Order order;

  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late Order currentOrder;
  bool isProcessing = false;
  bool isCheckingEligibility = true;
  List<OrderItem> eligibleReturnItems = [];
  List<OrderItem> eligibleReplacementItems = [];

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order;
    _checkEligibility();
    print('Order Details - Order ID: ${currentOrder.orderId}'); // Debug log
    print('Order Details - Status: ${currentOrder.status}'); // Debug log
  }

  Future<void> _checkEligibility() async {
    if (!mounted) return;

    try {
      final List<OrderItem> returns = [];
      final List<OrderItem> replacements = [];
      final now = DateTime.now();

      print('=== Starting Eligibility Check ===');
      print('Order Items Count: ${currentOrder.items.length}');

      // Get all product IDs from the order items
      for (final item in currentOrder.items) {
        if (item.productId.isEmpty) {
          print('Skipping item with empty productId: ${item.productTitle}');
          continue;
        }

        print('Checking item: ${item.productTitle} (ID: ${item.productId})');

        try {
          // Use query to find product by pid field (not document ID)
          final productQuery = await FirebaseFirestore.instance
              .collection('products')
              .where('pid', isEqualTo: item.productId)
              .limit(1)
              .get();

          if (productQuery.docs.isNotEmpty) {
            final productDoc = productQuery.docs.first;
            final data = productDoc.data();

            print('Product found. Firebase Doc ID: ${productDoc.id}');
            print('Product data keys: ${data.keys.toList()}');

            // Check return eligibility
            if (data.containsKey('returnDays')) {
              final returnDaysValue = data['returnDays'];
              int days = 0;

              // Handle both int and String types
              if (returnDaysValue is int) {
                days = returnDaysValue;
              } else if (returnDaysValue is String) {
                final daysMatch = RegExp(r'(\d+)').firstMatch(returnDaysValue);
                days = daysMatch != null ? int.parse(daysMatch.group(1)!) : 0;
              }

              print(
                'Return check: ${item.productTitle} - returnDays: $returnDaysValue (parsed: $days)',
              );

              // Only allow returns if days > 0
              if (days > 0) {
                // Calculate deadline: orderDate + returnDays
                final deadline = currentOrder.orderDate.add(
                  Duration(days: days),
                );
                print('Return deadline: $deadline, Current: $now');

                // Check if within window
                if (now.isBefore(deadline)) {
                  returns.add(item);
                  print(
                    '✅ Return eligible: ${item.productTitle} - ${days} days',
                  );
                } else {
                  print(
                    '❌ Return expired: ${item.productTitle} - deadline passed',
                  );
                }
              } else {
                print(
                  '❌ Return not allowed: ${item.productTitle} - days: $days',
                );
              }
            } else {
              print(
                '❌ Return not allowed: ${item.productTitle} - returnDays field missing',
              );
            }

            // Check replacement eligibility
            if (data.containsKey('replacementDays')) {
              final replacementDaysValue = data['replacementDays'];
              int days = 0;

              // Handle both int and String types
              if (replacementDaysValue is int) {
                days = replacementDaysValue;
              } else if (replacementDaysValue is String) {
                final daysMatch = RegExp(
                  r'(\d+)',
                ).firstMatch(replacementDaysValue);
                days = daysMatch != null ? int.parse(daysMatch.group(1)!) : 0;
              }

              print(
                'Replacement check: ${item.productTitle} - replacementDays: $replacementDaysValue (parsed: $days)',
              );

              // Only allow replacements if days > 0
              if (days > 0) {
                final deadline = currentOrder.orderDate.add(
                  Duration(days: days),
                );
                print('Replacement deadline: $deadline, Current: $now');

                if (now.isBefore(deadline)) {
                  replacements.add(item);
                  print(
                    '✅ Replacement eligible: ${item.productTitle} - ${days} days',
                  );
                } else {
                  print(
                    '❌ Replacement expired: ${item.productTitle} - deadline passed',
                  );
                }
              } else {
                print(
                  '❌ Replacement not allowed: ${item.productTitle} - days: $days',
                );
              }
            } else {
              print(
                '❌ Replacement not allowed: ${item.productTitle} - replacementDays field missing',
              );
            }
          } else {
            print(
              '❌ Product not found in database: ${item.productTitle} (ID: ${item.productId})',
            );

            // Try fallback with document ID
            print('Trying fallback with document ID...');
            final fallbackDoc = await FirebaseFirestore.instance
                .collection('products')
                .doc(item.productId)
                .get();

            if (fallbackDoc.exists) {
              print('✅ Found product using document ID');
              final data = fallbackDoc.data()!;

              // Repeat the same logic for fallback
              if (data.containsKey('returnDays')) {
                final returnDaysValue = data['returnDays'];
                int days = 0;
                if (returnDaysValue is int) {
                  days = returnDaysValue;
                } else if (returnDaysValue is String) {
                  final daysMatch = RegExp(
                    r'(\d+)',
                  ).firstMatch(returnDaysValue);
                  days = daysMatch != null ? int.parse(daysMatch.group(1)!) : 0;
                }

                if (days > 0) {
                  final deadline = currentOrder.orderDate.add(
                    Duration(days: days),
                  );
                  if (now.isBefore(deadline)) {
                    returns.add(item);
                    print(
                      '✅ Return eligible (fallback): ${item.productTitle} - ${days} days',
                    );
                  }
                }
              }

              if (data.containsKey('replacementDays')) {
                final replacementDaysValue = data['replacementDays'];
                int days = 0;
                if (replacementDaysValue is int) {
                  days = replacementDaysValue;
                } else if (replacementDaysValue is String) {
                  final daysMatch = RegExp(
                    r'(\d+)',
                  ).firstMatch(replacementDaysValue);
                  days = daysMatch != null ? int.parse(daysMatch.group(1)!) : 0;
                }

                if (days > 0) {
                  final deadline = currentOrder.orderDate.add(
                    Duration(days: days),
                  );
                  if (now.isBefore(deadline)) {
                    replacements.add(item);
                    print(
                      '✅ Replacement eligible (fallback): ${item.productTitle} - ${days} days',
                    );
                  }
                }
              }
            } else {
              print('❌ Product not found even with document ID fallback');
            }
          }
        } catch (itemError) {
          print('❌ Error checking item ${item.productTitle}: $itemError');
        }
      }

      if (mounted) {
        setState(() {
          eligibleReturnItems = returns;
          eligibleReplacementItems = replacements;
          isCheckingEligibility = false;
        });

        // Debug output
        print('=== Final Eligibility Results ===');
        print('Eligible return items: ${returns.length}');
        for (final item in returns) {
          print('  - ${item.productTitle}');
        }
        print('Eligible replacement items: ${replacements.length}');
        for (final item in replacements) {
          print('  - ${item.productTitle}');
        }
        print('====================================');
      }
    } catch (e, stackTrace) {
      print('❌ Error in _checkEligibility: $e');
      print('Stack trace: $stackTrace');
      debugPrint('Error checking eligibility: $e');
      if (mounted) {
        setState(() {
          isCheckingEligibility = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(),
            const SizedBox(height: 12),
            _buildOrderItems(),
            const SizedBox(height: 12),
            _buildOrderStatus(),
            const SizedBox(height: 12),
            _buildDeliveryInfo(),
            const SizedBox(height: 12),
            _buildPaymentInfo(),
            const SizedBox(height: 12),
            _buildPricingSummary(),
            const SizedBox(height: 20),
            _buildOrderActions(),
            const SizedBox(height: 20),
            _buildInvoiceInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    final status = currentOrder.status.isNotEmpty
        ? currentOrder.status
        : 'Confirmed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order ID: ${currentOrder.orderId}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Ordered on ${_formatDateTime(currentOrder.orderDate)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _getStatusColor(status).withAlpha(100),
                  ),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildOrderTracker().animate().fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 24),
          _buildStatusTimeline(),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final status =
        (currentOrder.status.isEmpty ? 'confirmed' : currentOrder.status)
            .toLowerCase();

    bool hasReturnRequest =
        status == 'request for return' || status == 'return approved';
    bool hasReplacementRequest =
        status == 'request for replacement' || status == 'replacement approved';
    bool isReturnApproved = status == 'return approved';
    bool isReplacementApproved = status == 'replacement approved';
    bool isCancelled = status == 'cancelled';
    bool isDelivered = [
      'delivered',
      'request for return',
      'request for replacement',
      'return approved',
      'replacement approved',
    ].contains(status);

    // Build timeline events
    List<Map<String, dynamic>> events = [];

    if (isCancelled) {
      events = [
        {
          'title': 'Order Placed',
          'description': 'Your order has been placed',
          'active': true,
          'completed': true,
        },
        {
          'title': 'Cancelled',
          'description': 'Your order has been cancelled',
          'active': true,
          'completed': true, // Final state
          'isError': true,
        },
      ];
    } else {
      // Standard flow
      events = [
        {
          'title': 'Order Placed',
          'description': 'We have received your order',
          'status_key': 'placed',
        },
        {
          'title': 'Packed',
          'description': 'Seller has packed your order',
          'status_key': 'packed',
        },
        {
          'title': 'Shipped',
          'description': 'Your order is on the way',
          'status_key': 'shipped',
        },
        {
          'title': 'Delivered',
          'description': 'Package delivered',
          'status_key': 'delivered',
        },
      ];

      // Insert return/replacement if active
      if (hasReturnRequest || hasReplacementRequest) {
        // Assume delivered is completed
        events.add({
          'title': hasReturnRequest
              ? 'Return Requested'
              : 'Replacement Requested',
          'description': 'Request submitted for review',
          'active': true,
          'completed': isReturnApproved || isReplacementApproved,
        });

        if (isReturnApproved || isReplacementApproved) {
          events.add({
            'title': isReturnApproved
                ? 'Return Approved'
                : 'Replacement Approved',
            'description': isReturnApproved
                ? 'Return request accepted'
                : 'Replacement request accepted',
            'active': true,
            'completed': true,
          });
        }
      }
    }

    // Determine state for standard flow
    if (!isCancelled) {
      int currentIdx = 0;
      if (status == 'confirmed' || status == 'placed')
        currentIdx = 0;
      else if (status == 'packed')
        currentIdx = 1;
      else if (status == 'shipped')
        currentIdx = 2;
      else if (status == 'delivered' || isDelivered)
        currentIdx = 3;

      for (int i = 0; i < events.length; i++) {
        if (i < 4) {
          // Handling standard events
          if (i <= currentIdx) {
            events[i]['active'] = true;
            events[i]['completed'] =
                (i < currentIdx) || (i == 3 && isDelivered);
          } else {
            events[i]['active'] = false;
            events[i]['completed'] = false;
          }
        }
      }
    }

    return Column(
      children: List.generate(events.length, (index) {
        final event = events[index];
        final isLast = index == events.length - 1;
        final isActive = event['active'] == true;
        final isCompleted = event['completed'] == true;
        final isError = event['isError'] == true;

        Color dotColor;
        if (isError) {
          dotColor = Colors.red;
        } else if (isCompleted) {
          dotColor = Colors.green;
        } else if (isActive) {
          dotColor = Colors.blue;
        } else {
          dotColor = Colors.grey[300]!;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    height: 40,
                    width: 2,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive || isCompleted
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event['description'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24), // Spacing for line
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildOrderTracker() {
    final status =
        (currentOrder.status.isEmpty ? 'confirmed' : currentOrder.status)
            .toLowerCase();

    // Map status to step index
    // 0: Placed
    // 1: Packed
    // 2: Shipped
    // 3: Delivered
    int currentStep = 0;
    if (status == 'confirmed' ||
        status == 'placed' ||
        status == 'order placed') {
      currentStep = 0;
    } else if (status == 'packed') {
      currentStep = 1;
    } else if (status == 'shipped' || status == 'out for delivery') {
      currentStep = 2;
    } else if ([
      'delivered',
      'return requested',
      'replacement requested',
      'return approved',
      'replacement approved',
    ].contains(status)) {
      currentStep = 3;
    } else if (status == 'cancelled') {
      // Handle cancelled separately if needed, for now show as stuck at 0 or red
      currentStep = -1;
    }

    final steps = [
      {'title': 'Placed', 'icon': Icons.shopping_bag_outlined},
      {'title': 'Packed', 'icon': Icons.inventory_2_outlined},
      {'title': 'Shipped', 'icon': Icons.local_shipping_outlined},
      {'title': 'Delivered', 'icon': Icons.check_circle_outline},
    ];

    if (status == 'cancelled') {
      return Container(
        padding: EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 40),
            SizedBox(height: 8),
            Text(
              "Order Cancelled",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final bool isCompleted = index <= currentStep;
              final bool isActive = index == currentStep;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Left Line
                        Expanded(
                          child: Container(
                            height: 3,
                            color: index == 0
                                ? Colors.transparent
                                : (index <= currentStep
                                      ? ColorPallete.color1
                                      : Colors.grey[200]),
                          ),
                        ),
                        // Icon Circle
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? ColorPallete.color1
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompleted
                                  ? ColorPallete.color1
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: ColorPallete.color1.withAlpha(60),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            step['icon'] as IconData,
                            size: 18,
                            color: isCompleted
                                ? Colors.white
                                : Colors.grey[400],
                          ),
                        ),
                        // Right Line
                        Expanded(
                          child: Container(
                            height: 3,
                            color: index == steps.length - 1
                                ? Colors.transparent
                                : (index < currentStep
                                      ? ColorPallete.color1
                                      : Colors.grey[200]),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                          step['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isCompleted ? Colors.black87 : Colors.grey,
                          ),
                        )
                        .animate(target: isActive ? 1 : 0)
                        .scale(begin: Offset(1, 1), end: Offset(1.1, 1.1)),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Address',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${currentOrder.shippingAddress['first'] ?? ''} ${currentOrder.shippingAddress['last'] ?? ''}'
                .trim(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${currentOrder.shippingAddress['line1'] ?? ''}',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          if (currentOrder.shippingAddress['line2']?.isNotEmpty == true) ...[
            Text(
              '${currentOrder.shippingAddress['line2']}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${currentOrder.shippingAddress['city'] ?? ''}, ${currentOrder.shippingAddress['state'] ?? ''} - ${currentOrder.shippingAddress['pincode'] ?? ''}',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          if (currentOrder.shippingAddress['phone'] != null)
            Text(
              'Phone: ${currentOrder.shippingAddress['phone']}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Payment Method', currentOrder.paymentMethod),
          // Only show status if relevant
          if (!currentOrder.paymentMethod.toLowerCase().contains('cash') ||
              currentOrder.status == 'delivered')
            _buildInfoRow('Status', 'Paid', isBold: false),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Order Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ...currentOrder.items.map(
            (item) => Column(
              children: [
                Divider(height: 1, color: Colors.grey[200]),
                _buildItemCard(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.productImage != null && item.productImage!.isNotEmpty
                  ? Image.network(
                      item.productImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image, color: Colors.grey[400]),
                    )
                  : Icon(Icons.image, color: Colors.grey[400]),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Variant info if exists
                if (item.variantAttributes != null &&
                    item.variantAttributes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      item.variantAttributes!.values.join(', '),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Qty: ${item.quantity}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      '₹${(item.productPrice * item.quantity).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

  Widget _buildInfoRow(String label, String value, {bool isBold = true}) {
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

  Widget _buildOrderActions() {
    final status = currentOrder.status.toLowerCase();
    final canCancel = ['confirmed', 'packed'].contains(status);
    final canCancelWithFee = status == 'shipped';
    final canReturnReplace = status == 'delivered';

    if (!canCancel && !canCancelWithFee && !canReturnReplace) {
      return SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (canCancel || canCancelWithFee)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () => _showCancellationDialog(canCancelWithFee),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
                child: isProcessing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.red),
                        ),
                      )
                    : Text(
                        canCancelWithFee
                            ? 'Cancel Order (Charges Apply)'
                            : 'Cancel Order',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          if (canReturnReplace) ...[
            if (eligibleReturnItems.isEmpty && eligibleReplacementItems.isEmpty)
              Text(
                'No eligible items for return/replace',
                style: TextStyle(color: Colors.grey),
              )
            else
              Row(
                children: [
                  if (eligibleReturnItems.isNotEmpty)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showReturnDialog(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Return'),
                      ),
                    ),
                  if (eligibleReturnItems.isNotEmpty &&
                      eligibleReplacementItems.isNotEmpty)
                    const SizedBox(width: 12),
                  if (eligibleReplacementItems.isNotEmpty)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showReplacementDialog(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Replace'),
                      ),
                    ),
                ],
              ),
          ],
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
      case 'return approved':
        return Colors.green;
      case 'request for replacement':
        return Colors.indigo;
      case 'replacement approved':
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
    if (eligibleReturnItems.isEmpty) return;

    final List<String> returnReasons = [
      'Defective/Damaged',
      'Wrong Item Received',
      'Item Missing',
      'Quality Not As Expected',
      'Size/Fit Issue',
      'Other',
    ];

    // Initially select all eligible items
    final Set<OrderItem> selectedItems = Set.from(eligibleReturnItems);
    String? selectedReasonCategory;
    String detailedReason = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Return Request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select items to return:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: eligibleReturnItems.map((item) {
                      final isSelected = selectedItems.contains(item);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedItems.add(item);
                            } else {
                              selectedItems.remove(item);
                            }
                          });
                        },
                        title: Text(
                          item.productTitle,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.blue,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reason for Return:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  hint: const Text('Select a reason'),
                  value: selectedReasonCategory,
                  items: returnReasons.map((String reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedReasonCategory = newValue;
                    });
                  },
                ),
                if (selectedReasonCategory != null) ...[
                  const SizedBox(height: 16),
                  const Text('Additional Comments:'),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        detailedReason = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Describe the issue in detail...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedItems.isEmpty || selectedReasonCategory == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      _submitReturnRequest(
                        selectedItems.toList(),
                        selectedReasonCategory!,
                        detailedReason,
                      );
                    },
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReplacementDialog() {
    if (eligibleReplacementItems.isEmpty) return;

    final List<String> replacementReasons = [
      'Defective/Damaged',
      'Wrong Item Received',
      'Item Missing',
      'Quality Not As Expected',
      'Other',
    ];

    // Initially select all eligible items
    final Set<OrderItem> selectedItems = Set.from(eligibleReplacementItems);
    String? selectedReasonCategory;
    String detailedReason = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Replacement Request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select items to replace:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: eligibleReplacementItems.map((item) {
                      final isSelected = selectedItems.contains(item);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedItems.add(item);
                            } else {
                              selectedItems.remove(item);
                            }
                          });
                        },
                        title: Text(
                          item.productTitle,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.blue,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reason for Replacement:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  hint: const Text('Select a reason'),
                  value: selectedReasonCategory,
                  items: replacementReasons.map((String reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedReasonCategory = newValue;
                    });
                  },
                ),
                if (selectedReasonCategory != null) ...[
                  const SizedBox(height: 16),
                  const Text('Additional Comments:'),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        detailedReason = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Describe the issue in detail...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedItems.isEmpty || selectedReasonCategory == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      _submitReplacementRequest(
                        selectedItems.toList(),
                        selectedReasonCategory!,
                        detailedReason,
                      );
                    },
              child: const Text('Submit Request'),
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

  Future<void> _submitReturnRequest(
    List<OrderItem> items,
    String category,
    String comments,
  ) async {
    try {
      // Validate order ID
      if (currentOrder.orderId.isEmpty) {
        throw Exception('Invalid order ID');
      }

      print(
        'Submitting return request for order: ${currentOrder.orderId}',
      ); // Debug log

      // Create return request document
      await FirebaseFirestore.instance.collection('return_requests').add({
        'orderId': currentOrder.orderId,
        'customerEmail': currentOrder.customerEmail,
        'reasonCategory': category,
        'reasonDetails': comments,
        'requestType': 'return',
        'status': 'pending',
        'requestDate': Timestamp.now(),
        'items': items
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
      if (mounted) {
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
      }
    } catch (e) {
      print('Error submitting return request: $e'); // Debug logging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit return request: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _submitReplacementRequest(
    List<OrderItem> items,
    String category,
    String comments,
  ) async {
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
        'reasonCategory': category,
        'reasonDetails': comments,
        'requestType': 'replacement',
        'status': 'pending',
        'requestDate': Timestamp.now(),
        'items': items
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
      if (mounted) {
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
      }
    } catch (e) {
      print('Error submitting replacement request: $e'); // Debug logging
      if (mounted) {
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
  }

  Widget _buildInvoiceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withAlpha(30)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Invoice sent to ${currentOrder.customerEmail}',
                    style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Invoice ID', 'INV-${currentOrder.orderId}'),
          _buildInfoRow(
            'Invoice Date',
            _formatDateTime(currentOrder.orderDate),
          ),
        ],
      ),
    );
  }
}
