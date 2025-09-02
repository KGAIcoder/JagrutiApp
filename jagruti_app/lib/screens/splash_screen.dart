import 'dart:async';
import 'package:flutter/material.dart';
import 'password_screen.dart'; // ✅ Import password screen

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PasswordScreen()), // ✅ Go to password screen
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // ✅ fallback background color
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ✅ Full screen splash image (works on any resolution)
          Image.asset(
            "assets/Jagruti_splash.png",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // ✅ Progress indicator at bottom
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
