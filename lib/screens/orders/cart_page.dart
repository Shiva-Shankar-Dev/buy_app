import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:flutter/material.dart';
import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/models/models.dart'; // Add this import for CartItem
import 'package:buy_app/services/selected_address_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final cart = Cart.instance;
  final selectedAddressService = SelectedAddressService.instance;

  Widget _buildAddressCard() {
    final hasAddress = selectedAddressService.hasSelectedAddress;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: hasAddress ? Colors.green : ColorPallete.color1,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Spacer(),
              if (hasAddress)
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/address_select').then((_) {
                      setState(() {}); // Refresh the UI after selection
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: ColorPallete.color1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'CHANGE',
                      style: TextStyle(
                        color: ColorPallete.color1,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          if (hasAddress) ...[
            Text(
              selectedAddressService.getFullAddressText(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/address_select').then((_) {
                  setState(() {}); // Refresh the UI after selection
                });
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: ColorPallete.color1, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: ColorPallete.color1.withAlpha(13),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tap to select delivery address',
                        style: TextStyle(
                          color: ColorPallete.color1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: ColorPallete.color1,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

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
        backgroundColor: ColorPallete.color1,
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
                      backgroundColor: ColorPallete.color1,
                    ),
                    child: Text(
                      'Continue Shopping',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Address Selection Card
                  _buildAddressCard(),

                  // Cart Items List
                  Card(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: cart.items.length,
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return Card(
                          elevation: 0,
                          color: Colors.white,
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
                                    errorBuilder: (_, _, _) => Container(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      SizedBox(height: 4),
                                      Text(
                                        item.product.description,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
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
                                              color: ColorPallete.color1,
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
                  SizedBox(height: 16),

                  // Cart Summary - Separate Container
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Subtotal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal (${cart.totalItems} items):',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              '₹${cart.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Divider(height: 1, color: Colors.grey.shade300),
                        SizedBox(height: 12),

                        // Shipping
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Shipping:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              'FREE',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Divider(height: 1, color: Colors.grey.shade300),
                        SizedBox(height: 12),

                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
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
                                color: ColorPallete.color1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Checkout Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectedAddressService.hasSelectedAddress) {
                                Navigator.pushNamed(context, '/checkout');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please select a delivery address first',
                                    ),
                                    backgroundColor: Colors.orange,
                                    action: SnackBarAction(
                                      label: 'SELECT',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/address_select',
                                        ).then((_) {
                                          setState(
                                            () {},
                                          ); // Refresh the UI after selection
                                        });
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorPallete.color1,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              selectedAddressService.hasSelectedAddress
                                  ? 'PROCEED TO CHECKOUT'
                                  : 'SELECT DELIVERY ADDRESS',
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
                  SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
