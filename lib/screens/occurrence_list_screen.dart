import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../database/app_database.dart';
import '../providers/providers.dart';
import '../widgets/status_badge.dart';
import '../widgets/category_badge.dart';

class OccurrenceListScreen extends ConsumerStatefulWidget {
  const OccurrenceListScreen({super.key});

  @override
  ConsumerState<OccurrenceListScreen> createState() => _OccurrenceListScreenState();
}

class _OccurrenceListScreenState extends ConsumerState<OccurrenceListScreen> {
  String _filterStatus = 'all';
  int? _filterCategoryId;

  static const _statusOptions = ['all', 'upcoming', 'overdue', 'completed', 'skipped'];

  @override
  Widget build(BuildContext context) {
    final occurrencesAsync = ref.watch(occurrencesProvider);
    final categoriesAsync  = ref.watch(categoriesProvider);
    // Fix #7: fetch events once at the screen level, keyed by serverId.
    final eventsAsync      = ref.watch(eventsProvider);

    return occurrencesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (occurrences) {
        final categories = categoriesAsync.value ?? [];
        final catMap = {for (final c in categories) c.serverId: c};
        final events = eventsAsync.value ?? [];
        final eventMap = {for (final e in events) e.serverId: e};

        // Apply filters (exclude pending-delete rows)
        var filtered = occurrences
            .where((o) => o.syncStatus != SyncStatus.pendingDelete.value)
            .toList();
        if (_filterStatus != 'all') {
          filtered = filtered.where((o) => o.status == _filterStatus).toList();
        }

        // Sort: overdue first, then by date
        filtered.sort((a, b) {
          final statusOrder = {'overdue': 0, 'upcoming': 1, 'skipped': 2, 'completed': 3};
          final sa = statusOrder[a.status] ?? 4;
          final sb = statusOrder[b.status] ?? 4;
          if (sa != sb) return sa.compareTo(sb);
          return a.occurrenceDate.compareTo(b.occurrenceDate);
        });

        return Column(
          children: [
            _Toolbar(
              filterStatus: _filterStatus,
              statusOptions: _statusOptions,
              categories: categories,
              filterCategoryId: _filterCategoryId,
              onStatusChanged: (v) => setState(() => _filterStatus = v),
              onCategoryChanged: (v) => setState(() => _filterCategoryId = v),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No occurrences', style: AppText.small))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      separatorBuilder: (c, i) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final occ = filtered[i];
                        return _OccurrenceRow(
                          occurrence: occ,
                          event: eventMap[occ.eventServerId],
                          catMap: catMap,
                          onStatusChange: (s) => _updateStatus(occ, s),
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

  // Fix #6: guard against widget disposal after each await.
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

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.filterStatus,
    required this.statusOptions,
    required this.categories,
    required this.filterCategoryId,
    required this.onStatusChanged,
    required this.onCategoryChanged,
  });

  final String filterStatus;
  final List<String> statusOptions;
  final List<Category> categories;
  final int? filterCategoryId;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<int?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.tableHeader,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: filterStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style: AppText.small,
              items: statusOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s == 'all' ? 'All' : s)))
                  .toList(),
              onChanged: (v) => v != null ? onStatusChanged(v) : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int?>(
              initialValue: filterCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style: AppText.small,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...categories.map((c) => DropdownMenuItem(value: c.serverId, child: Text(c.name))),
              ],
              onChanged: onCategoryChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// Fix #7: event is resolved at the parent and passed in — no per-row DB query.
class _OccurrenceRow extends StatelessWidget {
  const _OccurrenceRow({
    required this.occurrence,
    required this.event,
    required this.catMap,
    required this.onStatusChange,
    required this.onDelete,
  });

  final Occurrence occurrence;
  final Event? event;
  final Map<int?, Category> catMap;
  final void Function(String) onStatusChange;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cat = event != null ? catMap[event!.categoryServerId] : null;
    final dateLabel = _relDate(occurrence.occurrenceDate);

    return InkWell(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date column
            SizedBox(
              width: 52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _shortDate(occurrence.occurrenceDate),
                    style: AppText.small.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(dateLabel, style: AppText.label.copyWith(fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event?.title ?? 'Event #${occurrence.eventServerId}',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (cat != null) ...[
                    const SizedBox(height: 3),
                    CategoryBadge(name: cat.name, color: cat.color, icon: cat.icon),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status + quick actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(occurrence.status),
                const SizedBox(height: 4),
                _QuickActions(status: occurrence.status, onAction: onStatusChange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _DetailSheet(
        occurrence: occurrence,
        event: event,
        catMap: catMap,
        onStatusChange: onStatusChange,
        onDelete: onDelete,
      ),
    );
  }

  static String _shortDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('MMM d').format(d);
    } catch (_) {
      return iso.substring(0, 10);
    }
  }

  static String _relDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      final today = DateTime.now();
      final diff = d.difference(DateTime(today.year, today.month, today.day)).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Tomorrow';
      if (diff == -1) return 'Yesterday';
      if (diff > 1) return 'in $diff days';
      return '${-diff}d ago';
    } catch (_) {
      return '';
    }
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.status, required this.onAction});

  final String status;
  final void Function(String) onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status != 'completed')
          _IconBtn(icon: Icons.check_circle_outline, color: AppColors.btnGreen, onTap: () => onAction('completed')),
        if (status != 'skipped')
          _IconBtn(icon: Icons.skip_next_rounded, color: AppColors.textMuted, onTap: () => onAction('skipped')),
        if (status == 'completed' || status == 'skipped')
          _IconBtn(icon: Icons.replay_rounded, color: AppColors.btnBlue, onTap: () => onAction('upcoming')),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

// Fix #7: event is passed in from the parent — no FutureBuilder needed.
class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.occurrence,
    required this.event,
    required this.catMap,
    required this.onStatusChange,
    required this.onDelete,
  });

  final Occurrence occurrence;
  final Event? event;
  final Map<int?, Category> catMap;
  final void Function(String) onStatusChange;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cat = event != null ? catMap[event!.categoryServerId] : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            event?.title ?? 'Event #${occurrence.eventServerId}',
            style: AppText.heading,
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'DATE', value: occurrence.occurrenceDate),
          _DetailRow(label: 'STATUS', child: StatusBadge(occurrence.status)),
          if (cat != null)
            _DetailRow(
              label: 'CATEGORY',
              child: CategoryBadge(name: cat.name, color: cat.color, icon: cat.icon),
            ),
          if (event?.priority != null)
            _DetailRow(label: 'PRIORITY', value: event!.priority),
          if (occurrence.notes != null && occurrence.notes!.isNotEmpty)
            _DetailRow(label: 'NOTES', value: occurrence.notes!),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (occurrence.status != 'completed')
                _ActionBtn(
                  label: 'Mark Done',
                  color: AppColors.btnGreen,
                  onTap: () { onStatusChange('completed'); Navigator.pop(context); },
                ),
              if (occurrence.status != 'skipped')
                _ActionBtn(
                  label: 'Skip',
                  color: AppColors.btnGrayBg,
                  textColor: AppColors.btnGrayFg,
                  onTap: () { onStatusChange('skipped'); Navigator.pop(context); },
                ),
              if (occurrence.status == 'completed' || occurrence.status == 'skipped')
                _ActionBtn(
                  label: 'Reopen',
                  color: AppColors.btnBlue,
                  onTap: () { onStatusChange('upcoming'); Navigator.pop(context); },
                ),
              _ActionBtn(
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
                  if (confirmed == true && context.mounted) {
                    Navigator.pop(context);
                    onDelete();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, this.value, this.child});

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label),
          const SizedBox(height: 2),
          child ?? Text(value ?? '', style: AppText.body),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.color, required this.onTap, this.textColor});

  final String label;
  final Color color;
  final VoidCallback onTap;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label),
    );
  }
}
