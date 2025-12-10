import 'package:flutter/material.dart';
import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:buy_app/models/models.dart';
import 'package:buy_app/screens/orders/product_details.dart';
import 'package:buy_app/services/wishlist_service.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<Product> wishlistItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWishlist();
  }

  Future<void> loadWishlist() async {
    setState(() {
      isLoading = true;
    });

    try {
      final items = await WishlistService.getWishlistProducts();
      setState(() {
        wishlistItems = items;
        isLoading = false;
      });
      //print('📱 Loaded ${items.length} wishlist items');
    } catch (e) {
      //print('❌ Error loading wishlist: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> removeFromWishlist(Product product) async {
    final success = await WishlistService.removeFromWishlist(product);

    if (success) {
      setState(() {
        wishlistItems.remove(product);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} removed from wishlist'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () async {
                final added = await WishlistService.addToWishlist(product);
                if (added) {
                  setState(() {
                    wishlistItems.add(product);
                  });
                }
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> clearAllWishlist() async {
    final success = await WishlistService.clearWishlist();

    if (success) {
      setState(() {
        wishlistItems.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wishlist cleared'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void moveToCart(Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} moved to cart'),
        backgroundColor: Colors.green,
      ),
    );

    // Remove from wishlist after moving to cart
    removeFromWishlist(product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Wishlist'),
        backgroundColor: ColorPallete.color1,
        foregroundColor: Colors.white,
        actions: [
          if (wishlistItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Clear Wishlist'),
                    content: Text(
                      'Are you sure you want to remove all items from your wishlist?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          clearAllWishlist();
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ColorPallete.color1),
              ),
            )
          : wishlistItems.isEmpty
          ? _buildEmptyWishlist()
          : _buildWishlistGrid(),
    );
  }

  Widget _buildEmptyWishlist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
          SizedBox(height: 24),
          Text(
            'Your Wishlist is Empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Save items you love to your wishlist.\nReview them anytime and easily move them to your bag.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Go back to account page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPallete.color1,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Continue Shopping',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '${wishlistItems.length} ${wishlistItems.length == 1 ? 'Item' : 'Items'}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 1.0,
            ),
            itemCount: wishlistItems.length,
            itemBuilder: (context, index) {
              final product = wishlistItems[index];
              return _buildWishlistCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWishlistCard(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        Expanded(
          child: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(product: product),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: product.images.isNotEmpty
                        ? Center(
                            child: Image.network(
                              product.images[0],
                              fit: BoxFit.fill,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                ColorPallete.color1,
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey[400],
                                        size: 40,
                                      ),
                                      Text(
                                        'Image not found',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                  size: 40,
                                ),
                                Text(
                                  'No image',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              // Remove from wishlist button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => removeFromWishlist(product),
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.favorite, color: Colors.red, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Product Details
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                Spacer(),
                Text(
                  '₹${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ColorPallete.color1,
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => moveToCart(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPallete.color1,
                    ),
                    child: Text(
                      'Move to Cart',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
