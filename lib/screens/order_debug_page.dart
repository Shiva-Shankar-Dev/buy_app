import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/order_service.dart';

class OrderDebugPage extends StatefulWidget {
  const OrderDebugPage({super.key});

  @override
  State<OrderDebugPage> createState() => _OrderDebugPageState();
}

class _OrderDebugPageState extends State<OrderDebugPage> {
  bool _isLoading = false;
  Map<String, List<Map<String, dynamic>>> _allCollections = {};
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _currentUserId = user?.uid;
    });
    print('🔍 [DEBUG] Current user ID: $_currentUserId');
  }

  Future<void> _checkAllOrderCollections() async {
    setState(() {
      _isLoading = true;
      _allCollections.clear();
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // List of possible order collections
      final collections = [
        'orders',
        'user_orders',
        'simple_orders',
        'fresh_orders_2024',
      ];

      print('🔍 [DEBUG] Checking collections for user: $_currentUserId');

      for (final collection in collections) {
        try {
          print('🔍 [DEBUG] Checking collection: $collection');

          // Get all documents in collection
          final allDocsSnapshot = await firestore.collection(collection).get();
          print(
            '🔍 [DEBUG] Collection $collection has ${allDocsSnapshot.docs.length} total documents',
          );

          // Get user-specific documents if user is logged in
          List<QueryDocumentSnapshot> userDocs = [];
          if (_currentUserId != null) {
            final userSnapshot = await firestore
                .collection(collection)
                .where('userId', isEqualTo: _currentUserId)
                .get();
            userDocs = userSnapshot.docs;

            // Also check for customerEmail field (old system)
            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user?.email != null) {
                final emailSnapshot = await firestore
                    .collection(collection)
                    .where('customerEmail', isEqualTo: user!.email)
                    .get();
                userDocs.addAll(emailSnapshot.docs);
              }
            } catch (e) {
              print('🔍 [DEBUG] No customerEmail field in $collection');
            }
          }

          final docs = <Map<String, dynamic>>[];

          // Add user docs first
          for (final doc in userDocs) {
            final data = doc.data() as Map<String, dynamic>;
            data['_docId'] = doc.id;
            data['_isUserDoc'] = true;
            docs.add(data);
          }

          // Add some sample docs from the collection (non-user docs)
          int sampleCount = 0;
          for (final doc in allDocsSnapshot.docs) {
            if (sampleCount >= 5) break;
            if (!userDocs.any((userDoc) => userDoc.id == doc.id)) {
              final data = Map<String, dynamic>.from(doc.data());
              data['_docId'] = doc.id;
              data['_isUserDoc'] = false;
              docs.add(data);
              sampleCount++;
            }
          }

          _allCollections[collection] = docs;
          print(
            '🔍 [DEBUG] Found ${userDocs.length} user docs and ${sampleCount} sample docs in $collection',
          );
        } catch (e) {
          print('❌ [DEBUG] Error checking collection $collection: $e');
          _allCollections[collection] = [];
        }
      }
    } catch (e) {
      print('❌ [DEBUG] Error in debug check: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testOrderCreation() async {
    try {
      print('🧪 [DEBUG] Testing order creation...');

      // Create a test order using our service
      final testOrder = await OrderService.createOrder(
        cartItems: [], // Empty for test
        totalAmount: 123.45,
        paymentMethod: 'Debug Test',
        shippingAddress: {
          'first': 'Debug',
          'last': 'Test',
          'line1': 'Test Address',
          'city': 'Test City',
          'state': 'Test State',
          'pincode': '123456',
        },
      );

      if (testOrder != null) {
        _showMessage('✅ Test order created: $testOrder', Colors.green);
        await _checkAllOrderCollections(); // Refresh data
      } else {
        _showMessage('❌ Failed to create test order', Colors.red);
      }
    } catch (e) {
      _showMessage('❌ Error creating test order: $e', Colors.red);
      print('❌ [DEBUG] Test order error: $e');
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Debug'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _checkAllOrderCollections,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Control Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Current User: ${_currentUserId ?? 'Not logged in'}'),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : _checkAllOrderCollections,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                          _isLoading ? 'Checking...' : 'Check Collections',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _testOrderCreation,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Test Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _allCollections.isEmpty
                ? const Center(
                    child: Text('Click "Check Collections" to see data'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _allCollections.keys.length,
                    itemBuilder: (context, index) {
                      final collection = _allCollections.keys.elementAt(index);
                      final docs = _allCollections[collection]!;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ExpansionTile(
                          title: Text(
                            '$collection (${docs.length} docs)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${docs.where((d) => d['_isUserDoc'] == true).length} user docs, '
                            '${docs.where((d) => d['_isUserDoc'] == false).length} sample docs',
                          ),
                          children: docs.map((doc) {
                            final isUserDoc = doc['_isUserDoc'] as bool;
                            final docId = doc['_docId'] as String;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isUserDoc
                                    ? Colors.green
                                    : Colors.grey,
                                child: Icon(
                                  isUserDoc ? Icons.person : Icons.data_object,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                docId,
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (doc['totalAmount'] != null)
                                    Text('Amount: ₹${doc['totalAmount']}'),
                                  if (doc['orderDate'] != null)
                                    Text('Date: ${doc['orderDate']}'),
                                  if (doc['userId'] != null)
                                    Text('User: ${doc['userId']}'),
                                  if (doc['customerEmail'] != null)
                                    Text('Email: ${doc['customerEmail']}'),
                                  Text(
                                    isUserDoc ? 'YOUR ORDER' : 'Sample Order',
                                    style: TextStyle(
                                      color: isUserDoc
                                          ? Colors.green
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
