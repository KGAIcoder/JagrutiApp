import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => instance; // Singleton pattern

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "jagruti.db");

    // Check if database already exists
    if (!await File(path).exists()) {
      await _copyDatabaseFromAssets(path);
    }

    return await openDatabase(path); // Use standard openDatabase
  }

  Future<void> _copyDatabaseFromAssets(String path) async {
    print("Copying database from assets...");
    ByteData data = await rootBundle.load("assets/jagruti.db");
    List<int> bytes = data.buffer.asUint8List();
    await File(path).writeAsBytes(bytes, flush: true);
    print("Database copied successfully!");
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await database;
    return await db.query('contacts');
  }
}