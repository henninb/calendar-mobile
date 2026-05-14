import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/extensions/date_extensions.dart';
import '../database/app_database.dart';
import '../providers/providers.dart';
import '../widgets/sheet_handle.dart';
import '../widgets/status_badge.dart';
import '../widgets/category_badge.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  String _filterStatus = 'active';
  String _searchQuery = '';
  final Map<String, bool> _collapsedSections = {};
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isCollapsed(String key, bool isEmpty) =>
      _collapsedSections[key] ?? (key != 'overdue' && key != 'today');

  void _toggleSection(String key, bool isEmpty) {
    setState(() {
      _collapsedSections[key] = !_isCollapsed(key, isEmpty);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final showSearch = ref.watch(taskSearchVisibleProvider);

    ref.listen<bool>(taskSearchVisibleProvider, (_, visible) {
      if (!visible) {
        _searchCtrl.clear();
        setState(() => _searchQuery = '');
      }
    });

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Failed to load tasks — try refreshing')),
      data: (tasks) {
        final categories = categoriesAsync.value ?? [];
        final catMap = {for (final c in categories) c.serverId: c};

        final today = DateTime.now();
        final todayStr    = today.toIso8601DateString();
        final tomorrowStr = today.add(const Duration(days: 1)).toIso8601DateString();
        final week1EndStr = today.add(const Duration(days: 7)).toIso8601DateString();
        final week2EndStr = today.add(const Duration(days: 14)).toIso8601DateString();

        var filtered = tasks.where((t) {
          if (t.syncStatus == SyncStatus.pendingDelete.value) return false;
          if (t.dueDate == null) return true;
          if (t.dueDate!.compareTo(todayStr) >= 0) return true;
          // Past due: only show if not completed
          return t.status != TaskStatus.done && t.status != TaskStatus.cancelled;
        }).toList();
        if (_filterStatus == 'active') {
          filtered = filtered.where((t) => t.status == TaskStatus.todo || t.status == TaskStatus.inProgress).toList();
        } else if (_filterStatus != 'all') {
          filtered = filtered.where((t) => t.status == _filterStatus).toList();
        }
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          filtered = filtered.where((t) =>
            t.title.toLowerCase().contains(q) ||
            (t.description?.toLowerCase().contains(q) ?? false),
          ).toList();
        }
        filtered.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return _doneWeight(a) - _doneWeight(b);
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          final dateCmp = a.dueDate!.compareTo(b.dueDate!);
          if (dateCmp != 0) return dateCmp;
          return _doneWeight(a) - _doneWeight(b);
        });

        final sections = _buildSections(filtered, todayStr, tomorrowStr, week1EndStr, week2EndStr);

        return Stack(
          children: [
            Column(
              children: [
                _StatusFilter(
                  selected: _filterStatus,
                  onChanged: (s) => setState(() => _filterStatus = s),
                ),
                if (showSearch)
                  _SearchBar(
                    controller: _searchCtrl,
                    onChanged: (q) => setState(() => _searchQuery = q),
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
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                            children: [
                              for (final section in sections)
                                if (!section.hideWhenEmpty || section.tasks.isNotEmpty) ...[
                                  _SectionHeader(
                                    sectionKey: section.key,
                                    label: section.label,
                                    count: section.tasks.length,
                                    isExpanded: !_isCollapsed(section.key, section.tasks.isEmpty),
                                    onTap: () => _toggleSection(section.key, section.tasks.isEmpty),
                                  ),
                                  if (!_isCollapsed(section.key, section.tasks.isEmpty))
                                    Builder(builder: (ctx) {
                                      final colors = AppColors.of(ctx);
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: colors.dividerLight,
                                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                                          border: Border(
                                            left:   BorderSide(color: colors.divider),
                                            right:  BorderSide(color: colors.divider),
                                            bottom: BorderSide(color: colors.divider),
                                          ),
                                        ),
                                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                                        child: Column(
                                          children: [
                                            for (final task in section.tasks)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 6),
                                                child: _TaskCard(
                                                  key: ValueKey(task.id),
                                                  task: task,
                                                  catMap: catMap,
                                                  todayStr: todayStr,
                                                  tomorrowStr: tomorrowStr,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }),
                                  const SizedBox(height: 8),
                                ],
                            ],
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

  List<_TaskSection> _buildSections(
    List<Task> tasks,
    String todayStr,
    String tomorrowStr,
    String week1EndStr,
    String week2EndStr,
  ) {
    final done         = <Task>[];
    final overdue      = <Task>[];
    final todayList    = <Task>[];
    final tomorrowList = <Task>[];
    final thisWeek     = <Task>[];
    final nextWeek     = <Task>[];
    final later        = <Task>[];
    final noDate       = <Task>[];

    for (final task in tasks) {
      if (task.status == TaskStatus.done) {
        done.add(task);
      } else if (task.dueDate == null) {
        noDate.add(task);
      } else if (task.dueDate!.compareTo(todayStr) < 0) {
        overdue.add(task);
      } else if (task.dueDate == todayStr) {
        todayList.add(task);
      } else if (task.dueDate == tomorrowStr) {
        tomorrowList.add(task);
      } else if (task.dueDate!.compareTo(week1EndStr) <= 0) {
        thisWeek.add(task);
      } else if (task.dueDate!.compareTo(week2EndStr) <= 0) {
        nextWeek.add(task);
      } else {
        later.add(task);
      }
    }

    return [
      _TaskSection(key: 'done',     label: 'Done',     tasks: done,         hideWhenEmpty: true),
      _TaskSection(key: 'overdue',  label: 'Overdue',  tasks: overdue),
      _TaskSection(key: 'today',    label: 'Today',    tasks: todayList),
      _TaskSection(key: 'tomorrow', label: 'Tomorrow', tasks: tomorrowList),
      _TaskSection(key: 'this_week', label: 'This Week', tasks: thisWeek),
      _TaskSection(key: 'next_week', label: 'Next Week', tasks: nextWeek),
      _TaskSection(key: 'later',    label: 'Later',    tasks: later),
      _TaskSection(key: 'no_date',  label: 'No Date',  tasks: noDate,        hideWhenEmpty: true),
    ];
  }

  static int _doneWeight(Task t) =>
      (t.status == TaskStatus.done || t.status == TaskStatus.cancelled) ? 1 : 0;

  Future<void> _showTaskForm(BuildContext context, Task? existing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TaskForm(existing: existing),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      color: colors.tableHeader,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppText.body,
        decoration: InputDecoration(
          hintText: 'Search tasks…',
          hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
          prefixIcon: Icon(Icons.search, size: 18, color: colors.textMuted),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Icon(Icons.close, size: 16, color: colors.textMuted),
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          filled: true,
          fillColor: colors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  static const _statusOptions = [
    'active', 'all', TaskStatus.todo, TaskStatus.inProgress, TaskStatus.done, TaskStatus.cancelled,
  ];
  static const _statusLabels = {
    'active': 'Active',
    'all': 'All',
    TaskStatus.todo: 'Todo',
    TaskStatus.inProgress: 'In Progress',
    TaskStatus.done: 'Done',
    TaskStatus.cancelled: 'Cancelled',
  };

  Widget _chip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    required AppColors colors,
    Color? activeColor,
  }) {
    final bg = active ? (activeColor ?? AppColors.primary) : colors.surface;
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
              color: active ? bg : colors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      color: colors.tableHeader,
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          children: _statusOptions.map((s) => _chip(
            label: _statusLabels[s] ?? s,
            active: selected == s,
            onTap: () => onChanged(s),
            colors: colors,
          )).toList(),
        ),
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

  Color _priorityStripe(String priority) {
    switch (priority) {
      case 'high':   return const Color(0xFFEF4444);
      case 'medium': return const Color(0xFFF59E0B);
      default:       return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final cat = widget.catMap[task.categoryServerId];
    final todayStr = widget.todayStr;
    final isActive = task.status != TaskStatus.done && task.status != TaskStatus.cancelled;
    final isDueToday = task.dueDate == todayStr;
    final isOverdue = task.dueDate != null && task.dueDate!.compareTo(todayStr) < 0;
    final isDimmed = !isActive;
    final showRecurrence = task.recurrence != 'none';

    final subtasksAsync = ref.watch(subtasksForTaskProvider(task.id));
    final subtasks = subtasksAsync.value ?? [];
    final doneCount = subtasks.where((s) => s.status == 'done').length;
    final progress = subtasks.isEmpty ? 0.0 : doneCount / subtasks.length;

    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stripeColor = _priorityStripe(task.priority);
    final cardBg = isActive && isOverdue
        ? (isDark ? const Color(0x1ADC2626) : const Color(0xFFFEF2F2))
        : isActive && isDueToday
            ? (isDark ? const Color(0x1AF97316) : const Color(0xFFFFFBEB))
            : colors.surface;

    final card = Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.divider, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left priority stripe
              Container(width: 4, color: stripeColor),
              Expanded(
                child: InkWell(
                  onTap: () => _showDetail(context),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row + status pill + icon actions
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: AppText.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: isDimmed ? TextDecoration.lineThrough : null,
                                  color: isDimmed ? colors.textMuted : colors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _WebStatusPill(task.status),
                            const SizedBox(width: 4),
                            _IconActions(
                              task: task,
                              onShowEdit: () => _showEdit(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Meta row: priority, category, date, recurrence
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PriorityBadge(task.priority),
                            if (cat != null)
                              CategoryBadge(name: cat.name, color: cat.color, icon: cat.icon),
                            if (task.dueDate != null)
                              GestureDetector(
                                onTap: () => _showQuickDateSheet(context),
                                child: _DaysBadge(dueDate: task.dueDate!, todayStr: todayStr, isActive: isActive),
                              ),
                            if (showRecurrence)
                              _RecurrenceBadge(task.recurrence),
                            if (task.syncStatus != SyncStatus.synced.value)
                              Icon(Icons.cloud_upload_outlined, size: 12, color: colors.textMuted),
                          ],
                        ),
                        // Subtask progress bar + expand toggle
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 4,
                                    backgroundColor: colors.divider,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$doneCount/${subtasks.length}',
                                style: AppText.small.copyWith(
                                  color: colors.textMuted,
                                  fontFeatures: [const FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _expanded ? '▾ hide' : '▸ subtasks',
                                style: AppText.small.copyWith(color: colors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (_expanded) ...[
                          const SizedBox(height: 6),
                          const Divider(height: 1),
                          const SizedBox(height: 4),
                          if (task.description != null && task.description!.isNotEmpty) ...[
                            Text(
                              task.description!,
                              style: AppText.small,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                          ],
                          ...subtasks.map((s) => _InlineSubtaskRow(subtask: s)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newSubtaskCtrl,
                                  style: AppText.small,
                                  maxLength: 255,
                                  decoration: InputDecoration(
                                    hintText: 'Add subtask…',
                                    hintStyle: TextStyle(fontSize: 12, color: colors.textMuted),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    border: OutlineInputBorder(),
                                    counterText: '',
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
              ),
            ],
          ),
        ),
      ),
    );

    return isDimmed ? Opacity(opacity: 0.55, child: card) : card;
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TaskDetailSheet(task: widget.task, catMap: widget.catMap),
    );
  }

  void _showEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TaskForm(existing: widget.task),
    );
  }

  Future<void> _updateDueDate(String? date) async {
    final task = widget.task;
    final syncNotifier = ref.read(syncStateProvider.notifier);
    final db = ref.read(dbProvider);
    try {
      await db.updateTask(
        task.id,
        TasksCompanion(
          dueDate: Value(date),
          updatedAt: Value(DateTime.now().toIso8601String()),
          syncStatus: Value(SyncStatus.next(task.syncStatus)),
        ),
      );
      syncNotifier.syncIfOnline();
    } catch (e, st) {
      dev.log('updateDueDate: $e', name: 'tasks', level: 900, stackTrace: st);
    }
  }

  void _showQuickDateSheet(BuildContext context) {
    final task = widget.task;
    final now = DateTime.now();
    final today = now.toIso8601DateString();
    final tomorrow = now.add(const Duration(days: 1)).toIso8601DateString();
    final nextWeek = now.add(const Duration(days: 7)).toIso8601DateString();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Change Due Date', style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.today_outlined, size: 20),
                title: Text('Today', style: AppText.body),
                subtitle: Text(today, style: AppText.small),
                dense: true,
                onTap: () async {
                  Navigator.pop(context);
                  await _updateDueDate(today);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_view_day_outlined, size: 20),
                title: Text('Tomorrow', style: AppText.body),
                subtitle: Text(tomorrow, style: AppText.small),
                dense: true,
                onTap: () async {
                  Navigator.pop(context);
                  await _updateDueDate(tomorrow);
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range_outlined, size: 20),
                title: Text('Next Week', style: AppText.body),
                subtitle: Text(nextWeek, style: AppText.small),
                dense: true,
                onTap: () async {
                  Navigator.pop(context);
                  await _updateDueDate(nextWeek);
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_busy_outlined, size: 20),
                title: Text('No Date', style: AppText.body),
                dense: true,
                onTap: () async {
                  Navigator.pop(context);
                  await _updateDueDate(null);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined, size: 20),
                title: Text('Pick a date…', style: AppText.body),
                dense: true,
                onTap: () async {
                  Navigator.pop(context);
                  if (!mounted) return;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(task.dueDate ?? '') ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && mounted) await _updateDueDate(picked.toIso8601DateString());
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InlineSubtaskRow extends ConsumerWidget {
  const _InlineSubtaskRow({required this.subtask});

  final Subtask subtask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = subtask.status == TaskStatus.done;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final newStatus = done ? TaskStatus.todo : TaskStatus.done;
              final syncNotifier = ref.read(syncStateProvider.notifier);
              try {
                await ref.read(dbProvider).updateSubtask(
                  subtask.id,
                  SubtasksCompanion(
                    status: Value(newStatus),
                    syncStatus: Value(SyncStatus.next(subtask.syncStatus)),
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
              color: done ? AppColors.of(context).completedFg : AppColors.of(context).textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtask.title,
              style: AppText.small.copyWith(
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? AppColors.of(context).textMuted : AppColors.of(context).textPrimary,
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

    final colors = AppColors.of(context);

    if (!isActive) {
      // Completed/cancelled — show plain date, no urgency styling.
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined, size: 11, color: colors.textMuted),
          const SizedBox(width: 3),
          Text(dueDate, style: AppText.label),
        ],
      );
    }

    if (daysDelta < 0) {
      label = '${daysDelta.abs()}d overdue';
      bg = colors.overdueBg;
      fg = AppColors.ccOverdue;
    } else if (daysDelta == 0) {
      label = 'today';
      bg = colors.warningBg;
      fg = colors.warningFg;
    } else if (daysDelta <= 3) {
      label = '${daysDelta}d';
      bg = colors.warningBg;
      fg = colors.warningFg;
    } else {
      label = '${daysDelta}d';
      bg = colors.skippedBg;
      fg = colors.skippedFg;
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
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.pendingBanner,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.pendingBorder),
      ),
      child: Text(
        '↻ $recurrence',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

/// Status pill matching the web design (○ ◑ ✓ ✕ icons with colored background).
class _WebStatusPill extends StatelessWidget {
  const _WebStatusPill(this.status);
  final String status;

  static const _icons = {
    TaskStatus.todo:       '○',
    TaskStatus.inProgress: '◑',
    TaskStatus.done:       '✓',
    TaskStatus.cancelled:  '✕',
  };

  static const _bgsLight = {
    TaskStatus.todo:       Color(0xFFEFF6FF),
    TaskStatus.inProgress: Color(0xFFFFFBEB),
    TaskStatus.done:       Color(0xFFF0FDF4),
    TaskStatus.cancelled:  Color(0xFFF8FAFC),
  };
  static const _fgsLight = {
    TaskStatus.todo:       Color(0xFF1D4ED8),
    TaskStatus.inProgress: Color(0xFFB45309),
    TaskStatus.done:       Color(0xFF15803D),
    TaskStatus.cancelled:  Color(0xFF64748B),
  };
  static const _bordersLight = {
    TaskStatus.todo:       Color(0xFFBFDBFE),
    TaskStatus.inProgress: Color(0xFFFDE68A),
    TaskStatus.done:       Color(0xFFBBF7D0),
    TaskStatus.cancelled:  Color(0xFFE2E8F0),
  };

  static const _bgsDark = {
    TaskStatus.todo:       Color(0x331D4ED8),
    TaskStatus.inProgress: Color(0x1AFBBF24),
    TaskStatus.done:       Color(0x3315803D),
    TaskStatus.cancelled:  Color(0xFF334155),
  };
  static const _fgsDark = {
    TaskStatus.todo:       Color(0xFF93C5FD),
    TaskStatus.inProgress: Color(0xFFFDE68A),
    TaskStatus.done:       Color(0xFF86EFAC),
    TaskStatus.cancelled:  Color(0xFF94A3B8),
  };
  static const _bordersDark = {
    TaskStatus.todo:       Color(0x661D4ED8),
    TaskStatus.inProgress: Color(0x1AFBBF24),
    TaskStatus.done:       Color(0x3315803D),
    TaskStatus.cancelled:  Color(0xFF334155),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgs     = isDark ? _bgsDark     : _bgsLight;
    final fgs     = isDark ? _fgsDark     : _fgsLight;
    final borders = isDark ? _bordersDark : _bordersLight;
    final colors  = AppColors.of(context);

    final bg     = bgs[status]     ?? colors.surface;
    final fg     = fgs[status]     ?? colors.textMuted;
    final border = borders[status] ?? colors.divider;
    final icon   = _icons[status]  ?? '○';
    final label  = {
      TaskStatus.todo:       'To Do',
      TaskStatus.inProgress: 'In Progress',
      TaskStatus.done:       'Done',
      TaskStatus.cancelled:  'Cancelled',
    }[status] ?? status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: 10, color: fg)),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

/// Compact icon action buttons: done circle, start play, overflow menu.
class _IconActions extends ConsumerWidget {
  const _IconActions({required this.task, required this.onShowEdit});
  final Task task;
  final VoidCallback onShowEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(dbProvider);
    final isActive = task.status != TaskStatus.done && task.status != TaskStatus.cancelled;

    Future<void> setStatus(String s) async {
      final syncNotifier = ref.read(syncStateProvider.notifier);
      try {
        final now = DateTime.now().toIso8601String();
        await db.updateTask(
          task.id,
          TasksCompanion(
            status: Value(s),
            updatedAt: Value(now),
            completedAt: s == TaskStatus.done ? Value(now) : const Value.absent(),
            syncStatus: Value(SyncStatus.next(task.syncStatus)),
          ),
        );
        syncNotifier.syncIfOnline();
      } catch (e, st) {
        dev.log('setStatus: $e', name: 'tasks', level: 900, stackTrace: st);
      }
    }

    Future<void> deleteTask() async {
      final syncNotifier = ref.read(syncStateProvider.notifier);
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
      try {
        await db.markTaskDeleted(task.id);
        syncNotifier.syncIfOnline();
      } catch (e, st) {
        dev.log('deleteTask: $e', name: 'tasks', level: 900, stackTrace: st);
      }
    }

    final colors = AppColors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mark done circle
        if (isActive)
          GestureDetector(
            onTap: () => setStatus(TaskStatus.done),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.divider, width: 1.5),
              ),
              child: Center(
                child: Text('✓', style: TextStyle(fontSize: 11, color: colors.textMuted)),
              ),
            ),
          )
        else
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.completedBg,
              border: Border.fromBorderSide(BorderSide(color: colors.completedFg, width: 1.5)),
            ),
            child: Center(
              child: Text(
                '✓',
                style: TextStyle(fontSize: 11, color: colors.completedFg, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        const SizedBox(width: 4),
        // Start button (todo only)
        if (task.status == TaskStatus.todo) ...[
          GestureDetector(
            onTap: () => setStatus(TaskStatus.inProgress),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.divider, width: 1.5),
              ),
              child: Center(
                child: Text('▶', style: TextStyle(fontSize: 9, color: colors.textMuted)),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        // Overflow menu (···)
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: colors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (_) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit_outlined, size: 18),
                      title: const Text('Edit'),
                      dense: true,
                      onTap: () { Navigator.pop(context); onShowEdit(); },
                    ),
                    if (isActive)
                      ListTile(
                        leading: const Icon(Icons.cancel_outlined, size: 18),
                        title: const Text('Cancel task'),
                        dense: true,
                        onTap: () { Navigator.pop(context); setStatus(TaskStatus.cancelled); },
                      ),
                    if (!isActive)
                      ListTile(
                        leading: const Icon(Icons.refresh_outlined, size: 18),
                        title: const Text('Reopen'),
                        dense: true,
                        onTap: () { Navigator.pop(context); setStatus(TaskStatus.todo); },
                      ),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, size: 18, color: AppColors.btnRed),
                      title: const Text('Delete', style: TextStyle(color: AppColors.btnRed)),
                      dense: true,
                      onTap: () { Navigator.pop(context); deleteTask(); },
                    ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text('···', style: TextStyle(fontSize: 14, color: colors.textMuted, letterSpacing: -1)),
            ),
          ),
        ),
      ],
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
          decoration: BoxDecoration(
            color: AppColors.of(context).surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SheetHandle(margin: EdgeInsets.symmetric(vertical: 12)),
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
            maxLength: 255,
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
              final newStatus = subtask.status == TaskStatus.done ? TaskStatus.todo : TaskStatus.done;
              final syncNotifier = ref.read(syncStateProvider.notifier);
              try {
                await ref.read(dbProvider).updateSubtask(
                  subtask.id,
                  SubtasksCompanion(
                    status: Value(newStatus),
                    syncStatus: Value(SyncStatus.next(subtask.syncStatus)),
                  ),
                );
                syncNotifier.syncIfOnline();
              } catch (e, st) {
                dev.log('_SubtaskRow toggle: $e', name: 'tasks', level: 900, stackTrace: st);
              }
            },
            child: Icon(
              subtask.status == TaskStatus.done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: subtask.status == TaskStatus.done
                  ? AppColors.of(context).completedFg
                  : AppColors.of(context).textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtask.title,
              style: AppText.body.copyWith(
                decoration: subtask.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                color: subtask.status == TaskStatus.done
                    ? AppColors.of(context).textMuted
                    : AppColors.of(context).textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: AppColors.of(context).textMuted),
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

  static const _statuses    = [TaskStatus.todo, TaskStatus.inProgress, TaskStatus.done, TaskStatus.cancelled];
  static const _priorities  = ['low', 'medium', 'high'];
  static const _recurrences = ['none', 'daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'semiannual', 'yearly'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title       = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _status      = e?.status ?? TaskStatus.todo;
    _priority    = e?.priority ?? 'medium';
    _recurrence  = e?.recurrence ?? 'none';
    _dueDate     = e?.dueDate ?? DateTime.now().toIso8601DateString();
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
              maxLength: 255,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
              maxLength: 2000,
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
                  setState(() => _dueDate = picked.toIso8601DateString());
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Due Date'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_dueDate!, style: AppText.body),
                    Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.of(context).textMuted),
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
    final title = _title.text.trim();
    final desc = _description.text.trim();

    try {
      if (widget.existing == null) {
        await db.insertTask(TasksCompanion(
          title: Value(title),
          description: Value(desc.isEmpty ? null : desc),
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
            title: Value(title),
            description: Value(desc.isEmpty ? null : desc),
            status: Value(_status),
            priority: Value(_priority),
            recurrence: Value(_recurrence),
            dueDate: Value(_dueDate),
            assigneeServerId: Value(_assigneeServerId),
            categoryServerId: Value(_categoryServerId),
            updatedAt: Value(now),
            syncStatus: Value(SyncStatus.next(widget.existing!.syncStatus)),
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

// ── Section data ─────────────────────────────────────────────────────────────

class _TaskSection {
  const _TaskSection({
    required this.key,
    required this.label,
    required this.tasks,
    this.hideWhenEmpty = false,
  });

  final String key;
  final String label;
  final List<Task> tasks;
  final bool hideWhenEmpty;
}

// ── Section accent styles ─────────────────────────────────────────────────────

class _SectionAccent {
  const _SectionAccent({
    required this.stripe,
    required this.bg,
    required this.labelColor,
    required this.badgeBg,
    required this.badgeFg,
    required this.icon,
  });
  final Color stripe;
  final Color bg;
  final Color labelColor;
  final Color badgeBg;
  final Color badgeFg;
  final String icon;
}

const _kSectionAccents = <String, _SectionAccent>{
  'overdue': _SectionAccent(
    stripe: Color(0xFFEF4444), bg: Color(0xFFFEF2F2),
    labelColor: Color(0xFFB91C1C), badgeBg: Color(0xFFFEE2E2), badgeFg: Color(0xFFB91C1C),
    icon: '🔥',
  ),
  'today': _SectionAccent(
    stripe: Color(0xFFF97316), bg: Color(0xFFFFF7ED),
    labelColor: Color(0xFFC2410C), badgeBg: Color(0xFFFED7AA), badgeFg: Color(0xFFC2410C),
    icon: '🔥',
  ),
  'tomorrow': _SectionAccent(
    stripe: Color(0xFFF59E0B), bg: Color(0xFFFFFBEB),
    labelColor: Color(0xFFB45309), badgeBg: Color(0xFFFDE68A), badgeFg: Color(0xFFB45309),
    icon: '📅',
  ),
  'this_week': _SectionAccent(
    stripe: Color(0xFF3B82F6), bg: Color(0xFFEFF6FF),
    labelColor: Color(0xFF1D4ED8), badgeBg: Color(0xFFDBEAFE), badgeFg: Color(0xFF1D4ED8),
    icon: '📆',
  ),
  'next_week': _SectionAccent(
    stripe: Color(0xFF8B5CF6), bg: Color(0xFFF5F3FF),
    labelColor: Color(0xFF6D28D9), badgeBg: Color(0xFFEDE9FE), badgeFg: Color(0xFF6D28D9),
    icon: '🗓',
  ),
  'later': _SectionAccent(
    stripe: Color(0xFF94A3B8), bg: Color(0xFFF8FAFC),
    labelColor: Color(0xFF475569), badgeBg: Color(0xFFE2E8F0), badgeFg: Color(0xFF475569),
    icon: '⏳',
  ),
  'done': _SectionAccent(
    stripe: Color(0xFF22C55E), bg: Color(0xFFF0FDF4),
    labelColor: Color(0xFF15803D), badgeBg: Color(0xFFDCFCE7), badgeFg: Color(0xFF15803D),
    icon: '✅',
  ),
  'no_date': _SectionAccent(
    stripe: Color(0xFF94A3B8), bg: Color(0xFFF8FAFC),
    labelColor: Color(0xFF64748B), badgeBg: Color(0xFFE2E8F0), badgeFg: Color(0xFF64748B),
    icon: '📌',
  ),
};

const _kSectionAccentsDark = <String, _SectionAccent>{
  'overdue': _SectionAccent(
    stripe: Color(0xFFEF4444), bg: Color(0x1ADC2626),
    labelColor: Color(0xFFFCA5A5), badgeBg: Color(0x26DC2626), badgeFg: Color(0xFFFCA5A5),
    icon: '🔥',
  ),
  'today': _SectionAccent(
    stripe: Color(0xFFF97316), bg: Color(0x1AF97316),
    labelColor: Color(0xFFFDBA74), badgeBg: Color(0x26F97316), badgeFg: Color(0xFFFDBA74),
    icon: '🔥',
  ),
  'tomorrow': _SectionAccent(
    stripe: Color(0xFFF59E0B), bg: Color(0x1AF59E0B),
    labelColor: Color(0xFFFDE68A), badgeBg: Color(0x26F59E0B), badgeFg: Color(0xFFFDE68A),
    icon: '📅',
  ),
  'this_week': _SectionAccent(
    stripe: Color(0xFF3B82F6), bg: Color(0x1A3B82F6),
    labelColor: Color(0xFF93C5FD), badgeBg: Color(0x263B82F6), badgeFg: Color(0xFF93C5FD),
    icon: '📆',
  ),
  'next_week': _SectionAccent(
    stripe: Color(0xFF8B5CF6), bg: Color(0x1A8B5CF6),
    labelColor: Color(0xFFC4B5FD), badgeBg: Color(0x268B5CF6), badgeFg: Color(0xFFC4B5FD),
    icon: '🗓',
  ),
  'later': _SectionAccent(
    stripe: Color(0xFF94A3B8), bg: Color(0xFF1E293B),
    labelColor: Color(0xFF94A3B8), badgeBg: Color(0xFF334155), badgeFg: Color(0xFF94A3B8),
    icon: '⏳',
  ),
  'done': _SectionAccent(
    stripe: Color(0xFF22C55E), bg: Color(0x1A22C55E),
    labelColor: Color(0xFF86EFAC), badgeBg: Color(0x2622C55E), badgeFg: Color(0xFF86EFAC),
    icon: '✅',
  ),
  'no_date': _SectionAccent(
    stripe: Color(0xFF94A3B8), bg: Color(0xFF1E293B),
    labelColor: Color(0xFF64748B), badgeBg: Color(0xFF334155), badgeFg: Color(0xFF64748B),
    icon: '📌',
  ),
};

_SectionAccent _accentFor(BuildContext context, String key) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final map = isDark ? _kSectionAccentsDark : _kSectionAccents;
  return map[key] ?? map['later']!;
}

// ── Section header widget ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.sectionKey,
    required this.label,
    required this.count,
    required this.isExpanded,
    required this.onTap,
  });

  final String sectionKey;
  final String label;
  final int count;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(context, sectionKey);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accent.bg,
          borderRadius: isExpanded
              ? const BorderRadius.vertical(top: Radius.circular(10))
              : BorderRadius.circular(10),
          border: Border.all(color: AppColors.of(context).divider),
          // left priority stripe
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: accent.stripe,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(accent.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w700,
                color: accent.labelColor,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accent.badgeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent.badgeFg,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: accent.labelColor,
            ),
          ],
        ),
      ),
    );
  }
}

