import 'package:buy_app/animated_splash_screen_widget.dart';
import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:buy_app/screens/address/account_page.dart';
import 'package:buy_app/screens/address/add_new_address.dart';
import 'package:buy_app/screens/add_page.dart';
import 'package:buy_app/screens/address/address_selection_page.dart';
import 'package:buy_app/screens/cart_page.dart';
import 'package:buy_app/screens/checkout_page.dart';
import 'package:buy_app/screens/auth/otp_page.dart';
import 'package:buy_app/screens/payments/payment_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/signup_page.dart';
import 'screens/home_page.dart';
import 'screens/auth/mobile_login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBb_1jJnMQy2qAebBpDnojunskioxt7omg",
        appId: "1:720739834245:android:258b055c58eb166c02ccec",
        messagingSenderId: "720739834245",
        projectId: "ecom-app-af213",
      ),
    );
  } catch (e) {
    print("🔥 Firebase already initialized or failed: $e");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: colorPallete.color6,
        appBarTheme: AppBarTheme(
          backgroundColor: colorPallete.color1,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'PlayfairDisplay',
          ),
          toolbarHeight: 70,
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AnimatedSplashScreenWidget(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
        '/mobile': (context) => MobileLoginPage(),
        '/cart': (context) => CartPage(),
        '/add': (context) => AddPage(),
        '/checkout': (context) => CheckoutPage(),
        '/account': (context) => AccountPage(),
        '/address_select': (context) => AddressSelectionPage(),
        '/add_address': (context) => AddAddressPage(),
        '/payment': (context) => PaymentPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/otp') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => OtpPage(
              phone: args['phone'],
              verificationId: args['verificationId'],
            ),
          );
        }
        return null;
      },
    );
  }
}
