import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // Import SplashScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jagrati Diary',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(), // Start with SplashScreen
    );
  }
}