import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String npm;
  final String nama;
  final String jurusan;
  final int tahunMasuk;
  final String password;

  UserModel({
    required this.npm,
    required this.nama,
    required this.jurusan,
    required this.tahunMasuk,
    required this.password,
  });

  // ── Firestore ──────────────────────────────────────────────────────────────

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return UserModel(
      npm: doc.id,
      nama: d['nama'] as String,
      jurusan: d['jurusan'] as String,
      tahunMasuk: d['tahun_masuk'] as int,
      password: d['password'] as String,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nama': nama,
        'jurusan': jurusan,
        'tahun_masuk': tahunMasuk,
        'password': password,
        // npm tidak disimpan di body — npm IS the document ID
      };

  UserModel copyWith({
    String? npm,
    String? nama,
    String? jurusan,
    int? tahunMasuk,
    String? password,
  }) =>
      UserModel(
        npm: npm ?? this.npm,
        nama: nama ?? this.nama,
        jurusan: jurusan ?? this.jurusan,
        tahunMasuk: tahunMasuk ?? this.tahunMasuk,
        password: password ?? this.password,
      );
}
