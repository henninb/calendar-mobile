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
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tasks) {
        final categories = categoriesAsync.value ?? [];
        final catMap = {for (final c in categories) c.serverId: c};

        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        var filtered = tasks.where((t) {
          if (t.syncStatus == SyncStatus.pendingDelete.value) return false;
          if (t.dueDate == null) return true;
          if (t.dueDate!.compareTo(todayStr) >= 0) return true;
          // Past due: only show if not completed
          return t.status != 'done' && t.status != 'cancelled';
        }).toList();
        if (_filterStatus != 'all') {
          filtered = filtered.where((t) => t.status == _filterStatus).toList();
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
  const _StatusFilter({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  static const _options = ['all', 'todo', 'in_progress', 'done', 'cancelled'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: AppColors.tableHeader,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: _options.map((s) {
          final active = selected == s;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onChanged(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  s == 'all' ? 'All' : s.replaceAll('_', ' ').toUpperCase().split(' ').map((w) => w[0] + w.substring(1).toLowerCase()).join(' '),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TaskCard extends ConsumerStatefulWidget {
  const _TaskCard({super.key, required this.task, required this.catMap});

  final Task task;
  final Map<int?, Category> catMap;

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
    await ref.read(dbProvider).insertSubtask(SubtasksCompanion(
      taskLocalId: Value(task.id),
      taskServerId: Value(task.serverId),
      title: Value(title),
      syncStatus: Value(SyncStatus.pendingCreate.value),
    ));
    if (ref.read(isOnlineProvider)) {
      ref.read(syncStateProvider.notifier).sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final cat = widget.catMap[task.categoryServerId];

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final isActive = task.status != 'done' && task.status != 'cancelled';
    final isDueToday = task.dueDate == todayStr;
    final isOverdue = task.dueDate != null && task.dueDate!.compareTo(todayStr) < 0;
    final highlight = isActive && (isDueToday || isOverdue);

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
              Row(
                children: [
                  PriorityBadge(task.priority),
                  if (cat != null) ...[
                    const SizedBox(width: 6),
                    CategoryBadge(name: cat.name, color: cat.color, icon: cat.icon),
                  ],
                  if (task.dueDate != null) ...[
                    const SizedBox(width: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(task.dueDate!, style: AppText.label),
                        if (isActive && isDueToday) ...[
                          const SizedBox(width: 4),
                          const Text('today', style: TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
                        ] else if (isActive && isOverdue) ...[
                          const SizedBox(width: 4),
                          const Text('overdue', style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ],
                  if (task.syncStatus != SyncStatus.synced.value) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.cloud_upload_outlined, size: 12, color: AppColors.textMuted),
                  ],
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
              await ref.read(dbProvider).updateSubtask(
                subtask.id,
                SubtasksCompanion(
                  status: Value(newStatus),
                  syncStatus: Value(SyncStatus.pendingUpdate.value),
                ),
              );
              if (ref.read(isOnlineProvider)) {
                ref.read(syncStateProvider.notifier).sync();
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

class _QuickStatusRow extends ConsumerWidget {
  const _QuickStatusRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(dbProvider);

    Future<void> setStatus(String s) async {
      await db.updateTask(
        task.id,
        TasksCompanion(
          status: Value(s),
          updatedAt: Value(DateTime.now().toIso8601String()),
          syncStatus: Value(SyncStatus.pendingUpdate.value),
        ),
      );
      if (ref.read(isOnlineProvider)) {
        ref.read(syncStateProvider.notifier).sync();
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
      if (confirmed != true) return;
      await db.markTaskDeleted(task.id);
      if (ref.read(isOnlineProvider)) {
        ref.read(syncStateProvider.notifier).sync();
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
                      _TaskEditForm(task: _task, onSaved: (t) => setState(() { _task = t; _editing = false; }))
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
                      error: (e, _) => Text('$e', style: AppText.small),
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
              final db = ref.read(dbProvider);
              final localTask = await db.getTasks().then(
                    (ts) => ts.firstWhere((t) => t.id == _task.id),
                  );
              await db.insertSubtask(SubtasksCompanion(
                taskLocalId: Value(_task.id),
                taskServerId: Value(localTask.serverId),
                title: Value(ctrl.text.trim()),
                syncStatus: Value(SyncStatus.pendingCreate.value),
              ));
              if (mounted) Navigator.pop(context);
              if (ref.read(isOnlineProvider)) {
                ref.read(syncStateProvider.notifier).sync();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
    await ref.read(dbProvider).markTaskDeleted(_task.id);
    if (mounted) Navigator.pop(context);
    if (ref.read(isOnlineProvider)) {
      ref.read(syncStateProvider.notifier).sync();
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
              await ref.read(dbProvider).updateSubtask(
                subtask.id,
                SubtasksCompanion(
                  status: Value(newStatus),
                  syncStatus: Value(SyncStatus.pendingUpdate.value),
                ),
              );
              if (ref.read(isOnlineProvider)) {
                ref.read(syncStateProvider.notifier).sync();
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
              await ref.read(dbProvider).markSubtaskDeleted(subtask.id);
              if (ref.read(isOnlineProvider)) {
                ref.read(syncStateProvider.notifier).sync();
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
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: _priorities.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _recurrence,
              decoration: const InputDecoration(labelText: 'Recurrence'),
              items: _recurrences.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _recurrence = v!),
            ),
            const SizedBox(height: 10),
            // Due date picker
            FormField<String>(
              initialValue: _dueDate,
              validator: (_) => _dueDate == null ? 'Required' : null,
              builder: (field) => InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(_dueDate!) ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked.toIso8601String().substring(0, 10));
                    field.didChange(_dueDate);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Due Date *',
                    errorText: field.errorText,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_dueDate!, style: AppText.body),
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Category dropdown
            ref.watch(categoriesProvider).when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (cats) => DropdownButtonFormField<int?>(
                value: _categoryServerId,
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
              error: (_, __) => const SizedBox.shrink(),
              data: (persons) => DropdownButtonFormField<int?>(
                value: _assigneeServerId,
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
    final now = DateTime.now().toIso8601String();

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

    if (mounted) Navigator.pop(context);
    if (ref.read(isOnlineProvider)) {
      ref.read(syncStateProvider.notifier).sync();
    }
  }
}

class _TaskEditForm extends ConsumerWidget {
  const _TaskEditForm({required this.task, required this.onSaved});

  final Task task;
  final ValueChanged<Task> onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _TaskForm(existing: task);
  }
}
