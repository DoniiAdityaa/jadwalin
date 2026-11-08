import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'models.dart';

/// Akses data sesi & pesan chat ke SQLite lokal.
class ChatDao {
  ChatDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<Database> get _db async => _dbHelper.database;

  // ------------------------- SESSIONS -------------------------

  /// Semua sesi chat, terbaru dulu (untuk sidebar "Riwayat Chat").
  Future<List<ChatSessionModel>> getSessions({int limit = 30}) async {
    final db = await _db;
    final rows = await db.query(
      'chat_sessions',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows.map(ChatSessionModel.fromMap).toList();
  }

  Future<ChatSessionModel?> getSession(String id) async {
    final db = await _db;
    final rows = await db.query(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ChatSessionModel.fromMap(rows.first);
  }

  Future<void> upsertSession(ChatSessionModel session) async {
    final db = await _db;
    await db.insert(
      'chat_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Perbarui judul + waktu update (dipanggil tiap ada pesan baru).
  Future<void> touchSession(String id, {DateTime? time}) async {
    final db = await _db;
    await db.update(
      'chat_sessions',
      {'updated_at': (time ?? DateTime.now()).millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await _db;
    // ON DELETE CASCADE pastikan semua pesan ikut terhapus
    await db.delete('chat_sessions', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------------- MESSAGES -------------------------

  Future<List<ChatMessageModel>> getMessages(String sessionId) async {
    final db = await _db;
    final rows = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
    return rows.map(ChatMessageModel.fromMap).toList();
  }

  /// Simpan satu pesan, return id-nya.
  Future<int> insertMessage(ChatMessageModel message) async {
    final db = await _db;
    final id = await db.insert('chat_messages', message.toMap());
    await touchSession(message.sessionId, time: message.createdAt);
    return id;
  }

  Future<void> clearMessages(String sessionId) async {
    final db = await _db;
    await db.delete(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }
}
