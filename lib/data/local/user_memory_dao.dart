import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

/// Akses data memori lintas-sesi: fakta ringkas tentang user
/// (nama, kampus, semester, dsb) yang dibagikan ke setiap chat baru.
class UserMemoryDao {
  UserMemoryDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<Database> get _db async => _dbHelper.database;

  /// Batas jumlah fakta yang disimpan, supaya prompt tidak membengkak.
  static const int maxFacts = 20;

  /// Semua fakta, terbaru dulu.
  Future<List<String>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      'user_memory',
      orderBy: 'updated_at DESC',
      limit: maxFacts,
    );
    return rows.map((r) => r['fact'] as String).toList();
  }

  /// Simpan satu fakta. Duplikat diabaikan (UNIQUE constraint).
  Future<void> saveFact(String fact) async {
    final trimmed = fact.trim();
    if (trimmed.isEmpty) return;

    final db = await _db;
    await db.insert(
      'user_memory',
      {
        'fact': trimmed,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await _trimToLimit();
  }

  /// Simpan banyak fakta sekaligus.
  Future<void> saveFacts(List<String> facts) async {
    for (final fact in facts) {
      await saveFact(fact);
    }
  }

  /// Potong fakta lama kalau melewati [maxFacts].
  Future<void> _trimToLimit() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM user_memory'),
        ) ??
        0;
    if (count <= maxFacts) return;

    await db.rawDelete('''
      DELETE FROM user_memory
      WHERE id NOT IN (
        SELECT id FROM user_memory ORDER BY updated_at DESC LIMIT $maxFacts
      )
    ''');
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('user_memory');
  }
}
