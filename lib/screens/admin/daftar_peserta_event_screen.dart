import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../firebase/firebase_service.dart';
import '../../models/peserta_event_model.dart';

class DaftarPesertaEventScreen extends StatelessWidget {
  final String idEvent;
  final String namaEvent;

  const DaftarPesertaEventScreen({
    super.key,
    required this.idEvent,
    required this.namaEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Peserta: $namaEvent',
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<PesertaEventModel>>(
        stream: FirebaseService.instance.getPesertaByEventIdStream(idEvent),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan:\n${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            );
          }

          final peserta = snapshot.data ?? [];

          if (peserta.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    color: Colors.grey.withValues(alpha: 0.5),
                    size: 72,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada peserta yang mendaftar',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    namaEvent,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Counter header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: const Color(0xFF0D0D0D),
                child: Text(
                  '${peserta.length} peserta terdaftar',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: peserta.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _PesertaCard(peserta: peserta[i], index: i + 1),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PesertaCard extends StatelessWidget {
  final PesertaEventModel peserta;
  final int index;

  const _PesertaCard({required this.peserta, required this.index});

  @override
  Widget build(BuildContext context) {
    String? tanggalFormatted;
    if (peserta.tanggalDaftar != null) {
      try {
        final dt = DateTime.parse(peserta.tanggalDaftar!);
        tanggalFormatted = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
      } catch (_) {
        tanggalFormatted = peserta.tanggalDaftar;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nomor urut
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info peserta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peserta.nama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                _InfoRow(icon: Icons.badge_outlined, text: peserta.npm),
                const SizedBox(height: 2),
                _InfoRow(
                  icon: Icons.school_outlined,
                  text: peserta.jurusan,
                ),
                const SizedBox(height: 2),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: 'Angkatan ${peserta.tahunMasuk}',
                ),
                if (tanggalFormatted != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 11,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Daftar: $tanggalFormatted',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
