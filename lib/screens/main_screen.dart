import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/extensions/date_extensions.dart';
import '../core/theme.dart';
import '../widgets/sheet_handle.dart';
import '../providers/providers.dart';
import '../services/wireguard_service.dart';
import '../widgets/sync_banner.dart';
import 'calendar_screen.dart';
import 'occurrence_list_screen.dart';
import 'task_list_screen.dart';
import 'credit_card_screen.dart';
import 'grocery_screen.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _tabIndex = 0;

  static const _tabs = [
    _Tab(icon: Icons.check_circle_outline,    activeIcon: Icons.check_circle,    label: 'Tasks'),
    _Tab(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month,  label: 'Calendar'),
    _Tab(icon: Icons.list_alt_outlined,       activeIcon: Icons.list_alt,        label: 'Upcoming'),
    _Tab(icon: Icons.credit_card_outlined,    activeIcon: Icons.credit_card,     label: 'Cards'),
    _Tab(icon: Icons.shopping_cart_outlined,  activeIcon: Icons.shopping_cart,   label: 'Grocery'),
    _Tab(icon: Icons.settings_outlined,       activeIcon: Icons.settings,        label: 'Settings'),
  ];

  static const _titles = [
    'Tasks',
    'Calendar',
    'Upcoming',
    'Credit Cards',
    'Grocery',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    // Initial silent refresh when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncStateProvider.notifier).silentRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.calendar_month, size: 18, color: Colors.white70),
            const SizedBox(width: 8),
            Text(_titles[_tabIndex]),
          ],
        ),
        actions: [
          if (_tabIndex == 0)
            const _TaskSearchButton(),
          if (_tabIndex == 1) ...[
            const _NewEventButton(),
            const _GenerateButton(),
          ],
          const _OfflineToggleButton(),
          const _SyncButton(),
        ],
      ),
      body: Column(
        children: [
          const SyncBanner(),
          Expanded(child: _body()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: _tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  activeIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }

  Widget _body() {
    return switch (_tabIndex) {
      0 => const TaskListScreen(),
      1 => const CalendarScreen(),
      2 => const OccurrenceListScreen(),
      3 => const CreditCardScreen(),
      4 => const GroceryScreen(),
      5 => const SettingsScreen(),
      _ => const SizedBox.shrink(),
    };
  }
}

class _TaskSearchButton extends ConsumerWidget {
  const _TaskSearchButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(taskSearchVisibleProvider);
    return IconButton(
      tooltip: visible ? 'Hide search' : 'Search tasks',
      icon: Icon(
        visible ? Icons.search_off : Icons.search,
        color: visible ? Colors.white : Colors.white70,
      ),
      onPressed: () => ref.read(taskSearchVisibleProvider.notifier).toggle(),
    );
  }
}

class _GenerateButton extends ConsumerStatefulWidget {
  const _GenerateButton();

  @override
  ConsumerState<_GenerateButton> createState() => _GenerateButtonState();
}

class _GenerateButtonState extends ConsumerState<_GenerateButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    return TextButton.icon(
      onPressed: isOnline && !_loading ? _generate : null,
      icon: _loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
            )
          : const Icon(Icons.refresh_rounded, size: 16, color: Colors.white70),
      label: Text(
        _loading ? 'Generating…' : 'Generate',
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      ),
    );
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      await ref.read(apiClientProvider).generateAllOccurrences();
      await ref.read(syncStateProvider.notifier).silentRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Occurrences generated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate occurrences — check your connection')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }
}

class _OfflineToggleButton extends ConsumerWidget {
  const _OfflineToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forcedOffline = ref.watch(forcedOfflineProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return IconButton(
      tooltip: forcedOffline
          ? 'Offline mode on — tap to re-enable sync'
          : isOnline
              ? 'Connected — tap to force offline mode'
              : 'No network connection',
      icon: Icon(
        forcedOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
        color: forcedOffline
            ? Colors.orangeAccent
            : isOnline
                ? Colors.white70
                : Colors.white38,
      ),
      onPressed: () {
        final next = !forcedOffline;
        ref.read(forcedOfflineProvider.notifier).toggle();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next ? 'Offline mode enabled' : 'Offline mode disabled'),
            duration: const Duration(seconds: 2),
          ),
        );
        toggleWireGuardTunnel(goOffline: next, context: context);
      },
    );
  }
}

class _SyncButton extends ConsumerWidget {
  const _SyncButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    final isOnline  = ref.watch(isOnlineProvider);
    // Only pulling/pushing are active work — offline and error are terminal
    // states that should not keep the spinner running.
    final busy = syncState.phase == SyncPhase.pulling || syncState.phase == SyncPhase.pushing;

    return IconButton(
      tooltip: busy ? 'Syncing…' : 'Sync now',
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
            )
          : Icon(
              Icons.sync_rounded,
              color: isOnline ? Colors.white : Colors.white38,
            ),
      onPressed: isOnline && !busy
          ? () => ref.read(syncStateProvider.notifier).sync()
          : null,
    );
  }
}

class _Tab {
  const _Tab({required this.icon, required this.activeIcon, required this.label});

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

// ── New Event Button ──────────────────────────────────────────────────────────

class _NewEventButton extends StatelessWidget {
  const _NewEventButton();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => const _EventFormSheet(),
      ),
      icon: const Icon(Icons.add, size: 16, color: Colors.white70),
      label: const Text(
        'New Event',
        style: TextStyle(fontSize: 12, color: Colors.white70),
      ),
    );
  }
}

// ── Event Creation Form ───────────────────────────────────────────────────────

class _EventFormSheet extends ConsumerStatefulWidget {
  const _EventFormSheet();

  @override
  ConsumerState<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends ConsumerState<_EventFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  int? _categoryServerId;
  String _dtstart = _todayStr();
  int _durationDays = 1;
  String _rrule = '';
  String _dtendRule = '';
  bool _saving = false;

  static const _rruleOptions = [
    ('', 'One-time'),
    ('FREQ=DAILY', 'Daily'),
    ('FREQ=WEEKLY', 'Weekly'),
    ('FREQ=WEEKLY;INTERVAL=2', 'Biweekly'),
    ('FREQ=MONTHLY', 'Monthly'),
    ('FREQ=MONTHLY;INTERVAL=3', 'Every 3 Months'),
    ('FREQ=MONTHLY;INTERVAL=6', 'Every 6 Months'),
    ('FREQ=YEARLY', 'Yearly'),
  ];

  static String _todayStr() => DateTime.now().toIso8601DateString();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecurring = _rrule.isNotEmpty;

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
              const SheetHandle(),
              Text('New Event', style: AppText.heading),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title *'),
                maxLength: 255,
                autofocus: true,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              ref.watch(categoriesProvider).when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (cats) => DropdownButtonFormField<int?>(
                  initialValue: _categoryServerId,
                  decoration: const InputDecoration(labelText: 'Category *'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select…')),
                    ...cats.map((c) => DropdownMenuItem(
                          value: c.serverId,
                          child: Text('${c.icon} ${c.name}'),
                        )),
                  ],
                  validator: (v) => v == null ? 'Required' : null,
                  onChanged: (v) => setState(() => _categoryServerId = v),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(_dtstart) ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _dtstart = picked.toIso8601DateString());
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Start Date *'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_dtstart, style: AppText.body),
                            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: _durationDays.toString(),
                      decoration: const InputDecoration(labelText: 'Duration (days)'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null && n >= 1) setState(() => _durationDays = n);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _rrule,
                decoration: const InputDecoration(labelText: 'Recurrence'),
                items: _rruleOptions
                    .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _rrule = v ?? '';
                  if (_rrule.isEmpty) _dtendRule = '';
                }),
              ),
              if (isRecurring) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dtendRule.isNotEmpty
                          ? (DateTime.tryParse(_dtendRule) ?? DateTime.now().add(const Duration(days: 365)))
                          : DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _dtendRule = picked.toIso8601DateString());
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Repeat Until (optional)'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dtendRule.isEmpty ? 'No end date' : _dtendRule,
                          style: AppText.body.copyWith(
                            color: _dtendRule.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
                          ),
                        ),
                        const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
                maxLength: 2000,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount (\$)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(_saving ? 'Creating…' : 'Create Event'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final syncNotifier = ref.read(syncStateProvider.notifier);
    final desc   = _descCtrl.text.trim();
    final amount = _amountCtrl.text.trim();
    final payload = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'category_id': _categoryServerId,
      'dtstart': _dtstart,
      'duration_days': _durationDays,
      if (_rrule.isNotEmpty) 'rrule': _rrule,
      if (_dtendRule.isNotEmpty) 'dtend_rule': _dtendRule,
      if (desc.isNotEmpty) 'description': desc,
      if (amount.isNotEmpty) 'amount': amount,
    };

    try {
      await ref.read(apiClientProvider).createEvent(payload);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) Navigator.pop(context);
        await syncNotifier.silentRefresh();
      });
    } catch (e, st) {
      dev.log('_EventFormSheet._save: $e', name: 'events', level: 900, stackTrace: st);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event — $e')),
        );
      }
    }
  }
}
