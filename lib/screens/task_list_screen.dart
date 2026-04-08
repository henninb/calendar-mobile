import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../core/theme.dart';
import '../core/constants.dart';
import '../database/app_database.dart';
import '../providers/providers.dart';
import '../widgets/status_badge.dart';
import '../widgets/category_badge.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  String _filterStatus = 'active';
  String _filterDate = 'all'; // 'all' | 'today' | 'tomorrow'

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Failed to load tasks — try refreshing')),
      data: (tasks) {
        final categories = categoriesAsync.value ?? [];
        final catMap = {for (final c in categories) c.serverId: c};

        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final tomorrow = today.add(const Duration(days: 1));
        final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

        var filtered = tasks.where((t) {
          if (t.syncStatus == SyncStatus.pendingDelete.value) return false;
          if (t.dueDate == null) return true;
          if (t.dueDate!.compareTo(todayStr) >= 0) return true;
          // Past due: only show if not completed
          return t.status != 'done' && t.status != 'cancelled';
        }).toList();
        if (_filterStatus == 'active') {
          filtered = filtered.where((t) => t.status == 'todo' || t.status == 'in_progress').toList();
        } else if (_filterStatus != 'all') {
          filtered = filtered.where((t) => t.status == _filterStatus).toList();
        }
        if (_filterDate == 'today') {
          filtered = filtered.where((t) => t.dueDate == todayStr).toList();
        } else if (_filterDate == 'tomorrow') {
          filtered = filtered.where((t) => t.dueDate == tomorrowStr).toList();
        }
        filtered.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return _doneWeight(a) - _doneWeight(b);
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          final dateCmp = a.dueDate!.compareTo(b.dueDate!);
          if (dateCmp != 0) return dateCmp;
          return _doneWeight(a) - _doneWeight(b);
        });

        return Stack(
          children: [
            Column(
              children: [
                _StatusFilter(
                  selected: _filterStatus,
                  onChanged: (s) => setState(() => _filterStatus = s),
                  selectedDate: _filterDate,
                  onDateChanged: (d) => setState(() => _filterDate = d),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref.read(syncStateProvider.notifier).sync(),
                    child: filtered.isEmpty
                        ? const SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 400,
                              child: Center(child: Text('No tasks', style: AppText.small)),
                            ),
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                            itemCount: filtered.length,
                            separatorBuilder: (c, i) => const SizedBox(height: 8),
                            itemBuilder: (context, i) => _TaskCard(
                              key: ValueKey(filtered[i].id),
                              task: filtered[i],
                              catMap: catMap,
                              todayStr: todayStr,
                              tomorrowStr: tomorrowStr,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () => _showTaskForm(context, null),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  static int _doneWeight(Task t) =>
      (t.status == 'done' || t.status == 'cancelled') ? 1 : 0;

  Future<void> _showTaskForm(BuildContext context, Task? existing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TaskForm(existing: existing),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
    required this.selected,
    required this.onChanged,
    required this.selectedDate,
    required this.onDateChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final String selectedDate;
  final ValueChanged<String> onDateChanged;

  static const _statusOptions = ['active', 'all', 'todo', 'in_progress', 'done', 'cancelled'];
  static const _statusLabels = {
    'active': 'Active',
    'all': 'All',
    'todo': 'Todo',
    'in_progress': 'In Progress',
    'done': 'Done',
    'cancelled': 'Cancelled',
  };

  static const _dateOptions = ['all', 'today', 'tomorrow'];
  static const _dateLabels = {
    'all': 'Any Date',
    'today': 'Today',
    'tomorrow': 'Tomorrow',
  };

  Widget _chip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final bg = active ? (activeColor ?? AppColors.primary) : AppColors.surface;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? bg : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tableHeader,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: _statusOptions.map((s) => _chip(
                label: _statusLabels[s] ?? s,
                active: selected == s,
                onTap: () => onChanged(s),
              )).toList(),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
              children: _dateOptions.map((d) => _chip(
                label: _dateLabels[d] ?? d,
                active: selectedDate == d,
                onTap: () => onDateChanged(d),
                activeColor: const Color(0xFF6D28D9),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends ConsumerStatefulWidget {
  const _TaskCard({
    super.key,
    required this.task,
    required this.catMap,
    required this.todayStr,
    required this.tomorrowStr,
  });

  final Task task;
  final Map<int?, Category> catMap;
  final String todayStr;
  final String tomorrowStr;

  @override
  ConsumerState<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<_TaskCard> {
  bool _expanded = false;
  final _newSubtaskCtrl = TextEditingController();

  @override
  void dispose() {
    _newSubtaskCtrl.dispose();
    super.dispose();
  }

  Future<void> _addSubtask() async {
    final title = _newSubtaskCtrl.text.trim();
    if (title.isEmpty) return;
    _newSubtaskCtrl.clear();
    final task = widget.task;
    // Capture before the await — ref must not be accessed after an async gap
    // in a ConsumerStatefulWidget because the widget may be disposed by then.
    final syncNotifier = ref.read(syncStateProvider.notifier);
    try {
      await ref.read(dbProvider).insertSubtask(SubtasksCompanion(
        taskLocalId: Value(task.id),
        taskServerId: Value(task.serverId),
        title: Value(title),
        syncStatus: Value(SyncStatus.pendingCreate.value),
      ));
      syncNotifier.syncIfOnline();
    } catch (e, st) {
      dev.log('_addSubtask: $e', name: 'tasks', level: 900, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final cat = widget.catMap[task.categoryServerId];
    final todayStr = widget.todayStr;
    final isActive = task.status != 'done' && task.status != 'cancelled';
    final isDueToday = task.dueDate == todayStr;
    final isOverdue = task.dueDate != null && task.dueDate!.compareTo(todayStr) < 0;
    final highlight = isActive && (isDueToday || isOverdue);
    final showRecurrence = task.recurrence != 'none';

    final subtasksAsync = ref.watch(subtasksForTaskProvider(task.id));
    final subtasks = subtasksAsync.value ?? [];
    final doneCount = subtasks.where((s) => s.status == 'done').length;

    return Card(
      color: highlight ? const Color(0xFFFEE2E2) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TaskStatusBadge(task.status),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PriorityBadge(task.priority),
                  if (cat != null)
                    CategoryBadge(name: cat.name, color: cat.color, icon: cat.icon),
                  if (task.dueDate != null)
                    _DaysBadge(dueDate: task.dueDate!, todayStr: todayStr, isActive: isActive),
                  if (showRecurrence)
                    _RecurrenceBadge(task.recurrence),
                  if (task.syncStatus != SyncStatus.synced.value)
                    const Icon(Icons.cloud_upload_outlined, size: 12, color: AppColors.textMuted),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(task.description!, style: AppText.small, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              // Quick status actions
              const SizedBox(height: 8),
              _QuickStatusRow(task: task),
              // Subtask expand toggle (always visible)
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  children: [
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtasks.isEmpty
                          ? 'Subtasks'
                          : '${subtasks.length} subtask${subtasks.length == 1 ? '' : 's'}  ·  $doneCount/${subtasks.length} done',
                      style: AppText.small.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: 6),
                const Divider(height: 1),
                const SizedBox(height: 4),
                ...subtasks.map((s) => _InlineSubtaskRow(subtask: s)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newSubtaskCtrl,
                        style: AppText.small,
                        decoration: const InputDecoration(
                          hintText: 'Add subtask…',
                          hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addSubtask(),
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _addSubtask,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text('Add', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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
      builder: (_) => _TaskDetailSheet(task: widget.task, catMap: widget.catMap),
    );
  }
}

class _InlineSubtaskRow extends ConsumerWidget {
  const _InlineSubtaskRow({required this.subtask});

  final Subtask subtask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = subtask.status == 'done';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final newStatus = done ? 'todo' : 'done';
              final syncNotifier = ref.read(syncStateProvider.notifier);
              try {
                await ref.read(dbProvider).updateSubtask(
                  subtask.id,
                  SubtasksCompanion(
                    status: Value(newStatus),
                    syncStatus: Value(SyncStatus.pendingUpdate.value),
                  ),
                );
                syncNotifier.syncIfOnline();
              } catch (e, st) {
                dev.log('_InlineSubtaskRow toggle: $e', name: 'tasks', level: 900, stackTrace: st);
              }
            },
            child: Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: done ? AppColors.completedFg : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtask.title,
              style: AppText.small.copyWith(
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a pill badge with the days until/since the due date.
/// - Overdue + active: "Xd overdue" in red
/// - Due today + active: "today" in amber
/// - Due within 3 days + active: "Xd" in amber
/// - Future: "Xd" in gray
/// - Completed/cancelled tasks: plain date label (no urgency color)
class _DaysBadge extends StatelessWidget {
  const _DaysBadge({
    required this.dueDate,
    required this.todayStr,
    required this.isActive,
  });

  final String dueDate;
  final String todayStr;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.tryParse(todayStr);
    final due = DateTime.tryParse(dueDate);
    if (today == null || due == null) {
      return Text(dueDate, style: AppText.label);
    }

    final daysDelta = due.difference(today).inDays;

    final String label;
    final Color bg;
    final Color fg;

    if (!isActive) {
      // Completed/cancelled — show plain date, no urgency styling.
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textMuted),
          const SizedBox(width: 3),
          Text(dueDate, style: AppText.label),
        ],
      );
    }

    if (daysDelta < 0) {
      label = '${daysDelta.abs()}d overdue';
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    } else if (daysDelta == 0) {
      label = 'today';
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else if (daysDelta <= 3) {
      label = '${daysDelta}d';
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else {
      label = '${daysDelta}d';
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

/// Shows a recurrence badge: "↻ weekly" in blue.
class _RecurrenceBadge extends StatelessWidget {
  const _RecurrenceBadge(this.recurrence);

  final String recurrence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        '↻ $recurrence',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }
}

class _QuickStatusRow extends ConsumerWidget {
  const _QuickStatusRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(dbProvider);

    Future<void> setStatus(String s) async {
      final syncNotifier = ref.read(syncStateProvider.notifier);
      try {
        final now = DateTime.now().toIso8601String();
        await db.updateTask(
          task.id,
          TasksCompanion(
            status: Value(s),
            updatedAt: Value(now),
            // Set completedAt locally so the UI reflects it before sync.
            completedAt: s == 'done' ? Value(now) : const Value.absent(),
            syncStatus: Value(SyncStatus.pendingUpdate.value),
          ),
        );
        syncNotifier.syncIfOnline();
      } catch (e, st) {
        dev.log('setStatus: $e', name: 'tasks', level: 900, stackTrace: st);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update task. Please try again.')),
          );
        }
      }
    }

    void editTask() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _TaskForm(existing: task),
      );
    }

    Future<void> deleteTask() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Delete "${task.title}"?'),
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
      if (confirmed != true || !context.mounted) return;
      final syncNotifier = ref.read(syncStateProvider.notifier);
      try {
        await db.markTaskDeleted(task.id);
        syncNotifier.syncIfOnline();
      } catch (e, st) {
        dev.log('deleteTask: $e', name: 'tasks', level: 900, stackTrace: st);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete task. Please try again.')),
          );
        }
      }
    }

    return Wrap(
      spacing: 6,
      children: [
        if (task.status == 'todo')
          _Chip(label: 'Start', color: const Color(0xFF7C3AED), onTap: () => setStatus('in_progress')),
        if (task.status != 'done' && task.status != 'cancelled')
          _Chip(label: 'Done', color: AppColors.btnGreen, onTap: () => setStatus('done')),
        if (task.status != 'cancelled' && task.status != 'done')
          _Chip(label: 'Cancel', color: AppColors.btnGrayBg, textColor: AppColors.btnGrayFg, onTap: () => setStatus('cancelled')),
        _Chip(label: 'Edit', color: const Color(0xFF3B82F6), onTap: editTask),
        _Chip(label: 'Del', color: AppColors.btnRed, onTap: deleteTask),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.onTap, this.textColor});

  final String label;
  final Color color;
  final VoidCallback onTap;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor ?? Colors.white),
        ),
      ),
    );
  }
}

// ── Task Detail / Edit Sheet ──────────────────────────────────────────────────

class _TaskDetailSheet extends ConsumerStatefulWidget {
  const _TaskDetailSheet({required this.task, required this.catMap});

  final Task task;
  final Map<int?, Category> catMap;

  @override
  ConsumerState<_TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<_TaskDetailSheet> {
  late Task _task;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    // Keep _task in sync with live DB data so syncs are reflected immediately.
    ref.listen<AsyncValue<List<Task>>>(tasksProvider, (_, next) {
      final live = next.value?.where((t) => t.id == widget.task.id).firstOrNull;
      if (live != null) setState(() => _task = live);
    });
    final subtasksStream = ref.watch(subtasksForTaskProvider(_task.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_task.title, style: AppText.heading),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _editing = !_editing),
                      child: Text(_editing ? 'Cancel' : 'Edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.btnRed),
                      onPressed: _deleteTask,
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (_editing)
                      _TaskForm(existing: _task)
                    else ...[
                      _InfoRow(label: 'STATUS', child: TaskStatusBadge(_task.status)),
                      _InfoRow(label: 'PRIORITY', child: PriorityBadge(_task.priority)),
                      if (widget.catMap[_task.categoryServerId] != null)
                        _InfoRow(
                          label: 'CATEGORY',
                          child: CategoryBadge(
                            name: widget.catMap[_task.categoryServerId]!.name,
                            color: widget.catMap[_task.categoryServerId]!.color,
                            icon: widget.catMap[_task.categoryServerId]!.icon,
                          ),
                        ),
                      if (_task.dueDate != null) _InfoRow(label: 'DUE', value: _task.dueDate!),
                      if (_task.completedAt != null) _InfoRow(label: 'COMPLETED', value: _task.completedAt!),
                      if (_task.assigneeServerId != null)
                        Consumer(builder: (context, ref, _) {
                          final persons = ref.watch(personsProvider).value ?? [];
                          final person = persons.where((p) => p.serverId == _task.assigneeServerId).firstOrNull;
                          if (person == null) return const SizedBox.shrink();
                          return _InfoRow(label: 'ASSIGNEE', value: person.name);
                        }),
                      if (_task.recurrence != 'none') _InfoRow(label: 'RECURRENCE', value: _task.recurrence),
                      if (_task.estimatedMinutes != null)
                        _InfoRow(label: 'ESTIMATED', value: '${_task.estimatedMinutes} min'),
                      if (_task.description != null && _task.description!.isNotEmpty)
                        _InfoRow(label: 'DESCRIPTION', value: _task.description!),
                    ],
                    const SizedBox(height: 16),
                    // Subtasks
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtasks', style: AppText.subheading),
                        TextButton.icon(
                          onPressed: _addSubtask,
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    subtasksStream.when(
                      loading: () => const SizedBox(height: 32, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                      error: (e, _) => const Text('Failed to load subtasks', style: AppText.small),
                      data: (subs) => subs.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('No subtasks', style: AppText.small),
                            )
                          : Column(
                              children: subs.map((s) => _SubtaskRow(subtask: s, taskId: _task.id)).toList(),
                            ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addSubtask() async {
    final ctrl = TextEditingController();
    try {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Add Subtask', style: AppText.heading),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Subtask title'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                final syncNotifier = ref.read(syncStateProvider.notifier);
                try {
                  final db = ref.read(dbProvider);
                  await db.insertSubtask(SubtasksCompanion(
                    taskLocalId: Value(_task.id),
                    taskServerId: Value(_task.serverId),
                    title: Value(ctrl.text.trim()),
                    syncStatus: Value(SyncStatus.pendingCreate.value),
                  ));
                  if (mounted) Navigator.pop(context);
                  syncNotifier.syncIfOnline();
                } catch (e, st) {
                  dev.log('_TaskDetailSheet _addSubtask: $e', name: 'tasks', level: 900, stackTrace: st);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add subtask. Please try again.')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${_task.title}"?'),
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
    if (confirmed != true || !mounted) return;
    final syncNotifier = ref.read(syncStateProvider.notifier);
    try {
      await ref.read(dbProvider).markTaskDeleted(_task.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
        syncNotifier.syncIfOnline();
      });
    } catch (e, st) {
      dev.log('_TaskDetailSheet _deleteTask: $e', name: 'tasks', level: 900, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete task. Please try again.')),
        );
      }
    }
  }
}

class _SubtaskRow extends ConsumerWidget {
  const _SubtaskRow({required this.subtask, required this.taskId});

  final Subtask subtask;
  final int taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final newStatus = subtask.status == 'done' ? 'todo' : 'done';
              final syncNotifier = ref.read(syncStateProvider.notifier);
              try {
                await ref.read(dbProvider).updateSubtask(
                  subtask.id,
                  SubtasksCompanion(
                    status: Value(newStatus),
                    syncStatus: Value(SyncStatus.pendingUpdate.value),
                  ),
                );
                syncNotifier.syncIfOnline();
              } catch (e, st) {
                dev.log('_SubtaskRow toggle: $e', name: 'tasks', level: 900, stackTrace: st);
              }
            },
            child: Icon(
              subtask.status == 'done' ? Icons.check_circle : Icons.radio_button_unchecked,
              color: subtask.status == 'done' ? AppColors.completedFg : AppColors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtask.title,
              style: AppText.body.copyWith(
                decoration: subtask.status == 'done' ? TextDecoration.lineThrough : null,
                color: subtask.status == 'done' ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
            onPressed: () async {
              final syncNotifier = ref.read(syncStateProvider.notifier);
              try {
                await ref.read(dbProvider).markSubtaskDeleted(subtask.id);
                syncNotifier.syncIfOnline();
              } catch (e, st) {
                dev.log('_SubtaskRow delete: $e', name: 'tasks', level: 900, stackTrace: st);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.child});

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

// ── Task Create / Edit Form ──────────────────────────────────────────────────

class _TaskForm extends ConsumerStatefulWidget {
  const _TaskForm({this.existing});

  final Task? existing;

  @override
  ConsumerState<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _description;
  String _status   = 'todo';
  String _priority = 'medium';
  String _recurrence = 'none';
  String? _dueDate;
  int? _assigneeServerId;
  int? _categoryServerId;

  static const _statuses    = ['todo', 'in_progress', 'done', 'cancelled'];
  static const _priorities  = ['low', 'medium', 'high'];
  static const _recurrences = ['none', 'daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'semiannual', 'yearly'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title       = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _status      = e?.status ?? 'todo';
    _priority    = e?.priority ?? 'medium';
    _recurrence  = e?.recurrence ?? 'none';
    _dueDate     = e?.dueDate ?? DateTime.now().toIso8601String().substring(0, 10);
    _assigneeServerId = e?.assigneeServerId;
    _categoryServerId = e?.categoryServerId;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: _priorities.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _recurrence,
              decoration: const InputDecoration(labelText: 'Recurrence'),
              items: _recurrences.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _recurrence = v!),
            ),
            const SizedBox(height: 10),
            // Due date picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(_dueDate!) ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _dueDate = picked.toIso8601String().substring(0, 10));
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Due Date'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_dueDate!, style: AppText.body),
                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Category dropdown
            ref.watch(categoriesProvider).when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (cats) => DropdownButtonFormField<int?>(
                initialValue: _categoryServerId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...cats.map((c) => DropdownMenuItem(
                        value: c.serverId,
                        child: Text('${c.icon} ${c.name}'),
                      )),
                ],
                onChanged: (v) => setState(() => _categoryServerId = v),
              ),
            ),
            const SizedBox(height: 10),
            // Assignee dropdown
            ref.watch(personsProvider).when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (persons) => DropdownButtonFormField<int?>(
                initialValue: _assigneeServerId,
                decoration: const InputDecoration(labelText: 'Assignee'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...persons.map((p) => DropdownMenuItem(value: p.serverId, child: Text(p.name))),
                ],
                onChanged: (v) => setState(() => _assigneeServerId = v),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(widget.existing == null ? 'Create Task' : 'Save Changes'),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(dbProvider);
    // Capture the notifier before the first await. Navigator.pop() disposes
    // this widget's ref — any ref.read() after that throws an assertion in
    // Riverpod 3.x ('_dependents.isEmpty' is not true).
    final syncNotifier = ref.read(syncStateProvider.notifier);
    final now = DateTime.now().toIso8601String();

    try {
      if (widget.existing == null) {
        await db.insertTask(TasksCompanion(
          title: Value(_title.text.trim()),
          description: Value(_description.text.trim().isEmpty ? null : _description.text.trim()),
          status: Value(_status),
          priority: Value(_priority),
          recurrence: Value(_recurrence),
          dueDate: Value(_dueDate),
          assigneeServerId: Value(_assigneeServerId),
          categoryServerId: Value(_categoryServerId),
          syncStatus: Value(SyncStatus.pendingCreate.value),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
      } else {
        await db.updateTask(
          widget.existing!.id,
          TasksCompanion(
            title: Value(_title.text.trim()),
            description: Value(_description.text.trim().isEmpty ? null : _description.text.trim()),
            status: Value(_status),
            priority: Value(_priority),
            recurrence: Value(_recurrence),
            dueDate: Value(_dueDate),
            assigneeServerId: Value(_assigneeServerId),
            categoryServerId: Value(_categoryServerId),
            updatedAt: Value(now),
            syncStatus: Value(SyncStatus.pendingUpdate.value),
          ),
        );
      }

      // Defer the dismiss to a post-frame callback.
      //
      // On Android the soft keyboard is often visible when the user taps
      // "Create Task". The button press starts keyboard dismissal, which
      // changes MediaQuery.viewInsets, which marks this element dirty for
      // rebuild. Calling Navigator.pop() synchronously while the element is
      // still dirty causes Flutter to assert '_dependents.isEmpty is not true'
      // inside InheritedElement.unmount(). Deferring to the next frame lets
      // Flutter finish all pending rebuilds before the element is unmounted.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
        syncNotifier.syncIfOnline();
      });
    } catch (e, st) {
      dev.log('_save: $e', name: 'tasks', level: 900, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save task. Please try again.')),
        );
      }
    }
  }
}

