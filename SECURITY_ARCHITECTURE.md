# Security Architecture & Data Flow

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       FIREBASE BACKEND                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │            FIRESTORE DATABASE (Cloud)                   │   │
│  │                                                          │   │
│  │  📦 Collections:                                        │   │
│  │  ├─ customers/{userId}                                 │   │
│  │  │  └─ [Name, Email, Phone]                            │   │
│  │  ├─ orders/{orderId}                                   │   │
│  │  │  ├─ userId (✅ Secured)                             │   │
│  │  │  ├─ sellerIds (✅ Secured)                          │   │
│  │  │  └─ items[] (✅ Secured)                            │   │
│  │  ├─ products/{productId}                               │   │
│  │  │  ├─ sellerId                                        │   │
│  │  │  └─ stockQuantity (✅ Updated on order)            │   │
│  │  ├─ sellers/{sellerId}                                 │   │
│  │  │  └─ [Business Info] (✅ Secured)                    │   │
│  │  └─ product_comments/{commentId}                       │   │
│  │     └─ [Reviews, Ratings] (✅ Secured)                │   │
│  │                                                          │   │
│  │  🔐 SECURITY RULES APPLIED:                            │   │
│  │  • Customer access control                             │   │
│  │  • Seller access control                               │   │
│  │  • Field-level authorization                           │   │
│  │  • Read/Write restrictions                             │   │
│  │                                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           ▲                                      │
│                           │                                      │
│          ┌────────────────┼────────────────┐                   │
│          │ SECURITY RULES │                │                   │
│          │ Validation     │                │                   │
│          └────────────────┼────────────────┘                   │
│                           │                                      │
└─────────────────────────────────────────────────┬───────────────┘
                                                  │
                    ┌─────────────────────────────┼─────────────────────────────┐
                    │                             │                             │
        ┌───────────▼──────────┐    ┌──────────────▼──────────┐    ┌───────────▼──────────┐
        │   CUSTOMER CLIENT    │    │   SELLER CLIENT        │    │   WEB ADMIN PORTAL   │
        ├──────────────────────┤    ├───────────────────────┤    ├──────────────────────┤
        │                      │    │                       │    │                      │
        │ 📱 Flutter App       │    │ 📱 Seller Dashboard   │    │ 🌐 Web Dashboard     │
        │                      │    │                       │    │                      │
        │ Features:            │    │ Features:             │    │ Features:            │
        │ ✅ Browse products   │    │ ✅ View orders        │    │ ✅ Analytics         │
        │ ✅ Add to cart       │    │ ✅ Track stock        │    │ ✅ Reporting         │
        │ ✅ View own orders   │    │ ✅ Update status      │    │ ✅ User management   │
        │ ❌ See other orders  │    │ ✅ View analytics     │    │                      │
        │                      │    │ ❌ Access other       │    │                      │
        │ Rules Enforced:      │    │    sellers' data      │    │                      │
        │ userId ==           │    │                       │    │                      │
        │ request.auth.uid    │    │ Rules Enforced:       │    │                      │
        │                      │    │ sellerId IN           │    │                      │
        │                      │    │ request.auth.uid      │    │                      │
        │                      │    │ sellerIds             │    │                      │
        └──────────────────────┘    └───────────────────────┘    └──────────────────────┘
```

---

## Data Access Flow

### Customer Access Pattern ✅

```
Customer User A
    │
    ├─ Authenticates
    │       │
    │       ▼
    └──> Firebase Auth ◄──► Firestore Security Rules
            │                      │
            ▼                      ▼
    ┌─────────────────────────────────────┐
    │ Is user authenticated?              │
    │ ✅ YES                              │
    │                                     │
    │ Query: orders where userId == A    │
    │ Rule checks:                        │
    │ • request.auth.uid == 'A'?         │
    │ • resource.data.userId == 'A'?     │
    │ ✅ BOTH TRUE → GRANT ACCESS         │
    └─────────────────────────────────────┘
            │
            ▼
    ┌─────────────────────────────────────┐
    │ Returns: User A's orders only       │
    │                                     │
    │ Order {                             │
    │   orderId: "ORD-123",               │
    │   userId: "A" ✓,                    │
    │   items: [...],                     │
    │   total: 5000                       │
    │ }                                   │
    └─────────────────────────────────────┘
```

### Malicious Access Pattern ❌ (BLOCKED)

```
Malicious User B
    │
    ├─ Authenticates (as User B)
    │       │
    │       ▼
    └──> Firebase Auth ◄──► Firestore Security Rules
            │                      │
            ▼                      ▼
    ┌─────────────────────────────────────┐
    │ Is user authenticated?              │
    │ ✅ YES (but as user B, not A)      │
    │                                     │
    │ Tries to query: orders where       │
    │ userId == 'A' (user A's orders)    │
    │                                     │
    │ Rule validation:                    │
    │ • request.auth.uid == 'B'           │
    │ • Check: 'B' == 'A'? ❌ NO         │
    │ • DENY ACCESS                       │
    └─────────────────────────────────────┘
            │
            ▼
    ┌─────────────────────────────────────┐
    │ Error Response:                     │
    │ "PERMISSION_DENIED:                 │
    │  Missing or insufficient            │
    │  permissions"                       │
    │                                     │
    │ No data returned ✓                  │
    └─────────────────────────────────────┘
```

### Seller Access Pattern ✅

```
Seller S
    │
    ├─ Authenticates
    │       │
    │       ▼
    └──> Firebase Auth ◄──► Firestore Security Rules
            │                      │
            ▼                      ▼
    ┌─────────────────────────────────────┐
    │ Is user authenticated?              │
    │ ✅ YES (Seller S)                   │
    │                                     │
    │ Tries to query: orders containing   │
    │ seller S's products                 │
    │                                     │
    │ Rule checks:                        │
    │ • request.auth.uid in               │
    │   resource.data.sellerIds?          │
    │ • Is 'S' in [seller IDs]? ✅ YES   │
    │ • GRANT ACCESS                      │
    └─────────────────────────────────────┘
            │
            ▼
    ┌─────────────────────────────────────┐
    │ Returns: Orders with seller S's     │
    │ products (filtered automatically)   │
    │                                     │
    │ Order {                             │
    │   orderId: "ORD-456",               │
    │   customer: "John Doe",             │
    │   items: [                          │
    │     {                               │
    │       productId: "P-100",           │
    │       sellerId: "S" ✓,              │
    │       quantity: 2                   │
    │     }                               │
    │   ],                                │
    │   total: 3000                       │
    │ }                                   │
    └─────────────────────────────────────┘
```

---

## Security Rule Structure

### Rule 1: Customer Orders (Most Restrictive)

```
┌──────────────────────────────────────────────────────────────┐
│                     /user_orders/{orderId}                    │
│                                                               │
│  RULE: allow read if request.auth.uid == resource.data.userId│
│                                                               │
│  Meaning:                                                    │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Customer can read ONLY IF:                             │ │
│  │                                                        │ │
│  │ 1. They are authenticated (logged in) ✅              │ │
│  │ 2. Their UID matches order's userId ✅               │ │
│  │                                                        │ │
│  │ = Can only see their own orders                       │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  Example:                                                   │
│  User 'A' tries to read order with userId='A' → ✅ ALLOWED   │
│  User 'B' tries to read order with userId='A' → ❌ DENIED    │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

### Rule 2: Seller Orders

```
┌──────────────────────────────────────────────────────────────┐
│                     /user_orders/{orderId}                    │
│                                                               │
│  RULE: allow read if request.auth.uid in resource.data.sellerIds│
│                                                               │
│  Meaning:                                                    │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Seller can read ONLY IF:                               │ │
│  │                                                        │ │
│  │ 1. They are authenticated ✅                           │ │
│  │ 2. Their UID is in order's sellerIds array ✅          │ │
│  │                                                        │ │
│  │ = Can only see orders for their products              │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  Example:                                                   │
│  Order has items from sellers: [S1, S2, S3]                │
│  User S1 queries → ✅ ALLOWED (S1 in array)                 │
│  User S4 queries → ❌ DENIED (S4 not in array)              │
│  User A (customer) → ❌ DENIED (only in Rule 1)             │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

### Rule 3: No Deletes (Audit Trail)

```
┌──────────────────────────────────────────────────────────────┐
│                     /user_orders/{orderId}                    │
│                                                               │
│  RULE: allow delete if false                                 │
│                                                               │
│  Meaning:                                                    │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ NO ONE can delete orders, EVER                         │ │
│  │                                                        │ │
│  │ = Orders are permanent (audit trail)                  │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                               │
│  Example:                                                   │
│  Anyone tries to delete → ❌ ALWAYS DENIED                   │
│  Exception: Cloud Functions with admin SDK only             │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## Data Encryption & Security Layers

```
┌─────────────────────────────────────────────────────────────┐
│                  SECURITY LAYERS                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Layer 1: TRANSPORT SECURITY                               │
│  ─────────────────────────────                             │
│  ┌─────────────┐              ┌────────────────────┐       │
│  │   Client    │ ◄──HTTPS──► │ Firestore (Cloud)  │       │
│  │   (App)     │ TLS 1.2+     │ (Always Encrypted) │       │
│  └─────────────┘              └────────────────────┘       │
│                 Data in transit encrypted ✅               │
│                                                              │
│  Layer 2: AUTHENTICATION                                   │
│  ──────────────────────────                               │
│  ┌──────────────────────────────────┐                      │
│  │ Firebase Auth                    │                      │
│  │ • Email/Password                 │                      │
│  │ • Phone OTP                      │                      │
│  │ • Social Login                   │                      │
│  │ Result: Unique UID token        │                      │
│  └──────────────────────────────────┘                      │
│                User identity verified ✅                    │
│                                                              │
│  Layer 3: AUTHORIZATION (RULES)                            │
│  ──────────────────────────────────                        │
│  ┌──────────────────────────────────┐                      │
│  │ Firestore Security Rules         │                      │
│  │ • Read rules                     │                      │
│  │ • Write rules                    │                      │
│  │ • Field-level rules              │                      │
│  │ • Custom validation              │                      │
│  └──────────────────────────────────┘                      │
│                Access control enforced ✅                   │
│                                                              │
│  Layer 4: ENCRYPTION AT REST                               │
│  ────────────────────────────                             │
│  ┌──────────────────────────────────┐                      │
│  │ Firestore Cloud Storage          │                      │
│  │ • AES-256 encryption             │                      │
│  │ • Google managed keys            │                      │
│  │ • Automatic backups              │                      │
│  └──────────────────────────────────┘                      │
│                Data at rest encrypted ✅                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Order Creation & Stock Update Flow

```
┌─────────────────────────────────────────────────────────────┐
│                COMPLETE ORDER FLOW                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Step 1: Customer Checkout                                │
│  ───────────────────────                                  │
│    ┌──────────────────────────────────────┐               │
│    │ Customer selects items & pays        │               │
│    │ • Product 1 (Seller A) × 2           │               │
│    │ • Product 2 (Seller B) × 1           │               │
│    │ Total: ₹5000                         │               │
│    └──────────────────────────────────────┘               │
│                  │                                         │
│                  ▼                                         │
│                                                              │
│  Step 2: Order Creation & Security                        │
│  ─────────────────────────────────                        │
│    ┌──────────────────────────────────────┐               │
│    │ OrderService.createOrder()           │               │
│    │                                      │               │
│    │ 1. Get current user (auth check)    │               │
│    │ 2. Create order document:           │               │
│    │    {                                │               │
│    │      orderId: "ORD-123",            │               │
│    │      userId: "A" ← ✅ SECURED       │               │
│    │      items: [...],                  │               │
│    │      sellerIds: ["SA", "SB"],       │               │
│    │      total: 5000,                   │               │
│    │      timestamp: NOW()               │               │
│    │    }                                │               │
│    │ 3. Write to Firestore               │               │
│    └──────────────────────────────────────┘               │
│                  │                                         │
│                  ▼                                         │
│                                                              │
│  Step 3: Firestore Rules Validation                       │
│  ──────────────────────────────────────                   │
│    ┌──────────────────────────────────────┐               │
│    │ match /user_orders/{orderId}         │               │
│    │                                      │               │
│    │ Rule 1: Validate creator            │               │
│    │ ✅ request.auth.uid == userId?      │               │
│    │                                      │               │
│    │ Rule 2: Validate data completeness  │               │
│    │ ✅ All required fields present?     │               │
│    │                                      │               │
│    │ Both passed? → WRITE ALLOWED         │               │
│    └──────────────────────────────────────┘               │
│                  │                                         │
│                  ▼                                         │
│                                                              │
│  Step 4: Stock Decrement                                 │
│  ─────────────────────                                   │
│    ┌──────────────────────────────────────┐               │
│    │ For each order item:                 │               │
│    │                                      │               │
│    │ StockService.decrementStock()        │               │
│    │                                      │               │
│    │ Product 1 (Qty: 2)                   │               │
│    │ Before: 50 units                     │               │
│    │ After: 48 units ← Updated            │               │
│    │                                      │               │
│    │ Product 2 (Qty: 1)                   │               │
│    │ Before: 30 units                     │               │
│    │ After: 29 units ← Updated            │               │
│    └──────────────────────────────────────┘               │
│                  │                                         │
│                  ▼                                         │
│                                                              │
│  Step 5: Notifications Sent                              │
│  ───────────────────────────                             │
│    ┌──────────────────────────────────────┐               │
│    │ EmailService.sendNotifications()    │               │
│    │                                      │               │
│    │ To Customer A:                       │               │
│    │ "Order confirmed! #ORD-123"          │               │
│    │ + Invoice PDF                        │               │
│    │                                      │               │
│    │ To Seller A:                         │               │
│    │ "New order! Customer ordered 2x"     │               │
│    │ + Order details                      │               │
│    │                                      │               │
│    │ To Seller B:                         │               │
│    │ "New order! Customer ordered 1x"     │               │
│    │ + Order details                      │               │
│    └──────────────────────────────────────┘               │
│                  │                                         │
│                  ▼                                         │
│                                                              │
│  Step 6: Order Complete                                  │
│  ──────────────────────                                  │
│    ✅ Order saved (secure)                                │
│    ✅ Stock updated                                        │
│    ✅ Notifications sent                                   │
│    ✅ Audit trail created                                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Seller Dashboard Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│        SELLER DASHBOARD DATA RETRIEVAL FLOW                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Seller logs in                                            │
│      │                                                      │
│      ▼                                                      │
│  ┌────────────────────────────────┐                        │
│  │ SellerDashboardPage init()     │                        │
│  │ • Get current seller UID       │                        │
│  └────────────────────────────────┘                        │
│      │                                                      │
│      ▼                                                      │
│  ┌────────────────────────────────────────────────────┐   │
│  │ Query 1: OrderService.getSellerOrders(sellerId)   │   │
│  │                                                    │   │
│  │ Firestore Query:                                   │   │
│  │ WHERE sellerIds CONTAINS sellerId                 │   │
│  │ RULE CHECK:                                       │   │
│  │ • Seller S queries                               │   │
│  │ • Check: S in document.sellerIds? → Yes           │   │
│  │ • ALLOW READ ✅                                   │   │
│  │                                                    │   │
│  │ Returns: [Order1, Order2, Order3, ...]           │   │
│  └────────────────────────────────────────────────────┘   │
│      │                                                      │
│      ▼                                                      │
│  ┌────────────────────────────────────────────────────┐   │
│  │ Query 2: OrderService.getStockAnalytics(sellerId) │   │
│  │                                                    │   │
│  │ Process each order:                               │   │
│  │ • Extract items from seller S                     │   │
│  │ • Count quantity by productId                     │   │
│  │ • Sum consumed quantities                         │   │
│  │                                                    │   │
│  │ Query products:                                   │   │
│  │ WHERE sellerId == S                              │   │
│  │ RULE CHECK:                                       │   │
│  │ • Seller can read own products                    │   │
│  │ • ALLOW READ ✅                                   │   │
│  │                                                    │   │
│  │ Calculate per product:                            │   │
│  │ • Total stock (from product)                      │   │
│  │ • Consumed (from orders)                          │   │
│  │ • Remaining = Total - Consumed                    │   │
│  │ • % Sold = (Consumed / Total) × 100               │   │
│  │                                                    │   │
│  │ Returns: Map<ProductId, Analytics>               │   │
│  └────────────────────────────────────────────────────┘   │
│      │                                                      │
│      ▼                                                      │
│  ┌────────────────────────────────┐                        │
│  │ Render Dashboard Tabs           │                        │
│  │                                 │                        │
│  │ Tab 1: Orders                   │                        │
│  │ ├─ Order #ORD-001               │                        │
│  │ │  ├─ Customer: John Doe        │                        │
│  │ │  ├─ Email: john@...           │                        │
│  │ │  ├─ Items: 2 products         │                        │
│  │ │  └─ Total: ₹5000              │                        │
│  │ │                                │                        │
│  │ └─ Order #ORD-002               │                        │
│  │    └─ ...                        │                        │
│  │                                 │                        │
│  │ Tab 2: Stock Analytics          │                        │
│  │ ├─ Product A                    │                        │
│  │ │  ├─ Total: 100 units          │                        │
│  │ │  ├─ Consumed: 25              │                        │
│  │ │  ├─ Remaining: 75             │                        │
│  │ │  └─ Sold: 25%                 │                        │
│  │ │                                │                        │
│  │ └─ Product B                    │                        │
│  │    └─ ...                        │                        │
│  └────────────────────────────────┘                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Security Rule Validation Flowchart

```
                        ┌─────────────────┐
                        │  Client Query   │
                        │  to Firestore   │
                        └────────┬────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │  Is user auth?  │
                        └────────┬────────┘
                                 │
                    ┌────────────┴────────────┐
                    │ No                      │ Yes
                    ▼                         ▼
            ┌──────────────┐        ┌─────────────────┐
            │ ❌ DENY ALL  │        │  Load Firestore │
            │  (Anonymous) │        │  Rules for path │
            └──────────────┘        └────────┬────────┘
                                             │
                                             ▼
                                  ┌──────────────────────┐
                                  │ Check READ rule:     │
                                  │                      │
                                  │ For /user_orders:    │
                                  │                      │
                                  │ Test 1:              │
                                  │ request.auth.uid ==  │
                                  │ document.userId?     │
                                  │                      │
                                  │ Test 2:              │
                                  │ request.auth.uid IN  │
                                  │ document.sellerIds?  │
                                  └──────┬───────────────┘
                                         │
                        ┌────────────────┼────────────────┐
                        │                │                │
              Test 1    │              Both               │    Neither
              Only ✅   │              Fail ❌            │    Pass ✅
                        │                │                │
                        ▼                ▼                ▼
                  ┌──────────┐    ┌──────────────┐  ┌──────────┐
                  │ ✅ GRANT │    │  ❌ DENY     │  │ ✅ GRANT │
                  │ (Customer)    │  (Hacker)    │  │ (Seller) │
                  └──────────┘    └──────────────┘  └──────────┘
                        │                │                │
                        └────────────────┼────────────────┘
                                         │
                                         ▼
                          ┌──────────────────────────┐
                          │ Return Data to Client    │
                          │ (or permission error)    │
                          └──────────────────────────┘
```

---

This architecture ensures that data access is always validated at the database level, making it impossible to bypass security through app manipulation.
