import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._instance();
  static Database? _database;

  DatabaseHelper._instance();

  Future<Database> get db async {
    _database ??= await initDb();
    return _database!;
  }

  Future<Database> initDb() async {
    String databasePath = await getDatabasesPath();
    String path = join(databasePath, 'pertemuan5.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        username TEXT,
        email TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<int> insertUser(User user) async {
    Database db = await instance.db;
    return await db.insert('users', user.toMap());
  }

  Future<List<Map<String, dynamic>>> queryAllUsers() async {
    Database db = await instance.db;
    return await db.query('users', orderBy: 'id');
  }

  Future<int> updateUser(User user) async {
    Database db = await instance.db;
    return await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    Database db = await instance.db;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}