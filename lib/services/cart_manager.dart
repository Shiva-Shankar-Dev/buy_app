import 'package:buy_app/screens/home_page.dart'; // for Product model

class Cart {
  static final Cart instance = Cart._internal();

  Cart._internal();

  final List<Product> _items = [];

  List<Product> get items => _items;

  void add(Product product) {
    _items.add(product);
  }

  void remove(Product product) {
    _items.remove(product);
  }

  void clear() {
    _items.clear();
  }

  double get totalPrice =>
      _items.fold(0.0, (sum, product) => sum + product.price);
}
