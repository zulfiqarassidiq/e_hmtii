import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/event_card.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import 'event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EventModel> _allEvents = [];
  Map<String, int> _pesertaCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final events = await DatabaseHelper.instance.getAllEvents();
    final counts = <String, int>{};
    for (final e in events) {
      counts[e.idEvent] =
          await DatabaseHelper.instance.getPesertaCount(e.idEvent);
    }
    if (mounted) {
      setState(() {
        _allEvents = events;
        _pesertaCounts = counts;
        _isLoading = false;
      });
    }
  }

  List<EventModel> get _ongoingEvents =>
      _allEvents.where((e) => e.isOngoing).toList();

  List<EventModel> get _finishedEvents =>
      _allEvents.where((e) => !e.isOngoing).toList();

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Kampus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ).then((_) => _loadEvents()),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          labelColor: Colors.red,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_circle_outline, size: 16),
                  const SizedBox(width: 6),
                  Text('Berlangsung (${_ongoingEvents.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16),
                  const SizedBox(width: 6),
                  Text('Selesai (${_finishedEvents.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Greeting banner
          if (user != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: const Color(0xFF0D0D0D),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFF2A0000),
                    child: Icon(Icons.person, color: Colors.red, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Halo, ${user.nama.split(' ').first}!',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(user.jurusan,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.grey),
                    onPressed: _loadEvents,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),

          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Colors.red))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _EventList(
                        events: _ongoingEvents,
                        pesertaCounts: _pesertaCounts,
                        onTap: _openDetail,
                        emptyMessage: 'Belum ada event yang sedang berlangsung',
                      ),
                      _EventList(
                        events: _finishedEvents,
                        pesertaCounts: _pesertaCounts,
                        onTap: _openDetail,
                        emptyMessage: 'Belum ada event yang selesai',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _openDetail(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: event),
      ),
    ).then((_) => _loadEvents());
  }
}

class _EventList extends StatelessWidget {
  final List<EventModel> events;
  final Map<String, int> pesertaCounts;
  final void Function(EventModel) onTap;
  final String emptyMessage;

  const _EventList({
    required this.events,
    required this.pesertaCounts,
    required this.onTap,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy,
                color: Colors.grey.withValues(alpha: 0.4), size: 64),
            const SizedBox(height: 16),
            Text(emptyMessage,
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: Colors.red,
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (_, i) => EventCard(
          event: events[i],
          pesertaCount: pesertaCounts[events[i].idEvent] ?? 0,
          onTap: () => onTap(events[i]),
        ),
      ),
    );
  }
}
