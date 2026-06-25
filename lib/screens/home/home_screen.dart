import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../firebase/firebase_service.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/event_card.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import 'calendar_screen.dart';
import 'event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-HMTI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Kalender Event',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: FirebaseService.instance.getEventsStream(),
        builder: (context, snapshot) {
          final allEvents = snapshot.data ?? [];
          final ongoingEvents = allEvents.where((e) => e.isOngoing).toList();
          final finishedEvents = allEvents.where((e) => !e.isOngoing).toList();
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData;

          return Column(
            children: [
              // Greeting banner
              if (user != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  color: const Color(0xFF0D0D0D),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF2A0000),
                        child:
                            Icon(Icons.person, color: Colors.red, size: 22),
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
                    ],
                  ),
                ),

              // TabBar
              TabBar(
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
                        Text('Berlangsung (${ongoingEvents.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16),
                        const SizedBox(width: 6),
                        Text('Selesai (${finishedEvents.length})'),
                      ],
                    ),
                  ),
                ],
              ),

              // Tab content
              Expanded(
                child: isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Colors.red))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _EventList(
                            events: ongoingEvents,
                            onTap: _openDetail,
                            emptyMessage:
                                'Belum ada event yang sedang berlangsung',
                          ),
                          _EventList(
                            events: finishedEvents,
                            onTap: _openDetail,
                            emptyMessage: 'Belum ada event yang selesai',
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openDetail(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: event),
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  final List<EventModel> events;
  final void Function(EventModel) onTap;
  final String emptyMessage;

  const _EventList({
    required this.events,
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (_, i) {
        final event = events[i];
        return StreamBuilder<int>(
          stream: FirebaseService.instance.getPesertaCountStream(event.idEvent),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return EventCard(
              event: event,
              pesertaCount: count,
              onTap: () => onTap(event),
            );
          },
        );
      },
    );
  }
}
