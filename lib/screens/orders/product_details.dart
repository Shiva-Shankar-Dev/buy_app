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

  // Variant selection state
  String? selectedVariantId;
  Map<String, String> selectedAttributes = {};
  double currentPrice = 0.0;
  int currentStock = 0;
  List<String> currentImages = [];

  @override
  void initState() {
    super.initState();

    debugPrint('=== PRODUCT LOADING DEBUG ===');
    debugPrint('Product received: ${widget.product}');
    debugPrint('Product name: ${widget.product.name}');
    debugPrint('Product hasVariants: ${widget.product.hasVariants}');
    debugPrint('=============================');

    try {
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
      _initializeVariantState();
    } catch (e, stackTrace) {
      debugPrint('Error in initState: $e');
      debugPrint('StackTrace: $stackTrace');
    }
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

  bool _shouldShowVariants() {
    debugPrint('=== _shouldShowVariants DEBUG ===');
    debugPrint('hasVariants: ${widget.product.hasVariants}');
    debugPrint('variants.isEmpty: ${widget.product.variants.isEmpty}');
    debugPrint('variants.length: ${widget.product.variants.length}');
    debugPrint('availableAttributes: ${widget.product.availableAttributes}');

    // Check if product is marked as having variants
    if (!widget.product.hasVariants) {
      debugPrint('Product hasVariants is false, not showing variants');
      return false;
    }

    // Enhanced variant detection - if product has variants, try to show them
    if (widget.product.variants.isEmpty) {
      debugPrint('No variants found in variants list');
      return false;
    }

    // If hasVariants is true and we have variants, show them
    if (widget.product.hasVariants && widget.product.variants.isNotEmpty) {
      debugPrint('Product has variants flag set to true and variants exist');

      // If availableAttributes is provided, use it
      if (widget.product.availableAttributes.isNotEmpty) {
        debugPrint(
          'Using provided availableAttributes: ${widget.product.availableAttributes}',
        );
        return true;
      }

      // If availableAttributes is empty, try to detect from variant data
      final detectedAttributes = _getDetectedAttributes();
      debugPrint('Detected attributes: $detectedAttributes');
      if (detectedAttributes.isNotEmpty) {
        debugPrint('Found detectable attributes, showing variants');
        return true;
      } else {
        debugPrint('No detectable attributes found');
        return false;
      }
    }

    debugPrint('Default case - not showing variants');
    debugPrint('================================');
    return false;
  }

  List<String> _getDetectedAttributes() {
    // Automatically detect available attributes from variant data
    final attributeNames = <String>{};

    debugPrint('=== _getDetectedAttributes DEBUG ===');
    debugPrint(
      'Checking ${widget.product.variants.length} variants for attributes',
    );

    if (widget.product.variants.isEmpty) {
      debugPrint('No variants to check');
      return [];
    }

    for (int i = 0; i < widget.product.variants.length; i++) {
      final variant = widget.product.variants[i];
      debugPrint('Variant $i: ${variant.variantId}');
      debugPrint('Variant $i attributes: ${variant.attributes}');
      debugPrint(
        'Variant $i attributes keys: ${variant.attributes.keys.toList()}',
      );
      debugPrint(
        'Variant $i attributes values: ${variant.attributes.values.toList()}',
      );

      if (variant.attributes.isNotEmpty) {
        attributeNames.addAll(variant.attributes.keys);
        debugPrint('Added attribute keys: ${variant.attributes.keys.toList()}');
      } else {
        debugPrint('Variant $i has no attributes');
      }
    }

    final result = attributeNames.toList()..sort();
    debugPrint('All collected attribute names: $attributeNames');
    debugPrint('Final detected attributes (sorted): $result');
    debugPrint('Detected attributes count: ${result.length}');
    debugPrint('===================================');
    return result;
  }

  List<String> get _effectiveAvailableAttributes {
    // Use provided attributes or detect them automatically
    if (widget.product.availableAttributes.isNotEmpty) {
      return widget.product.availableAttributes;
    }
    return _getDetectedAttributes();
  }

  // Helper method to get corrected color from variant ID if needed
  String _getCorrectedColor(ProductVariant variant) {
    final variantId = variant.variantId;
    if (variantId.endsWith('_W')) {
      return 'White';
    } else if (variantId.endsWith('_B')) {
      return 'Black';
    } else if (variantId.contains('_W_')) {
      return 'White';
    } else if (variantId.contains('_B_')) {
      return 'Black';
    }
    // Fallback to the attribute value
    return variant.attributes['Colour'] ??
        variant.attributes['Color'] ??
        'Unknown';
  }

  // Get unique attribute values with correction for color inconsistencies
  List<String> _getCorrectedAttributeValues(String attributeName) {
    final values = <String>{};

    debugPrint('=== _getCorrectedAttributeValues DEBUG ===');
    debugPrint('Getting values for attribute: $attributeName');

    for (int i = 0; i < widget.product.variants.length; i++) {
      final variant = widget.product.variants[i];
      debugPrint('Checking variant $i: ${variant.variantId}');

      if (attributeName.toLowerCase() == 'colour' ||
          attributeName.toLowerCase() == 'color') {
        final correctedColor = _getCorrectedColor(variant);
        debugPrint('Corrected color for variant $i: $correctedColor');
        values.add(correctedColor);
      } else {
        final value = variant.attributes[attributeName];
        debugPrint('Raw value for $attributeName in variant $i: $value');
        if (value != null) {
          values.add(value);
          debugPrint('Added value: $value');
        }
      }
    }

    final result = values.toList()..sort();
    debugPrint('Final values for $attributeName: $result');
    debugPrint('=========================================');
    return result;
  }

  void _initializeVariantState() {
    // Debug prints to check variant data structure
    debugPrint('=== VARIANT INITIALIZATION DEBUG ===');
    debugPrint('Product name: ${widget.product.name}');
    debugPrint('Product PID: ${widget.product.pid}');
    debugPrint('Product price: ${widget.product.price}');
    debugPrint('Product basePrice: ${widget.product.basePrice}');
    debugPrint('Has variants: ${widget.product.hasVariants}');
    debugPrint('Variants count: ${widget.product.variants.length}');
    debugPrint('Available attributes: ${widget.product.availableAttributes}');
    debugPrint('Detected attributes: ${_getDetectedAttributes()}');

    if (widget.product.variants.isNotEmpty) {
      for (int i = 0; i < widget.product.variants.length; i++) {
        final variant = widget.product.variants[i];
        debugPrint(
          'Variant $i: ID=${variant.variantId}, Attributes=${variant.attributes}, Price=${variant.price}, BasePrice=${variant.basePrice}, Image=${variant.image}, Stock=${variant.stockQuantity}',
        );
      }
    } else {
      debugPrint('NO VARIANTS FOUND - variants list is empty');
    }
    debugPrint('Should show variants: ${_shouldShowVariants()}');
    debugPrint('====================================');

    if (_shouldShowVariants()) {
      try {
        // Select the first variant by default
        final firstVariant = widget.product.variants.first;
        debugPrint(
          'Initializing with first variant: ${firstVariant.variantId}',
        );

        selectedVariantId = firstVariant.variantId;
        selectedAttributes = Map.from(firstVariant.attributes);

        // Correct the color attribute if needed
        if (selectedAttributes.containsKey('Colour') ||
            selectedAttributes.containsKey('Color')) {
          final colorKey = selectedAttributes.containsKey('Colour')
              ? 'Colour'
              : 'Color';
          selectedAttributes[colorKey] = _getCorrectedColor(firstVariant);
        }

        currentPrice = firstVariant.price ?? widget.product.price;
        currentStock = firstVariant.stockQuantity;
        currentImages = firstVariant.getEffectiveImages(widget.product.images);

        debugPrint(
          'Initialized variant state - Price: $currentPrice, Stock: $currentStock, Images: ${currentImages.length}',
        );
      } catch (e) {
        debugPrint('Error initializing variant state: $e');
        // Fallback to product defaults
        selectedVariantId = null;
        selectedAttributes = {};
        currentPrice = widget.product.price;
        currentStock = widget.product.stockQuantity;
        currentImages = widget.product.images;
      }
    } else {
      // No variants, use base product values
      selectedVariantId = null;
      selectedAttributes = {};
      currentPrice = widget.product.price;
      currentStock = widget.product.stockQuantity;
      currentImages = widget.product.images;
    }
  }

  void _updateVariantSelection(String attributeName, String value) {
    setState(() {
      selectedAttributes[attributeName] = value;

      // Find the matching variant based on selected attributes with color correction
      final matchingVariant = widget.product.variants.firstWhere((variant) {
        for (final entry in selectedAttributes.entries) {
          final entryKey = entry.key;
          final entryValue = entry.value;

          if (entryKey.toLowerCase() == 'colour' ||
              entryKey.toLowerCase() == 'color') {
            // Use corrected color for matching
            if (_getCorrectedColor(variant) != entryValue) {
              return false;
            }
          } else {
            // Normal attribute matching
            if (variant.attributes[entryKey] != entryValue) {
              return false;
            }
          }
        }
        return true;
      }, orElse: () => widget.product.variants.first);

      selectedVariantId = matchingVariant.variantId;
      currentPrice = matchingVariant.price ?? widget.product.price;
      currentStock = matchingVariant.stockQuantity;
      currentImages = matchingVariant.getEffectiveImages(widget.product.images);

      debugPrint(
        'Variant selected: ${matchingVariant.variantId}, Price: $currentPrice, Stock: $currentStock',
      );
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
                colors: [
                  Colors.grey[100] ?? Colors.grey,
                  Colors.grey[50] ?? Colors.grey,
                ],
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
            colors: [Colors.white, Colors.grey[50] ?? Colors.white],
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
                        colors: [
                          ColorPallete.color1,
                          ColorPallete.color1.withAlpha(200),
                        ],
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
                  Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: ColorPallete.color1,
                  ),
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
                  Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: ColorPallete.color1,
                  ),
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

  Widget _buildVariantErrorMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          border: Border.all(color: Colors.amber[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(Icons.warning, color: Colors.amber[700], size: 32),
            const SizedBox(height: 8),
            Text(
              'Variant Configuration Issue',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber[900],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This product has ${widget.product.variants.length} variants but no valid attributes could be detected. Please check the variant data structure.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.amber[800]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantSelection() {
    final effectiveAttributes = _effectiveAvailableAttributes;

    debugPrint('=== _buildVariantSelection DEBUG ===');
    debugPrint('hasVariants: ${widget.product.hasVariants}');
    debugPrint('availableAttributes: ${widget.product.availableAttributes}');
    debugPrint('effectiveAttributes: $effectiveAttributes');
    debugPrint('variants count: ${widget.product.variants.length}');

    // If hasVariants is true but no attributes detected, still try to show something
    if (widget.product.hasVariants && effectiveAttributes.isEmpty) {
      debugPrint(
        'hasVariants=true but no attributes detected, trying auto-detection again',
      );
      final detectedAttrs = _getDetectedAttributes();
      debugPrint('Re-detected attributes: $detectedAttrs');
      if (detectedAttrs.isNotEmpty) {
        debugPrint('Using re-detected attributes instead');
        // Use the detected attributes directly
        return _buildVariantSelectionWithAttributes(detectedAttrs);
      }
    }
    debugPrint('===================================');

    if (effectiveAttributes.isEmpty) {
      debugPrint('No effective attributes found, showing error message');
      return _buildVariantErrorMessage();
    }

    return _buildVariantSelectionWithAttributes(effectiveAttributes);
  }

  Widget _buildVariantSelectionWithAttributes(List<String> attributes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Variant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 16),

          // Show info if attributes were auto-detected
          if (widget.product.availableAttributes.isEmpty &&
              attributes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attributes auto-detected from variants',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Build attribute selectors
          ...attributes.map((attributeName) {
            final values = _getCorrectedAttributeValues(attributeName);
            debugPrint(
              'Building selector for $attributeName with values: $values',
            );

            if (values.isEmpty) {
              debugPrint('Skipping $attributeName - no values found');
              return const SizedBox.shrink(); // Skip empty attributes
            }

            final selectedValue =
                selectedAttributes[attributeName] ??
                (attributeName.toLowerCase() == 'colour' ||
                        attributeName.toLowerCase() == 'color'
                    ? _getCorrectedColor(widget.product.variants.first)
                    : values.first);

            debugPrint('Selected value for $attributeName: $selectedValue');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attributeName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: values.map((value) {
                    final isSelected = selectedValue == value;
                    return GestureDetector(
                      onTap: () =>
                          _updateVariantSelection(attributeName, value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ColorPallete.color1
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? ColorPallete.color1
                                : Colors.grey[400]!,
                          ),
                        ),
                        child: Text(
                          value,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: currentStock > 0 ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: currentStock > 0 ? Colors.green[200]! : Colors.red[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  currentStock > 0 ? Icons.check_circle : Icons.error,
                  color: currentStock > 0 ? Colors.green[700] : Colors.red[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentStock > 0
                        ? 'In Stock: $currentStock'
                        : 'Out of Stock',
                    style: TextStyle(
                      color: currentStock > 0
                          ? Colors.green[800]
                          : Colors.red[800],
                      fontWeight: FontWeight.w600,
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
            border: Border.all(
              color: Colors.grey[200] ?? Colors.grey,
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.green[50] ?? Colors.white],
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
                  child: Icon(
                    Icons.location_on,
                    color: Colors.green[700],
                    size: 26,
                  ),
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
    debugPrint('=== BUILD METHOD DEBUG ===');
    debugPrint('Current images: $currentImages');
    debugPrint('Current price: $currentPrice');
    debugPrint('Current stock: $currentStock');
    debugPrint('Selected variant ID: $selectedVariantId');
    debugPrint('Selected attributes: $selectedAttributes');
    debugPrint('========================');

    final images = currentImages.isNotEmpty
        ? currentImages
              .map<Widget>(
                (imgPath) => Image.network(
                  imgPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading image: $imgPath, Error: $error');
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                    );
                  },
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
                scale: _heartController.drive(Tween(begin: 1.0, end: 1.15)),
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
                                      '₹${currentPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '₹${(currentPrice * 1.25).toStringAsFixed(0)}',
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
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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

                    // Variant Selection Section - Enhanced
                    if (widget.product.hasVariants &&
                        widget.product.variants.isNotEmpty) ...[
                      Divider(thickness: 6, color: Colors.grey[100]),
                      _buildVariantSelection(),
                    ],

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
    final currentQuantity = cart.getQuantity(
      widget.product,
      variantId: selectedVariantId,
    );
    final limitInfo = cart.getQuantityLimitInfo(
      widget.product,
      variantId: selectedVariantId,
    );
    final canAdd = cart.canAddQuantity(
      widget.product,
      1,
      variantId: selectedVariantId,
    );

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
                    variantId: selectedVariantId,
                  );
                } else {
                  cart.remove(widget.product, variantId: selectedVariantId);
                  showGoToCartButton = false;
                }
              });
            },
            child: Container(
              width: 45,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorPallete.color1,
                    ColorPallete.color1.withAlpha(220),
                  ],
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
                  cart.updateQuantity(
                    widget.product,
                    currentQuantity + 1,
                    variantId: selectedVariantId,
                  );
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
                      ? [
                          ColorPallete.color1,
                          ColorPallete.color1.withAlpha(220),
                        ]
                      : [
                          Colors.grey[400] ?? Colors.grey,
                          Colors.grey[300] ?? Colors.grey,
                        ],
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
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorPallete.color1,
                    ColorPallete.color1.withAlpha(220),
                  ],
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
                  child: Center(
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
                  colors: [
                    ColorPallete.color1,
                    ColorPallete.color1.withAlpha(220),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.grey[400] ?? Colors.grey,
                    Colors.grey[300] ?? Colors.grey,
                  ],
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
            onTap: canAdd['canAdd'] && currentStock > 0
                ? () {
                    setState(() {
                      cart.add(
                        widget.product,
                        quantity: 1,
                        variantId: selectedVariantId,
                        variantAttributes: selectedAttributes,
                      );
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
                  currentStock <= 0
                      ? 'OUT OF STOCK'
                      : canAdd['canAdd']
                      ? 'ADD TO CART'
                      : 'LIMIT REACHED',
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
                  cart.updateQuantity(
                    widget.product,
                    currentQuantity - 1,
                    variantId: selectedVariantId,
                  );
                  showGoToCartButton = true;
                } else {
                  cart.remove(widget.product, variantId: selectedVariantId);
                  showGoToCartButton = false;
                }
              });
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorPallete.color1,
                    ColorPallete.color1.withAlpha(220),
                  ],
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
                    cart.updateQuantity(
                      widget.product,
                      currentQuantity + 1,
                      variantId: selectedVariantId,
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
                        ? [
                            ColorPallete.color1,
                            ColorPallete.color1.withAlpha(220),
                          ]
                        : [
                            Colors.grey[400] ?? Colors.grey,
                            Colors.grey[300] ?? Colors.grey,
                          ],
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
