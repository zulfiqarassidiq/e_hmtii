import 'package:cloud_firestore/cloud_firestore.dart';

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

  bool get isOngoing => DateTime.now().isBefore(tanggalSelesai);

  bool get isReallyOngoing {
    final now = DateTime.now();
    return now.isAfter(tanggalMulai) && now.isBefore(tanggalSelesai);
  }

  // ── Firestore ──────────────────────────────────────────────────────────────

  factory EventModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return EventModel(
      idEvent: doc.id,
      namaEvent: d['nama_event'] as String,
      tanggalMulai: (d['tanggal_mulai'] as Timestamp).toDate(),
      tanggalSelesai: (d['tanggal_selesai'] as Timestamp).toDate(),
      kuota: d['kuota'] as int,
      lokasi: d['lokasi'] as String,
      foto: (d['foto'] as String?) ?? '',
      deskripsi: (d['deskripsi'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nama_event': namaEvent,
        'tanggal_mulai': Timestamp.fromDate(tanggalMulai),
        'tanggal_selesai': Timestamp.fromDate(tanggalSelesai),
        'kuota': kuota,
        'lokasi': lokasi,
        'foto': foto,
        'deskripsi': deskripsi,
        // peserta_count dikelola via FieldValue.increment di firebase_service
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
