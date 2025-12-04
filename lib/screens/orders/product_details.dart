import 'package:buy_app/services/cart_manager.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:buy_app/ColorPallete/color_pallete.dart';
import 'package:flutter/material.dart';
import 'package:buy_app/models/models.dart';
import 'package:buy_app/services/wishlist_service.dart';

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

  @override
  void initState() {
    super.initState();
    checkWishlistStatus();
  }

  Future<void> checkWishlistStatus() async {
    final inWishlist = await WishlistService.isInWishlist(widget.product);
    setState(() {
      isInWishlist = inWishlist;
      isCheckingWishlist = false;
    });
  }

  Future<void> toggleWishlist() async {
    if (isInWishlist) {
      final removed = await WishlistService.removeFromWishlist(widget.product);
      if (removed) {
        setState(() {
          isInWishlist = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Removed from wishlist')));
      }
    } else {
      final added = await WishlistService.addToWishlist(widget.product);
      if (added) {
        setState(() {
          isInWishlist = true;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Added to wishlist')));
      }
    }
  }

  Widget _buildQuantitySelector() {
    final currentQuantity = cart.getQuantity(widget.product);
    final limitInfo = cart.getQuantityLimitInfo(widget.product);
    final canAdd = cart.canAddQuantity(widget.product, 1);

    if (currentQuantity == 0) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Show category limit info
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      limitInfo['limitMessage'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Add to cart button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canAdd['canAdd']
                    ? () {
                        setState(() {
                          cart.add(widget.product, quantity: 1);
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
              ),
            ),

            // Show why can't add if applicable
            if (!canAdd['canAdd'])
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  canAdd['message'],
                  style: TextStyle(fontSize: 14, color: Colors.red.shade600),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      );
    } else {
      final canIncrease = limitInfo['availableToAdd'] > 0;

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Quantity limit info
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: limitInfo['availableToAdd'] > 0
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: limitInfo['availableToAdd'] > 0
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    limitInfo['availableToAdd'] > 0
                        ? Icons.check_circle_outline
                        : Icons.warning,
                    color: limitInfo['availableToAdd'] > 0
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      limitInfo['availableToAdd'] > 0
                          ? 'You can add ${limitInfo['availableToAdd']} more items (${limitInfo['maxAllowed']} max for ${widget.product.category})'
                          : 'Maximum limit reached (${limitInfo['maxAllowed']} for ${widget.product.category})',
                      style: TextStyle(
                        fontSize: 14,
                        color: limitInfo['availableToAdd'] > 0
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Quantity controls
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: ColorPallete.color1, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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
                        }
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      '$currentQuantity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorPallete.color1,
                      ),
                    ),
                  ),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: canIncrease
                            ? ColorPallete.color1
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 20),
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

  @override
  Widget build(BuildContext context) {
    // Print all product attributes
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
              ).toList()
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
        actions: [
          IconButton(
            icon: isCheckingWishlist
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isInWishlist ? Icons.favorite : Icons.favorite_border,
                    color: isInWishlist ? Colors.red : Colors.white,
                  ),
            onPressed: isCheckingWishlist ? null : toggleWishlist,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: CarouselSlider(
                    items: images,
                    options: CarouselOptions(
                      height: 300,
                      viewportFraction: 1.0,
                      scrollDirection: Axis.horizontal,
                      enableInfiniteScroll: images.length > 1,
                      enlargeCenterPage: true,
                      pageSnapping: true,
                      autoPlay: images.length > 1,
                      autoPlayInterval: Duration(seconds: 3),
                    ),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Row(children: [Text(widget.product.brand)]),

                        Text(
                          '₹ ${widget.product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Delivery Time: ${widget.product.deliveryTime}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
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

                  const SizedBox(height: 20),
                  if (widget.product.keywords.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keywords',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            children: widget.product.keywords
                                .map((keyword) => Chip(label: Text(keyword)))
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                  // Quantity Selector
                  _buildQuantitySelector(),

                  SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
