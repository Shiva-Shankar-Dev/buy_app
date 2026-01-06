# Code Examples & Usage

## Table of Contents
1. [Using Seller Orders](#using-seller-orders)
2. [Using Stock Analytics](#using-stock-analytics)
3. [Using Seller Dashboard](#using-seller-dashboard)
4. [Testing Security Rules](#testing-security-rules)
5. [Common Patterns](#common-patterns)

---

## Using Seller Orders

### Example 1: Get All Orders for Current Seller

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buy_app/services/order_service.dart';

Future<void> viewSellerOrders() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser == null) {
    print('User not logged in');
    return;
  }

  // Get all orders for this seller
  final orders = await OrderService.getSellerOrders(currentUser.uid);
  
  // Process orders
  for (final order in orders) {
    print('Order ID: ${order.orderId}');
    print('Customer: ${order.customerName}');
    print('Customer Email: ${order.customerEmail}');
    print('Total: ₹${order.totalAmount}');
    print('Items sold: ${order.items.length}');
    print('Status: ${order.status}');
    print('---');
  }
}
```

### Example 2: Get Orders and Filter by Status

```dart
Future<List<Order>> getConfirmedOrders(String sellerId) async {
  final allOrders = await OrderService.getSellerOrders(sellerId);
  
  // Filter orders by status
  final confirmedOrders = allOrders
      .where((order) => order.status.toLowerCase() == 'confirmed')
      .toList();
  
  return confirmedOrders;
}
```

### Example 3: Calculate Total Revenue

```dart
Future<double> calculateMonthlyRevenue(String sellerId) async {
  final orders = await OrderService.getSellerOrders(sellerId);
  
  final now = DateTime.now();
  final monthAgo = DateTime(now.year, now.month - 1, now.day);
  
  double totalRevenue = 0;
  
  for (final order in orders) {
    if (order.orderDate.isAfter(monthAgo)) {
      totalRevenue += order.totalAmount;
    }
  }
  
  return totalRevenue;
}
```

---

## Using Stock Analytics

### Example 1: Display Stock Status

```dart
import 'package:buy_app/services/order_service.dart';

Future<void> displayStockStatus(String sellerId) async {
  final analytics = await OrderService.getSellerStockAnalytics(sellerId);
  
  for (final entry in analytics.entries) {
    final productId = entry.key;
    final data = entry.value as Map<String, dynamic>;
    
    print('Product: ${data['productName']}');
    print('Total Stock: ${data['totalStock']}');
    print('Consumed: ${data['consumedByOrders']}');
    print('Remaining: ${data['remaining']}');
    print('Sold: ${data['percentageSold'].toStringAsFixed(1)}%');
    print('---');
  }
}
```

### Example 2: Find Low Stock Products

```dart
Future<List<String>> getLowStockProducts(String sellerId) async {
  final analytics = await OrderService.getSellerStockAnalytics(sellerId);
  final lowStockProducts = <String>[];
  
  for (final entry in analytics.entries) {
    final productId = entry.key;
    final data = entry.value as Map<String, dynamic>;
    
    // Alert if less than 10 units remaining
    if ((data['remaining'] as int) < 10) {
      lowStockProducts.add(productId);
    }
  }
  
  return lowStockProducts;
}
```

### Example 3: Get Best Selling Products

```dart
Future<List<Map<String, dynamic>>> getTopSellingProducts(
  String sellerId,
  {int limit = 5}
) async {
  final analytics = await OrderService.getSellerStockAnalytics(sellerId);
  
  // Convert to list and sort by consumed
  final products = analytics.entries
      .map((entry) => {
        'productId': entry.key,
        ...entry.value as Map<String, dynamic>,
      })
      .toList();
  
  products.sort((a, b) => 
    (b['consumedByOrders'] as int).compareTo(a['consumedByOrders'] as int)
  );
  
  return products.take(limit).toList();
}
```

---

## Using Seller Dashboard

### Example 1: Navigate to Dashboard

```dart
// In your main menu or settings screen
import 'package:buy_app/screens/orders/seller_dashboard.dart';

ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SellerDashboardPage(),
      ),
    );
  },
  child: const Text('View Dashboard'),
)
```

### Example 2: Add to Routes

```dart
// In main.dart or your router configuration
Map<String, WidgetBuilder> appRoutes = {
  '/home': (context) => const HomePage(),
  '/seller-dashboard': (context) => const SellerDashboardPage(),
  '/orders': (context) => const OrderHistoryPage(),
  // ... other routes
};

// If using Navigator 2.0 or go_router
GoRoute(
  path: '/seller-dashboard',
  builder: (context, state) => const SellerDashboardPage(),
),
```

### Example 3: Conditional Access

```dart
// Only show dashboard to sellers
import 'package:buy_app/services/seller_service.dart';

FutureBuilder<bool>(
  future: isSeller(userId),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    
    if (snapshot.data == true) {
      return ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/seller-dashboard'),
        child: const Text('Seller Dashboard'),
      );
    }
    
    return const SizedBox.shrink();
  },
)
```

---

## Testing Security Rules

### Example 1: Verify Customer Can't Access Other Orders (Should Fail)

```dart
// This code will FAIL after security rules are deployed
// which is the CORRECT behavior
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> testUnauthorizedAccess() async {
  try {
    final maliciousSnapshot = await FirebaseFirestore.instance
        .collection('user_orders')
        .where('userId', isEqualTo: 'some_other_user_id')
        .get();
    
    // This line should never be reached
    print('ERROR: Unauthorized access succeeded!');
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      print('✅ GOOD: Unauthorized access was blocked');
    }
  }
}
```

### Example 2: Verify Seller Can Access Own Orders (Should Work)

```dart
Future<void> testAuthorizedAccess() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser == null) {
    print('Please log in first');
    return;
  }
  
  try {
    // This should work for sellers
    final orders = await OrderService.getSellerOrders(currentUser.uid);
    print('✅ GOOD: Seller access succeeded');
    print('Orders found: ${orders.length}');
  } on FirebaseException catch (e) {
    print('❌ ERROR: ${e.message}');
  }
}
```

### Example 3: Test Different User Roles

```dart
Future<void> comprehensiveSecurityTest() async {
  final firestore = FirebaseFirestore.instance;
  
  // Test 1: Unauthenticated access
  try {
    await FirebaseAuth.instance.signOut();
    await firestore.collection('user_orders').get();
    print('❌ FAIL: Unauthenticated access succeeded');
  } catch (e) {
    print('✅ PASS: Unauthenticated access blocked');
  }
  
  // Test 2: Customer accessing own orders
  await FirebaseAuth.instance.signInAnonymously();
  try {
    await firestore
        .collection('user_orders')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();
    print('✅ PASS: Customer accessed own orders');
  } catch (e) {
    print('❌ FAIL: Customer access failed - $e');
  }
  
  // Test 3: Customer accessing other's orders
  try {
    await firestore
        .collection('user_orders')
        .where('userId', isEqualTo: 'other_user_id')
        .get();
    print('❌ FAIL: Customer accessed other orders');
  } catch (e) {
    print('✅ PASS: Customer access to other orders blocked');
  }
}
```

---

## Common Patterns

### Pattern 1: Real-time Order Updates for Seller

```dart
// StreamBuilder for live order updates
StreamBuilder<List<Order>>(
  stream: FirebaseFirestore.instance
      .collection('user_orders')
      .where('sellerIds', arrayContains: currentSellerId)
      .orderBy('orderDate', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Order.fromFirestore(doc))
          .toList()),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    
    final orders = snapshot.data ?? [];
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) => OrderCard(order: orders[index]),
    );
  },
)
```

### Pattern 2: Update Order Status (By Seller)

```dart
Future<bool> updateOrderStatus(
  String orderId,
  String newStatus,
) async {
  try {
    await FirebaseFirestore.instance
        .collection('user_orders')
        .doc(orderId)
        .update({'status': newStatus});
    
    return true;
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      print('Not authorized to update this order');
    }
    return false;
  }
}
```

### Pattern 3: Calculate Order Statistics

```dart
Future<Map<String, dynamic>> getOrderStatistics(String sellerId) async {
  final orders = await OrderService.getSellerOrders(sellerId);
  
  double totalRevenue = 0;
  int totalOrders = 0;
  int totalItems = 0;
  
  for (final order in orders) {
    totalRevenue += order.totalAmount;
    totalOrders++;
    totalItems += order.items.length;
  }
  
  return {
    'totalRevenue': totalRevenue,
    'totalOrders': totalOrders,
    'totalItems': totalItems,
    'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
    'averageItemsPerOrder': totalOrders > 0 ? totalItems / totalOrders : 0,
  };
}
```

### Pattern 4: Export Orders to CSV

```dart
import 'package:csv/csv.dart';

String exportOrdersToCSV(List<Order> orders) {
  List<List<dynamic>> rows = [];
  
  // Header
  rows.add(['Order ID', 'Customer', 'Email', 'Total', 'Status', 'Date']);
  
  // Data
  for (final order in orders) {
    rows.add([
      order.orderId,
      order.customerName,
      order.customerEmail,
      order.totalAmount.toStringAsFixed(2),
      order.status,
      order.orderDate.toString(),
    ]);
  }
  
  String csv = const ListToCsvConverter().convert(rows);
  return csv;
}
```

### Pattern 5: Search Orders

```dart
Future<List<Order>> searchSellerOrders(
  String sellerId,
  String query,
) async {
  final orders = await OrderService.getSellerOrders(sellerId);
  
  return orders.where((order) {
    final lowerQuery = query.toLowerCase();
    
    return order.orderId.toLowerCase().contains(lowerQuery) ||
        order.customerName.toLowerCase().contains(lowerQuery) ||
        order.customerEmail.toLowerCase().contains(lowerQuery);
  }).toList();
}
```

---

## Error Handling Examples

### Example 1: Handle Permission Errors Gracefully

```dart
Future<void> safeGetSellerOrders() async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      print('User not authenticated');
      return;
    }
    
    final orders = await OrderService.getSellerOrders(currentUser.uid);
    print('Loaded ${orders.length} orders');
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      print('Access denied - verify Firestore rules');
    } else if (e.code == 'unauthenticated') {
      print('Please log in first');
    } else {
      print('Error: ${e.message}');
    }
  } catch (e) {
    print('Unexpected error: $e');
  }
}
```

### Example 2: Network Error Handling

```dart
Future<List<Order>> getSellerOrdersWithRetry(
  String sellerId, {
  int maxRetries = 3,
}) async {
  int retryCount = 0;
  
  while (retryCount < maxRetries) {
    try {
      return await OrderService.getSellerOrders(sellerId);
    } catch (e) {
      retryCount++;
      
      if (retryCount >= maxRetries) {
        rethrow;
      }
      
      // Wait before retrying (exponential backoff)
      await Future.delayed(Duration(seconds: 1 << retryCount));
    }
  }
  
  return [];
}
```

---

## Performance Tips

### Tip 1: Cache Results Locally

```dart
class SellerOrderCache {
  Map<String, List<Order>> _cache = {};
  DateTime _lastFetch = DateTime(2000);
  
  Future<List<Order>> getOrders(String sellerId) async {
    // Return cached if less than 5 minutes old
    if (_cache.containsKey(sellerId) &&
        DateTime.now().difference(_lastFetch).inMinutes < 5) {
      return _cache[sellerId]!;
    }
    
    // Fetch fresh data
    final orders = await OrderService.getSellerOrders(sellerId);
    _cache[sellerId] = orders;
    _lastFetch = DateTime.now();
    
    return orders;
  }
  
  void invalidate(String sellerId) {
    _cache.remove(sellerId);
  }
}
```

### Tip 2: Lazy Load Order Details

```dart
// Instead of loading full orders, load summaries first
Future<List<OrderSummary>> getOrderSummaries(String sellerId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('user_orders')
      .where('sellerIds', arrayContains: sellerId)
      .limit(20) // Only load first 20
      .get();
  
  return snapshot.docs
      .map((doc) => OrderSummary.fromFirestore(doc))
      .toList();
}

// Then load full details on demand
Future<Order?> loadFullOrder(String orderId) async {
  return OrderService.getOrderById(orderId);
}
```

---

## Next Steps

1. **Test** - Run the examples above in your app
2. **Monitor** - Check Firebase Console for any errors
3. **Optimize** - Use caching for frequently accessed data
4. **Extend** - Add more features like notifications, analytics
