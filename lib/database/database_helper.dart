import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/outfit.dart';
import '../models/user_profile.dart';
import '../models/favorite.dart';
import '../models/tryon_history.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smartfit.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';

    // Table Outfits
    await db.execute('''
      CREATE TABLE outfits (
        id $textType PRIMARY KEY,
        name $textType,
        imagePath $textType,
        price $realType,
        gender $textType,
        morphologies $textType,
        seasons $textType,
        matchScore $realType
      )
    ''');

    // Table UserProfile
    await db.execute('''
      CREATE TABLE user_profile (
        id $idType,
        name $textType,
        gender $textType,
        morphology $textType,
        season $textType,
        avatarPath TEXT
      )
    ''');

    // Table Favorites
    await db.execute('''
      CREATE TABLE favorites (
        id $idType,
        outfitId $textType,
        addedAt $textType,
        FOREIGN KEY (outfitId) REFERENCES outfits (id) ON DELETE CASCADE
      )
    ''');

    // Table TryOnHistory
    await db.execute('''
      CREATE TABLE tryon_history (
        id $idType,
        outfitId $textType,
        userImagePath $textType,
        generatedImagePath TEXT,
        triedAt $textType,
        FOREIGN KEY (outfitId) REFERENCES outfits (id) ON DELETE CASCADE
      )
    ''');
  }

  // ========== CRUD OUTFITS ==========
  Future<void> insertOutfit(Outfit outfit) async {
    final db = await database;
    await db.insert('outfits', outfit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Outfit>> getAllOutfits() async {
    final db = await database;
    final result = await db.query('outfits');
    return result.map((map) => Outfit.fromMap(map)).toList();
  }

  Future<Outfit?> getOutfitById(String id) async {
    final db = await database;
    final result = await db.query('outfits', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Outfit.fromMap(result.first);
    }
    return null;
  }

  Future<void> updateOutfit(Outfit outfit) async {
    final db = await database;
    await db.update('outfits', outfit.toMap(),
        where: 'id = ?', whereArgs: [outfit.id]);
  }

  Future<void> deleteOutfit(String id) async {
    final db = await database;
    await db.delete('outfits', where: 'id = ?', whereArgs: [id]);
  }

  // Filtrer les outfits selon profil utilisateur
  // ✅ Add or replace inside DatabaseHelper class
  Future<List<Outfit>> getRecommendedOutfits(
      String gender,
      String morphology,
      String season,
      ) async {
    final db = await database;
    final result = await db.query('outfits');
    final outfits = result.map((map) => Outfit.fromMap(map)).toList();

    final List<Outfit> scoredOutfits = [];

    for (var outfit in outfits) {
      double score = 0;

      final outfitGender = outfit.gender.toLowerCase();
      final userGender = gender.toLowerCase();
      final outfitSeasons = outfit.seasons.map((e) => e.toLowerCase()).toList();
      final outfitMorphs = outfit.morphologies.map((e) => e.toLowerCase()).toList();

      // ❌ Skip if gender doesn't match (unless unisex)
      if (outfitGender != userGender && outfitGender != 'unisex') {
        continue;
      }

      // ❌ Skip if season doesn't match
      if (!outfitSeasons.contains(season.toLowerCase())) {
        continue;
      }

      // ✅ Scoring logic
      if (outfitGender == userGender) score += 40;
      if (outfitMorphs.contains(morphology.toLowerCase())) score += 35;
      if (outfitSeasons.contains(season.toLowerCase())) score += 25;

      scoredOutfits.add(outfit.copyWith(matchScore: score));
    }

    // Sort by descending score
    scoredOutfits.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return scoredOutfits;
  }

  // ========== CRUD USER PROFILE ==========
  Future<int> insertUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.insert('user_profile', profile.toMap());
  }
  Future<void> deleteUserProfile() async {
    final db = await instance.database;
    await db.delete('user_profile');
  }
  // database/database_helper.dart  (add this utility method)

  int calculateMatchScore({
    required String userGender,
    required String userMorphology,
    required String userSeason,
    required String outfitGender,
    required String outfitMorphology,
    required String outfitSeason,
  }) {
    int score = 0;

    if (userGender.toLowerCase() == outfitGender.toLowerCase()) {
      score += 40;
    }
    if (userMorphology.toLowerCase() == outfitMorphology.toLowerCase()) {
      score += 35;
    }
    if (userSeason.toLowerCase() == outfitSeason.toLowerCase()) {
      score += 25;
    }

    return score;
  }

  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final result = await db.query('user_profile', limit: 1);
    if (result.isNotEmpty) {
      return UserProfile.fromMap(result.first);
    }
    return null;
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    final db = await database;
    await db.update('user_profile', profile.toMap(),
        where: 'id = ?', whereArgs: [profile.id]);
  }

  // ===================== FAVORITES CRUD =====================

  Future<void> addFavorite(String outfitId) async {
    final db = await instance.database;

    // ✅ Check first if it already exists
    final existing = await db.query(
      'favorites',
      where: 'outfitId = ?',
      whereArgs: [outfitId],
    );

    if (existing.isNotEmpty) {
      // Already in favorites — don’t insert again
      return;
    }

    await db.insert(
      'favorites',
      {
        'outfitId': outfitId,
        'addedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // safety check
    );
  }

  Future<List<Outfit>> getFavoriteOutfits() async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT o.* FROM outfits o
    INNER JOIN favorites f ON o.id = f.outfitId
    ORDER BY f.addedAt DESC
  ''');
    return result.map((map) => Outfit.fromMap(map)).toList();
  }

  Future<bool> isFavorite(String outfitId) async {
    final dbClient = await database;
    final result = await dbClient.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [outfitId],
    );
    return result.isNotEmpty;
  }

  Future<void> removeFavorite(String outfitId) async {
    final db = await database;
    await db.delete('favorites', where: 'outfitId = ?', whereArgs: [outfitId]);
  }

// 🧩 Optionnel : pour mettre à jour une tenue favorite (si tu veux modifier un champ)
  Future<void> updateFavorite(String outfitId, DateTime newDate) async {
    final db = await database;
    await db.update(
      'favorites',
      {'addedAt': newDate.toIso8601String()},
      where: 'outfitId = ?',
      whereArgs: [outfitId],
    );
  }

  // ========== CRUD TRY-ON HISTORY ==========
  Future<int> addTryOnHistory(TryOnHistory history) async {
    final db = await database;
    return await db.insert('tryon_history', history.toMap());
  }

  Future<List<TryOnHistory>> getTryOnHistory() async {
    final db = await database;
    final result =
    await db.query('tryon_history', orderBy: 'triedAt DESC', limit: 50);
    return result.map((map) => TryOnHistory.fromMap(map)).toList();
  }

  Future<void> deleteTryOnHistory(int id) async {
    final db = await database;
    await db.delete('tryon_history', where: 'id = ?', whereArgs: [id]);
  }

  // ========== UTILITIES ==========
  Future close() async {
    final db = await database;
    db.close();
  }
}
