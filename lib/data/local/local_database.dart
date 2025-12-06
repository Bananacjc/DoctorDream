import 'package:doctor_dream/data/models/dream_diagnosis.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/dream_analysis.dart';
import '../models/dream_entry.dart';
import '../models/safety_plan.dart';
import '../models/support_contact.dart';
import '../models/user_profile.dart';
import '../../constants/string_constant.dart';
import '../models/music_track.dart';
import '../models/video_track.dart';
import '../models/article_recommendation.dart';

class LocalDatabase {
  LocalDatabase._();

  static const _dbName = StringConstant.dbName;
  static const _dbVersion = 3;

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
      CREATE TABLE IF NOT EXISTS safety_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS safety_plan_steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        step_order INTEGER,
        description TEXT NOT NULL,
        FOREIGN KEY (plan_id) REFERENCES safety_plans(id) ON DELETE CASCADE
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS dream_analysis (
        analysis_id TEXT PRIMARY KEY,
        dream_id TEXT NOT NULL,
        analysis_content TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (dream_id) REFERENCES dream_entries(dream_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS dream_diagnosis (
        diagnosis_id TEXT PRIMARY KEY,
        diagnosis_content TEXT,
        created_at TEXT
      )
    ''');

    // New tables for Calm Kit
    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_music (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        note TEXT,
        thumbnailUrl TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        channel TEXT,
        note TEXT,
        thumbnailUrl TEXT,
        videoId TEXT,
        videoUrl TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_articles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        summary TEXT,
        content TEXT,
        moodBenefit TEXT,
        tags TEXT,
        created_at TEXT
      )
    ''');
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
      CREATE TABLE IF NOT EXISTS safety_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS safety_plan_steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        step_order INTEGER,
        description TEXT NOT NULL,
        FOREIGN KEY (plan_id) REFERENCES safety_plans(id) ON DELETE CASCADE
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS dream_analysis (
        analysis_id TEXT PRIMARY KEY,
        dream_id TEXT NOT NULL,
        analysis_content TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (dream_id) REFERENCES dream_entries(dream_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS dream_diagnosis (
        diagnosis_id TEXT PRIMARY KEY,
        diagnosis_content TEXT,
        created_at TEXT
      )
    ''');

    // New tables for Calm Kit
    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_music (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        note TEXT,
        thumbnailUrl TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        channel TEXT,
        note TEXT,
        thumbnailUrl TEXT,
        videoId TEXT,
        videoUrl TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_articles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        summary TEXT,
        content TEXT,
        moodBenefit TEXT,
        tags TEXT,
        created_at TEXT
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
  Future<List<SupportContact>> fetchSupportContacts() async {
    final db = await database;
    await _ensureTablesExist(db);
    final result = await db.query(
      StringConstant.supportContactsTable,
      orderBy: 'created_at DESC, id DESC',
    );
    return result.map(SupportContact.fromMap).toList();
  }

  Future<SupportContact> insertSupportContact(SupportContact contact) async {
    final db = await database;
    await _ensureTablesExist(db);
    final timestamped = contact.copyWith(createdAt: DateTime.now());
    final map = timestamped.toMap()..remove('id');
    final id = await db.insert(
      StringConstant.supportContactsTable,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return timestamped.copyWith(id: id);
  }

  Future<void> deleteSupportContact(int id) async {
    final db = await database;
    await _ensureTablesExist(db);
    await db.delete(
      StringConstant.supportContactsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Safety plans ------------------------------------------------------------
  Future<List<SafetyPlan>> fetchSafetyPlans() async {
    final db = await database;
    await _ensureTablesExist(db);
    final planRows = await db.query(
      StringConstant.safetyPlansTable,
      orderBy: 'created_at DESC, id DESC',
    );
    if (planRows.isEmpty) return [];

    final planIds = planRows.map((row) => row['id']).whereType<int>().toList();
    if (planIds.isEmpty) {
      return planRows.map((row) => SafetyPlan.fromMap(row, const [])).toList();
    }

    final placeholders = List.filled(planIds.length, '?').join(',');
    final stepRows = await db.query(
      StringConstant.safetyPlanStepsTable,
      where: 'plan_id IN ($placeholders)',
      whereArgs: planIds,
      orderBy: 'plan_id ASC, step_order ASC, id ASC',
    );

    final stepsByPlan = <int, List<String>>{};
    for (final row in stepRows) {
      final planId = row['plan_id'] as int?;
      if (planId == null) continue;
      stepsByPlan.putIfAbsent(planId, () => []);
      stepsByPlan[planId]!.add(row['description'] as String? ?? '');
    }

    return planRows.map((row) {
      final planId = row['id'] as int?;
      final steps = planId != null
          ? List<String>.from(stepsByPlan[planId] ?? [])
          : <String>[];
      return SafetyPlan.fromMap(row, steps);
    }).toList();
  }

  Future<SafetyPlan> insertSafetyPlan(SafetyPlan plan) async {
    final db = await database;
    await _ensureTablesExist(db);
    return db.transaction((txn) async {
      final timestamped = plan.copyWith(createdAt: DateTime.now());
      final planMap = timestamped.toMap()..remove('id');
      final planId = await txn.insert(
        StringConstant.safetyPlansTable,
        planMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (var index = 0; index < timestamped.steps.length; index++) {
        final step = timestamped.steps[index];
        await txn.insert(
          StringConstant.safetyPlanStepsTable,
          {'plan_id': planId, 'step_order': index, 'description': step},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return timestamped.copyWith(id: planId);
    });
  }

  Future<void> deleteSafetyPlan(int id) async {
    final db = await database;
    await _ensureTablesExist(db);
    await db.delete(
      StringConstant.safetyPlansTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  // Analysis -----------------------------------------------------------
  Future<void> saveDreamAnalysis(
    String dreamID,
    String content,
    String analysisID,
  ) async {
    final db = await database;
    final now = DateTime.now();

    final analysis = DreamAnalysis(
      analysisID: analysisID,
      dreamID: dreamID,
      analysisContent: content,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert(
      StringConstant.dreamAnalysisTable,
      analysis.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DreamAnalysis?> fetchDreamAnalysis(String dreamID) async {
    final db = await database;

    await _ensureTablesExist(db);

    final result = await db.query(
      StringConstant.dreamAnalysisTable,
      where: 'dream_id = ?',
      whereArgs: [dreamID],
    );

    if (result.isNotEmpty) {
      return DreamAnalysis.fromMap(result.first);
    }
    return null;
  }

  // Diagnosis -----------------------------------------------------------
  Future<void> saveDreamDiagnosis(String diagnosisID, String content) async {
    final db = await database;
    final now = DateTime.now();

    final diagnosis = DreamDiagnosis(
      diagnosisID: diagnosisID,
      diagnosisContent: content,
      createdAt: now,
    );

    await db.insert(
      StringConstant.dreamDiagnosisTable,
      diagnosis.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DreamDiagnosis>> fetchDreamDiagnosis() async {
    final db = await database;
    final result = await db.query(
      StringConstant.dreamDiagnosisTable,
      orderBy: 'created_at DESC',
    );
    return result.map((map) => DreamDiagnosis.fromMap(map)).toList();
  }

  // Recommendation Helper ------------------------------------------------
  Future<Map<String, Object?>?> getLatestDreamWithAnalysis() async {
    final db = await database;
    
    // Get latest dream
    final dreamRows = await db.query(
      StringConstant.dreamEntryTable,
      orderBy: 'created_at DESC',
      limit: 1,
    );
    
    if (dreamRows.isEmpty) return null;
    final dream = DreamEntry.fromMap(dreamRows.first);
    
    // Get its analysis
    final analysisRows = await db.query(
      StringConstant.dreamAnalysisTable,
      where: 'dream_id = ?',
      whereArgs: [dream.dreamID],
    );
    
    final analysis = analysisRows.isNotEmpty 
        ? DreamAnalysis.fromMap(analysisRows.first) 
        : null;
        
    return {
      'dream': dream,
      'analysis': analysis,
    };
  }

  // Saved Music ----------------------------------------------------------
  Future<void> saveMusic(MusicTrack track) async {
    final db = await database;
    await db.insert(
      'saved_music',
      {
        'title': track.title,
        'artist': track.artist,
        'note': track.note,
        'thumbnailUrl': track.thumbnailUrl,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeMusic(MusicTrack track) async {
    final db = await database;
    await db.delete(
      'saved_music',
      where: 'title = ? AND artist = ?',
      whereArgs: [track.title, track.artist],
    );
  }

  Future<bool> isMusicSaved(MusicTrack track) async {
    final db = await database;
    final result = await db.query(
      'saved_music',
      where: 'title = ? AND artist = ?',
      whereArgs: [track.title, track.artist],
    );
    return result.isNotEmpty;
  }

  Future<List<MusicTrack>> fetchSavedMusic() async {
    final db = await database;
    final result = await db.query(
      'saved_music',
      orderBy: 'created_at DESC',
    );
    return result.map(MusicTrack.fromMap).toList();
  }

  // Saved Videos ---------------------------------------------------------
  Future<void> saveVideo(VideoTrack track) async {
    final db = await database;
    await db.insert(
      'saved_videos',
      {
        'title': track.title,
        'channel': track.channel,
        'note': track.note,
        'thumbnailUrl': track.thumbnailUrl,
        'videoId': track.videoId,
        'videoUrl': track.videoUrl,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeVideo(VideoTrack track) async {
    final db = await database;
    await db.delete(
      'saved_videos',
      where: 'title = ?',
      whereArgs: [track.title],
    );
  }

  Future<bool> isVideoSaved(VideoTrack track) async {
    final db = await database;
    final result = await db.query(
      'saved_videos',
      where: 'title = ?',
      whereArgs: [track.title],
    );
    return result.isNotEmpty;
  }

  Future<List<VideoTrack>> fetchSavedVideos() async {
    final db = await database;
    final result = await db.query(
      'saved_videos',
      orderBy: 'created_at DESC',
    );
    return result.map(VideoTrack.fromMap).toList();
  }

  // Saved Articles -------------------------------------------------------
  Future<void> saveArticle(ArticleRecommendation article) async {
    final db = await database;
    await db.insert(
      'saved_articles',
      {
        'title': article.title,
        'summary': article.summary,
        'content': article.content,
        'moodBenefit': article.moodBenefit,
        'tags': article.tags.join(','), // Store as comma-separated string
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeArticle(ArticleRecommendation article) async {
    final db = await database;
    await db.delete(
      'saved_articles',
      where: 'title = ?',
      whereArgs: [article.title],
    );
  }

  Future<bool> isArticleSaved(ArticleRecommendation article) async {
    final db = await database;
    final result = await db.query(
      'saved_articles',
      where: 'title = ?',
      whereArgs: [article.title],
    );
    return result.isNotEmpty;
  }

  Future<List<ArticleRecommendation>> fetchSavedArticles() async {
    final db = await database;
    final result = await db.query(
      'saved_articles',
      orderBy: 'created_at DESC',
    );
    return result.map(ArticleRecommendation.fromMap).toList();
  }
}
