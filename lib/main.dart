import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'file_upload.dart';

void main() => runApp(
  const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),
  ),
);

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: Image.asset("asset/Wcht_logo.jpg"),
              ),
              const Text(
                'ChatMood',
                style: TextStyle(
                  fontSize: 35,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      splashIconSize: 300,
      splashTransition: SplashTransition.scaleTransition,
      backgroundColor: Colors.deepPurpleAccent,
      duration: 3000,
      nextScreen: MyApp(),
    );
  }
}
