import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'models.dart';

/// Akses data jadwal ke SQLite lokal.
class ScheduleDao {
  ScheduleDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<Database> get _db async => _dbHelper.database;

  /// Semua jadwal pada satu hari (range 00:00 - 23:59).
  Future<List<ScheduleModel>> getByDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _rangeQuery(start, end);
  }

  /// Jadwal rentang tanggal (misal kebutuhan tampilan minggu/bulan).
  Future<List<ScheduleModel>> getByRange(DateTime from, DateTime to) {
    return _rangeQuery(from, to);
  }

  Future<List<ScheduleModel>> _rangeQuery(DateTime from, DateTime to) async {
    final db = await _db;
    final rows = await db.query(
      'schedules',
      where: 'start_at < ? AND end_at > ?',
      whereArgs: [
        to.millisecondsSinceEpoch,
        from.millisecondsSinceEpoch,
      ],
      orderBy: 'start_at ASC',
    );
    return rows.map(ScheduleModel.fromMap).toList();
  }

  /// Tanggal-tanggal yang punya minimal satu jadwal (untuk dot di kalender).
  Future<Set<DateTime>> getEventDays(DateTime month) async {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 1);
    final db = await _db;
    final rows = await db.query(
      'schedules',
      columns: ['start_at'],
      where: 'start_at < ? AND end_at > ?',
      whereArgs: [
        to.millisecondsSinceEpoch,
        from.millisecondsSinceEpoch,
      ],
    );
    return rows
        .map((r) {
          final dt =
              DateTime.fromMillisecondsSinceEpoch(r['start_at'] as int);
          return DateTime(dt.year, dt.month, dt.day);
        })
        .toSet();
  }

  Future<void> insert(ScheduleModel model) async {
    final db = await _db;
    await db.insert(
      'schedules',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(ScheduleModel model) async {
    final db = await _db;
    await db.update(
      'schedules',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('schedules');
  }
}
