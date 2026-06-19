import 'package:cloud_firestore/cloud_firestore.dart';

class PesertaEventModel {
  final String npm;
  final String nama;
  final String jurusan;
  final int tahunMasuk;
  final String? tanggalDaftar;

  PesertaEventModel({
    required this.npm,
    required this.nama,
    required this.jurusan,
    required this.tahunMasuk,
    this.tanggalDaftar,
  });

  // ── Firestore (membaca dari koleksi pendaftaran_event yang telah di-denormalisasi) ──

  factory PesertaEventModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    final ts = d['tanggal_daftar'] as Timestamp?;
    return PesertaEventModel(
      npm: d['npm'] as String,
      nama: (d['nama'] as String?) ?? 'Unknown',
      jurusan: (d['jurusan'] as String?) ?? '-',
      tahunMasuk: (d['tahun_masuk'] as int?) ?? 0,
      tanggalDaftar: ts?.toDate().toIso8601String(),
    );
  }
}
