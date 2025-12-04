import 'package:flutter/material.dart';
import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:buy_app/services/auth.dart';
import 'package:buy_app/screens/account/saved_addresses.dart';
import 'package:buy_app/screens/account/wishlist_page.dart'; // Add this import
import 'package:buy_app/screens/orders/order_history.dart';

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
      debugPrint('User data loaded: $data'); // Debug print
      setState(() {
        userData =
            data ?? {'name': 'User', 'email': 'user@example.com', 'phone': ''};
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300)
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? ColorPallete.color1).withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor ?? ColorPallete.color1, size: 24),
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorPallete.color1,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ColorPallete.color1),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          ColorPallete.color1,
                          ColorPallete.color1.withAlpha(80),
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
                                color: ColorPallete.color1,
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
                              color: Colors.white.withAlpha(90),
                            ),
                          ),
                          if (userData?['phone'] != null &&
                              userData!['phone'].toString().isNotEmpty)
                            Text(
                              userData!['phone'].toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withAlpha(90),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Menu Items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildMenuItem(
                                icon: Icons.receipt_long,
                                title: 'Orders',
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
                            ),

                            Expanded(
                              child: _buildMenuItem(
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
                            ),
                          ],
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
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Sign Out Button
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
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
