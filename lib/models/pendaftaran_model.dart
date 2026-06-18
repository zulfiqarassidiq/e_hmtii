class PendaftaranModel {
  final int? idPendaftaran;
  final String npm;
  final String idEvent;

  PendaftaranModel({
    this.idPendaftaran,
    required this.npm,
    required this.idEvent,
  });

  factory PendaftaranModel.fromMap(Map<String, dynamic> map) => PendaftaranModel(
        idPendaftaran: map['id_pendaftaran'] as int?,
        npm: map['npm'] as String,
        idEvent: map['id_event'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (idPendaftaran != null) 'id_pendaftaran': idPendaftaran,
        'npm': npm,
        'id_event': idEvent,
      };
}
