import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:buy_app/screens/login_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AnimatedSplashScreenWidget extends StatelessWidget {
  const AnimatedSplashScreenWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      //decoration: BoxDecoration(image: DecorationImage(image: AssetImage('./assets/background.jpg',), fit: BoxFit.cover)),
      child: AnimatedSplashScreen(
        splash: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Try to load the Lottie animation with error handling
              SizedBox(
                height: 200,
                width: 200,
                child: Lottie.asset(
                  'assets/Animation _1.json',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Lottie loading error: $error');
                    return Icon(
                      Icons.shopping_bag,
                      size: 100,
                      color: Colors.blue,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        nextScreen: LoginPage(),
        splashIconSize: 400,
        backgroundColor: Color.fromARGB(255, 255, 254, 254),
        duration: 4000,
      ),
    );
  }
}
