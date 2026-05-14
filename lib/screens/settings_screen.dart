import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../providers/providers.dart';
import '../services/wireguard_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _wireGuardAndroidUri =
      'intent:#Intent;action=android.intent.action.MAIN;'
      'category=android.intent.category.LAUNCHER;'
      'package=com.wireguard.android;end';
  static const _wireGuardIosUri = 'wireguard://';
  late TextEditingController _urlCtrl;
  late TextEditingController _keyCtrl;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: ref.read(baseUrlProvider));
    _keyCtrl = TextEditingController(text: ref.read(apiKeyProvider));
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncState     = ref.watch(syncStateProvider);
    final isOnline      = ref.watch(isOnlineProvider);
    final forcedOffline = ref.watch(forcedOfflineProvider);
    final connectivity  = ref.watch(connectivityProvider);
    final themeMode     = ref.watch(themeModeProvider);
    final colors        = AppColors.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Appearance ────────────────────────────────────────────────────────
        _Section(
          title: 'Appearance',
          children: [
            const Text('Theme', style: AppText.subheading),
            const SizedBox(height: 10),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined, size: 16),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (Set<ThemeMode> s) {
                if (s.isNotEmpty) {
                  ref.read(themeModeProvider.notifier).set(s.first);
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Connection ─────────────────────────────────────────────────────────
        _Section(
          title: 'Backend Connection',
          children: [
            TextFormField(
              controller: _urlCtrl,
              decoration: InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://your-backend.example.com',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save_outlined, color: AppColors.primary),
                  onPressed: _saveUrl,
                ),
              ),
              onChanged: (_) => setState(() => _saved = false),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _keyCtrl,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'Leave empty if backend has no key set',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save_outlined, color: AppColors.primary),
                  onPressed: _saveKey,
                ),
              ),
              onChanged: (_) => setState(() => _saved = false),
              obscureText: true,
              autocorrect: false,
            ),
            if (_saved)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Saved!',
                  style: TextStyle(color: colors.completedFg, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline
                        ? AppColors.btnGreen
                        : forcedOffline
                            ? AppColors.ccSoon
                            : AppColors.btnRed,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline
                      ? 'Online'
                      : forcedOffline
                          ? 'Offline mode (sync paused)'
                          : 'Offline',
                  style: AppText.small.copyWith(
                    color: isOnline
                        ? colors.completedFg
                        : forcedOffline
                            ? AppColors.ccSoon
                            : colors.overdueFg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                if (!isOnline && !forcedOffline)
                  Text(
                    connectivity.value?.map((r) => r.name).join(', ') ?? 'checking…',
                    style: AppText.small,
                  ),
              ],
            ),
            if (!isOnline && !forcedOffline) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openWireGuard(context),
                  icon: const Icon(Icons.vpn_lock_rounded, size: 16),
                  label: const Text('Open WireGuard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.overdueFg,
                    side: BorderSide(color: colors.overdueFg.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Force offline mode'),
              subtitle: Text('Pause sync and disconnect WireGuard tunnel "$wgTunnelName"'),
              value: forcedOffline,
              onChanged: (val) async {
                ref.read(forcedOfflineProvider.notifier).toggle();
                final ok = await toggleWireGuardTunnel(goOffline: val, context: context);
                if (!ok && context.mounted) {
                  ref.read(forcedOfflineProvider.notifier).toggle();
                }
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            if (Platform.isAndroid) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 13, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Requires WireGuard → Settings → "Allow remote control apps" to be enabled.',
                      style: AppText.small.copyWith(color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),

        // ── Sync ──────────────────────────────────────────────────────────────
        _Section(
          title: 'Sync',
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sync status', style: AppText.subheading),
                    Text(
                      _phaseLabel(syncState.phase),
                      style: AppText.small.copyWith(
                        color: syncState.phase == SyncPhase.error
                            ? colors.overdueFg
                            : colors.textSecondary,
                      ),
                    ),
                    if (syncState.errorMessage != null)
                      Text(
                        syncState.errorMessage!,
                        style: AppText.small.copyWith(color: colors.overdueFg),
                      ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: isOnline && syncState.phase == SyncPhase.idle
                      ? () => ref.read(syncStateProvider.notifier).sync()
                      : null,
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Sync Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Data ──────────────────────────────────────────────────────────────
        _Section(
          title: 'Data',
          children: [
            _ActionRow(
              label: 'Refresh all data from server',
              description: 'Pulls the latest occurrences, tasks, and credit cards.',
              buttonLabel: 'Refresh',
              buttonColor: AppColors.btnBlue,
              enabled: isOnline,
              onTap: () => ref.read(syncStateProvider.notifier).sync(),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── About ─────────────────────────────────────────────────────────────
        _Section(
          title: 'About',
          children: [
            _InfoRow(
              label: 'App',
              value: ref.watch(packageInfoProvider).when(
                data: (info) => 'Calendar Mobile v${info.version}+${info.buildNumber}',
                loading: () => 'Calendar Mobile',
                error: (err, st) => 'Calendar Mobile',
              ),
            ),
            _InfoRow(label: 'Backend', value: ref.watch(baseUrlProvider)),
            _InfoRow(label: 'Offline support', value: 'Full CRUD with sync queue'),
          ],
        ),
      ],
    );
  }

  Future<void> _openWireGuard(BuildContext context) async {
    Uri uri;
    if (Platform.isAndroid) {
      uri = Uri.parse(_wireGuardAndroidUri);
    } else if (Platform.isIOS) {
      uri = Uri.parse(_wireGuardIosUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please open WireGuard manually to establish a VPN connection')),
        );
      }
      return;
    }

    final launched = await canLaunchUrl(uri) && await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WireGuard not found — please install or open it manually')),
      );
    }
  }

  Future<void> _saveKey() async {
    await ref.read(apiKeyProvider.notifier).set(_keyCtrl.text.trim());
    if (mounted) setState(() => _saved = true);
  }

  void _saveUrl() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    final accepted = ref.read(baseUrlProvider.notifier).set(url);
    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL — must start with https://')),
      );
      return;
    }
    setState(() => _saved = true);
  }

  static String _phaseLabel(SyncPhase p) => switch (p) {
        SyncPhase.idle    => 'Idle',
        SyncPhase.pushing => 'Pushing changes…',
        SyncPhase.pulling => 'Pulling data…',
        SyncPhase.offline => 'Offline — sync suppressed',
        SyncPhase.error   => 'Error',
      };
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.heading),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.description,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String description;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.subheading),
              Text(description, style: AppText.small),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
          child: Text(buttonLabel),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppText.label),
          ),
          Expanded(child: Text(value, style: AppText.small)),
        ],
      ),
    );
  }
}
