# Seller Email Notification System Documentation

## Overview
This system automatically sends order details to sellers when customers place orders.

## How it works:

### 1. Product Structure (Firestore: `products` collection)
```json
{
  "title": "Product Name",
  "description": "Product description",
  "price": 299.99,
  "Delivery Time": "2-3 days",
  "ratings": "4.5 stars",
  "images": ["url1", "url2"],
  "sellerId": "seller_firebase_user_id",  // ← This is the key field
  "extraFields": {
    "category": "electronics",
    "brand": "Samsung"
  }
}
```

### 2. Sellers Structure (Firestore: `sellers` collection)
```json
{
  "name": "John's Electronics Store",
  "email": "john@electronicsstore.com",  // ← Email where orders will be sent
  "phone": "+91987654321",
  "address": "123 Market Street",
  "businessType": "electronics"
}
```

### 3. Customer Structure (Firestore: `customers` collection)
```json
{
  "name": "Customer Name",
  "email": "customer@email.com",
  "phone": "+919876543210",
  "role": "customer"
}
```

## Email Flow:

1. **Customer places order** → Selects products and address
2. **System groups products by sellerId** → Multiple products from same seller = 1 email
3. **Fetches seller email** → Using sellerId from SellerService
4. **Sends detailed email to seller** containing:
   - Customer details (name, email, phone)
   - Shipping address (complete address)
   - Ordered products list with prices
   - Total amount
5. **Sends confirmation email to customer**

## What sellers receive:
```
Subject: New Order Received - Order from John Doe

Dear Seller,

You have received a new order from John Doe!

CUSTOMER DETAILS:
Name: John Doe
Email: john@email.com
Phone: +919876543210

SHIPPING ADDRESS:
John Doe
123 Main Street
Apartment 4B
Mumbai, Maharashtra - 400001

ORDERED PRODUCTS:
- Smartphone - ₹25000.00
- Phone Case - ₹500.00

TOTAL AMOUNT: ₹25500.00

Please process this order and contact the customer if needed.

Thank you!
```

## Setup Requirements:

1. **Products must have sellerId**: Add `sellerId` field to your products in Firestore
2. **Create sellers collection**: Add seller documents with email addresses
3. **Node.js email server**: Must be running on localhost:3000
4. **Cart system**: Products go through cart → checkout → payment flow

## Usage:
When customer clicks "Confirm Order" in payment page:
- ✅ Customer gets confirmation email
- ✅ Each seller gets order details email
- ✅ SMS sent to customer
- ✅ Order processing begins
