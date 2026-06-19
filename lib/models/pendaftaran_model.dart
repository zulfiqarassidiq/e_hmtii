import 'package:cloud_firestore/cloud_firestore.dart';

class PendaftaranModel {
  final String? idPendaftaran; // Firestore document ID
  final String npm;
  final String idEvent;
  final DateTime? tanggalDaftar;

  PendaftaranModel({
    this.idPendaftaran,
    required this.npm,
    required this.idEvent,
    this.tanggalDaftar,
  });

  // ── Firestore ──────────────────────────────────────────────────────────────

  factory PendaftaranModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    return PendaftaranModel(
      idPendaftaran: doc.id,
      npm: d['npm'] as String,
      idEvent: d['id_event'] as String,
      tanggalDaftar: (d['tanggal_daftar'] as Timestamp?)?.toDate(),
    );
  }
}
