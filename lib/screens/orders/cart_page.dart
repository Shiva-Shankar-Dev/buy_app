import 'package:buy_app/widgets/normal_button.dart';
import 'package:buy_app/widgets/outline_button.dart';
import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:flutter/material.dart';
import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/models/models.dart'; // Add this import for CartItem

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final cart = Cart.instance;

  Widget _buildQuantityControls(CartItem item) {
    final limitInfo = cart.getQuantityLimitInfo(item.product);
    final canIncrease = limitInfo['availableToAdd'] > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrease button
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (item.quantity > 1) {
                      cart.updateQuantity(item.product, item.quantity - 1);
                    } else {
                      cart.remove(item.product);
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    item.quantity > 1 ? Icons.remove : Icons.delete,
                    color: item.quantity > 1 ? Colors.black : Colors.red,
                    size: 18,
                  ),
                ),
              ),

              // Quantity display
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${item.quantity}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              // Increase button
              GestureDetector(
                onTap: () {
                  if (canIncrease) {
                    setState(() {
                      cart.updateQuantity(item.product, item.quantity + 1);
                    });
                  } else {
                    // Show limit message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Maximum ${limitInfo['maxAllowed']} items allowed for ${item.product.category} category',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.add,
                    color: canIncrease ? Colors.black : Colors.grey,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Show limit info if approaching limit
        if (limitInfo['availableToAdd'] <= 2 && limitInfo['availableToAdd'] > 0)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '${limitInfo['availableToAdd']} more available',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Show max reached message
        if (limitInfo['availableToAdd'] == 0)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Max limit reached',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorPallete.color1,
        title: Text(
          'Cart (${cart.totalItems} items)',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPallete.color1,
                    ),
                    child: Text(
                      'Continue Shopping',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.product.images.isNotEmpty
                                      ? item.product.images.first
                                      : '',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),

                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '₹${item.product.price.toStringAsFixed(2)} each',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildQuantityControls(item),
                                        Text(
                                          '₹${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: colorPallete.color1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Cart Summary
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total (${cart.totalItems} items):',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${cart.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorPallete.color1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/checkout');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPallete.color1,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'PROCEED TO CHECKOUT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
