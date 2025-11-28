import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/order_service.dart' as OrderSvc;
import '../models/models.dart';

class TestOrderPage extends StatefulWidget {
  const TestOrderPage({super.key});

  @override
  State<TestOrderPage> createState() => _TestOrderPageState();
}

class _TestOrderPageState extends State<TestOrderPage> {
  bool _isCreating = false;
  bool _isLoading = false;
  List<OrderSvc.Order> _orders = [];
  String? _lastOrderId;

  Future<void> _createTestOrder() async {
    setState(() => _isCreating = true);

    try {
      // Create a dummy product for testing
      final testProduct = Product(
        name: 'Test Product',
        brand: 'Test Brand',
        description: 'This is a test product',
        deliveryTime: '2-3 days',
        price: 99.99,
        images: ['test-image.jpg'],
        category: 'Test Category',
        keywords: ['test', 'product'],
        pid: 'test-001',
        stockQuantity: 100,
      );

      // Create cart item
      final cartItem = CartItem(product: testProduct, quantity: 2);

      // Create order
      final orderId = await OrderSvc.OrderService.createOrder(
        cartItems: [cartItem],
        totalAmount: 199.98,
        paymentMethod: 'Test Payment',
        shippingAddress: {
          'first': 'Test',
          'last': 'User',
          'line1': '123 Test Street',
          'line2': '',
          'city': 'Test City',
          'state': 'Test State',
          'pincode': '123456',
        },
      );

      if (orderId != null) {
        setState(() => _lastOrderId = orderId);
        _showMessage('✅ Test order created: $orderId', Colors.green);
        await _loadOrders();
      } else {
        _showMessage('❌ Failed to create test order', Colors.red);
      }
    } catch (e) {
      _showMessage('❌ Error: $e', Colors.red);
      print('Error creating test order: $e');
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showMessage('❌ No user logged in', Colors.red);
        return;
      }

      final orders = await OrderSvc.OrderService.getUserOrders(currentUser.uid);
      setState(() => _orders = orders);

      _showMessage('📦 Loaded ${orders.length} orders', Colors.blue);
    } catch (e) {
      _showMessage('❌ Error loading orders: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Orders'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test buttons
            ElevatedButton.icon(
              onPressed: _isCreating ? null : _createTestOrder,
              icon: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_shopping_cart),
              label: Text(_isCreating ? 'Creating...' : 'Create Test Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadOrders,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isLoading ? 'Loading...' : 'Load Orders'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Results
            if (_lastOrderId != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Last Order Created: $_lastOrderId',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            Text(
              'Orders Found: ${_orders.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Orders list
            Expanded(
              child: _orders.isEmpty
                  ? const Center(child: Text('No orders found'))
                  : ListView.builder(
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text('Order: ${order.orderId}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Amount: ₹${order.totalAmount}'),
                                Text('Items: ${order.items.length}'),
                                Text(
                                  'Date: ${order.orderDate.toString().split('.')[0]}',
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
