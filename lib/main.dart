import 'package:buy_app/animated_splash_screen_widget.dart';
import 'package:buy_app/screens/add_page.dart';
import 'package:buy_app/screens/cart_page.dart';
import 'package:buy_app/screens/checkout_page.dart';
import 'package:buy_app/screens/otp_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/home_page.dart';
import 'screens/mobile_login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Check if any Firebase app is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: "AIzaSyDuRkAfWOOcyFfxJ0U6l81-ZXZvpMo6tPU",
          appId: "1:373635829159:android:0b6fc6cd7c5bdd6df17a82",
          messagingSenderId: "373635829159",
          projectId: "buyers-app-930a3",
        ),
      );
      await Hive.initFlutter();
      await Hive.openBox('FilesBox');
    }
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
      theme: ThemeData(brightness: Brightness.light),
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
