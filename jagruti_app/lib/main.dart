import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/splash_screen.dart'; // Import SplashScreen

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jagruti Diary',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFF4E6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA52A2A),
          primary: const Color(0xFFA52A2A),
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Start with SplashScreen
    );
  }
}