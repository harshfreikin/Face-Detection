import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _databaseName = "UserDatabase.db";
  static final _databaseVersion = 2; // Updated version to 2

  static final table = 'users';

  static final columnId = '_id';
  static final columnName = 'name';
  static final columnFaceDataHash = 'face_data_hash'; // New column name

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnName TEXT NOT NULL,
            $columnFaceDataHash TEXT NOT NULL
          )
          ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE $table ADD COLUMN $columnFaceDataHash TEXT NOT NULL DEFAULT ''
      ''');
    }
  }

  Future<int> insertUser(Map<String, dynamic> row) async {
    try {
      Database? db = await database;
      return await db!.insert(table, row);
    } catch (e) {
      print("Error inserting user: $e");
      rethrow; // Optional: rethrow the exception if you want to handle it higher up
    }
  }

  Future<List<Map<String, dynamic>>> queryAllUsers() async {
    try {
      Database? db = await database;
      return await db!.query(table);
    } catch (e) {
      print("Error querying all users: $e");
      return []; // Return an empty list in case of error
    }
  }

  Future<Map<String, dynamic>?> getUserByFaceDataHash(String faceDataHash) async {
    try {
      Database? db = await database;
      final result = await db!.query(
        table,
        where: '$columnFaceDataHash = ?',
        whereArgs: [faceDataHash],
      );
      if (result.isNotEmpty) {
        return result.first;
      } else {
        return null;
      }
    } catch (e) {
      print("Error getting user by face data hash: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserByName(String name) async {
    try {
      Database? db = await database;
      final result = await db!.query(
        table,
        where: '$columnName = ?',
        whereArgs: [name],
      );
      if (result.isNotEmpty) {
        return result.first;
      } else {
        return null;
      }
    } catch (e) {
      print("Error getting user by name: $e");
      return null;
    }
  }
}
