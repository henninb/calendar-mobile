import 'package:calendar_mobile/providers/providers.dart';
import 'package:calendar_mobile/core/theme.dart';
import 'package:calendar_mobile/widgets/sync_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StaticConnectivityNotifier extends ConnectivityNotifier {
  _StaticConnectivityNotifier(this.value);

  final bool value;

  @override
  bool build() => value;
}

class _StaticForcedOfflineNotifier extends ForcedOfflineNotifier {
  _StaticForcedOfflineNotifier(this.value);

  final bool value;

  @override
  bool build() => value;
}

class _TestSyncNotifier extends SyncNotifier {
  _TestSyncNotifier(this.initialState);

  final SyncState initialState;

  @override
  SyncState build() => initialState;
}

Widget _wrap({
  required bool isOnline,
  required bool forcedOffline,
  required SyncState syncState,
}) {
  return ProviderScope(
    overrides: [
      isOnlineProvider.overrideWith(() => _StaticConnectivityNotifier(isOnline)),
      forcedOfflineProvider.overrideWith(
        () => _StaticForcedOfflineNotifier(forcedOffline),
      ),
      syncStateProvider.overrideWith(() => _TestSyncNotifier(syncState)),
    ],
    child: MaterialApp(
      theme: buildAppTheme(),
      home: const Scaffold(
        body: SyncBanner(),
      ),
    ),
  );
}

void main() {
  group('SyncBanner', () {
    testWidgets('shows forced offline banner when offline mode is enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          isOnline: false,
          forcedOffline: true,
          syncState: const SyncState(),
        ),
      );

      expect(find.text('Offline mode enabled — sync paused'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, AppColors.light.skippedBg);
    });

    testWidgets('shows connectivity offline banner when network is down', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          isOnline: false,
          forcedOffline: false,
          syncState: const SyncState(),
        ),
      );

      expect(
        find.text('Offline — changes will sync when connection is restored'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, AppColors.light.offlineBanner);
    });

    testWidgets('shows refreshing banner while pulling', (tester) async {
      await tester.pumpWidget(
        _wrap(
          isOnline: true,
          forcedOffline: false,
          syncState: const SyncState(phase: SyncPhase.pulling),
        ),
      );

      expect(find.text('Refreshing data…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('shows pushing banner while pushing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          isOnline: true,
          forcedOffline: false,
          syncState: const SyncState(phase: SyncPhase.pushing),
        ),
      );

      expect(find.text('Pushing changes…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('shows dismissible error banner and clears error on tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          isOnline: true,
          forcedOffline: false,
          syncState: const SyncState(
            phase: SyncPhase.error,
            errorMessage: 'Sync failed',
          ),
        ),
      );

      expect(find.text('Sync failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.text('Sync failed'), findsNothing);
    });

    testWidgets('falls back to default error text when message is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          isOnline: true,
          forcedOffline: false,
          syncState: const SyncState(phase: SyncPhase.error),
        ),
      );

      expect(find.text('Sync error'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('renders nothing when online and idle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          isOnline: true,
          forcedOffline: false,
          syncState: const SyncState(),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Offline'), findsNothing);
    });
  });
}
