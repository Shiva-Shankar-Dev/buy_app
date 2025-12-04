import 'package:buy_app/services/cart_manager.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:buy_app/ColorPallete/color_pallete.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:buy_app/models/models.dart';
import 'package:buy_app/services/wishlist_service.dart';
import 'package:buy_app/services/addresses.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final cart = Cart.instance;
  bool isInWishlist = false;
  bool isLoadingWishlist = false;
  bool isCheckingWishlist = true;
  bool isLoadingSeller = true;
  Map<String, dynamic>? sellerData;
  bool showGoToCartButton = false;
  Address? selectedAddress;
  bool isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    checkWishlistStatus();
    loadSellerDetails();
    loadSelectedAddress();
  }

  Future<void> checkWishlistStatus() async {
    final inWishlist = await WishlistService.isInWishlist(widget.product);
    setState(() {
      isInWishlist = inWishlist;
      isCheckingWishlist = false;
    });
  }

  Future<void> loadSellerDetails() async {
    try {
      if (widget.product.sellerId.isEmpty) {
        setState(() {
          isLoadingSeller = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(widget.product.sellerId)
          .get();

      if (doc.exists) {
        setState(() {
          sellerData = doc.data();
          isLoadingSeller = false;
        });
      } else {
        setState(() {
          isLoadingSeller = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading seller details: $e');
      setState(() {
        isLoadingSeller = false;
      });
    }
  }

  Future<void> loadSelectedAddress() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          isLoadingAddress = false;
        });
        return;
      }

      final addressesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .limit(1)
          .get();

      if (addressesSnapshot.docs.isNotEmpty) {
        final addressDoc = addressesSnapshot.docs.first;
        setState(() {
          selectedAddress = Address.fromMap(
            addressDoc.data(),
            addressDoc.id,
          );
          isLoadingAddress = false;
        });
      } else {
        setState(() {
          isLoadingAddress = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading address: $e');
      setState(() {
        isLoadingAddress = false;
      });
    }
  }

  Future<void> toggleWishlist() async {
    if (isInWishlist) {
      final removed = await WishlistService.removeFromWishlist(widget.product);
      if (removed) {
        setState(() {
          isInWishlist = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed from wishlist')),
        );
      }
    } else {
      final added = await WishlistService.addToWishlist(widget.product);
      if (added) {
        setState(() {
          isInWishlist = true;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to wishlist')),
        );
      }
    }
  }

  Widget _buildSellerCard() {
    if (isLoadingSeller) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (sellerData == null) {
      return SizedBox.shrink();
    }

    final sellerName = sellerData?['name'] ?? 'Unknown Seller';
    final sellerEmail = sellerData?['email'] ?? 'N/A';
    final sellerRating = (sellerData?['rating'] ?? 0.0).toDouble();
    final sellerPhone = sellerData?['mobile'] ?? 'N/A';
    final sellerVerified = sellerData?['verified'] ?? false;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10)
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: ColorPallete.color1,
                    child: Icon(Icons.store, color: Colors.white, size: 30),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                sellerName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (sellerVerified)
                              Icon(Icons.verified, color: Colors.blue, size: 18),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              sellerRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 18, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sellerEmail,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 18, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    sellerPhone,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    if (isLoadingAddress) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    if (selectedAddress == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/address_select').then((_) {
              loadSelectedAddress();
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: ColorPallete.color1, width: 2),
              borderRadius: BorderRadius.circular(10),
              color: ColorPallete.color1.withOpacity(0.05),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: ColorPallete.color1,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Delivery Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorPallete.color1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to choose your delivery address',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: ColorPallete.color1,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/addressSelection').then((_) {
            // Reload address when returning from selection page
            loadSelectedAddress();
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: ColorPallete.color1,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedAddress?.first} ${selectedAddress?.last}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${selectedAddress?.line1}, ${selectedAddress?.line2}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${selectedAddress?.city}, ${selectedAddress?.state} - ${selectedAddress?.pincode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.edit,
                  color: ColorPallete.color1,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images.isNotEmpty
        ? widget.product.images
        .map<Widget>(
          (imgPath) => Image.network(
        imgPath,
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: Icon(Icons.image, size: 64, color: Colors.grey[400]),
        ),
      ),
    )
        .toList()
        : [
      Container(
        color: Colors.grey[200],
        child: Icon(Icons.image, size: 64, color: Colors.grey[400]),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorPallete.color1,
        title: Text(
          widget.product.name,
          style: TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height / 2,
                          child: CarouselSlider(
                            items: images,
                            options: CarouselOptions(
                              enlargeFactor: 1.0,
                              scrollDirection: Axis.horizontal,
                              enableInfiniteScroll: images.length > 1,
                              autoPlay: images.length > 1,
                              autoPlayInterval: Duration(seconds: 3),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isInWishlist ? Colors.transparent : Colors.grey.shade500,
                          ),
                          child: IconButton(
                            icon: isCheckingWishlist
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : Icon(
                              isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                              isInWishlist ? Colors.red : Colors.white,
                            ),
                            onPressed: isCheckingWishlist ? null : toggleWishlist,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5.0),
                              child: Text(
                                widget.product.name,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 7.0),
                              child: Text(widget.product.brand),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(7.0),
                              child: Text(
                                '₹ ${widget.product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontFamily: "Poppins",
                                  fontWeight: FontWeight.w800,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'Expected Delivery At: ${widget.product.deliveryTime}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.product.description,
                              style: TextStyle(fontSize: 16, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      // Address card
                      _buildAddressCard(),
                      // Seller details card
                      _buildSellerCard(),
                      // Bottom padding to prevent content from being hidden under fixed button
                      SizedBox(height: 140),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Fixed button at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: _buildFixedActionButton(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedActionButton() {
    final currentQuantity = cart.getQuantity(widget.product);
    final limitInfo = cart.getQuantityLimitInfo(widget.product);
    final canAdd = cart.canAddQuantity(widget.product, 1);

    if (showGoToCartButton) {
      final canIncrease = limitInfo['availableToAdd'] > 0;

      return Row(
        children: [
          // Minus button
          GestureDetector(
            onTap: () {
              setState(() {
                if (currentQuantity > 1) {
                  cart.updateQuantity(
                    widget.product,
                    currentQuantity - 1,
                  );
                } else {
                  cart.remove(widget.product);
                  showGoToCartButton = false;
                }
              });
            },
            child: Container(
              width: 45,
              height: 50,
              decoration: BoxDecoration(
                color: ColorPallete.color1,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                currentQuantity > 1 ? Icons.remove : Icons.delete,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 8),

          Container(
            height: 50,
            width: 50,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: ColorPallete.color1, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$currentQuantity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorPallete.color1,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (canIncrease) {
                setState(() {
                  cart.updateQuantity(
                    widget.product,
                    currentQuantity + 1,
                  );
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Maximum ${limitInfo['maxAllowed']} items allowed for ${widget.product.category} category',
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: Container(
              width: 45,
              height: 50,
              decoration: BoxDecoration(
                color: canIncrease
                    ? ColorPallete.color1
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/cart');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPallete.color1,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'GO TO CART',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (currentQuantity == 0) {
      return ElevatedButton(
        onPressed: canAdd['canAdd']
            ? () {
          setState(() {
            cart.add(widget.product, quantity: 1);
            showGoToCartButton = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${widget.product.name} added to cart!',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPallete.color1,
          disabledBackgroundColor: Colors.grey.shade400,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          canAdd['canAdd'] ? 'ADD TO CART' : 'LIMIT REACHED',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    } else {
      final canIncrease = limitInfo['availableToAdd'] > 0;

      return Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (currentQuantity > 1) {
                  cart.updateQuantity(
                    widget.product,
                    currentQuantity - 1,
                  );
                  showGoToCartButton = true;
                } else {
                  cart.remove(widget.product);
                  showGoToCartButton = false;
                }
              });
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ColorPallete.color1,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                currentQuantity > 1 ? Icons.remove : Icons.delete,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: ColorPallete.color1, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$currentQuantity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorPallete.color1,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (canIncrease) {
                  setState(() {
                    cart.updateQuantity(
                      widget.product,
                      currentQuantity + 1,
                    );
                    showGoToCartButton = true;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Maximum ${limitInfo['maxAllowed']} items allowed for ${widget.product.category} category',
                      ),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: canIncrease
                      ? ColorPallete.color1
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      );
    }
  }
}
