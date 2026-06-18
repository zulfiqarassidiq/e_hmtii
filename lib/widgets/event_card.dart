import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final int pesertaCount;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.pesertaCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final isOngoing = event.isOngoing;
    final isFull = pesertaCount >= event.kuota;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOngoing
                ? Colors.red.withValues(alpha: 0.4)
                : const Color(0xFF333333),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster / image area
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: _buildImage(),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Row(
                    children: [
                      _StatusBadge(isOngoing: isOngoing),
                      const Spacer(),
                      if (isFull)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.4)),
                          ),
                          child: const Text('Kuota Penuh',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Nama event
                  Text(
                    event.namaEvent,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Tanggal
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    text:
                        '${dateFormat.format(event.tanggalMulai)} – ${dateFormat.format(event.tanggalSelesai)}',
                  ),
                  const SizedBox(height: 6),

                  // Lokasi
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: event.lokasi,
                  ),
                  const SizedBox(height: 6),

                  // Peserta
                  _InfoRow(
                    icon: Icons.people_outline,
                    text: '$pesertaCount / ${event.kuota} peserta',
                    color: isFull ? Colors.red : Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (event.foto.isNotEmpty && event.foto.startsWith('http')) {
      return Image.network(
        event.foto,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        height: 160,
        width: double.infinity,
        color: const Color(0xFF111111),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event, color: Colors.red.withValues(alpha: 0.6), size: 48),
            const SizedBox(height: 8),
            Text(
              event.namaEvent,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  final bool isOngoing;
  const _StatusBadge({required this.isOngoing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOngoing
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOngoing
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOngoing ? Icons.circle : Icons.check_circle_outline,
            size: 8,
            color: isOngoing ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            isOngoing ? 'Berlangsung' : 'Selesai',
            style: TextStyle(
              color: isOngoing ? Colors.green : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
  final Color? color;

  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey;
    return Row(
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(color: c, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
