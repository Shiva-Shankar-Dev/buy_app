import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/widgets/normal_button.dart';
import 'package:buy_app/widgets/outline_button.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'home_page.dart'; // For Product

class ProductDetailPage extends StatelessWidget {
  final Product product;

  final cart = Cart.instance;

  ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final images = product.images
        .map<Widget>((imgPath) => Image.network(imgPath, fit: BoxFit.cover))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼️ Image Gallery
                SizedBox(
                  height: 500,
                  child: CarouselSlider(
                    items: images,
                    options: CarouselOptions(
                      scrollDirection: Axis.horizontal,
                      enableInfiniteScroll: false,
                      enlargeCenterPage: true,
                      pageSnapping: true,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  product.title,
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
                      product.reviews,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Text(
                  '₹ ${product.price}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: NormalButton(
                        hintText: 'Add to Cart',
                        onPressed: () {
                          Cart.instance.add(
                            product,
                          ); // or use a provider pattern
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added to cart')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomOutlineButton(
                        hintText: 'Buy Now',
                        onPressed: () {
                          Navigator.pushNamed(context, '/checkout');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Delivery Time: ${product.deliveryTime}',
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 20),
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(product.description),

                const SizedBox(height: 20),
                if (product.extraFields.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Info',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...product.extraFields.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value.toString(),
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
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
}
