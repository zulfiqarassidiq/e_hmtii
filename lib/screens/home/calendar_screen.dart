import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../firebase/firebase_service.dart';
import '../../models/event_model.dart';
import 'event_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  /// Bulan yang sedang ditampilkan (selalu hari ke-1).
  late DateTime _focusedMonth;

  /// Tanggal yang sedang dipilih user (null = belum ada pilihan).
  int? _selectedDay;

  static const _weekLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
  }

  // ─── Kalkulasi kalender ───────────────────────────────────────────────────────

  int get _daysInMonth =>
      DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

  int get _leadingBlanks =>
      DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1;

  int get _totalCells {
    final filled = _leadingBlanks + _daysInMonth;
    final remainder = filled % 7;
    return remainder == 0 ? filled : filled + (7 - remainder);
  }

  // ─── Logika event (menerima list dari StreamBuilder) ──────────────────────────

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _hasEvent(int day, List<EventModel> events) {
    final target = _dateOnly(
      DateTime(_focusedMonth.year, _focusedMonth.month, day),
    );
    return events.any((e) {
      final start = _dateOnly(e.tanggalMulai);
      final end = _dateOnly(e.tanggalSelesai);
      return !target.isBefore(start) && !target.isAfter(end);
    });
  }

  List<EventModel> _filteredEvents(List<EventModel> events) {
    if (_selectedDay == null) {
      return events.where((e) {
        final start = _dateOnly(e.tanggalMulai);
        final end = _dateOnly(e.tanggalSelesai);
        final monthStart = _focusedMonth;
        final monthEnd =
            DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
        return !end.isBefore(monthStart) && !start.isAfter(monthEnd);
      }).toList();
    }
    final target = _dateOnly(
      DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay!),
    );
    return events.where((e) {
      final start = _dateOnly(e.tanggalMulai);
      final end = _dateOnly(e.tanggalSelesai);
      return !target.isBefore(start) && !target.isAfter(end);
    }).toList();
  }

  // ─── Navigasi bulan ───────────────────────────────────────────────────────────

  void _prevMonth() => setState(() {
        _focusedMonth =
            DateTime(_focusedMonth.year, _focusedMonth.month - 1);
        _selectedDay = null;
      });

  void _nextMonth() => setState(() {
        _focusedMonth =
            DateTime(_focusedMonth.year, _focusedMonth.month + 1);
        _selectedDay = null;
      });

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _focusedMonth.year == now.year &&
        _focusedMonth.month == now.month;
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Kalender Event'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_outlined, color: Colors.red),
            tooltip: 'Kembali ke bulan ini',
            onPressed: _isCurrentMonth
                ? null
                : () => setState(() {
                      final now = DateTime.now();
                      _focusedMonth = DateTime(now.year, now.month);
                      _selectedDay = null;
                    }),
          ),
        ],
      ),

      // ── StreamBuilder: mendengarkan koleksi 'events' secara real-time ─────────
      body: StreamBuilder<List<EventModel>>(
        stream: FirebaseService.instance.getEventsStream(),
        builder: (context, snap) {
          // Loading awal — belum ada data dari Firestore
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.red));
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          // Data sudah tersedia — render kalender
          final events = snap.data ?? [];
          final filtered = _filteredEvents(events);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildCalendar(events)),
              SliverToBoxAdapter(child: _buildEventListHeader(filtered)),
              filtered.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _EventTile(
                          event: filtered[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EventDetailScreen(event: filtered[i]),
                            ),
                          ),
                        ),
                        childCount: filtered.length,
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  // ─── Bagian UI: header bulan + grid ──────────────────────────────────────────

  Widget _buildCalendar(List<EventModel> events) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          _buildMonthHeader(),
          const SizedBox(height: 12),
          _buildWeekdayLabels(),
          const SizedBox(height: 4),
          _buildDayGrid(events),
          const SizedBox(height: 8),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    final label = DateFormat('MMMM yyyy', 'id_ID').format(_focusedMonth);
    return Row(
      children: [
        _NavButton(icon: Icons.chevron_left, onTap: _prevMonth),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _NavButton(icon: Icons.chevron_right, onTap: _nextMonth),
      ],
    );
  }

  Widget _buildWeekdayLabels() {
    return Row(
      children: _weekLabels
          .map((label) => Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: (label == 'Min') ? Colors.red.shade300 : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDayGrid(List<EventModel> events) {
    final now = DateTime.now();
    final todayDay = _isCurrentMonth ? now.day : -1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 0,
        childAspectRatio: 0.85,
      ),
      itemCount: _totalCells,
      itemBuilder: (_, i) {
        final day = i - _leadingBlanks + 1;
        if (day < 1 || day > _daysInMonth) return const SizedBox.shrink();

        final isSelected = _selectedDay == day;
        // hasEvent kini dihitung dari data real-time stream
        final hasEvent = _hasEvent(day, events);
        final isToday = todayDay == day;
        final isSunday = (i % 7) == 6;

        return GestureDetector(
          onTap: () => setState(
            () => _selectedDay = (_selectedDay == day) ? null : day,
          ),
          child: _DayCell(
            day: day,
            isSelected: isSelected,
            hasEvent: hasEvent,
            isToday: isToday,
            isSunday: isSunday,
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendDot(color: Colors.red, label: 'Ada event'),
          const SizedBox(width: 16),
          _LegendDot(
              color: Colors.red.shade900, label: 'Dipilih & ada event'),
          const SizedBox(width: 16),
          _LegendDot(
              color: Colors.red.withValues(alpha: 0.25), label: 'Hari ini'),
        ],
      ),
    );
  }

  // ─── Bagian UI: header daftar event ──────────────────────────────────────────

  Widget _buildEventListHeader(List<EventModel> filtered) {
    final String label;
    if (_selectedDay == null) {
      label =
          'Event Bulan ${DateFormat('MMMM', 'id_ID').format(_focusedMonth)}';
    } else {
      label =
          'Event $_selectedDay ${DateFormat('MMMM yyyy', 'id_ID').format(_focusedMonth)}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.event_note, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${filtered.length}',
              style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
          if (_selectedDay != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _selectedDay = null),
              child: const Icon(Icons.close, color: Colors.grey, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy,
                color: Colors.grey.withValues(alpha: 0.35), size: 72),
            const SizedBox(height: 16),
            Text(
              _selectedDay == null
                  ? 'Tidak ada event di bulan ini'
                  : 'Tidak ada event pada tanggal ini',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (_selectedDay != null) ...[
              const SizedBox(height: 8),
              Text(
                'Coba pilih tanggal lain atau ketuk × untuk reset',
                style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.6), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── _DayCell ─────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool hasEvent;
  final bool isToday;
  final bool isSunday;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.hasEvent,
    required this.isToday,
    required this.isSunday,
  });

  @override
  Widget build(BuildContext context) {
    Color? circleBg;
    Color textColor;
    Border? circleBorder;

    if (isSelected && hasEvent) {
      circleBg = Colors.red.shade700;
      textColor = Colors.white;
    } else if (isSelected && !hasEvent) {
      circleBg = Colors.transparent;
      circleBorder = Border.all(color: Colors.grey.shade600, width: 1.5);
      textColor = Colors.white;
    } else if (isToday) {
      circleBg = Colors.red.withValues(alpha: 0.20);
      textColor = Colors.red.shade300;
    } else {
      circleBg = null;
      textColor = isSunday ? Colors.red.shade300 : Colors.white70;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleBg,
            border: circleBorder,
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight:
                  (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(height: 2),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: hasEvent ? 1.0 : 0.0,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.transparent : Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── _NavButton ───────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
      );
}

// ─── _LegendDot ───────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      );
}

// ─── _EventTile ───────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _EventTile({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final isOngoing = event.isReallyOngoing;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isOngoing
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
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
                  Text(
                    event.namaEvent,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 11, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${dateFormat.format(event.tanggalMulai)} – '
                        '${dateFormat.format(event.tanggalSelesai)}',
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
            Icon(Icons.chevron_right,
                color: Colors.grey.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
