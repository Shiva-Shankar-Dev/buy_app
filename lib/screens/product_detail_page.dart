import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/services/auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:buy_app/colorPallete/color_pallete.dart';
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
  int _selectedImageIndex = 0;
  final cart = Cart.instance;
  final AuthService _authService = AuthService();
  bool isInWishlist = false;
  bool isLoadingWishlist = false;
  bool isCheckingWishlist = true;
  String? userEmail;

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Added to wishlist')));
      }
    }
  }

  Widget _buildQuantitySelector() {
    final currentQuantity = cart.getQuantity(widget.product);

    if (currentQuantity == 0) {
      return Container(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              cart.add(widget.product, quantity: 1);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.product.title} added to cart!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorPallete.color1,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'ADD TO CART',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: colorPallete.color1, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  if (currentQuantity > 1) {
                    cart.updateQuantity(widget.product, currentQuantity - 1);
                  } else {
                    cart.remove(widget.product);
                  }
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorPallete.color1,
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
                  color: colorPallete.color1,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  cart.updateQuantity(widget.product, currentQuantity + 1);
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorPallete.color1,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images.isNotEmpty
        ? widget.product.images
              .map<Widget>(
                (imgPath) => Image.network(
                  imgPath,
                  fit: BoxFit.cover,
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
        backgroundColor: colorPallete.color1,
        title: Text(
          widget.product.title,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery
            Container(
              height: 300,
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

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    widget.product.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange),
                      const SizedBox(width: 5),
                      Text(
                        widget.product.reviews,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Text(
                    '₹ ${widget.product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Delivery Time: ${widget.product.deliveryTime}',
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.product.description,
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 20),
                  if (widget.product.extraFields.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Additional Info',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...widget.product.extraFields.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.key}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value.toString(),
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),

                  // Quantity Selector
                  _buildQuantitySelector(),

                  SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
