import 'package:buy_app/screens/account_page.dart'; // Changed: Remove 'address/' from path
import 'package:buy_app/screens/cart_page.dart';
import 'package:buy_app/screens/home_page.dart';
import 'package:buy_app/screens/add_page.dart'; // Add this for the Menu tab
import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:flutter/material.dart';

class Index extends StatefulWidget {
  const Index({super.key});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  int _selectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> pages = [
    HomePage(),
    AccountPage(), // This now points to the correct AccountPage with wishlist, etc.
    CartPage(),
    AddPage(), // Changed from Placeholder to AddPage
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorPallete.color1,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps_outlined),
            activeIcon: Icon(Icons.apps),
            label: 'Menu',
          ),
        ],
        onTap: onItemTapped,
        currentIndex: _selectedIndex,
      ),
    );
  }
}
