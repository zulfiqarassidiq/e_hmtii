import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../firebase/firebase_service.dart';
import '../../models/event_model.dart';
import '../../models/pendaftaran_model.dart';
import '../../providers/auth_provider.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isLoading = false;

  Future<void> _showRegistrationDialog(EventModel event) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Pendaftaran',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Data pendaftar:',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            _DetailRow(label: 'NPM', value: user.npm),
            _DetailRow(label: 'Nama', value: user.nama),
            _DetailRow(label: 'Jurusan', value: user.jurusan),
            const Divider(color: Color(0xFF333333), height: 24),
            _DetailRow(label: 'Event', value: event.namaEvent),
            _DetailRow(label: 'Lokasi', value: event.lokasi),
            _DetailRow(
              label: 'Tanggal',
              value: DateFormat('dd MMM yyyy').format(event.tanggalMulai),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Daftar Sekarang'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _registerEvent(event);
    }
  }

  Future<void> _registerEvent(EventModel event) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await DatabaseHelper.instance.insertPendaftaran(
        PendaftaranModel(npm: user.npm, idEvent: event.idEvent),
      );
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil mendaftar event!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mendaftar: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelRegistration(EventModel event) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pendaftaran?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Apakah Anda yakin ingin membatalkan pendaftaran event ini?',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      await DatabaseHelper.instance
          .deletePendaftaran(user.npm, event.idEvent);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pendaftaran berhasil dibatalkan'),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return StreamBuilder<EventModel?>(
      stream: FirebaseService.instance.getEventStream(widget.event.idEvent),
      builder: (context, eventSnap) {
        final event = eventSnap.data ?? widget.event;

        return StreamBuilder<int>(
          stream: FirebaseService.instance
              .getPesertaCountStream(event.idEvent),
          builder: (context, countSnap) {
            final pesertaCount = countSnap.data ?? 0;

            return StreamBuilder<bool>(
              stream: user != null
                  ? FirebaseService.instance
                      .isUserRegisteredStream(user.npm, event.idEvent)
                  : Stream.value(false),
              builder: (context, regSnap) {
                final isRegistered = regSnap.data ?? false;
                final isFull = pesertaCount >= event.kuota;
                final isOngoing = event.isOngoing;
                final dateFormat =
                    DateFormat('EEEE, dd MMMM yyyy – HH:mm', 'id_ID');

                return Scaffold(
                  body: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 220,
                        pinned: true,
                        backgroundColor: Colors.black,
                        leading: IconButton(
                          icon: const CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 18),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          background: _buildPoster(event),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status badges
                              Row(
                                children: [
                                  _Badge(
                                    label: isOngoing
                                        ? 'Berlangsung'
                                        : 'Selesai',
                                    color: isOngoing
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  if (isFull) ...[
                                    const SizedBox(width: 8),
                                    const _Badge(
                                        label: 'Kuota Penuh',
                                        color: Colors.red),
                                  ],
                                  if (isRegistered) ...[
                                    const SizedBox(width: 8),
                                    const _Badge(
                                        label: 'Terdaftar',
                                        color: Colors.blue),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Nama event
                              Text(event.namaEvent,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),

                              // Info cards
                              _InfoCard(children: [
                                _InfoItem(
                                  icon: Icons.play_arrow_rounded,
                                  label: 'Mulai',
                                  value: dateFormat
                                      .format(event.tanggalMulai),
                                ),
                                const Divider(
                                    color: Color(0xFF2A2A2A), height: 1),
                                _InfoItem(
                                  icon: Icons.stop_rounded,
                                  label: 'Selesai',
                                  value: dateFormat
                                      .format(event.tanggalSelesai),
                                ),
                                const Divider(
                                    color: Color(0xFF2A2A2A), height: 1),
                                _InfoItem(
                                  icon: Icons.location_on_outlined,
                                  label: 'Lokasi',
                                  value: event.lokasi,
                                ),
                              ]),
                              const SizedBox(height: 12),

                              _InfoCard(children: [
                                _InfoItem(
                                  icon: Icons.people_outline,
                                  label: 'Peserta',
                                  value:
                                      '$pesertaCount dari ${event.kuota} kuota',
                                  valueColor:
                                      isFull ? Colors.red : Colors.green,
                                ),
                              ]),

                              const SizedBox(height: 12),

                              // Progress bar kuota
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Kapasitas',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13)),
                                      Text(
                                        '${((pesertaCount / event.kuota) * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                            color: isFull
                                                ? Colors.red
                                                : Colors.green,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (pesertaCount / event.kuota)
                                          .clamp(0.0, 1.0),
                                      backgroundColor:
                                          const Color(0xFF2A2A2A),
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              isFull
                                                  ? Colors.red
                                                  : Colors.green),
                                      minHeight: 8,
                                    ),
                                  ),
                                ],
                              ),

                              // Deskripsi Event
                              if (event.deskripsi.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                        color: const Color(0xFF2A2A2A)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.article_outlined,
                                              color: Colors.red, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'Deskripsi Event',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        event.deskripsi,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 32),

                              // Register / Cancel button
                              if (isOngoing) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: isRegistered
                                      ? OutlinedButton.icon(
                                          icon: const Icon(
                                              Icons.cancel_outlined,
                                              color: Colors.red),
                                          label: const Text(
                                              'Batalkan Pendaftaran',
                                              style: TextStyle(
                                                  color: Colors.red)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                                color: Colors.red),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12)),
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 14),
                                          ),
                                          onPressed: _isLoading
                                              ? null
                                              : () =>
                                                  _cancelRegistration(event),
                                        )
                                      : ElevatedButton.icon(
                                          icon: _isLoading
                                              ? const SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2))
                                              : const Icon(
                                                  Icons.how_to_reg),
                                          label: const Text(
                                              'Registrasi Event'),
                                          onPressed: (isFull || _isLoading)
                                              ? null
                                              : () => _showRegistrationDialog(
                                                  event),
                                          style: ElevatedButton.styleFrom(
                                            disabledBackgroundColor:
                                                Colors.grey.shade800,
                                          ),
                                        ),
                                ),
                                if (isFull && !isRegistered)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Center(
                                      child: Text(
                                        'Kuota event ini sudah penuh',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 13),
                                      ),
                                    ),
                                  ),
                              ] else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFF333333)),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.event_busy,
                                          color: Colors.grey, size: 18),
                                      SizedBox(width: 8),
                                      Text('Event ini sudah selesai',
                                          style: TextStyle(
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPoster(EventModel event) {
    if (event.foto.isNotEmpty && event.foto.startsWith('http')) {
      return Image.network(
        event.foto,
        fit: BoxFit.cover,
        errorBuilder: (context2, e, s) => _posterPlaceholder(event),
      );
    }
    return _posterPlaceholder(event);
  }

  Widget _posterPlaceholder(EventModel event) => Container(
        color: const Color(0xFF0D0D0D),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event, color: Colors.red, size: 64),
              const SizedBox(height: 8),
              Text(event.namaEvent,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(children: children),
      );
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          color: valueColor ?? Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            const Text(': ',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      );
}
