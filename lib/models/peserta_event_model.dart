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

  factory PesertaEventModel.fromMap(Map<String, dynamic> map) =>
      PesertaEventModel(
        npm: map['npm'] as String,
        nama: map['nama'] as String,
        jurusan: map['jurusan'] as String,
        tahunMasuk: map['tahun_masuk'] as int,
        tanggalDaftar: map['tanggal_daftar'] as String?,
      );
}
