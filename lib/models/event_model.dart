class EventModel {
  final String idEvent;
  final String namaEvent;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final int kuota;
  final String lokasi;
  final String foto;
  final String deskripsi;

  EventModel({
    required this.idEvent,
    required this.namaEvent,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.kuota,
    required this.lokasi,
    required this.foto,
    this.deskripsi = '',
  });

  /// True jika saat ini sedang berlangsung (sudah mulai & belum selesai).
  bool get isOngoing => DateTime.now().isBefore(tanggalSelesai);

  /// True jika benar-benar berjalan: mulai <= now <= selesai.
  bool get isReallyOngoing {
    final now = DateTime.now();
    return now.isAfter(tanggalMulai) && now.isBefore(tanggalSelesai);
  }

  factory EventModel.fromMap(Map<String, dynamic> map) => EventModel(
        idEvent: map['id_event'] as String,
        namaEvent: map['nama_event'] as String,
        tanggalMulai: DateTime.parse(map['tanggal_mulai'] as String),
        tanggalSelesai: DateTime.parse(map['tanggal_selesai'] as String),
        kuota: map['kuota'] as int,
        lokasi: map['lokasi'] as String,
        foto: (map['foto'] as String?) ?? '',
        deskripsi: (map['deskripsi'] as String?) ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id_event': idEvent,
        'nama_event': namaEvent,
        'tanggal_mulai': tanggalMulai.toIso8601String(),
        'tanggal_selesai': tanggalSelesai.toIso8601String(),
        'kuota': kuota,
        'lokasi': lokasi,
        'foto': foto,
        'deskripsi': deskripsi,
      };

  EventModel copyWith({
    String? idEvent,
    String? namaEvent,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
    int? kuota,
    String? lokasi,
    String? foto,
    String? deskripsi,
  }) =>
      EventModel(
        idEvent: idEvent ?? this.idEvent,
        namaEvent: namaEvent ?? this.namaEvent,
        tanggalMulai: tanggalMulai ?? this.tanggalMulai,
        tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
        kuota: kuota ?? this.kuota,
        lokasi: lokasi ?? this.lokasi,
        foto: foto ?? this.foto,
        deskripsi: deskripsi ?? this.deskripsi,
      );
}
