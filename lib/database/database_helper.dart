// Compatibility wrapper — semua method mendelegasikan ke FirebaseService.
// Screen-screen lama yang masih mengimport DatabaseHelper tidak perlu diubah.
// Migrasi bertahap: ganti import satu per satu ke FirebaseService jika diperlukan.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_service.dart';
import '../models/admin_model.dart';
import '../models/event_model.dart';
import '../models/pendaftaran_model.dart';
import '../models/peserta_event_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  // ─── USER ─────────────────────────────────────────────────────────────────

  Future<int> insertUser(UserModel user) async {
    await FirebaseService.instance.registerUser(user);
    return 1;
  }

  Future<UserModel?> getUserByNpm(String npm) =>
      FirebaseService.instance.getUserByNpm(npm);

  Future<UserModel?> loginUser(String npm, String password) =>
      FirebaseService.instance.loginUser(npm, password);

  Future<int> updateUserPassword(String npm, String newPassword) async {
    await FirebaseService.instance.updateUserPassword(npm, newPassword);
    return 1;
  }

  Future<List<UserModel>> getAllUsers() =>
      FirebaseService.instance.getAllUsersStream().first;

  // ─── ADMIN ────────────────────────────────────────────────────────────────

  Future<AdminModel?> loginAdmin(String idAdmin, String password) =>
      FirebaseService.instance.loginAdmin(idAdmin, password);

  // ─── EVENT ────────────────────────────────────────────────────────────────

  Future<List<EventModel>> getAllEvents() =>
      FirebaseService.instance.getEventsStream().first;

  Future<List<EventModel>> getOngoingEvents() =>
      FirebaseService.instance.getOngoingEventsStream().first;

  Future<EventModel?> getEventById(String idEvent) async {
    final doc = await FirebaseFirestore.instance
        .collection('events')
        .doc(idEvent)
        .get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc);
  }

  Future<int> insertEvent(EventModel event) async {
    await FirebaseService.instance.addEvent(event);
    return 1;
  }

  Future<int> updateEvent(EventModel event) async {
    await FirebaseService.instance.updateEvent(event);
    return 1;
  }

  Future<int> deleteEvent(String idEvent) async {
    await FirebaseService.instance.deleteEvent(idEvent);
    return 1;
  }

  // ─── PENDAFTARAN ──────────────────────────────────────────────────────────

  Future<int> insertPendaftaran(PendaftaranModel p) async {
    await FirebaseService.instance.registerForEvent(p.npm, p.idEvent);
    return 1;
  }

  Future<bool> isUserRegistered(String npm, String idEvent) =>
      FirebaseService.instance.isUserRegistered(npm, idEvent);

  Future<int> getPesertaCount(String idEvent) =>
      FirebaseService.instance.getPesertaCount(idEvent);

  Future<List<PendaftaranModel>> getPendaftaranByNpm(String npm) =>
      FirebaseService.instance.getPendaftaranByNpmStream(npm).first;

  Future<int> deletePendaftaran(String npm, String idEvent) async {
    await FirebaseService.instance.cancelRegistration(npm, idEvent);
    return 1;
  }

  Future<List<PesertaEventModel>> getPesertaByEventId(String idEvent) =>
      FirebaseService.instance.getPesertaByEventIdStream(idEvent).first;
}
