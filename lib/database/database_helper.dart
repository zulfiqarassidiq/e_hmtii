import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/admin_model.dart';
import '../models/event_model.dart';
import '../models/pendaftaran_model.dart';
import '../models/peserta_event_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('event_kampus.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user (
        npm         VARCHAR PRIMARY KEY,
        nama        VARCHAR NOT NULL,
        jurusan     VARCHAR NOT NULL,
        tahun_masuk INTEGER NOT NULL,
        password    VARCHAR NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE admin (
        id_admin VARCHAR PRIMARY KEY,
        password VARCHAR NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE event_kampus (
        id_event        VARCHAR PRIMARY KEY,
        nama_event      VARCHAR NOT NULL,
        tanggal_mulai   DATETIME NOT NULL,
        tanggal_selesai DATETIME NOT NULL,
        kuota           INTEGER NOT NULL,
        lokasi          VARCHAR NOT NULL,
        foto            VARCHAR,
        deskripsi       TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pendaftaran_event (
        id_pendaftaran INTEGER PRIMARY KEY AUTOINCREMENT,
        npm            VARCHAR NOT NULL,
        id_event       VARCHAR NOT NULL,
        tanggal_daftar TEXT,
        FOREIGN KEY (npm)      REFERENCES user(npm),
        FOREIGN KEY (id_event) REFERENCES event_kampus(id_event)
      )
    ''');

    // Seed default admin
    await db.insert('admin', {'id_admin': 'admin001', 'password': 'admin123'});

    // Seed sample events
    await db.insert('event_kampus', {
      'id_event': 'EVT001',
      'nama_event': 'Seminar Nasional Teknologi 2025',
      'tanggal_mulai': '2025-07-10 08:00:00',
      'tanggal_selesai': '2025-07-10 17:00:00',
      'kuota': 200,
      'lokasi': 'Aula Utama Gedung A',
      'foto': '',
      'deskripsi':
          'Seminar nasional yang membahas tren teknologi terkini, meliputi kecerdasan buatan, komputasi awan, dan keamanan siber. Terbuka untuk seluruh mahasiswa dan civitas akademika.',
    });

    await db.insert('event_kampus', {
      'id_event': 'EVT002',
      'nama_event': 'Workshop UI/UX Design',
      'tanggal_mulai': '2025-08-15 09:00:00',
      'tanggal_selesai': '2025-08-15 16:00:00',
      'kuota': 50,
      'lokasi': 'Lab Komputer Lantai 3',
      'foto': '',
      'deskripsi':
          'Workshop intensif desain antarmuka dan pengalaman pengguna menggunakan Figma. Peserta akan langsung mempraktikkan proses wireframing, prototyping, dan user testing.',
    });

    await db.insert('event_kampus', {
      'id_event': 'EVT003',
      'nama_event': 'Lomba Karya Tulis Ilmiah',
      'tanggal_mulai': '2025-05-01 08:00:00',
      'tanggal_selesai': '2025-05-03 17:00:00',
      'kuota': 100,
      'lokasi': 'Ruang Seminar B',
      'foto': '',
      'deskripsi':
          'Kompetisi karya tulis ilmiah tingkat fakultas. Peserta mempresentasikan hasil penelitian di hadapan dewan juri. Pemenang mendapatkan sertifikat dan penghargaan.',
    });
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE pendaftaran_event ADD COLUMN tanggal_daftar TEXT',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE event_kampus ADD COLUMN deskripsi TEXT',
      );
    }
  }

  // ─── USER ────────────────────────────────────────────────────────────────────

  Future<int> insertUser(UserModel user) async {
    final db = await instance.database;
    return await db.insert(
      'user',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<UserModel?> getUserByNpm(String npm) async {
    final db = await instance.database;
    final maps = await db.query('user', where: 'npm = ?', whereArgs: [npm]);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> loginUser(String npm, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'user',
      where: 'npm = ? AND password = ?',
      whereArgs: [npm, password],
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<int> updateUserPassword(String npm, String newPassword) async {
    final db = await instance.database;
    return await db.update(
      'user',
      {'password': newPassword},
      where: 'npm = ?',
      whereArgs: [npm],
    );
  }

  /// Mengambil semua akun mahasiswa, diurutkan berdasarkan nama.
  Future<List<UserModel>> getAllUsers() async {
    final db = await instance.database;
    final maps = await db.query('user', orderBy: 'nama ASC');
    return maps.map(UserModel.fromMap).toList();
  }

  // ─── ADMIN ───────────────────────────────────────────────────────────────────

  Future<AdminModel?> loginAdmin(String idAdmin, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'admin',
      where: 'id_admin = ? AND password = ?',
      whereArgs: [idAdmin, password],
    );
    if (maps.isEmpty) return null;
    return AdminModel.fromMap(maps.first);
  }

  // ─── EVENT ───────────────────────────────────────────────────────────────────

  Future<List<EventModel>> getAllEvents() async {
    final db = await instance.database;
    final maps = await db.query('event_kampus', orderBy: 'tanggal_mulai DESC');
    return maps.map(EventModel.fromMap).toList();
  }

  /// Query SQLite untuk event yang sedang berlangsung (mulai <= now <= selesai).
  Future<List<EventModel>> getOngoingEvents() async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.rawQuery('''
      SELECT * FROM event_kampus
      WHERE tanggal_mulai <= ? AND tanggal_selesai >= ?
      ORDER BY tanggal_mulai ASC
    ''', [now, now]);
    return maps.map(EventModel.fromMap).toList();
  }

  Future<EventModel?> getEventById(String idEvent) async {
    final db = await instance.database;
    final maps = await db.query(
      'event_kampus',
      where: 'id_event = ?',
      whereArgs: [idEvent],
    );
    if (maps.isEmpty) return null;
    return EventModel.fromMap(maps.first);
  }

  Future<int> insertEvent(EventModel event) async {
    final db = await instance.database;
    return await db.insert(
      'event_kampus',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateEvent(EventModel event) async {
    final db = await instance.database;
    return await db.update(
      'event_kampus',
      event.toMap(),
      where: 'id_event = ?',
      whereArgs: [event.idEvent],
    );
  }

  Future<int> deleteEvent(String idEvent) async {
    final db = await instance.database;
    await db.delete(
      'pendaftaran_event',
      where: 'id_event = ?',
      whereArgs: [idEvent],
    );
    return await db.delete(
      'event_kampus',
      where: 'id_event = ?',
      whereArgs: [idEvent],
    );
  }

  // ─── PENDAFTARAN ─────────────────────────────────────────────────────────────

  Future<int> insertPendaftaran(PendaftaranModel p) async {
    final db = await instance.database;
    final map = p.toMap();
    map['tanggal_daftar'] = DateTime.now().toIso8601String();
    return await db.insert('pendaftaran_event', map);
  }

  Future<bool> isUserRegistered(String npm, String idEvent) async {
    final db = await instance.database;
    final maps = await db.query(
      'pendaftaran_event',
      where: 'npm = ? AND id_event = ?',
      whereArgs: [npm, idEvent],
    );
    return maps.isNotEmpty;
  }

  Future<int> getPesertaCount(String idEvent) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pendaftaran_event WHERE id_event = ?',
      [idEvent],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<List<PendaftaranModel>> getPendaftaranByNpm(String npm) async {
    final db = await instance.database;
    final maps = await db.query(
      'pendaftaran_event',
      where: 'npm = ?',
      whereArgs: [npm],
    );
    return maps.map(PendaftaranModel.fromMap).toList();
  }

  Future<int> deletePendaftaran(String npm, String idEvent) async {
    final db = await instance.database;
    return await db.delete(
      'pendaftaran_event',
      where: 'npm = ? AND id_event = ?',
      whereArgs: [npm, idEvent],
    );
  }

  /// JOIN pendaftaran_event ← user untuk event tertentu, diurutkan nama.
  Future<List<PesertaEventModel>> getPesertaByEventId(String idEvent) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT u.npm, u.nama, u.jurusan, u.tahun_masuk, pe.tanggal_daftar
      FROM pendaftaran_event pe
      INNER JOIN user u ON pe.npm = u.npm
      WHERE pe.id_event = ?
      ORDER BY u.nama ASC
    ''', [idEvent]);
    return maps.map(PesertaEventModel.fromMap).toList();
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
