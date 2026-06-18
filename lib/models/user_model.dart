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

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        npm: map['npm'] as String,
        nama: map['nama'] as String,
        jurusan: map['jurusan'] as String,
        tahunMasuk: map['tahun_masuk'] as int,
        password: map['password'] as String,
      );

  Map<String, dynamic> toMap() => {
        'npm': npm,
        'nama': nama,
        'jurusan': jurusan,
        'tahun_masuk': tahunMasuk,
        'password': password,
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
