import 'package:flutter/material.dart';
import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:buy_app/services/auth.dart';
import 'package:buy_app/screens/account/saved_addresses_page.dart';
import 'package:buy_app/screens/account/wishlist_page.dart'; // Add this import
import 'package:buy_app/screens/account/order_history.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    try {
      final data = await _authService.getUserDetailsAsMap();
      print('User data loaded: $data'); // Debug print
      setState(() {
        userData =
            data ?? {'name': 'User', 'email': 'user@example.com', 'phone': ''};
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        userData = {'name': 'User', 'email': 'user@example.com', 'phone': ''};
        isLoading = false;
      });
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? colorPallete.color1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor ?? colorPallete.color1, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Account'),
        backgroundColor: colorPallete.color1,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorPallete.color1),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // User Profile Header
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorPallete.color1,
                          colorPallete.color1.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              (userData?['name'] ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colorPallete.color1,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            userData?['name'] ?? 'User',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            userData?['email'] ?? 'No email',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          if (userData?['phone'] != null &&
                              userData!['phone'].toString().isNotEmpty)
                            Text(
                              userData!['phone'].toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Menu Items
                  _buildMenuItem(
                    icon: Icons.receipt_long,
                    title: 'Order History',
                    subtitle: 'View your past orders and track current ones',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderHistoryPage(),
                        ),
                      );
                    },
                  ),

                  _buildMenuItem(
                    icon: Icons.favorite,
                    title: 'Wishlist',
                    subtitle: 'Items you want to buy later',
                    iconColor: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WishlistPage()),
                      );
                    },
                  ),

                  _buildMenuItem(
                    icon: Icons.location_on,
                    title: 'Saved Addresses',
                    subtitle: 'Manage your delivery addresses',
                    iconColor: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SavedAddressesPage(),
                        ),
                      );
                    },
                  ),

                  _buildMenuItem(
                    icon: Icons.payment,
                    title: 'Payment Methods',
                    subtitle: 'Manage your saved payment methods',
                    iconColor: Colors.blue,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment Methods feature coming soon!'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                  ),

                  _buildMenuItem(
                    icon: Icons.person,
                    title: 'Profile Settings',
                    subtitle: 'Edit your personal information',
                    iconColor: Colors.orange,
                    onTap: () {
                      _showProfileDialog();
                    },
                  ),

                  _buildMenuItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage your notification preferences',
                    iconColor: Colors.purple,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Notification settings coming soon!'),
                          backgroundColor: Colors.purple,
                        ),
                      );
                    },
                  ),

                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help with your orders and account',
                    iconColor: Colors.teal,
                    onTap: () {
                      _showHelpDialog();
                    },
                  ),

                  _buildMenuItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    subtitle: 'App preferences and account settings',
                    iconColor: Colors.grey,
                    onTap: () {
                      _showSettingsDialog();
                    },
                  ),

                  SizedBox(height: 24),

                  // Sign Out Button
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showSignOutDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profile Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${userData?['name'] ?? 'Not set'}'),
            SizedBox(height: 8),
            Text('Email: ${userData?['email'] ?? 'Not set'}'),
            SizedBox(height: 8),
            Text('Phone: ${userData?['phone'] ?? 'Not set'}'),
            SizedBox(height: 16),
            Text(
              'Profile editing feature coming soon!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Contact us:'),
            SizedBox(height: 12),
            Text('📧 Email: support@buyapp.com'),
            SizedBox(height: 8),
            Text('📞 Phone: +91 12345 67890'),
            SizedBox(height: 8),
            Text('💬 Live Chat: Available 24/7'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text('Dark Mode'),
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Dark mode coming soon!')),
                  );
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.language),
              title: Text('Language'),
              trailing: Text('English'),
            ),
            ListTile(
              leading: Icon(Icons.security),
              title: Text('Privacy & Security'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _authService.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
