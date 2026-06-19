import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/admin_model.dart';
import '../models/event_model.dart';
import '../models/pendaftaran_model.dart';
import '../models/peserta_event_model.dart';
import '../models/user_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  STRUKTUR KOLEKSI FIRESTORE
// ──────────────────────────────────────────────────────────────────────────────
//  users/{npm}
//    nama          : String
//    jurusan       : String
//    tahun_masuk   : Number
//    password      : String
//    (npm IS the document ID — tidak disimpan di body)
//
//  admins/{id_admin}
//    password      : String
//
//  events/{autoId}
//    nama_event    : String
//    tanggal_mulai : Timestamp
//    tanggal_selesai: Timestamp
//    kuota         : Number
//    lokasi        : String
//    foto          : String   (URL dari Firebase Storage atau internet)
//    deskripsi     : String
//    peserta_count : Number   (counter atomik, dikelola via FieldValue.increment)
//
//  pendaftaran_event/{npm_eventId}   ← ID deterministik: "${npm}_${eventId}"
//    npm           : String
//    id_event      : String
//    tanggal_daftar: Timestamp  (serverTimestamp)
//    nama          : String   (denormalisasi dari users)
//    jurusan       : String   (denormalisasi dari users)
//    tahun_masuk   : Number   (denormalisasi dari users)
//
//  COMPOSITE INDEXES YANG DIBUTUHKAN (buat di Firebase Console):
//    Collection: pendaftaran_event  →  Fields: id_event ASC, nama ASC
//    Collection: pendaftaran_event  →  Fields: npm ASC, tanggal_daftar DESC
// ══════════════════════════════════════════════════════════════════════════════

class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _admins =>
      _db.collection('loginAdmin');
  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');
  CollectionReference<Map<String, dynamic>> get _pendaftaran =>
      _db.collection('pendaftaran_event');

  // ─── DIAGNOSTIK ───────────────────────────────────────────────────────────

  /// Cek koneksi Firestore dari server (bukan cache lokal).
  /// Kembalikan kode error, atau null jika berhasil.
  Future<String?> testConnection() async {
    try {
      await _db
          .collection('loginAdmin')
          .limit(1)
          .get(const GetOptions(source: Source.server));
      return null;
    } on FirebaseException catch (e) {
      return e.code;
    } catch (_) {
      return 'unknown';
    }
  }

  // ─── STORAGE ──────────────────────────────────────────────────────────────

  /// Upload foto event ke Firebase Storage dan kembalikan URL download-nya.
  Future<String> uploadEventPhoto(XFile file) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref =
        FirebaseStorage.instance.ref().child('event_photos/$fileName');
    final snapshot = await ref.putFile(File(file.path));
    return snapshot.ref.getDownloadURL();
  }

  // ─── USER ─────────────────────────────────────────────────────────────────

  /// Mendaftarkan mahasiswa baru. NPM dipakai sebagai document ID.
  Future<void> registerUser(UserModel user) async {
    final existing = await _users.doc(user.npm).get();
    if (existing.exists) throw Exception('NPM sudah terdaftar.');
    await _users.doc(user.npm).set(user.toFirestore());
  }

  /// Autentikasi mahasiswa dengan NPM & password (disimpan plain-text).
  /// Rekomendasi: migrasi ke Firebase Authentication untuk keamanan produksi.
  Future<UserModel?> loginUser(String npm, String password) async {
    final doc = await _users.doc(npm).get();
    if (!doc.exists) return null;
    final user = UserModel.fromFirestore(doc);
    return user.password == password ? user : null;
  }

  Future<void> updateUserPassword(String npm, String newPassword) async {
    await _users.doc(npm).update({'password': newPassword});
  }

  Future<UserModel?> getUserByNpm(String npm) async {
    final doc = await _users.doc(npm).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Stream profil satu mahasiswa — dipakai di ProfileScreen.
  Stream<UserModel?> getUserStream(String npm) {
    return _users.doc(npm).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Stream semua mahasiswa, diurutkan nama — dipakai di DaftarUserScreen.
  Stream<List<UserModel>> getAllUsersStream() {
    return _users.orderBy('nama').snapshots().map(
          (snap) => snap.docs.map(UserModel.fromFirestore).toList(),
        );
  }

  /// Stream jumlah mahasiswa terdaftar — untuk card "Total Peserta" di admin panel.
  Stream<int> getTotalUsersStream() {
    return _users.snapshots().map((snap) => snap.docs.length);
  }

  // ─── ADMIN ────────────────────────────────────────────────────────────────

  Future<AdminModel?> loginAdmin(String idAdmin, String password) async {
    final doc = await _admins.doc(idAdmin).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['password'] != password) return null;
    return AdminModel(idAdmin: idAdmin, password: password);
  }

  // ─── EVENTS ───────────────────────────────────────────────────────────────

  /// Semua event, diurutkan tanggal mulai terbaru — dipakai di HomeScreen &
  /// AdminHomeScreen.
  Stream<List<EventModel>> getEventsStream() {
    return _events
        .orderBy('tanggal_mulai', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(EventModel.fromFirestore).toList());
  }

  /// Event yang saat ini berlangsung: tanggal_selesai >= now (filter Firestore)
  /// + tanggal_mulai <= now (filter client-side).
  ///
  /// Firestore tidak mendukung range filter ganda pada dua field berbeda dalam
  /// satu query, sehingga satu kondisi difilter di sisi klien.
  Stream<List<EventModel>> getOngoingEventsStream() {
    return _events
        .where('tanggal_selesai', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('tanggal_selesai')
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      return snap.docs
          .map(EventModel.fromFirestore)
          .where((e) => !e.tanggalMulai.isAfter(now))
          .toList();
    });
  }

  /// Menambahkan event baru. ID di-generate otomatis oleh Firestore.
  Future<void> addEvent(EventModel event) async {
    final data = event.toFirestore();
    data['peserta_count'] = 0; // inisialisasi counter atomik
    await _events.add(data);
  }

  /// Memperbarui event yang sudah ada (berdasarkan event.idEvent sebagai doc ID).
  Future<void> updateEvent(EventModel event) async {
    await _events.doc(event.idEvent).update(event.toFirestore());
  }

  /// Menghapus event beserta seluruh data pendaftarannya menggunakan Batch Write.
  Future<void> deleteEvent(String eventId) async {
    final batch = _db.batch();

    // Hapus semua pendaftaran terkait
    final regSnap =
        await _pendaftaran.where('id_event', isEqualTo: eventId).get();
    for (final doc in regSnap.docs) {
      batch.delete(doc.reference);
    }

    // Hapus event itu sendiri
    batch.delete(_events.doc(eventId));
    await batch.commit();
  }

  // ─── PENDAFTARAN ──────────────────────────────────────────────────────────

  /// Jumlah peserta real-time per event.
  /// Membaca field peserta_count dari dokumen event (dikelola via increment).
  Stream<int> getPesertaCountStream(String eventId) {
    return _events.doc(eventId).snapshots().map((doc) {
      if (!doc.exists) return 0;
      return (doc.data()!['peserta_count'] as int?) ?? 0;
    });
  }

  /// Total seluruh peserta real-time — dipakai di stat card Admin.
  /// Menjumlahkan peserta_count dari semua dokumen events.
  Stream<int> getTotalPesertaStream() {
    return _events.snapshots().map((snap) => snap.docs.fold<int>(
          0,
          (acc, doc) => acc + ((doc.data()['peserta_count'] as int?) ?? 0),
        ));
  }

  /// Status pendaftaran real-time seorang user pada satu event.
  Stream<bool> isUserRegisteredStream(String npm, String eventId) {
    // Dokumen registrasi memakai ID deterministik agar bisa dibaca by-reference.
    return _pendaftaran
        .doc('${npm}_$eventId')
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Daftar event yang diikuti seorang mahasiswa (untuk ProfileScreen).
  Stream<List<PendaftaranModel>> getPendaftaranByNpmStream(String npm) {
    return _pendaftaran
        .where('npm', isEqualTo: npm)
        .orderBy('tanggal_daftar', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(PendaftaranModel.fromFirestore).toList());
  }

  /// Daftar peserta suatu event dengan detail user (untuk DaftarPesertaEventScreen).
  /// Data user di-denormalisasi saat pendaftaran sehingga tidak perlu JOIN.
  Stream<List<PesertaEventModel>> getPesertaByEventIdStream(String eventId) {
    return _pendaftaran
        .where('id_event', isEqualTo: eventId)
        .orderBy('nama')
        .snapshots()
        .map((snap) =>
            snap.docs.map(PesertaEventModel.fromFirestore).toList());
  }

  // ─── DAFTAR EVENT (Transaction) ───────────────────────────────────────────

  /// Mendaftarkan mahasiswa ke event menggunakan Firestore Transaction.
  ///
  /// Keamanan race condition:
  ///   - Dokumen registrasi memakai ID deterministik → duplikasi terdeteksi atomik.
  ///   - peserta_count di dokumen event di-increment secara atomik.
  ///   - Semua read harus terjadi sebelum write dalam satu transaction.
  ///
  /// Data user di-fetch di luar transaction (user data jarang berubah saat
  /// proses registrasi berlangsung).
  Future<void> registerForEvent(String npm, String eventId) async {
    // Pre-fetch data user untuk denormalisasi (di luar transaction = ok)
    final userDoc = await _users.doc(npm).get();
    if (!userDoc.exists) throw Exception('Data user tidak ditemukan.');
    final userData = userDoc.data()!;

    final registrationId = '${npm}_$eventId';
    final registrationRef = _pendaftaran.doc(registrationId);
    final eventRef = _events.doc(eventId);

    await _db.runTransaction((transaction) async {
      // ── SEMUA READ DULU ──────────────────────────────────────────────────
      final eventDoc = await transaction.get(eventRef);
      final regDoc = await transaction.get(registrationRef);

      // ── VALIDASI ─────────────────────────────────────────────────────────
      if (!eventDoc.exists) throw Exception('Event tidak ditemukan.');
      if (regDoc.exists) throw Exception('Anda sudah terdaftar di event ini.');

      final data = eventDoc.data()!;
      final kuota = data['kuota'] as int;
      final pesertaCount = (data['peserta_count'] as int?) ?? 0;

      if (pesertaCount >= kuota) {
        throw Exception('Kuota event sudah penuh ($kuota/$kuota).');
      }

      // ── WRITE: buat dokumen pendaftaran ─────────────────────────────────
      transaction.set(registrationRef, {
        'npm': npm,
        'id_event': eventId,
        'tanggal_daftar': FieldValue.serverTimestamp(),
        // Denormalisasi data user agar query peserta tidak perlu JOIN
        'nama': userData['nama'],
        'jurusan': userData['jurusan'],
        'tahun_masuk': userData['tahun_masuk'],
      });

      // ── WRITE: increment counter di dokumen event ─────────────────────
      transaction.update(eventRef, {
        'peserta_count': FieldValue.increment(1),
      });
    });
  }

  /// Membatalkan pendaftaran dan mengurangi counter peserta secara atomik.
  Future<void> cancelRegistration(String npm, String eventId) async {
    final registrationId = '${npm}_$eventId';
    final registrationRef = _pendaftaran.doc(registrationId);
    final eventRef = _events.doc(eventId);

    await _db.runTransaction((transaction) async {
      final regDoc = await transaction.get(registrationRef);
      if (!regDoc.exists) return; // sudah dibatalkan sebelumnya

      transaction.delete(registrationRef);
      transaction.update(eventRef, {
        'peserta_count': FieldValue.increment(-1),
      });
    });
  }

  /// Cek sekali (non-stream) apakah user terdaftar — berguna sebelum operasi.
  Future<bool> isUserRegistered(String npm, String eventId) async {
    final doc = await _pendaftaran.doc('${npm}_$eventId').get();
    return doc.exists;
  }

  /// Ambil jumlah peserta sekali (non-stream) — untuk kalkulasi kuota di dialog.
  Future<int> getPesertaCount(String eventId) async {
    final doc = await _events.doc(eventId).get();
    if (!doc.exists) return 0;
    return (doc.data()!['peserta_count'] as int?) ?? 0;
  }
}
