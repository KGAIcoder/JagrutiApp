import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;
  static const String _dbFileName = 'jagruti_members.db';
  static const String _assetDbPath = 'assets/jagruti_members.db';

  factory DatabaseHelper() => instance; // Singleton pattern

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbFileName);

    // Check if database already exists
    if (!await File(path).exists()) {
      await _copyDatabaseFromAssets(path);
    }

    return await openDatabase(path); // Use standard openDatabase
  }

  Future<void> _copyDatabaseFromAssets(String path) async {
    ByteData data = await rootBundle.load(_assetDbPath);
    List<int> bytes = data.buffer.asUint8List();
    await File(path).writeAsBytes(bytes, flush: true);
  }

  Future<List<Map<String, dynamic>>> getMembers() async {
    final db = await database;
    return await db.query('members', orderBy: 'member_id ASC');
  }
}