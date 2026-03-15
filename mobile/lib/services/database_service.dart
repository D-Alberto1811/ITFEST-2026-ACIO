import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_user.dart';
import '../models/player_progress.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String _databaseName = 'fitlingo.db';
  static const int _databaseVersion = 6;

  static const String usersTable = 'users';
  static const String playerProgressTable = 'player_progress';
  static const String questProgressTable = 'quest_progress';

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

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _createPlayerProgressTable(db);
    await _createQuestProgressTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createPlayerProgressTable(db);
      await _createQuestProgressTable(db);
    }

    if (oldVersion < 3) {
      final hasTotalXp = await _columnExists(db, playerProgressTable, 'total_xp');
      if (!hasTotalXp) {
        await db.execute('''
          ALTER TABLE $playerProgressTable
          ADD COLUMN total_xp INTEGER NOT NULL DEFAULT 0
        ''');
      }
    }

    if (oldVersion < 5) {
      await _addIntegerColumnIfMissing(
        db,
        playerProgressTable,
        'total_pushups',
      );
      await _addIntegerColumnIfMissing(
        db,
        playerProgressTable,
        'total_squats',
      );
      await _addIntegerColumnIfMissing(
        db,
        playerProgressTable,
        'total_jumping_jacks',
      );
      await _addTextColumnIfMissing(
        db,
        playerProgressTable,
        'last_streak_date',
      );
    }

    if (oldVersion < 6) {
      await _addIntegerColumnIfMissing(
        db,
        playerProgressTable,
        'best_streak_days',
      );
      await _addIntegerColumnIfMissing(
        db,
        playerProgressTable,
        'total_workouts_completed',
      );
      await _addIntegerColumnIfMissing(
        db,
        playerProgressTable,
        'total_daily_challenges_completed',
      );
    }
  }

  Future<bool> _columnExists(Database db, String table, String column) async {
    final result = await db.rawQuery(
      'PRAGMA table_info($table)',
    );
    return result.any((row) => (row['name'] as String?) == column);
  }

  Future<void> _addIntegerColumnIfMissing(
    Database db,
    String table,
    String column,
    ) async {
      final exists = await _columnExists(db, table, column);
      if (!exists) {
        await db.execute('''
          ALTER TABLE $table
          ADD COLUMN $column INTEGER NOT NULL DEFAULT 0
        ''');
      }
  }
  
  Future<void> _addTextColumnIfMissing(
    Database db,
    String table,
    String column,
    ) async {
      final exists = await _columnExists(db, table, column);
      if (!exists) {
        await db.execute('''
          ALTER TABLE $table
          ADD COLUMN $column TEXT
        ''');
      }
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $usersTable (
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
      CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email
      ON $usersTable(email)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_users_google_id
      ON $usersTable(google_id)
    ''');
  }

  Future<void> _createPlayerProgressTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $playerProgressTable (
        user_id INTEGER PRIMARY KEY,
        level INTEGER NOT NULL,
        xp INTEGER NOT NULL,
        total_xp INTEGER NOT NULL DEFAULT 0,
        xp_for_next INTEGER NOT NULL,
        gems INTEGER NOT NULL,
        streak_days INTEGER NOT NULL,
        best_streak_days INTEGER NOT NULL DEFAULT 0,
        total_pushups INTEGER NOT NULL DEFAULT 0,
        total_squats INTEGER NOT NULL DEFAULT 0,
        total_jumping_jacks INTEGER NOT NULL DEFAULT 0,
        total_workouts_completed INTEGER NOT NULL DEFAULT 0,
        total_daily_challenges_completed INTEGER NOT NULL DEFAULT 0,
        last_streak_date TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES $usersTable(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createQuestProgressTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $questProgressTable (
        user_id INTEGER NOT NULL,
        quest_id INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        PRIMARY KEY(user_id, quest_id),
        FOREIGN KEY(user_id) REFERENCES $usersTable(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertUser(AppUser user) async {
    final db = await database;
    return db.insert(
      usersTable,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateUser(AppUser user) async {
    if (user.id == null) {
      throw Exception('Cannot update a user without an id.');
    }

    final db = await database;
    return db.update(
      usersTable,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
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

    if (result.isEmpty) return null;
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

    if (result.isEmpty) return null;
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

    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  Future<List<AppUser>> getAllUsers() async {
    final db = await database;
    final result = await db.query(usersTable, orderBy: 'id DESC');
    return result.map((map) => AppUser.fromMap(map)).toList();
  }

  Future<void> upsertPlayerProgress(PlayerProgress progress) async {
    final db = await database;

    await db.insert(
      playerProgressTable,
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PlayerProgress?> getPlayerProgress(int userId) async {
    final db = await database;

    final result = await db.query(
      playerProgressTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return PlayerProgress.fromMap(result.first);
  }

  Future<void> markQuestCompleted(int userId, int questId) async {
    final db = await database;

    await db.insert(
      questProgressTable,
      {
        'user_id': userId,
        'quest_id': questId,
        'completed_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Set<int>> getCompletedQuestIds(int userId) async {
    final db = await database;

    final result = await db.query(
      questProgressTable,
      columns: ['quest_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return result
        .map((row) => (row['quest_id'] as num).toInt())
        .toSet();
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