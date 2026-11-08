import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper tunggal untuk buka & migrasi database SQLite lokal.
///
/// Catatan: semua tabel di sini LOCAL-ONLY. Saat fitur login + sync
/// ditambahkan nanti, cukup tambah kolom `remote_id` & `synced_at`
/// lewat migrasi versi baru (lihat `_onUpgrade`).
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'jadwalin.db';
  static const int _dbVersion = 2;

  Database? _db;

  /// Getter database (lazy-open).
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        // Wajib untuk ON DELETE CASCADE
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ---------------------------------------------------------------
  // SCHEMA
  // ---------------------------------------------------------------
  Future<void> _onCreate(Database db, int version) async {
    // 1. Kategori jadwal (KULIAH, ORGANISASI, BOOTCAMP, DEADLINE, ...)
    await db.execute('''
      CREATE TABLE categories (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        color_hex   TEXT NOT NULL,
        icon_asset  TEXT,
        sort_order  INTEGER NOT NULL DEFAULT 0,
        created_at  INTEGER NOT NULL
      )
    ''');

    // 2. Jadwal / agenda
    await db.execute('''
      CREATE TABLE schedules (
        id            TEXT PRIMARY KEY,
        title         TEXT NOT NULL,
        description   TEXT,
        category_id   TEXT,
        location      TEXT,
        start_at      INTEGER NOT NULL,
        end_at        INTEGER NOT NULL,
        is_all_day    INTEGER NOT NULL DEFAULT 0,
        reminder_min  INTEGER,
        created_at    INTEGER NOT NULL,
        updated_at    INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_schedules_start ON schedules (start_at)',
    );
    await db.execute('CREATE INDEX idx_schedules_end ON schedules (end_at)');

    // 3. Sesi chat (satu percakapan = satu sesi, muncul di sidebar)
    await db.execute('''
      CREATE TABLE chat_sessions (
        id          TEXT PRIMARY KEY,
        title       TEXT NOT NULL,
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_sessions_updated ON chat_sessions (updated_at DESC)',
    );

    // 4. Pesan chat
    await db.execute('''
      CREATE TABLE chat_messages (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id  TEXT NOT NULL,
        role        TEXT NOT NULL,
        content     TEXT NOT NULL,
        created_at  INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_session
      ON chat_messages (session_id, created_at)
    ''');

    // Seed kategori default
    await _seedCategories(db);

    // Memori lintas-sesi
    await _createUserMemoryTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    // Migrasi v1 → v2: tabel memori lintas-sesi.
    if (oldV < 2) {
      await _createUserMemoryTable(db);
    }

    // Contoh saat login + sync ditambahkan (versi 3):
    //   ALTER TABLE schedules    ADD COLUMN remote_id TEXT;
    //   ALTER TABLE schedules    ADD COLUMN synced_at INTEGER;
    //   ALTER TABLE chat_sessions ADD COLUMN remote_id TEXT;
    //   ALTER TABLE chat_messages ADD COLUMN remote_id TEXT;
    //   ALTER TABLE user_memory   ADD COLUMN remote_id TEXT;
  }

  /// Tabel fakta tentang user yang dipakai lintas sesi chat.
  Future<void> _createUserMemoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE user_memory (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        fact        TEXT NOT NULL UNIQUE,
        updated_at  INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _seedCategories(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final defaults = <Map<String, Object?>>[
      {
        'id': 'kuliah',
        'name': 'KULIAH',
        'color_hex': '#2563EB',
        'icon_asset': 'assets/svg/ic_book_open.svg',
        'sort_order': 0,
      },
      {
        'id': 'organisasi',
        'name': 'ORGANISASI',
        'color_hex': '#D97706',
        'icon_asset': 'assets/svg/ic_users.svg',
        'sort_order': 1,
      },
      {
        'id': 'bootcamp',
        'name': 'BOOTCAMP',
        'color_hex': '#059669',
        'icon_asset': 'assets/svg/ic_cpu.svg',
        'sort_order': 2,
      },
      {
        'id': 'deadline',
        'name': 'DEADLINE',
        'color_hex': '#DC2626',
        'icon_asset': 'assets/svg/ic_alarm_clock.svg',
        'sort_order': 3,
      },
    ];

    for (final c in defaults) {
      await db.insert('categories', {
        ...c,
        'created_at': now,
      });
    }
  }

  /// Isi contoh jadwal sekali saja, saat app pertama kali dibuka.
  ///
  /// Ditandai di `SharedPreferences` lewat key [seedFlag], supaya tidak
  /// menimpa data user saat app dibuka ulang.
  Future<void> seedSampleSchedulesOnce(SharedPreferences prefs) async {
    if (prefs.getBool('sample_schedules_seeded_v1') ?? false) return;

    final db = await database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final stamp = now.millisecondsSinceEpoch;

    DateTime at(int hour, int minute) =>
        today.add(Duration(hours: hour, minutes: minute));

    final samples = <Map<String, Object?>>[
      {
        'id': 'sample-kalkulus',
        'title': 'Kalkulus & Aljabar Linear',
        'location': 'Gedung D (R. 302)',
        'category_id': 'kuliah',
        'start_at': at(8, 0).millisecondsSinceEpoch,
        'end_at': at(9, 40).millisecondsSinceEpoch,
      },
      {
        'id': 'sample-alpro',
        'title': 'Algoritma & Pemrograman II',
        'location': 'Lab Komputer 4',
        'category_id': 'kuliah',
        'start_at': at(10, 0).millisecondsSinceEpoch,
        'end_at': at(11, 40).millisecondsSinceEpoch,
      },
      {
        'id': 'sample-rapat',
        'title': 'Rapat Finalisasi Rundown Dies Natalis',
        'location': 'Sekre BEM Gedung F',
        'category_id': 'organisasi',
        'start_at': at(13, 30).millisecondsSinceEpoch,
        'end_at': at(15, 0).millisecondsSinceEpoch,
      },
      {
        'id': 'sample-flutter',
        'title': 'Flutter & Mobile Development',
        'location': 'Online (Google Meet)',
        'category_id': 'bootcamp',
        'start_at': at(19, 30).millisecondsSinceEpoch,
        'end_at': at(21, 0).millisecondsSinceEpoch,
      },
    ];

    for (final s in samples) {
      await db.insert('schedules', {
        ...s,
        'is_all_day': 0,
        'created_at': stamp,
        'updated_at': stamp,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await prefs.setBool('sample_schedules_seeded_v1', true);
  }

  /// Tutup database (dipakai di test / logout).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
