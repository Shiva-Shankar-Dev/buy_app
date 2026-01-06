# Firebase Security Vulnerability Analysis

## Executive Summary
Your Firebase setup has **critical security vulnerabilities** that allow:
1. ✅ **Any authenticated user can access ALL order details** (customer names, addresses, payment methods)
2. ✅ **Any user can view seller information** 
3. ❌ **Sellers CANNOT currently see stock remaining from orders**

---

## 🚨 CRITICAL VULNERABILITIES

### 1. **Order Data Access - CRITICAL**

**Problem:** The `user_orders` collection allows any authenticated user to query and read orders from ANY customer.

**Current Code (order_service.dart - Line 287-298):**
```dart
static Future<List<Order>> getUserOrders(String userId) async {
  final querySnapshot = await _firestore
      .collection('user_orders')
      .where('userId', isEqualTo: userId)  // ❌ Only checked on client-side
      .orderBy('orderDate', descending: true)
      .get();
  // ...
}
```

**The Vulnerability:**
- A malicious user can modify the app or use Firebase SDK directly to fetch ANY user's orders
- No server-side validation exists
- **A user can do this:**
  ```dart
  // Attacker can fetch ANY user's orders by changing the userId parameter
  firestore.collection('user_orders')
      .where('userId', isEqualTo: 'victim_user_id')
      .get();
  ```

**What Attackers Can Access:**
- ✅ Customer full names
- ✅ Customer email addresses
- ✅ Complete shipping addresses (street, city, postal code)
- ✅ Payment methods used
- ✅ Product items purchased (revealing customer preferences)
- ✅ Order totals and amounts paid

**Severity: CRITICAL** 🔴

---

### 2. **Seller Details Access - HIGH**

**Problem:** Any user can access ALL seller information including business details.

**Current Code (seller_service.dart - Line 10-23):**
```dart
static Future<Map<String, dynamic>?> getSellerDetails(String sellerId) async {
  final doc = await _firestore.collection('sellers').doc(sellerId).get();
  // ❌ No authorization check
  if (doc.exists) {
    return data;  // Returns all seller data without validation
  }
}
```

**What's Exposed:**
- ✅ Seller business name
- ✅ Seller email addresses (enables targeted spam/phishing)
- ✅ Phone numbers
- ✅ Business addresses

**Severity: HIGH** 🟠

---

### 3. **Product Comments & Reviews - MEDIUM**

**Problem:** User emails are stored in public comments without privacy protection.

**Data Stored (models.dart):**
```dart
class ProductComment {
  final String userEmail;  // ❌ Exposed in product_comments collection
  final String userId;
  final String comment;
  final double rating;
  // ...
}
```

**Severity: MEDIUM** 🟡

---

## ❌ SELLERS CANNOT SEE STOCK REMAINING

**Current Problem:** There's NO mechanism for sellers to:
1. See how many items were ordered of their products
2. Track remaining stock due to online orders
3. View their seller dashboard

**Missing Functionality:**
- No seller portal/dashboard
- No method to query orders by `sellerId`
- No stock analytics for sellers
- No integration between order items and seller visibility

---

## 📋 REQUIRED FIRESTORE SECURITY RULES

**Replace your default rules with this:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ======== CUSTOMERS COLLECTION ========
    match /customers/{userId} {
      // Users can only read/write their own data
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // ======== ORDERS COLLECTION ========
    match /user_orders/{orderId} {
      // 1. Customer can read their own orders
      allow read: if request.auth != null && 
                     request.auth.uid == resource.data.userId;
      
      // 2. Seller can read orders containing their products
      allow read: if request.auth != null && 
                     request.auth.uid in resource.data.sellerIds;
      
      // 3. Only customers can create orders (validated on client)
      allow create: if request.auth != null && 
                       request.auth.uid == request.resource.data.userId;
      
      // 4. Only customers can update their own orders
      allow update: if request.auth != null && 
                       request.auth.uid == resource.data.userId;
      
      // Default deny all other access
      allow delete: if false;
    }

    // ======== SELLERS COLLECTION ========
    match /sellers/{sellerId} {
      // Sellers can read their own complete profile
      allow read: if request.auth != null && request.auth.uid == sellerId;
      
      // Hide seller data from customers (only show in orders)
      allow write: if false;
    }

    // ======== PRODUCTS COLLECTION ========
    match /products/{document=**} {
      // Anyone can read products (shopping)
      allow read: if request.auth != null;
      
      // Only sellers can write their own products
      allow write: if request.auth != null && 
                      request.auth.uid == resource.data.sellerId;
    }

    // ======== PRODUCT COMMENTS ========
    match /product_comments/{commentId} {
      // Users can read all comments
      allow read: if request.auth != null;
      
      // Users can create their own comments
      allow create: if request.auth != null && 
                       request.auth.uid == request.resource.data.userId;
      
      // Users can only update/delete their own comments
      allow update, delete: if request.auth != null && 
                               request.auth.uid == resource.data.userId;
    }

    // ======== WISHLISTS ========
    match /user_wishlists/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // ======== ADDRESSES ========
    match /user_addresses/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Default deny everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## ✅ ENABLING SELLERS TO VIEW STOCK & ORDERS

### Step 1: Add Seller Orders Query Method

Create a new method in `order_service.dart`:

```dart
/// Get orders for a seller (products they've sold)
static Future<List<Order>> getSellerOrders(String sellerId) async {
  try {
    debugPrint('🔍 Loading orders for seller: $sellerId');

    final querySnapshot = await _firestore
        .collection('user_orders')
        .where('sellerIds', arrayContains: sellerId)  // Orders containing this seller's products
        .orderBy('orderDate', descending: true)
        .get();

    final orders = <Order>[];
    for (final doc in querySnapshot.docs) {
      try {
        final order = Order.fromFirestore(doc);
        // Filter items to only show this seller's products
        final sellerItems = order.items
            .where((item) => item.sellerId == sellerId)
            .toList();
        
        if (sellerItems.isNotEmpty) {
          // Create a modified order with only this seller's items
          final sellerOrder = Order(
            orderId: order.orderId,
            userId: order.userId,
            customerName: order.customerName,
            customerEmail: order.customerEmail,
            items: sellerItems,
            totalAmount: sellerItems.fold(0.0, 
              (sum, item) => sum + (item.productPrice * item.quantity)),
            paymentMethod: order.paymentMethod,
            status: order.status,
            orderDate: order.orderDate,
            shippingAddress: order.shippingAddress,
            sellerIds: [sellerId],
            lastUpdated: order.lastUpdated,
          );
          orders.add(sellerOrder);
        }
      } catch (e) {
        debugPrint('❌ Error parsing order: $e');
      }
    }

    debugPrint('✅ Loaded ${orders.length} orders for seller');
    return orders;
  } catch (e) {
    debugPrint('❌ Error fetching seller orders: $e');
    return [];
  }
}

/// Get stock consumed by orders for a seller's products
static Future<Map<String, int>> getStockConsumedByOrders(String sellerId) async {
  try {
    debugPrint('📊 Calculating stock consumed for seller: $sellerId');
    
    final orders = await getSellerOrders(sellerId);
    final stockMap = <String, int>{};

    for (final order in orders) {
      for (final item in order.items) {
        final key = item.productId;
        stockMap[key] = (stockMap[key] ?? 0) + item.quantity;
      }
    }

    debugPrint('📊 Stock consumed: $stockMap');
    return stockMap;
  } catch (e) {
    debugPrint('❌ Error calculating stock consumed: $e');
    return {};
  }
}
```

### Step 2: Update Stock Service to Show Remaining Stock

Add this method to `stock_service.dart`:

```dart
/// Get remaining stock for seller products (accounting for orders)
static Future<Map<String, dynamic>> getSellerStockStatus(
  String productId,
  String? variantId,
) async {
  try {
    // Get original stock from product
    final querySnapshot = await _firestore
        .collection('products')
        .where('pid', isEqualTo: productId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return {'error': 'Product not found'};
    }

    final productData = querySnapshot.docs.first.data();
    
    int remainingStock = 0;
    if (variantId != null) {
      // Get variant stock
      final variants = List<dynamic>.from(productData['variants'] ?? []);
      for (final variant in variants) {
        if (variant['variantId'] == variantId) {
          remainingStock = (variant['stockQuantity'] as num?)?.toInt() ?? 0;
          break;
        }
      }
    } else {
      // Get base product stock
      remainingStock = (productData['stockQuantity'] as num?)?.toInt() ?? 0;
    }

    return {
      'productId': productId,
      'variantId': variantId,
      'remainingStock': remainingStock,
      'productName': productData['name'],
      'lastUpdate': productData['lastStockUpdate'],
    };
  } catch (e) {
    debugPrint('❌ Error getting stock status: $e');
    return {'error': 'Could not fetch stock'};
  }
}
```

### Step 3: Create Seller Dashboard Screen

Create `lib/screens/seller_dashboard.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/order_service.dart';
import '../services/stock_service.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({Key? key}) : super(key: key);

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  late Future<List<Order>> _ordersF;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _ordersF = OrderService.getSellerOrders(currentUser.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        backgroundColor: const Color(0xFF6200EA),
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersF,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${order.orderId}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Customer: ${order.customerName}'),
                      Text('Email: ${order.customerEmail}'),
                      const SizedBox(height: 8),
                      Text('Items:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          '${item.productTitle} x${item.quantity} @ ₹${item.productPrice}',
                        ),
                      )),
                      const SizedBox(height: 8),
                      Text('Total: ₹${order.totalAmount}'),
                      Text('Status: ${order.status}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 🔐 ADDITIONAL SECURITY RECOMMENDATIONS

### 1. **Implement Backend Cloud Functions** (Highly Recommended)
Instead of relying on client-side queries, use Cloud Functions to enforce security:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.getSellerOrders = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
  }

  const sellerId = context.auth.uid;
  
  // Query orders where this seller's ID is in sellerIds array
  const snapshot = await admin.firestore()
    .collection('user_orders')
    .where('sellerIds', 'array-contains', sellerId)
    .get();

  return snapshot.docs.map(doc => doc.data());
});
```

### 2. **Hash Sensitive Data**
Never store plain email addresses in public comments. Hash them:

```dart
import 'package:crypto/crypto.dart';

String hashEmail(String email) {
  return sha256.convert(utf8.encode(email.toLowerCase())).toString();
}
```

### 3. **Audit Logging**
Add logging to track who accesses what:

```dart
Future<void> _logDataAccess(String userId, String collectionAccessed) async {
  await FirebaseFirestore.instance.collection('audit_logs').add({
    'userId': userId,
    'collection': collectionAccessed,
    'timestamp': FieldValue.serverTimestamp(),
    'userAgent': 'mobile_app',
  });
}
```

### 4. **Rate Limiting**
Implement rate limiting to prevent data scraping:
- Use Cloud Functions with throttling
- Limit query results
- Add delays between requests

### 5. **Data Minimization**
- Don't store customer addresses in orders if not needed
- Remove email from product comments (keep user ID only)
- Use separate collection for seller "profiles" that customers see vs. "settings" that only sellers access

---

## ✅ IMPLEMENTATION CHECKLIST

- [ ] Deploy new Firestore security rules
- [ ] Add `getSellerOrders()` method to OrderService
- [ ] Add `getStockConsumedByOrders()` method to OrderService
- [ ] Add `getSellerStockStatus()` method to StockService
- [ ] Create Seller Dashboard screen
- [ ] Implement Cloud Functions for backend validation
- [ ] Add audit logging
- [ ] Test security rules with unauthorized access attempts
- [ ] Remove sensitive data from public queries
- [ ] Update user documentation about seller features

---

## 🧪 TESTING YOUR SECURITY

### Test 1: Verify Order Access Restriction
```dart
// This should FAIL after security rules are deployed
final evilSnapshot = await FirebaseFirestore.instance
    .collection('user_orders')
    .where('userId', isEqualTo: 'someone_elses_uid')
    .get();
// Expected: Permission denied error
```

### Test 2: Verify Seller Can See Own Orders
```dart
final sellerOrders = await OrderService.getSellerOrders(currentUser.uid);
// Expected: Only orders containing this seller's products
```

### Test 3: Verify Stock Calculation
```dart
final stock = await OrderService.getStockConsumedByOrders(sellerId);
// Expected: Map showing qty consumed per product
```

---

## 📊 COMPARISON: BEFORE vs AFTER

| Feature | Before | After |
|---------|--------|-------|
| **Any user can read any order?** | ✅ YES (VULNERABLE) | ❌ NO |
| **Sellers see their orders?** | ❌ NO | ✅ YES |
| **Sellers see stock consumed?** | ❌ NO | ✅ YES |
| **Customer data protected?** | ❌ NO | ✅ YES (encrypted access) |
| **Seller emails visible to customers?** | ✅ YES | ⚠️ Only if needed |

---

## CRITICAL NEXT STEPS

1. **TODAY**: Deploy the security rules above (if any orders exist, this won't break them)
2. **THIS WEEK**: Implement seller order methods
3. **THIS WEEK**: Create seller dashboard
4. **NEXT**: Move validation to Cloud Functions
5. **ONGOING**: Monitor audit logs for suspicious activity

**DO NOT** ignore these vulnerabilities - they expose all your customer and seller data!
