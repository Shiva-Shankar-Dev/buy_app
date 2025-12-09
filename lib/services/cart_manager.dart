import '../models/models.dart';

class Cart {
  static final Cart instance = Cart._internal();
  Cart._internal();

  final List<CartItem> _items = [];

  // Define maximum quantities per category
  static const Map<String, int> _categoryMaxQuantities = {
    'mobiles': 4,
    'mobile': 4,
    'phone': 4,
    'smartphone': 4,
    'electronics': 3,
    'laptop': 2,
    'computer': 2,
    'tablet': 3,
    'headphones': 5,
    'earphones': 5,
    'watch': 3,
    'smartwatch': 3,
    'camera': 2,
    'gaming': 2,
    'console': 1,
    'tv': 1,
    'television': 1,
    'appliances': 1,
    'refrigerator': 1,
    'washing machine': 1,
    'microwave': 1,
    'ac': 1,
    'air conditioner': 1,
    'furniture': 2,
    'books': 10,
    'clothing': 8,
    'shoes': 6,
    'accessories': 10,
    'beauty': 5,
    'cosmetics': 5,
    'health': 5,
    'sports': 4,
    'toys': 6,
    'home': 5,
    'kitchen': 3,
    'automotive': 2,
    'jewelry': 4,
    'default': 10, // Default maximum for categories not listed
  };

  /// Get maximum allowed quantity for a category
  static int getMaxQuantityForCategory(String category) {
    if (category.isEmpty) return _categoryMaxQuantities['default']!;

    final categoryLower = category.toLowerCase().trim();

    // Check for exact match first
    if (_categoryMaxQuantities.containsKey(categoryLower)) {
      return _categoryMaxQuantities[categoryLower]!;
    }

    // Check for partial matches
    for (final key in _categoryMaxQuantities.keys) {
      if (categoryLower.contains(key) || key.contains(categoryLower)) {
        return _categoryMaxQuantities[key]!;
      }
    }

    return _categoryMaxQuantities['default']!;
  }

  List<CartItem> get items => _items;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(
    0.0,
    (sum, item) => sum + (item.effectivePrice * item.quantity),
  );

  void add(
    Product product, {
    int quantity = 1,
    String? variantId,
    Map<String, String>? variantAttributes,
  }) {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.product.pid == product.pid &&
          item.selectedVariantId == variantId,
    );

    if (existingIndex >= 0) {
      _items[existingIndex] = CartItem(
        product: _items[existingIndex].product,
        quantity: _items[existingIndex].quantity + quantity,
        selectedVariantId: _items[existingIndex].selectedVariantId,
        selectedAttributes: _items[existingIndex].selectedAttributes,
      );
    } else {
      _items.add(
        CartItem(
          product: product,
          quantity: quantity,
          selectedVariantId: variantId,
          selectedAttributes: variantAttributes,
        ),
      );
    }
  }

  /// Add item to cart with quantity validation
  Map<String, dynamic> addToCartWithValidation(
    Product product, {
    int quantity = 1,
  }) {
    final validation = canAddQuantity(product, quantity);

    if (validation['canAdd']) {
      add(product, quantity: quantity);
      return {'success': true, 'message': validation['message']};
    } else {
      return {
        'success': false,
        'message': validation['message'],
        'reason': validation['reason'],
      };
    }
  }

  void updateQuantity(Product product, int quantity, {String? variantId}) {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.product.pid == product.pid &&
          item.selectedVariantId == variantId,
    );

    if (existingIndex >= 0) {
      if (quantity <= 0) {
        _items.removeAt(existingIndex);
      } else {
        _items[existingIndex] = CartItem(
          product: _items[existingIndex].product,
          quantity: quantity,
          selectedVariantId: _items[existingIndex].selectedVariantId,
          selectedAttributes: _items[existingIndex].selectedAttributes,
        );
      }
    }
  }

  /// Update item quantity with validation
  Map<String, dynamic> updateItemQuantityWithValidation(
    Product product,
    int newQuantity, {
    String? variantId,
  }) {
    final validation = canSetQuantity(
      product,
      newQuantity,
      variantId: variantId,
    );

    if (validation['canSet']) {
      if (newQuantity <= 0) {
        remove(product, variantId: variantId);
      } else {
        updateQuantity(product, newQuantity, variantId: variantId);
      }
      return {'success': true, 'message': validation['message']};
    } else {
      return {
        'success': false,
        'message': validation['message'],
        'reason': validation['reason'],
      };
    }
  }

  /// Get maximum allowed quantity for a product's category
  int getMaxQuantityForProduct(Product product) {
    return getMaxQuantityForCategory(product.category);
  }

  /// Check if adding a quantity would exceed limits
  Map<String, dynamic> canAddQuantity(
    Product product,
    int quantity, {
    String? variantId,
  }) {
    final maxAllowed = getMaxQuantityForCategory(product.category);
    final currentQuantity = getQuantity(product, variantId: variantId);
    final newTotal = currentQuantity + quantity;

    if (quantity > maxAllowed) {
      return {
        'canAdd': false,
        'reason': 'single_quantity_exceeds_limit',
        'message':
            'Cannot add $quantity items. Maximum $maxAllowed allowed for ${product.category} category.',
        'maxAllowed': maxAllowed,
        'requested': quantity,
      };
    }

    if (newTotal > maxAllowed) {
      final availableToAdd = maxAllowed - currentQuantity;
      return {
        'canAdd': false,
        'reason': 'total_would_exceed_limit',
        'message':
            'Cannot add $quantity items. You already have $currentQuantity in cart. Maximum $maxAllowed allowed for ${product.category} category. You can add $availableToAdd more.',
        'maxAllowed': maxAllowed,
        'currentInCart': currentQuantity,
        'requested': quantity,
        'availableToAdd': availableToAdd,
      };
    }

    return {'canAdd': true, 'message': 'Can add $quantity items to cart'};
  }

  /// Check if setting a new quantity is valid
  Map<String, dynamic> canSetQuantity(
    Product product,
    int newQuantity, {
    String? variantId,
  }) {
    if (newQuantity <= 0) {
      return {'canSet': true, 'message': 'Will remove item from cart'};
    }

    final maxAllowed = getMaxQuantityForCategory(product.category);

    if (newQuantity > maxAllowed) {
      return {
        'canSet': false,
        'reason': 'exceeds_category_limit',
        'message':
            'Cannot set quantity to $newQuantity. Maximum $maxAllowed allowed for ${product.category} category.',
        'maxAllowed': maxAllowed,
        'requested': newQuantity,
      };
    }

    return {'canSet': true, 'message': 'Can set quantity to $newQuantity'};
  }

  /// Get validation info for display in UI
  Map<String, dynamic> getQuantityLimitInfo(
    Product product, {
    String? variantId,
  }) {
    final maxAllowed = getMaxQuantityForCategory(product.category);
    final currentInCart = getQuantity(product, variantId: variantId);
    final availableToAdd = maxAllowed - currentInCart;

    return {
      'maxAllowed': maxAllowed,
      'currentInCart': currentInCart,
      'availableToAdd': availableToAdd,
      'category': product.category,
      'limitMessage':
          'Maximum $maxAllowed items allowed for ${product.category} category',
    };
  }

  void remove(Product product, {String? variantId}) {
    _items.removeWhere(
      (item) =>
          item.product.pid == product.pid &&
          item.selectedVariantId == variantId,
    );
  }

  void clear() {
    _items.clear();
  }

  int getQuantity(Product product, {String? variantId}) {
    final item = _items.firstWhere(
      (item) =>
          item.product.pid == product.pid &&
          item.selectedVariantId == variantId,
      orElse: () =>
          CartItem(product: product, quantity: 0, selectedVariantId: variantId),
    );
    return item.quantity;
  }

  bool isInCart(Product product, {String? variantId}) {
    return _items.any(
      (item) =>
          item.product.pid == product.pid &&
          item.selectedVariantId == variantId,
    );
  }

  /// Check if any variant of a product is in cart
  bool isProductInCart(Product product) {
    return _items.any((item) => item.product.pid == product.pid);
  }

  /// Get all cart items for a specific product (all variants)
  List<CartItem> getItemsForProduct(Product product) {
    return _items.where((item) => item.product.pid == product.pid).toList();
  }
}
