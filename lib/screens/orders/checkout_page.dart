import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/widgets/normal_button.dart';
import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:flutter/material.dart';
import 'package:buy_app/services/selected_address_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final cart = Cart.instance;
  final selectedAddressService = SelectedAddressService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: ColorPallete.color1,
        foregroundColor: Colors.white,
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    child: Text('Continue Shopping'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildAddressSection(),
                    SizedBox(height: 20),
                    _buildCartSummary(),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: NormalButton(
                        hintText: selectedAddressService.hasSelectedAddress
                            ? 'Place Order'
                            : 'Select Delivery Address',
                        onPressed: () {
                          if (selectedAddressService.hasSelectedAddress) {
                            Navigator.pushNamed(
                              context,
                              '/payment',
                              arguments: selectedAddressService.selectedAddress,
                            );
                          } else {
                            Navigator.pushNamed(
                              context,
                              '/address_select',
                            ).then((_) {
                              setState(() {}); // Refresh the UI after selection
                            });
                          }
                        },
                        height: 55,
                        length: double.infinity,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAddressSection() {
    final hasAddress = selectedAddressService.hasSelectedAddress;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: hasAddress ? Colors.green : ColorPallete.color1,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPallete.color1,
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
              Container(
                width: MediaQuery.of(context).size.width - 10,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedAddressService.getFullAddressText(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.orange.shade50,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade600,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please select a delivery address to continue',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorPallete.color1,
              ),
            ),
            SizedBox(height: 16),

            // List all cart items with quantities
            ...cart.items.map(
              (item) => Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
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
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),

                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Qty: ${item.quantity}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '₹${item.effectivePrice.toStringAsFixed(2)} each',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Total for this item
                    Text(
                      '₹${(item.effectivePrice * item.quantity).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorPallete.color1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),
            Divider(thickness: 2),
            SizedBox(height: 8),

            // Total Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Items:', style: TextStyle(fontSize: 16)),
                Text(
                  '${cart.totalItems}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }
}
