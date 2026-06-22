import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../home/event_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<EventModel> _registeredEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegisteredEvents();
  }

  Future<void> _loadRegisteredEvents() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);

    try {
      final pendaftaranList =
          await DatabaseHelper.instance.getPendaftaranByNpm(user.npm);
      final events = <EventModel>[];
      for (final p in pendaftaranList) {
        final event = await DatabaseHelper.instance.getEventById(p.idEvent);
        if (event != null) events.add(event);
      }
      if (mounted) setState(() => _registeredEvents = events);
    } catch (_) {
      // Gagal fetch — tampilkan kosong, tidak crash
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() {
    context.read<AuthProvider>().logoutUser();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) {
      return const Scaffold(
          body: Center(child: Text('Tidak ada data pengguna')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.red,
        onRefresh: _loadRegisteredEvents,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Profile header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D0D0D),
                  border: Border(
                      bottom: BorderSide(color: Color(0xFF1A1A1A))),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2A0000),
                        border: Border.all(color: Colors.red, width: 2.5),
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.red, size: 50),
                    ),
                    const SizedBox(height: 14),
                    Text(user.nama,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Builder(builder: (_) {
                      final selisihTahun =
                          DateTime.now().year - user.tahunMasuk;
                      final isAktif = selisihTahun <= 7;
                      final badgeLabel =
                          isAktif ? 'Mahasiswa Aktif' : 'Alumni';
                      final badgeColor =
                          isAktif ? Colors.green : Colors.grey;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: badgeColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(badgeLabel,
                            style: TextStyle(
                                color: badgeColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      );
                    }),
                  ],
                ),
              ),

              // Info cards
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Akademik',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    _InfoCard(children: [
                      _InfoTile(
                        icon: Icons.badge_outlined,
                        label: 'NPM',
                        value: user.npm,
                      ),
                      _InfoTile(
                        icon: Icons.person_outline,
                        label: 'Nama Lengkap',
                        value: user.nama,
                      ),
                      _InfoTile(
                        icon: Icons.school_outlined,
                        label: 'Jurusan',
                        value: user.jurusan,
                      ),
                      _InfoTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Tahun Masuk',
                        value: '${user.tahunMasuk}',
                        isLast: true,
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Registered events section
                    Row(
                      children: [
                        const Text('Event Terdaftar',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_registeredEvents.length} event',
                            style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_isLoading)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: Colors.red),
                      ))
                    else if (_registeredEvents.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.event_note,
                                  color: Colors.grey.withValues(alpha: 0.4),
                                  size: 48),
                              const SizedBox(height: 8),
                              const Text(
                                  'Belum ada event yang diikuti',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _registeredEvents.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final e = _registeredEvents[i];
                          return _RegisteredEventTile(
                            event: e,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      EventDetailScreen(event: e)),
                            ).then((_) => _loadRegisteredEvents()),
                          );
                        },
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: Colors.red, size: 20),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
                height: 1, color: Color(0xFF2A2A2A), indent: 50),
        ],
      );
}

class _RegisteredEventTile extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _RegisteredEventTile(
      {required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOngoing = event.isOngoing;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
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
                isOngoing ? Icons.event_available : Icons.event_busy,
                color: isOngoing ? Colors.green : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.namaEvent,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(event.lokasi,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
