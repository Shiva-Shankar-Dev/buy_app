import 'package:flutter/material.dart';

Map<String, List<Map<String, dynamic>>> categorySubcategories = {
  'Electronics': [
    {'name': 'Television', 'icon': Icons.tv, 'keywords': ['tv', 'television', 'smart tv', 'led', 'oled']},
    {'name': 'Laptop', 'icon': Icons.laptop, 'keywords': ['laptop', 'notebook', 'macbook', 'gaming laptop']},
    {'name': 'Home Theatre', 'icon': Icons.speaker, 'keywords': ['speaker', 'home theatre', 'sound system', 'audio', 'soundbar']},
    {'name': 'Headphones', 'icon': Icons.headphones, 'keywords': ['headphones', 'earphones', 'earbuds', 'airpods']},
    {'name': 'Camera', 'icon': Icons.camera_alt, 'keywords': ['camera', 'dslr', 'photography', 'video camera', 'mirrorless']},
    {'name': 'Gaming', 'icon': Icons.sports_esports, 'keywords': ['gaming console', 'playstation', 'xbox', 'nintendo', 'ps5']},
    {'name': 'Smartwatch', 'icon': Icons.watch, 'keywords': ['smartwatch', 'fitness tracker', 'apple watch', 'galaxy watch']},
  ],
  'Mobile': [
    {'name': 'Smartphone', 'icon': Icons.smartphone, 'keywords': ['mobile', 'smartphone', 'android', 'iphone', 'phone']},
    {'name': 'Feature Phones', 'icon': Icons.phone, 'keywords': ['feature phone', 'basic phone', 'keypad phone']},
    {'name': 'Accessories', 'icon': Icons.phone_android, 'keywords': ['mobile case', 'phone cover', 'mobile charger', 'screen guard', 'phone accessories']},
  ],
  'Appliances': [
    {'name': 'Refrigerator', 'icon': Icons.kitchen, 'keywords': ['refrigerator', 'fridge', 'cooling']},
    {'name': 'Washing Machine', 'icon': Icons.local_laundry_service, 'keywords': ['washing machine', 'laundry']},
    {'name': 'Air Conditioner', 'icon': Icons.ac_unit, 'keywords': ['ac', 'air conditioner', 'cooling']},
    {'name': 'Microwave', 'icon': Icons.microwave, 'keywords': ['microwave', 'oven']},
    {'name': 'Kitchen', 'icon': Icons.kitchen, 'keywords': ['mixer', 'grinder', 'blender', 'kitchen appliance']},
  ],
  'Fashion': [
    {'name': 'Mens Wear', 'icon': Icons.man, 'keywords': ['men', 'shirt', 'trouser', 'jeans', 'mens']},
    {'name': 'Womens Wear', 'icon': Icons.woman, 'keywords': ['women', 'dress', 'saree', 'kurti', 'womens']},
    {'name': 'Kids Wear', 'icon': Icons.child_care, 'keywords': ['kids', 'children', 'baby', 'infant']},
    {'name': 'Footwear', 'icon': Icons.directions_walk, 'keywords': ['shoes', 'sandals', 'slippers', 'boots']},
    {'name': 'Accessories', 'icon': Icons.watch, 'keywords': ['belt', 'wallet', 'bag', 'accessories']},
  ],
  'Books': [
    {'name': 'Fiction', 'icon': Icons.auto_stories, 'keywords': ['fiction', 'novel', 'story']},
    {'name': 'Non-Fiction', 'icon': Icons.book, 'keywords': ['non-fiction', 'biography', 'history']},
    {'name': 'Educational', 'icon': Icons.school, 'keywords': ['textbook', 'educational', 'study', 'academic']},
    {'name': 'Children', 'icon': Icons.child_friendly, 'keywords': ['children book', 'kids book', 'story book']},
  ],
  'Sports': [
    {'name': 'Fitness', 'icon': Icons.fitness_center, 'keywords': ['gym', 'fitness', 'exercise', 'workout']},
    {'name': 'Outdoor', 'icon': Icons.directions_run, 'keywords': ['outdoor', 'cycling', 'running', 'hiking']},
    {'name': 'Indoor Games', 'icon': Icons.sports_tennis, 'keywords': ['indoor', 'table tennis', 'badminton']},
    {'name': 'Team Sports', 'icon': Icons.sports_football, 'keywords': ['football', 'cricket', 'basketball']},
  ],
  'Beauty': [
    {'name': 'Skincare', 'icon': Icons.face, 'keywords': ['skincare', 'face wash', 'moisturizer', 'serum']},
    {'name': 'Makeup', 'icon': Icons.brush, 'keywords': ['makeup', 'lipstick', 'foundation', 'cosmetics']},
    {'name': 'Hair Care', 'icon': Icons.content_cut, 'keywords': ['shampoo', 'conditioner', 'hair oil', 'hair care']},
    {'name': 'Fragrances', 'icon': Icons.local_florist, 'keywords': ['perfume', 'fragrance', 'deodorant']},
  ],
  'Groceries': [
    {'name': 'Fruits & Vegetables', 'icon': Icons.eco, 'keywords': ['fruits', 'vegetables', 'fresh', 'organic']},
    {'name': 'Dairy', 'icon': Icons.local_drink, 'keywords': ['milk', 'cheese', 'butter', 'dairy']},
    {'name': 'Packaged Food', 'icon': Icons.inventory, 'keywords': ['packaged', 'snacks', 'biscuits', 'chips']},
    {'name': 'Beverages', 'icon': Icons.local_cafe, 'keywords': ['tea', 'coffee', 'juice', 'drinks']},
  ],
};