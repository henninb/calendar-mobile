import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../widgets/sync_banner.dart';
import 'calendar_screen.dart';
import 'occurrence_list_screen.dart';
import 'task_list_screen.dart';
import 'credit_card_screen.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _tabIndex = 0;

  static const _tabs = [
    _Tab(icon: Icons.check_circle_outline,      activeIcon: Icons.check_circle,     label: 'Tasks'),
    _Tab(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Calendar'),
    _Tab(icon: Icons.list_alt_outlined,        activeIcon: Icons.list_alt,        label: 'Upcoming'),
    _Tab(icon: Icons.credit_card_outlined,      activeIcon: Icons.credit_card,      label: 'Cards'),
    _Tab(icon: Icons.settings_outlined,         activeIcon: Icons.settings,         label: 'Settings'),
  ];

  static const _titles = [
    'Tasks',
    'Calendar',
    'Upcoming',
    'Credit Cards',
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
          if (_tabIndex == 1)
            _GenerateButton(),
          _OfflineToggleButton(),
          _SyncButton(),
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
      4 => const SettingsScreen(),
      _ => const SizedBox.shrink(),
    };
  }
}

class _GenerateButton extends ConsumerStatefulWidget {
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
          SnackBar(content: Text('Generate failed: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }
}

class _OfflineToggleButton extends ConsumerWidget {
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
        ref.read(forcedOfflineProvider.notifier).toggle();
        final next = !forcedOffline;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next ? 'Offline mode enabled — sync paused' : 'Offline mode disabled — sync resumed',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}

class _SyncButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    final isOnline  = ref.watch(isOnlineProvider);
    final busy      = syncState.phase != SyncPhase.idle;

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
