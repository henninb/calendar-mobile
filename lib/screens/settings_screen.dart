import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlCtrl;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: ref.read(baseUrlProvider));
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncStateProvider);
    final isOnline  = ref.watch(isOnlineProvider);
    final connectivity = ref.watch(connectivityProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Connection ─────────────────────────────────────────────────────────
        _Section(
          title: 'Backend Connection',
          children: [
            TextFormField(
              controller: _urlCtrl,
              decoration: InputDecoration(
                labelText: 'Base URL',
                hintText: AppConstants.defaultBaseUrl,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save_outlined, color: AppColors.primary),
                  onPressed: _saveUrl,
                ),
              ),
              onChanged: (_) => setState(() => _saved = false),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
            if (_saved)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Saved!', style: TextStyle(color: AppColors.completedFg, fontSize: 12)),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? AppColors.btnGreen : AppColors.btnRed,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: AppText.small.copyWith(
                    color: isOnline ? AppColors.completedFg : AppColors.overdueFg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                if (!isOnline)
                  Text(
                    connectivity.valueOrNull?.map((r) => r.name).join(', ') ?? 'checking…',
                    style: AppText.small,
                  ),
              ],
            ),
            if (!isOnline) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openWireGuard(context),
                  icon: const Icon(Icons.vpn_lock_rounded, size: 16),
                  label: const Text('Open WireGuard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.overdueFg,
                    side: BorderSide(color: AppColors.overdueFg.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
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
                            ? AppColors.overdueFg
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (syncState.errorMessage != null)
                      Text(syncState.errorMessage!, style: AppText.small.copyWith(color: AppColors.overdueFg)),
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
            _InfoRow(label: 'App', value: 'Calendar Mobile v1.0.0'),
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
      // Launch WireGuard by package name via Android intent
      uri = Uri.parse(
        'intent:#Intent;action=android.intent.action.MAIN;'
        'category=android.intent.category.LAUNCHER;'
        'package=com.wireguard.android;end',
      );
    } else if (Platform.isIOS) {
      uri = Uri.parse('wireguard://');
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

  void _saveUrl() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    ref.read(baseUrlProvider.notifier).set(url);
    // Update the API client
    ref.read(apiClientProvider).updateBaseUrl(url);
    setState(() => _saved = true);
  }

  static String _phaseLabel(SyncPhase p) => switch (p) {
        SyncPhase.idle    => 'Idle',
        SyncPhase.pushing => 'Pushing changes…',
        SyncPhase.pulling => 'Pulling data…',
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
