import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/event_model.dart';
import 'daftar_peserta_event_screen.dart';

/// Layar reusable untuk menampilkan daftar event admin.
/// [onlyOngoing] = true → query hanya event yang sedang berlangsung.
class DaftarEventAdminScreen extends StatelessWidget {
  final String title;
  final bool onlyOngoing;

  const DaftarEventAdminScreen({
    super.key,
    required this.title,
    this.onlyOngoing = false,
  });

  Future<List<EventModel>> _loadEvents() => onlyOngoing
      ? DatabaseHelper.instance.getOngoingEvents()
      : DatabaseHelper.instance.getAllEvents();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<EventModel>>(
        future: _loadEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    onlyOngoing ? Icons.event_available : Icons.event_note,
                    color: Colors.grey.withValues(alpha: 0.4),
                    size: 72,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    onlyOngoing
                        ? 'Tidak ada event yang sedang berlangsung'
                        : 'Belum ada event yang tersedia',
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFF0D0D0D),
                child: Text(
                  '${events.length} event ditemukan',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  separatorBuilder: (context, i) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) => _EventAdminTile(event: events[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EventAdminTile extends StatelessWidget {
  final EventModel event;
  const _EventAdminTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final isOngoing = event.isOngoing;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DaftarPesertaEventScreen(
            idEvent: event.idEvent,
            namaEvent: event.namaEvent,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOngoing
                ? Colors.green.withValues(alpha: 0.3)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isOngoing
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isOngoing ? Icons.play_circle_outline : Icons.event_busy,
                color: isOngoing ? Colors.green : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.namaEvent,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOngoing
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          isOngoing ? 'Aktif' : 'Selesai',
                          style: TextStyle(
                            color: isOngoing ? Colors.green : Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 11, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${dateFormat.format(event.tanggalMulai)} – ${dateFormat.format(event.tanggalSelesai)}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.lokasi,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron (hint klik ke peserta)
            Icon(Icons.chevron_right,
                color: Colors.grey.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    );
  }
}
