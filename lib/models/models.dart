import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CartItem {
  final Product product;
  final int quantity;
  final String?
  selectedVariantId; // Selected variant ID for products with variants
  final Map<String, String>? selectedAttributes; // Selected variant attributes

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedVariantId,
    this.selectedAttributes,
  });

  // Get effective price (variant price or base price)
  double get effectivePrice {
    return product.getPriceForVariant(selectedVariantId);
  }

  // Get effective stock (variant stock or base stock)
  int get effectiveStock {
    return product.getStockForVariant(selectedVariantId);
  }

  // Get effective images (variant images or base images)
  List<String> get effectiveImages {
    return product.getImagesForVariant(selectedVariantId);
  }

  // Get variant display text
  String get variantDisplayText {
    if (selectedVariantId != null) {
      final variant = product.getVariantById(selectedVariantId!);
      return variant?.displayText ?? '';
    }
    return '';
  }

  @override
  String toString() {
    final variantText = selectedVariantId != null
        ? ' (${variantDisplayText})'
        : '';
    return 'CartItem(product: ${product.name}$variantText, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.product.pid == product.pid &&
        other.selectedVariantId == selectedVariantId;
  }

  @override
  int get hashCode =>
      product.pid.hashCode ^
      (selectedVariantId?.hashCode ?? 0) ^
      quantity.hashCode;

  // Add toMap method for Firestore
  Map<String, dynamic> toMap() {
    return {
      'product': product.toFirestore(),
      'quantity': quantity,
      if (selectedVariantId != null) 'selectedVariantId': selectedVariantId,
      if (selectedAttributes != null) 'selectedAttributes': selectedAttributes,
    };
  }

  // Add fromMap method for Firestore
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: Product.fromFirestore(map['product'] ?? {}),
      quantity: map['quantity'] ?? 1,
      selectedVariantId: map['selectedVariantId'],
      selectedAttributes: map['selectedAttributes'] != null
          ? Map<String, String>.from(map['selectedAttributes'])
          : null,
    );
  }
}

// Product Variant Class
class ProductVariant {
  final String variantId;
  final Map<String, String> attributes; // e.g., {"color": "Red", "size": "M"}
  final double? price; // If variant has different price
  final double? basePrice; // Base price for the variant
  final double? priceModifier; // Price modifier amount
  final String? name; // Variant name
  final int stockQuantity;
  final List<String>? images; // Variant-specific images
  final String? image; // Single variant image (for compatibility)
  final String? sku; // Stock Keeping Unit

  ProductVariant({
    required this.variantId,
    required this.attributes,
    this.price,
    this.basePrice,
    this.priceModifier,
    this.name,
    required this.stockQuantity,
    this.images,
    this.image,
    this.sku,
  });

  factory ProductVariant.fromFirestore(Map<String, dynamic> data) {
    try {
      print('Creating ProductVariant from data: ${data.keys.toList()}');
      return ProductVariant(
        variantId: data['variantId'] ?? '',
        attributes: Map<String, String>.from(data['attributes'] ?? {}),
        price: data['price']?.toDouble(),
        basePrice: data['basePrice']?.toDouble(),
        priceModifier: data['priceModifier']?.toDouble(),
        name: data['name'],
        stockQuantity: data['stockQuantity'] ?? 0,
        images: data['images'] != null
            ? List<String>.from(data['images'])
            : null,
        image: data['image'],
        sku: data['sku'],
      );
    } catch (e, stackTrace) {
      print('Error creating ProductVariant from Firestore: $e');
      print('Data: $data');
      print('StackTrace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'variantId': variantId,
      'attributes': attributes,
      if (price != null) 'price': price,
      if (basePrice != null) 'basePrice': basePrice,
      if (priceModifier != null) 'priceModifier': priceModifier,
      if (name != null) 'name': name,
      'stockQuantity': stockQuantity,
      if (images != null) 'images': images,
      if (image != null) 'image': image,
      if (sku != null) 'sku': sku,
    };
  }

  // Get effective images for the variant
  List<String> getEffectiveImages(List<String> fallbackImages) {
    if (image != null && image!.isNotEmpty) {
      return [image!];
    } else if (images != null && images!.isNotEmpty) {
      return images!;
    } else {
      return fallbackImages;
    }
  }

  // Get display text for variant (e.g., "Red, Size M")
  String get displayText {
    return attributes.values.join(', ');
  }

  // Check if variant matches given attributes
  bool matchesAttributes(Map<String, String> searchAttributes) {
    for (final entry in searchAttributes.entries) {
      if (attributes[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductVariant && other.variantId == variantId;
  }

  @override
  int get hashCode => variantId.hashCode;
}

class Product {
  final String name, brand, description, deliveryTime, pid, sellerId;
  final double price; // Base price (used when no variants or as fallback)
  final double? basePrice; // Base price from product data
  final String category;
  final List<String> keywords;
  final List<String> images; // Base product images
  final int stockQuantity; // Base stock (used when no variants)
  final List<ProductVariant> variants; // Product variants
  final bool
  hasVariants; // Flag to indicate if product has variants (from Firestore)
  final List<String>
  availableAttributes; // Available attribute types (e.g., ["color", "size"])

  Product({
    required this.name,
    required this.brand,
    required this.images,
    required this.description,
    required this.category,
    required this.price,
    this.basePrice,
    required this.deliveryTime,
    required this.pid,
    required this.keywords,
    required this.stockQuantity,
    required this.sellerId,
    required this.hasVariants,
    this.variants = const [],
    this.availableAttributes = const [],
  });

  factory Product.fromFirestore(Map<String, dynamic> data) {
    try {
      print('═══════════════════════════════════════════════════');
      print('🔍 CREATING PRODUCT FROM FIRESTORE');
      print('═══════════════════════════════════════════════════');
      print('Data keys: ${data.keys.toList()}');

      // Get variants array with explicit type checking
      print('');
      print('📦 VARIANTS PARSING:');
      print('Raw variants value: ${data['variants']}');
      print('Variants type: ${data['variants'].runtimeType}');

      final variantsData = data['variants'];
      List<dynamic> variantsList = [];

      if (variantsData != null) {
        if (variantsData is List<dynamic>) {
          variantsList = variantsData;
          print('✅ Variants is a List<dynamic>');
        } else if (variantsData is List) {
          variantsList = List<dynamic>.from(variantsData);
          print('✅ Variants converted to List<dynamic>');
        } else {
          print('❌ Variants is not a list! Type: ${variantsData.runtimeType}');
          variantsList = [];
        }
      } else {
        print('⚠️ Variants key is null or missing');
        variantsList = [];
      }

      print('Final variantsList count: ${variantsList.length}');
      print('');

      final variants = <ProductVariant>[];

      for (int i = 0; i < variantsList.length; i++) {
        try {
          print('Processing variant $i:');
          final variantItem = variantsList[i];
          print('  Raw item: $variantItem');
          print('  Item type: ${variantItem.runtimeType}');

          // Ensure it's a map
          late Map<String, dynamic> variantMap;
          if (variantItem is Map<String, dynamic>) {
            variantMap = variantItem;
            print('  ✅ Already a Map<String, dynamic>');
          } else if (variantItem is Map) {
            variantMap = Map<String, dynamic>.from(variantItem);
            print('  ✅ Converted to Map<String, dynamic>');
          } else {
            print('  ❌ Item is not a map! Skipping variant $i');
            continue;
          }

          print('  Map keys: ${variantMap.keys.toList()}');
          print('  variantId: ${variantMap['variantId']}');
          print('  attributes: ${variantMap['attributes']}');
          print('  price: ${variantMap['price']}');

          final variant = ProductVariant.fromFirestore(variantMap);
          variants.add(variant);
          print('  ✅ Variant $i created successfully');
        } catch (e, st) {
          print('  ❌ Error processing variant $i: $e');
          print('  StackTrace: $st');
        }
        print('');
      }

      print('Total variants parsed: ${variants.length}');
      print('');

      // Auto-detect availableAttributes if not provided
      List<String> finalAvailableAttributes = List<String>.from(
        data['availableAttributes'] ?? [],
      );

      print('📋 AVAILABLE ATTRIBUTES:');
      print('From data: ${data['availableAttributes']}');

      // If no availableAttributes specified, auto-detect from variants
      if (finalAvailableAttributes.isEmpty && variants.isNotEmpty) {
        print('Auto-detecting attributes from ${variants.length} variants...');
        final detectedAttrs = <String>{};
        for (final variant in variants) {
          print('  Variant attributes: ${variant.attributes}');
          detectedAttrs.addAll(variant.attributes.keys);
        }
        finalAvailableAttributes = detectedAttrs.toList()..sort();
        print('✅ Auto-detected attributes: $finalAvailableAttributes');
      } else if (finalAvailableAttributes.isNotEmpty) {
        print('✅ Using provided attributes: $finalAvailableAttributes');
      } else {
        print('⚠️ No attributes found');
      }
      print('');

      final product = Product(
        name: data['name'] ?? 'Untitled',
        brand: data['brand'] ?? '',
        description: data['description'] ?? '',
        deliveryTime: data['deliveryTime'] ?? 'N/A',
        pid: data['pid'] ?? '',
        price: (data['price'] ?? 0).toDouble(),
        basePrice: data['basePrice']?.toDouble(),
        category: data['category'] ?? '',
        keywords: List<String>.from(data['keywords'] ?? []),
        images: List<String>.from(data['images'] ?? []),
        stockQuantity: data['stockQuantity'] ?? 0,
        sellerId: data['sellerId'] ?? '',
        hasVariants: data['hasVariants'] ?? false,
        variants: variants,
        availableAttributes: finalAvailableAttributes,
      );

      print('✅ PRODUCT CREATED:');
      print('  Name: ${product.name}');
      print('  PID: ${product.pid}');
      print('  hasVariants: ${product.hasVariants}');
      print('  Variants: ${product.variants.length}');
      print('  Available Attributes: ${product.availableAttributes}');
      print('═══════════════════════════════════════════════════');
      print('');

      return product;
    } catch (e, stackTrace) {
      print('❌ ERROR CREATING PRODUCT FROM FIRESTORE: $e');
      print('StackTrace: $stackTrace');
      print('═══════════════════════════════════════════════════');
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brand': brand,
      'description': description,
      'deliveryTime': deliveryTime,
      'pid': pid,
      'price': price,
      if (basePrice != null) 'basePrice': basePrice,
      'category': category,
      'keywords': keywords,
      'images': images,
      'stockQuantity': stockQuantity,
      'sellerId': sellerId,
      'variants': variants.map((v) => v.toFirestore()).toList(),
      'hasVariants': hasVariants,
      'availableAttributes': availableAttributes,
    };
  }

  // Helper methods for variants

  /// Get total available stock (sum of all variant stocks or base stock)
  int get totalAvailableStock {
    if (hasVariants) {
      return variants.fold(0, (sum, variant) => sum + variant.stockQuantity);
    }
    return stockQuantity;
  }

  /// Get variant by ID
  ProductVariant? getVariantById(String variantId) {
    try {
      return variants.firstWhere((v) => v.variantId == variantId);
    } catch (e) {
      return null;
    }
  }

  /// Get variants matching specific attributes
  List<ProductVariant> getVariantsByAttributes(Map<String, String> attributes) {
    return variants.where((v) => v.matchesAttributes(attributes)).toList();
  }

  /// Get all unique values for a specific attribute
  List<String> getAttributeValues(String attributeName) {
    final values = <String>{};
    for (final variant in variants) {
      final value = variant.attributes[attributeName];
      if (value != null) {
        values.add(value);
      }
    }
    return values.toList()..sort();
  }

  /// Get price for specific variant or base price
  double getPriceForVariant(String? variantId) {
    if (variantId != null && hasVariants) {
      final variant = getVariantById(variantId);
      return variant?.price ?? price;
    }
    return price;
  }

  /// Get stock for specific variant or base stock
  int getStockForVariant(String? variantId) {
    if (variantId != null && hasVariants) {
      final variant = getVariantById(variantId);
      return variant?.stockQuantity ?? 0;
    }
    return stockQuantity;
  }

  /// Get images for specific variant or base images
  List<String> getImagesForVariant(String? variantId) {
    if (variantId != null && hasVariants) {
      final variant = getVariantById(variantId);
      if (variant != null) {
        return variant.getEffectiveImages(images);
      }
    }
    return images;
  }

  @override
  String toString() {
    return 'Product(name: $name, price: $price, brand: $brand, variants: ${variants.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.pid == pid;
  }

  @override
  int get hashCode => pid.hashCode;
}

class Order {
  final String orderId;
  final String customerEmail;
  final String customerName;
  final List<CartItem> items;
  final double totalAmount;
  final String paymentMethod;
  final String txnId;
  final DateTime orderDate;
  final String status;
  final Map<String, dynamic> shippingAddress;

  Order({
    required this.orderId,
    required this.customerEmail,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.txnId,
    required this.orderDate,
    required this.status,
    required this.shippingAddress,
  });

  factory Order.fromFirestore(Map<String, dynamic> data) {
    try {
      return Order(
        orderId: data['orderId']?.toString() ?? '',
        customerEmail: data['customerEmail']?.toString() ?? '',
        customerName: data['customerName']?.toString() ?? '',
        items: _parseItems(data['items']),
        totalAmount: _parseDouble(data['totalAmount']),
        paymentMethod: data['paymentMethod']?.toString() ?? '',
        txnId: data['txnId']?.toString() ?? '',
        orderDate: _parseDateTime(data['orderDate']),
        status: data['status']?.toString() ?? 'Pending',
        shippingAddress: Map<String, dynamic>.from(
          data['shippingAddress'] ?? {},
        ),
      );
    } catch (e) {
      debugPrint('❌ Error parsing Order from Firestore: $e');
      // Return a default order in case of parsing error
      return Order(
        orderId: data['orderId']?.toString() ?? 'unknown',
        customerEmail: data['customerEmail']?.toString() ?? '',
        customerName: data['customerName']?.toString() ?? '',
        items: [],
        totalAmount: 0.0,
        paymentMethod: '',
        txnId: '',
        orderDate: DateTime.now(),
        status: 'Error',
        shippingAddress: {},
      );
    }
  }

  // Helper methods for parsing (static methods inside Order class)
  static List<CartItem> _parseItems(dynamic itemsData) {
    try {
      if (itemsData is List) {
        return itemsData.map((item) {
          try {
            return CartItem.fromMap(Map<String, dynamic>.from(item ?? {}));
          } catch (e) {
            debugPrint('❌ Error parsing CartItem: $e');
            // Return a default CartItem with basic Product
            return CartItem(
              product: Product(
                name: 'Error Product',
                brand: '',
                description: '',
                deliveryTime: '',
                pid: '',
                price: 0.0,
                category: '',
                keywords: [],
                images: [],
                stockQuantity: 0,
                sellerId: '',
                hasVariants: false,
              ),
              quantity: 1,
            );
          }
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error parsing items list: $e');
      return [];
    }
  }

  static double _parseDouble(dynamic value) {
    try {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    } catch (e) {
      debugPrint('❌ Error parsing double: $e');
      return 0.0;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    try {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    } catch (e) {
      debugPrint('❌ Error parsing DateTime: $e');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerEmail': customerEmail,
      'customerName': customerName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'txnId': txnId,
      'orderDate': Timestamp.fromDate(orderDate),
      'status': status,
      'shippingAddress': shippingAddress,
    };
  }

  @override
  String toString() {
    return 'Order(orderId: $orderId, customerEmail: $customerEmail, totalAmount: $totalAmount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.orderId == orderId;
  }

  @override
  int get hashCode => orderId.hashCode;
}
