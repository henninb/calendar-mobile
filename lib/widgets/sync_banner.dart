import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/providers.dart';

class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final syncState = ref.watch(syncStateProvider);

    if (!isOnline) {
      final isForcedOffline = ref.watch(forcedOfflineProvider);
      if (isForcedOffline) {
        return _Banner(
          color: AppColors.skippedBg,
          iconColor: AppColors.skippedFg,
          textColor: AppColors.skippedFg,
          icon: Icons.cloud_off_rounded,
          text: 'Offline mode enabled — sync paused',
        );
      }
      return _Banner(
        color: AppColors.offlineBanner,
        iconColor: AppColors.offlineFg,
        textColor: AppColors.offlineFg,
        icon: Icons.wifi_off_rounded,
        text: 'Offline — changes will sync when connection is restored',
      );
    }

    if (syncState.phase == SyncPhase.pulling || syncState.phase == SyncPhase.pushing) {
      return _Banner(
        color: AppColors.pendingBanner,
        iconColor: AppColors.pendingFg,
        textColor: AppColors.pendingFg,
        icon: Icons.sync_rounded,
        text: syncState.phase == SyncPhase.pushing ? 'Pushing changes…' : 'Refreshing data…',
        spinning: true,
      );
    }

    if (syncState.phase == SyncPhase.error) {
      return _Banner(
        color: AppColors.overdueBg,
        iconColor: AppColors.overdueFg,
        textColor: AppColors.overdueFg,
        icon: Icons.error_outline_rounded,
        text: syncState.errorMessage ?? 'Sync error',
        onDismiss: () => ref.read(syncStateProvider.notifier).clearError(),
      );
    }

    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.iconColor,
    required this.textColor,
    required this.icon,
    required this.text,
    this.spinning = false,
    this.onDismiss,
  });

  final Color color;
  final Color iconColor;
  final Color textColor;
  final IconData icon;
  final String text;
  final bool spinning;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color,
      child: Row(
        children: [
          spinning
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: iconColor,
                  ),
                )
              : Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, size: 14, color: iconColor),
            ),
        ],
      ),
    );
  }
}
