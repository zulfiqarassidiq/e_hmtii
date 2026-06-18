import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'daftar_user_screen.dart';
import 'daftar_peserta_event_screen.dart';
import 'daftar_event_admin_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  List<EventModel> _events = [];
  Map<String, int> _pesertaCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final events = await DatabaseHelper.instance.getAllEvents();
    final counts = <String, int>{};
    for (final e in events) {
      counts[e.idEvent] =
          await DatabaseHelper.instance.getPesertaCount(e.idEvent);
    }
    if (mounted) {
      setState(() {
        _events = events;
        _pesertaCounts = counts;
        _isLoading = false;
      });
    }
  }

  void _logout() {
    context.read<AuthProvider>().logoutAdmin();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showAddEventDialog() => _showEventDialog(null);

  // ─── Helper: pilih tanggal DAN jam sekaligus ─────────────────────────────────

  Future<DateTime?> _pickDateTime(
    BuildContext ctx,
    DateTime initial,
  ) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (c, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Colors.red)),
        child: child!,
      ),
    );
    if (date == null) return null;

    if (!ctx.mounted) return null;
    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
      builder: (c, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Colors.red)),
        child: child!,
      ),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // ─── Dialog tambah / edit event ──────────────────────────────────────────────

  void _showEventDialog(EventModel? existing) {
    final idCtrl = TextEditingController(text: existing?.idEvent ?? '');
    final namaCtrl = TextEditingController(text: existing?.namaEvent ?? '');
    final lokasiCtrl = TextEditingController(text: existing?.lokasi ?? '');
    final kuotaCtrl =
        TextEditingController(text: existing?.kuota.toString() ?? '');
    final fotoCtrl = TextEditingController(text: existing?.foto ?? '');
    final deskripsiCtrl =
        TextEditingController(text: existing?.deskripsi ?? '');

    DateTime mulai =
        existing?.tanggalMulai ?? DateTime.now().add(const Duration(days: 1));
    DateTime selesai = existing?.tanggalSelesai ??
        DateTime.now().add(const Duration(days: 2));

    final formKey = GlobalKey<FormState>();
    final dateFormat = DateFormat('dd MMM yyyy  HH:mm');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            existing == null ? 'Tambah Event' : 'Edit Event',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(idCtrl, 'ID Event',
                      enabled: existing == null),
                  _dialogField(namaCtrl, 'Nama Event'),
                  _dialogField(lokasiCtrl, 'Lokasi'),
                  _dialogField(kuotaCtrl, 'Kuota',
                      keyboard: TextInputType.number),
                  _dialogField(fotoCtrl, 'URL Foto (opsional)',
                      required: false),
                  _dialogField(deskripsiCtrl, 'Deskripsi Event',
                      required: false, maxLines: 3),
                  const SizedBox(height: 12),

                  // Date + Time picker — Mulai
                  _DateTimePickerRow(
                    label: 'Mulai',
                    value: dateFormat.format(mulai),
                    onTap: () async {
                      final result = await _pickDateTime(ctx, mulai);
                      if (result != null) {
                        setDialogState(() => mulai = result);
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  // Date + Time picker — Selesai
                  _DateTimePickerRow(
                    label: 'Selesai',
                    value: dateFormat.format(selesai),
                    onTap: () async {
                      final result = await _pickDateTime(ctx, selesai);
                      if (result != null) {
                        setDialogState(() => selesai = result);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final event = EventModel(
                  idEvent: idCtrl.text.trim(),
                  namaEvent: namaCtrl.text.trim(),
                  tanggalMulai: mulai,
                  tanggalSelesai: selesai,
                  kuota: int.tryParse(kuotaCtrl.text.trim()) ?? 0,
                  lokasi: lokasiCtrl.text.trim(),
                  foto: fotoCtrl.text.trim(),
                  deskripsi: deskripsiCtrl.text.trim(),
                );
                if (existing == null) {
                  await DatabaseHelper.instance.insertEvent(event);
                } else {
                  await DatabaseHelper.instance.updateEvent(event);
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadData();
              },
              child: Text(existing == null ? 'Tambah' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(EventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Event?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${event.namaEvent}"? Semua data pendaftaran juga akan dihapus.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteEvent(event.idEvent);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthProvider>().currentAdmin;
    final totalPeserta =
        _pesertaCounts.values.fold(0, (sum, c) => sum + c);
    final ongoingCount = _events.where((e) => e.isOngoing).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventDialog,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Event'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : RefreshIndicator(
              color: Colors.red,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Admin info bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFF0D0D0D),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.admin_panel_settings,
                                color: Colors.red),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Administrator',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              Text(admin?.idAdmin ?? '-',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Stats row
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _StatCard(
                            label: 'Total Event',
                            value: '${_events.length}',
                            icon: Icons.event,
                            color: Colors.blue,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DaftarEventAdminScreen(
                                  title: 'Semua Event',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: 'Berlangsung',
                            value: '$ongoingCount',
                            icon: Icons.play_circle_outline,
                            color: Colors.green,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DaftarEventAdminScreen(
                                  title: 'Event Berlangsung',
                                  onlyOngoing: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: 'Total Peserta',
                            value: '$totalPeserta',
                            icon: Icons.people_outline,
                            color: Colors.orange,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DaftarUserScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Daftar Event',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_events.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text('Belum ada event',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _events.length,
                        itemBuilder: (_, i) {
                          final event = _events[i];
                          final count = _pesertaCounts[event.idEvent] ?? 0;
                          return _AdminEventCard(
                            event: event,
                            pesertaCount: count,
                            onEdit: () => _showEventDialog(event),
                            onDelete: () => _deleteEvent(event),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DaftarPesertaEventScreen(
                                  idEvent: event.idEvent,
                                  namaEvent: event.namaEvent,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboard = TextInputType.text,
    bool enabled = true,
    bool required = true,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: ctrl,
          enabled: enabled,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(labelText: label),
          validator: required
              ? (v) =>
                  (v == null || v.isEmpty) ? '$label wajib diisi' : null
              : null,
        ),
      );
}

// ─── _StatCard ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: onTap != null
                    ? color.withValues(alpha: 0.35)
                    : const Color(0xFF2A2A2A),
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(label,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11),
                    textAlign: TextAlign.center),
                if (onTap != null) ...[
                  const SizedBox(height: 4),
                  Icon(Icons.arrow_forward_ios,
                      size: 9, color: color.withValues(alpha: 0.6)),
                ],
              ],
            ),
          ),
        ),
      );
}

// ─── _AdminEventCard ──────────────────────────────────────────────────────────

class _AdminEventCard extends StatelessWidget {
  final EventModel event;
  final int pesertaCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const _AdminEventCard({
    required this.event,
    required this.pesertaCount,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isOngoing = event.isOngoing;
    final isFull = pesertaCount >= event.kuota;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
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
                Expanded(
                  child: Text(event.namaEvent,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOngoing
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isOngoing ? 'Aktif' : 'Selesai',
                    style: TextStyle(
                        color: isOngoing ? Colors.green : Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${dateFormat.format(event.tanggalMulai)} – ${dateFormat.format(event.tanggalSelesai)}',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(event.lokasi,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '$pesertaCount / ${event.kuota}',
                  style: TextStyle(
                      color: isFull ? Colors.red : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.blue, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Hapus',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _DateTimePickerRow ───────────────────────────────────────────────────────

class _DateTimePickerRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTimePickerRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_calendar_outlined,
                  color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11)),
                    Text(value,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.access_time_outlined,
                  color: Colors.grey, size: 14),
            ],
          ),
        ),
      );
}
