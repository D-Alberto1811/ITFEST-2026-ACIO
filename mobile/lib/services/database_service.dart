import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_user.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String _databaseName = 'fitlingo.db';
  static const int _databaseVersion = 1;

  static const String usersTable = 'users';

  Database? _database;

  Future<void> initialize() async {
    await database;
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $usersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        auth_provider TEXT NOT NULL,
        google_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_users_email
      ON $usersTable(email)
    ''');

    await db.execute('''
      CREATE INDEX idx_users_google_id
      ON $usersTable(google_id)
    ''');
  }

  Future<int> insertUser(AppUser user) async {
    final db = await database;

    return await db.insert(
      usersTable,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final normalizedEmail = email.trim().toLowerCase();

    final result = await db.query(
      usersTable,
      where: 'LOWER(email) = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return AppUser.fromMap(result.first);
  }

  Future<AppUser?> getUserByGoogleId(String googleId) async {
    final db = await database;

    final result = await db.query(
      usersTable,
      where: 'google_id = ?',
      whereArgs: [googleId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return AppUser.fromMap(result.first);
  }

  Future<AppUser?> getUserById(int id) async {
    final db = await database;

    final result = await db.query(
      usersTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return AppUser.fromMap(result.first);
  }

  Future<int> updateUser(AppUser user) async {
    if (user.id == null) {
      throw Exception('Cannot update a user without an id.');
    }

    final db = await database;

    return await db.update(
      usersTable,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<AppUser>> getAllUsers() async {
    final db = await database;

    final result = await db.query(
      usersTable,
      orderBy: 'id DESC',
    );

    return result.map((map) => AppUser.fromMap(map)).toList();
  }

  Future<void> deleteAllUsers() async {
    final db = await database;
    await db.delete(usersTable);
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}