import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
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
  late EventModel _event;
  int _pesertaCount = 0;
  bool _isRegistered = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _loadData();
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    final count =
        await DatabaseHelper.instance.getPesertaCount(_event.idEvent);
    final registered = user != null
        ? await DatabaseHelper.instance
            .isUserRegistered(user.npm, _event.idEvent)
        : false;
    if (mounted) {
      setState(() {
        _pesertaCount = count;
        _isRegistered = registered;
      });
    }
  }

  Future<void> _showRegistrationDialog() async {
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
            _DetailRow(label: 'Event', value: _event.namaEvent),
            _DetailRow(label: 'Lokasi', value: _event.lokasi),
            _DetailRow(
              label: 'Tanggal',
              value: DateFormat('dd MMM yyyy').format(_event.tanggalMulai),
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
      await _registerEvent();
    }
  }

  Future<void> _registerEvent() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      // Cek kuota
      final currentCount =
          await DatabaseHelper.instance.getPesertaCount(_event.idEvent);
      if (currentCount >= _event.kuota) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Maaf, kuota event sudah penuh!'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

      // Cek sudah terdaftar
      final alreadyRegistered = await DatabaseHelper.instance
          .isUserRegistered(user.npm, _event.idEvent);
      if (alreadyRegistered) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Anda sudah terdaftar di event ini!'),
                backgroundColor: Colors.orange),
          );
        }
        return;
      }

      await DatabaseHelper.instance.insertPendaftaran(
        PendaftaranModel(npm: user.npm, idEvent: _event.idEvent),
      );

      if (mounted) {
        setState(() {
          _isRegistered = true;
          _pesertaCount = currentCount + 1;
          _isLoading = false;
        });
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

  Future<void> _cancelRegistration() async {
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
          .deletePendaftaran(user.npm, _event.idEvent);
      if (mounted) {
        setState(() {
          _isRegistered = false;
          _pesertaCount = (_pesertaCount - 1).clamp(0, _event.kuota);
          _isLoading = false;
        });
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
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy – HH:mm', 'id_ID');
    final isFull = _pesertaCount >= _event.kuota;
    final isOngoing = _event.isOngoing;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // SliverAppBar with poster
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
              background: _buildPoster(),
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
                        label: isOngoing ? 'Berlangsung' : 'Selesai',
                        color: isOngoing ? Colors.green : Colors.grey,
                      ),
                      if (isFull) ...[
                        const SizedBox(width: 8),
                        const _Badge(label: 'Kuota Penuh', color: Colors.red),
                      ],
                      if (_isRegistered) ...[
                        const SizedBox(width: 8),
                        const _Badge(
                            label: 'Terdaftar', color: Colors.blue),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Nama event
                  Text(_event.namaEvent,
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
                      value: dateFormat.format(_event.tanggalMulai),
                    ),
                    const Divider(color: Color(0xFF2A2A2A), height: 1),
                    _InfoItem(
                      icon: Icons.stop_rounded,
                      label: 'Selesai',
                      value: dateFormat.format(_event.tanggalSelesai),
                    ),
                    const Divider(color: Color(0xFF2A2A2A), height: 1),
                    _InfoItem(
                      icon: Icons.location_on_outlined,
                      label: 'Lokasi',
                      value: _event.lokasi,
                    ),
                  ]),
                  const SizedBox(height: 12),

                  _InfoCard(children: [
                    _InfoItem(
                      icon: Icons.people_outline,
                      label: 'Peserta',
                      value: '$_pesertaCount dari ${_event.kuota} kuota',
                      valueColor: isFull ? Colors.red : Colors.green,
                    ),
                  ]),

                  const SizedBox(height: 12),

                  // Progress bar kuota
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kapasitas',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                          Text(
                            '${((_pesertaCount / _event.kuota) * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                                color: isFull ? Colors.red : Colors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_pesertaCount / _event.kuota).clamp(0.0, 1.0),
                          backgroundColor: const Color(0xFF2A2A2A),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              isFull ? Colors.red : Colors.green),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),

                  // Deskripsi Event
                  if (_event.deskripsi.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.article_outlined,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              const Text(
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
                            _event.deskripsi,
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
                      child: _isRegistered
                          ? OutlinedButton.icon(
                              icon: const Icon(Icons.cancel_outlined,
                                  color: Colors.red),
                              label: const Text('Batalkan Pendaftaran',
                                  style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed:
                                  _isLoading ? null : _cancelRegistration,
                            )
                          : ElevatedButton.icon(
                              icon: _isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.how_to_reg),
                              label: const Text('Registrasi Event'),
                              onPressed: (isFull || _isLoading)
                                  ? null
                                  : _showRegistrationDialog,
                              style: ElevatedButton.styleFrom(
                                disabledBackgroundColor:
                                    Colors.grey.shade800,
                              ),
                            ),
                    ),
                    if (isFull && !_isRegistered)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text(
                            'Kuota event ini sudah penuh',
                            style:
                                TextStyle(color: Colors.red, fontSize: 13),
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
                        border: Border.all(color: const Color(0xFF333333)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy,
                              color: Colors.grey, size: 18),
                          SizedBox(width: 8),
                          Text('Event ini sudah selesai',
                              style: TextStyle(color: Colors.grey)),
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
  }

  Widget _buildPoster() {
    if (_event.foto.isNotEmpty && _event.foto.startsWith('http')) {
      return Image.network(
        _event.foto,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _posterPlaceholder(),
      );
    }
    return _posterPlaceholder();
  }

  Widget _posterPlaceholder() => Container(
        color: const Color(0xFF0D0D0D),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event, color: Colors.red, size: 64),
              const SizedBox(height: 8),
              Text(_event.namaEvent,
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
