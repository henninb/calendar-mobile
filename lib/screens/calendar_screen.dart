import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../database/app_database.dart';
import '../providers/providers.dart';
import '../widgets/status_badge.dart';
import '../widgets/category_badge.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _format = CalendarFormat.month;

  // Fix: static to avoid allocating a new DateFormat on every eventsForDay call.
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final occurrencesAsync = ref.watch(occurrencesProvider);
    final categoriesAsync  = ref.watch(categoriesProvider);
    // Fix: resolve events once at the screen level so _OccurrenceCard can do a
    // direct map lookup instead of issuing a DB query per card (N+1 fix).
    final eventsAsync      = ref.watch(eventsProvider);

    return occurrencesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (occurrences) {
        final categories = categoriesAsync.value ?? [];
        final catMap = {for (final c in categories) c.serverId: c};
        final dbEvents = eventsAsync.value ?? [];
        final eventMap = {for (final e in dbEvents) e.serverId: e};

        // Build date-string → occurrences map for the calendar.
        final Map<String, List<Occurrence>> occsByDate = {};
        for (final o in occurrences) {
          // Fix: use the enum constant instead of the magic number 3.
          if (o.syncStatus == SyncStatus.pendingDelete.value) continue;
          final key = o.occurrenceDate.substring(0, 10);
          occsByDate.putIfAbsent(key, () => []).add(o);
        }

        List<Occurrence> eventsForDay(DateTime day) {
          return occsByDate[_dateFormat.format(day)] ?? [];
        }

        final selected = _selectedDay;
        final selectedOccs = selected != null ? eventsForDay(selected) : <Occurrence>[];

        return Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: _buildCalendar(occsByDate, eventsForDay),
            ),
            const Divider(),
            Expanded(
              child: selectedOccs.isEmpty
                  ? const Center(
                      child: Text('No events', style: AppText.small),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: selectedOccs.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final occ = selectedOccs[i];
                        return _OccurrenceCard(
                          occurrence: occ,
                          eventMap: eventMap,
                          catMap: catMap,
                          onStatusChange: (newStatus) => _updateStatus(occ, newStatus),
                          onDelete: () => _deleteOccurrence(occ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendar(
    Map<String, List<Occurrence>> occsByDate,
    List<Occurrence> Function(DateTime) eventsForDay,
  ) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: TableCalendar<Occurrence>(
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        focusedDay: _focusedDay,
        calendarFormat: _format,
        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
        eventLoader: eventsForDay,
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        onFormatChanged: (f) => setState(() => _format = f),
        onPageChanged: (focused) => _focusedDay = focused,
        calendarStyle: CalendarStyle(
          todayDecoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.primaryDeep,
            fontWeight: FontWeight.w700,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          markerDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          markerSize: 5,
          markersMaxCount: 3,
          outsideDaysVisible: false,
          defaultTextStyle: AppText.body,
          weekendTextStyle: AppText.body.copyWith(color: AppColors.textSecondary),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          titleTextStyle: AppText.heading.copyWith(fontSize: 14),
          formatButtonTextStyle: const TextStyle(fontSize: 12),
          formatButtonDecoration: BoxDecoration(
            color: AppColors.tableHeader,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.divider),
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
          rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          weekendStyle: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Fix: added mounted guard after each await so we don't touch ref/context on
  // a disposed widget (mirrors the same fix already present in occurrence_list_screen).
  Future<void> _updateStatus(Occurrence occ, String newStatus) async {
    await ref.read(dbProvider).updateOccurrenceStatus(occ.id, newStatus);
    if (!mounted) return;
    if (ref.read(isOnlineProvider)) {
      await ref.read(syncStateProvider.notifier).sync();
    }
  }

  Future<void> _deleteOccurrence(Occurrence occ) async {
    await ref.read(dbProvider).markOccurrenceDeleted(occ.id);
    if (!mounted) return;
    if (ref.read(isOnlineProvider)) {
      await ref.read(syncStateProvider.notifier).sync();
    }
  }
}

// Fix: changed from ConsumerWidget to StatelessWidget — the event is now
// resolved at the screen level and passed in, eliminating the per-card
// FutureBuilder + getAllEvents() DB call (N+1 fix).
class _OccurrenceCard extends StatelessWidget {
  const _OccurrenceCard({
    required this.occurrence,
    required this.eventMap,
    required this.catMap,
    required this.onStatusChange,
    required this.onDelete,
  });

  final Occurrence occurrence;
  final Map<int?, Event> eventMap;
  final Map<int?, Category> catMap;
  final void Function(String) onStatusChange;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final event = eventMap[occurrence.eventServerId];
    final cat = event != null ? catMap[event.categoryServerId] : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event?.title ?? 'Event #${occurrence.eventServerId}',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                StatusBadge(occurrence.status),
              ],
            ),
            if (cat != null) ...[
              const SizedBox(height: 6),
              CategoryBadge(name: cat.name, color: cat.color, icon: cat.icon),
            ],
            if (occurrence.notes != null && occurrence.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(occurrence.notes!, style: AppText.small),
            ],
            const SizedBox(height: 10),
            _ActionRow(status: occurrence.status, onStatusChange: onStatusChange, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.status, required this.onStatusChange, required this.onDelete});

  final String status;
  final void Function(String) onStatusChange;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (status != 'completed')
          _Btn(label: 'Done', color: AppColors.btnGreen, onTap: () => onStatusChange('completed')),
        if (status != 'skipped')
          _Btn(label: 'Skip', color: AppColors.btnGrayBg, textColor: AppColors.btnGrayFg, onTap: () => onStatusChange('skipped')),
        if (status == 'completed' || status == 'skipped')
          _Btn(label: 'Reopen', color: AppColors.btnBlue, onTap: () => onStatusChange('upcoming')),
        _Btn(
          label: 'Delete',
          color: AppColors.btnRed,
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete occurrence?'),
                content: const Text('This cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.btnRed),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            if (confirmed == true) onDelete();
          },
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.color, required this.onTap, this.textColor});

  final String label;
  final Color color;
  final VoidCallback onTap;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}
