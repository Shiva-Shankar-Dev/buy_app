import 'package:buy_app/services/cart_manager.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:buy_app/ColorPallete/color_pallete.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:buy_app/models/models.dart';
import 'package:buy_app/services/wishlist_service.dart';
import 'package:buy_app/services/selected_address_service.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  final cart = Cart.instance;
  bool isInWishlist = false;
  bool isLoadingWishlist = false;
  bool isCheckingWishlist = true;
  bool isLoadingSeller = true;
  Map<String, dynamic>? sellerData;
  bool showGoToCartButton = false;
  final selectedAddressService = SelectedAddressService.instance;
  late AnimationController _pageController;
  late AnimationController _heartController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOut),
    );
    _pageController.forward();
    checkWishlistStatus();
    loadSellerDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heartController.dispose();
    super.dispose();
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

  Future<void> toggleWishlist() async {
    _heartController.forward(from: 0.0);
    if (isInWishlist) {
      final removed = await WishlistService.removeFromWishlist(widget.product);
      if (removed) {
        setState(() {
          isInWishlist = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from wishlist'),
            backgroundColor: Colors.red[400],
            duration: Duration(seconds: 2),
          ),
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
          SnackBar(
            content: Text('Added to wishlist ❤️'),
            backgroundColor: Colors.red[400],
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildSellerCard() {
    if (isLoadingSeller) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[100] ?? Colors.grey, Colors.grey[50] ?? Colors.grey],
          ),
        ),
            child: Center(
              child: CircularProgressIndicator(
                color: ColorPallete.color1,
                strokeWidth: 2,
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50] ?? Colors.white,
            ],
          ),
          border: Border.all(color: Colors.grey[200] ?? Colors.grey, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [ColorPallete.color1, ColorPallete.color1.withAlpha(200)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ColorPallete.color1.withAlpha(40),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.store, color: Colors.white, size: 32),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                sellerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (sellerVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 2),
                                    const Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              sellerRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '(${(sellerRating * 1000).toInt()} reviews)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.grey[200], thickness: 0.5),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 18, color: ColorPallete.color1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          sellerEmail,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 18, color: ColorPallete.color1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          sellerPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    final hasAddress = selectedAddressService.hasSelectedAddress;

    if (!hasAddress) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: GestureDetector(
          onTap: () async {
            await Navigator.pushNamed(context, '/address_select');
            if (mounted) {
              setState(() {});
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ColorPallete.color1, width: 2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorPallete.color1.withAlpha(8),
                  ColorPallete.color1.withAlpha(4),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: ColorPallete.color1.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: ColorPallete.color1,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Delivery Address',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ColorPallete.color1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose where you want your order delivered',
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
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: GestureDetector(
        onTap: () async {
          await Navigator.pushNamed(context, '/address_select');
          if (mounted) {
            setState(() {});
          }
        },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200] ?? Colors.grey, width: 1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.green[50] ?? Colors.white,
                ],
              ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withAlpha(15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.location_on, color: Colors.green[700], size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedAddressService.getFullAddressText(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'CHANGE',
                      style: TextStyle(
                        color: ColorPallete.color1,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: ColorPallete.color1,
                      size: 14,
                    ),
                  ],
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
                  fit: BoxFit.contain,
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
        elevation: 0,
        title: Text(
          widget.product.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ScaleTransition(
                scale: _heartController.drive(
                  Tween(begin: 1.0, end: 1.15),
                ),
                child: GestureDetector(
                  onTap: isCheckingWishlist ? null : toggleWishlist,
                  child: isCheckingWishlist
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Icon(
                          isInWishlist ? Icons.favorite : Icons.favorite_border,
                          color: isInWishlist ? Colors.red : Colors.white,
                          size: 24,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image Carousel with premium styling
                    Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height / 2.2,
                          child: CarouselSlider(
                            items: images,
                            options: CarouselOptions(
                              enlargeFactor: 1.0,
                              scrollDirection: Axis.horizontal,
                              enableInfiniteScroll: images.length > 1,
                              autoPlay: images.length > 1,
                              autoPlayInterval: const Duration(seconds: 3),
                              viewportFraction: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Product Info Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Name
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Brand and Rating
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.product.brand,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '4.5',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.amber[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Price Section with gradient
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green[50] ?? Colors.green,
                                  Colors.green[25] ?? Colors.green,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green[100] ?? Colors.green,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹${widget.product.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '₹${(widget.product.price * 1.25).toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red[100],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '-20%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.red[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[600],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'FREE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Delivery',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Delivery Info
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.blue[100] ?? Colors.blue,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.local_shipping_outlined,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Expected Delivery: ${widget.product.deliveryTime}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(thickness: 6, color: Colors.grey[100]),

                    // Description Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.product.description,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(thickness: 6, color: Colors.grey[100]),

                    // Address Card
                    _buildAddressCard(),

                    Divider(thickness: 6, color: Colors.grey[100]),

                    // Seller Card
                    _buildSellerCard(),

                    // Bottom padding
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ),

          // Fixed Bottom Action Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
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
                  cart.updateQuantity(widget.product, currentQuantity - 1);
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
                gradient: LinearGradient(
                  colors: [ColorPallete.color1, ColorPallete.color1.withAlpha(220)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: ColorPallete.color1.withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                currentQuantity > 1 ? Icons.remove : Icons.delete,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 50,
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: ColorPallete.color1, width: 2),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (canIncrease) {
                setState(() {
                  cart.updateQuantity(widget.product, currentQuantity + 1);
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Maximum ${limitInfo['maxAllowed']} items allowed for ${widget.product.category} category',
                    ),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: Container(
              width: 45,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: canIncrease
                      ? [ColorPallete.color1, ColorPallete.color1.withAlpha(220)]
                      : [Colors.grey[400] ?? Colors.grey, Colors.grey[300] ?? Colors.grey],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: canIncrease
                    ? [
                        BoxShadow(
                          color: ColorPallete.color1.withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ColorPallete.color1, ColorPallete.color1.withAlpha(220)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: ColorPallete.color1.withAlpha(50),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed('/cart');
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: const Center(
                    child: Text(
                      'GO TO CART',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (currentQuantity == 0) {
      return Container(
        decoration: BoxDecoration(
          gradient: canAdd['canAdd']
              ? LinearGradient(
                  colors: [ColorPallete.color1, ColorPallete.color1.withAlpha(220)],
                )
              : LinearGradient(
                  colors: [Colors.grey[400] ?? Colors.grey, Colors.grey[300] ?? Colors.grey],
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: canAdd['canAdd']
              ? [
                  BoxShadow(
                    color: ColorPallete.color1.withAlpha(50),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canAdd['canAdd']
                ? () {
                    setState(() {
                      cart.add(widget.product, quantity: 1);
                      showGoToCartButton = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.product.name} added to cart!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  canAdd['canAdd'] ? 'ADD TO CART' : 'LIMIT REACHED',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
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
                  cart.updateQuantity(widget.product, currentQuantity - 1);
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
                gradient: LinearGradient(
                  colors: [ColorPallete.color1, ColorPallete.color1.withAlpha(220)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: ColorPallete.color1.withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                currentQuantity > 1 ? Icons.remove : Icons.delete,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: ColorPallete.color1, width: 2),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
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
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (canIncrease) {
                  setState(() {
                    cart.updateQuantity(widget.product, currentQuantity + 1);
                    showGoToCartButton = true;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Maximum ${limitInfo['maxAllowed']} items allowed for ${widget.product.category} category',
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: canIncrease
                        ? [ColorPallete.color1, ColorPallete.color1.withAlpha(220)]
                        : [Colors.grey[400] ?? Colors.grey, Colors.grey[300] ?? Colors.grey],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: canIncrease
                      ? [
                          BoxShadow(
                            color: ColorPallete.color1.withAlpha(40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
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
