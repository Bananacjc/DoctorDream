import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user_profile.dart';
import '../models/dream_entry.dart';
import '../../constants/string_constant.dart';

class LocalDatabase {
  LocalDatabase._();

  static const _dbName = StringConstant.dbName;
  static const _dbVersion = 1;

  static final LocalDatabase instance = LocalDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    _database = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        // If database exists but tables don't, create them
        await _ensureTablesExist(db);
      },
    );
    // Ensure tables exist even if onCreate wasn't called
    await _ensureTablesExist(_database!);
    return _database!;
  }

  Future<void> _ensureTablesExist(Database db) async {
    // Check if user_profile table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='user_profile'",
    );
    if (tables.isEmpty) {
      // Table doesn't exist, create it
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profile (
          id INTEGER PRIMARY KEY,
          full_name TEXT,
          pronouns TEXT,
          birthday TEXT,
          email TEXT,
          phone TEXT,
          location TEXT,
          notes TEXT,
          updated_at TEXT
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id INTEGER PRIMARY KEY,
        full_name TEXT,
        pronouns TEXT,
        birthday TEXT,
        email TEXT,
        phone TEXT,
        location TEXT,
        notes TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS support_contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        relationship TEXT,
        phone TEXT NOT NULL,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS calm_resources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS dream_entries (
        dream_id TEXT PRIMARY KEY,
        dream_title TEXT NOT NULL,
        dream_content TEXT,
        created_at TEXT,
        updated_at TEXT,
        status INTEGER,
        is_favourite INTEGER DEFAULT 0
      )
    ''');
  }

  // User profile -------------------------------------------------------------
  Future<UserProfile> upsertUserProfile(UserProfile profile) async {
    final db = await database;
    final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
    await db.insert(
      'user_profile',
      updatedProfile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return updatedProfile;
  }

  Future<UserProfile> fetchUserProfile() async {
    final db = await database;
    final rows = await db.query('user_profile', limit: 1);
    if (rows.isEmpty) {
      return UserProfile.empty();
    }
    return UserProfile.fromMap(rows.first);
  }

  // Support contacts --------------------------------------------------------
  // TODO: Implement when support_contact model is available
  // Future<List<SupportContact>> fetchContacts() async { ... }

  // Calm resources ----------------------------------------------------------
  // TODO: Implement when calm_resource model is available
  // Future<List<CalmResource>> fetchCalmResources() async { ... }

  // Dream entries -----------------------------------------------------------
  Future<void> upsertDreamEntry(DreamEntry entry) async {
    final db = await database;
    await db.insert(
      StringConstant.dreamEntryTable,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DreamEntry>> fetchDreamEntries() async {
    final db = await database;
    final result = await db.query(
      StringConstant.dreamEntryTable,
      orderBy: 'updated_at DESC',
    );
    return result.map((map) => DreamEntry.fromMap(map)).toList();
  }

  Future<DreamEntry?> getDreamEntryById(String id) async {
    final db = await database;
    final result = await db.query(
      StringConstant.dreamEntryTable,
      where: 'dream_id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return DreamEntry.fromMap(result.first);
    }
    return null;
  }

  Future<void> deleteDreamEntry(String id) async {
    final db = await database;
    await db.delete(
      StringConstant.dreamEntryTable,
      where: 'dream_id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setDreamFavourite(String id, bool isFavourite) async {
    final db = await database;
    await db.update(
      StringConstant.dreamEntryTable,
        {'is_favourite': isFavourite ? 1 : 0},
      where: 'dream_id = ?',
      whereArgs: [id],
    );
  }
}
