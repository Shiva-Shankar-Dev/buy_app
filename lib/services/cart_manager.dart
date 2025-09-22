import '../models/models.dart';

class Cart {
  static final Cart instance = Cart._internal();
  Cart._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(
    0.0,
    (sum, item) => sum + (item.product.price * item.quantity),
  );

  void add(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.title == product.title,
    );

    if (existingIndex >= 0) {
      _items[existingIndex] = CartItem(
        product: _items[existingIndex].product,
        quantity: _items[existingIndex].quantity + quantity,
      );
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
  }

  void updateQuantity(Product product, int quantity) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.title == product.title,
    );

    if (existingIndex >= 0) {
      if (quantity <= 0) {
        _items.removeAt(existingIndex);
      } else {
        _items[existingIndex] = CartItem(
          product: _items[existingIndex].product,
          quantity: quantity,
        );
      }
    }
  }

  void remove(Product product) {
    _items.removeWhere((item) => item.product.title == product.title);
  }

  void clear() {
    _items.clear();
  }

  int getQuantity(Product product) {
    final item = _items.firstWhere(
      (item) => item.product.title == product.title,
      orElse: () => CartItem(product: product, quantity: 0),
    );
    return item.quantity;
  }

  bool isInCart(Product product) {
    return _items.any((item) => item.product.title == product.title);
  }
}
