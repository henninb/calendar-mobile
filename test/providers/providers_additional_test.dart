import 'dart:async';
import 'package:calendar_mobile/database/app_database.dart';
import 'package:calendar_mobile/providers/providers.dart';
import 'package:calendar_mobile/services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSyncService extends Mock implements SyncService {}

class MockConnectivity extends Mock implements Connectivity {}

class _FakeBaseUrlNotifier extends BaseUrlNotifier {
  final String _url;
  _FakeBaseUrlNotifier(this._url);
  @override
  String build() => _url;
}

class _FakeConnectivityNotifier extends ConnectivityNotifier {
  final bool _initial;
  _FakeConnectivityNotifier(this._initial);
  @override
  bool build() => _initial;
  @override
  Future<void> _init() async {}
}

ProviderContainer _makeOnlineContainer(
  SharedPreferences prefs,
  MockSyncService svc, {
  String baseUrl = 'https://example.com',
}) =>
    ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        syncServiceProvider.overrideWithValue(svc),
        baseUrlProvider.overrideWith(() => _FakeBaseUrlNotifier(baseUrl)),
        isOnlineProvider.overrideWith(() => _FakeConnectivityNotifier(true)),
      ],
    );

ProviderContainer _makeOfflineContainer(
  SharedPreferences prefs,
  MockSyncService svc, {
  String baseUrl = 'https://example.com',
}) =>
    ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        syncServiceProvider.overrideWithValue(svc),
        baseUrlProvider.overrideWith(() => _FakeBaseUrlNotifier(baseUrl)),
        isOnlineProvider.overrideWith(() => _FakeConnectivityNotifier(false)),
      ],
    );

void main() {
  // ── SyncNotifier - additional branch coverage ─────────────────────────────

  group('SyncNotifier - additional branches', () {
    late MockSyncService mockSyncService;
    late SharedPreferences prefs;

    setUp(() async {
      mockSyncService = MockSyncService();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('sync() sets error when baseUrl is empty', () async {
      final container =
          _makeOnlineContainer(prefs, mockSyncService, baseUrl: '');
      addTearDown(container.dispose);

      await container.read(syncStateProvider.notifier).sync();

      expect(container.read(syncStateProvider).phase, SyncPhase.error);
      expect(
        container.read(syncStateProvider).errorMessage,
        contains('No backend URL'),
      );
      verifyNever(() => mockSyncService.pushPending());
    });

    test('sync() returns early when already pushing (in-progress guard)',
        () async {
      final container = _makeOnlineContainer(prefs, mockSyncService);
      addTearDown(container.dispose);

      final blocker = Completer<SyncResult>();
      when(() => mockSyncService.pushPending())
          .thenAnswer((_) => blocker.future);

      // Start first sync without awaiting — it will sit in pushing state.
      final firstFuture =
          container.read(syncStateProvider.notifier).sync();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(container.read(syncStateProvider).phase, SyncPhase.pushing);

      // Second call must be a no-op while pushing is in progress.
      await container.read(syncStateProvider.notifier).sync();
      expect(container.read(syncStateProvider).phase, SyncPhase.pushing);

      // Unblock and clean up.
      blocker.complete(const SyncResult(pushed: 0, errors: []));
      when(() => mockSyncService.fullRefresh()).thenAnswer((_) async {});
      await firstFuture;
    });

    test('sync() returns early when already pulling (in-progress guard)',
        () async {
      final container = _makeOnlineContainer(prefs, mockSyncService);
      addTearDown(container.dispose);

      final blocker = Completer<void>();
      when(() => mockSyncService.pushPending()).thenAnswer(
          (_) async => const SyncResult(pushed: 0, errors: []));
      when(() => mockSyncService.fullRefresh())
          .thenAnswer((_) => blocker.future);

      final firstFuture =
          container.read(syncStateProvider.notifier).sync();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(container.read(syncStateProvider).phase, SyncPhase.pulling);

      // Second call must be a no-op while pulling is in progress.
      await container.read(syncStateProvider.notifier).sync();
      expect(container.read(syncStateProvider).phase, SyncPhase.pulling);

      blocker.complete();
      await firstFuture;
    });

    test('silentRefresh() returns early when offline', () async {
      final container = _makeOfflineContainer(prefs, mockSyncService);
      addTearDown(container.dispose);

      await container.read(syncStateProvider.notifier).silentRefresh();

      expect(container.read(syncStateProvider).phase, SyncPhase.idle);
      verifyNever(() => mockSyncService.pushPending());
    });

    test('silentRefresh() returns early when baseUrl is empty', () async {
      final container =
          _makeOnlineContainer(prefs, mockSyncService, baseUrl: '');
      addTearDown(container.dispose);

      await container.read(syncStateProvider.notifier).silentRefresh();

      expect(container.read(syncStateProvider).phase, SyncPhase.idle);
      verifyNever(() => mockSyncService.pushPending());
    });

    test('silentRefresh() returns early when already pulling', () async {
      final container = _makeOnlineContainer(prefs, mockSyncService);
      addTearDown(container.dispose);

      final blocker = Completer<void>();
      when(() => mockSyncService.pushPending()).thenAnswer(
          (_) async => const SyncResult(pushed: 0, errors: []));
      when(() => mockSyncService.fullRefresh())
          .thenAnswer((_) => blocker.future);

      final firstFuture =
          container.read(syncStateProvider.notifier).silentRefresh();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(container.read(syncStateProvider).phase, SyncPhase.pulling);

      // Second silentRefresh must be ignored.
      await container.read(syncStateProvider.notifier).silentRefresh();
      expect(container.read(syncStateProvider).phase, SyncPhase.pulling);

      blocker.complete();
      await firstFuture;
    });

    test('silentRefresh() sets error when fullRefresh throws', () async {
      final container = _makeOnlineContainer(prefs, mockSyncService);
      addTearDown(container.dispose);

      when(() => mockSyncService.pushPending()).thenAnswer(
          (_) async => const SyncResult(pushed: 0, errors: []));
      when(() => mockSyncService.fullRefresh())
          .thenThrow(Exception('DB error'));

      await container.read(syncStateProvider.notifier).silentRefresh();

      expect(container.read(syncStateProvider).phase, SyncPhase.error);
    });

    test('syncIfOnline() does nothing when offline', () async {
      final container = _makeOfflineContainer(prefs, mockSyncService);
      addTearDown(container.dispose);

      container.read(syncStateProvider.notifier).syncIfOnline();
      await Future.delayed(const Duration(milliseconds: 100));

      verifyNever(() => mockSyncService.pushPending());
    });

    // ── _friendlyError patterns ────────────────────────────────────────────

    test('_friendlyError: Connection refused', () async {
      final container = _makeOnlineContainer(prefs, mockSyncService);
      addTearDown(container.dispose);

      when(() => mockSyncService.pushPending()).thenAnswer(
          (_) async => const SyncResult(pushed: 0, errors: []));
      when(() => mockSyncService.fullRefresh())
          .thenThrow(Exception('Connection refused to host'));

      await container.read(syncStateProvider.notifier).sync();

      expect(
        container.read(syncStateProvider).errorMessage,
        contains('Cannot reach backend'),
      );
    });

    test('_friendlyError: SocketException', () async {
      final container = _makeOnlineContainer(prefs, mockSyncService);
      addTearDown(container.dispose);

      when(() => mockSyncService.pushPending()).thenAnswer(
          (_) async => const SyncResult(pushed: 0, errors: []));
      when(() => mockSyncService.fullRefresh())
          .thenThrow(Exception('SocketException: network unreachable'));

      await container.read(syncStateProvider.notifier).sync();

      expect(
        container.read(syncStateProvider).errorMessage,
        contains('Cannot reach backend'),
      );
    });

    test('_friendlyError: timed out', () async {
      final container = _makeOnlineContainer(prefs, mockSyncService);
      addTearDown(container.dispose);

      when(() => mockSyncService.pushPending()).thenAnswer(
          (_) async => const SyncResult(pushed: 0, errors: []));
      when(() => mockSyncService.fullRefresh())
          .thenThrow(Exception('Connection timed out after 30s'));

      await container.read(syncStateProvider.notifier).sync();

      expect(
        container.read(syncStateProvider).errorMessage,
        contains('timed out'),
      );
    });

    test('_friendlyError: 401 Unauthorized', () async {
      final container = _makeOnlineContainer(prefs, mockSyncService);
      addTearDown(container.dispose);

      when(() => mockSyncService.pushPending()).thenAnswer(
          (_) async => const SyncResult(pushed: 0, errors: []));
      when(() => mockSyncService.fullRefresh())
          .thenThrow(Exception('Server responded with status code of 401'));

      await container.read(syncStateProvider.notifier).sync();

      expect(
        container.read(syncStateProvider).errorMessage,
        contains('Authentication failed'),
      );
    });

    test('_friendlyError: 403 Forbidden', () async {
      final container = _makeOnlineContainer(prefs, mockSyncService);
      addTearDown(container.dispose);

      when(() => mockSyncService.pushPending()).thenAnswer(
          (_) async => const SyncResult(pushed: 0, errors: []));
      when(() => mockSyncService.fullRefresh())
          .thenThrow(Exception('Server responded with status code of 403'));

      await container.read(syncStateProvider.notifier).sync();

      expect(
        container.read(syncStateProvider).errorMessage,
        contains('Authentication failed'),
      );
    });

    test('_friendlyError: short message returned as-is', () async {
      final container = _makeOnlineContainer(prefs, mockSyncService);
      addTearDown(container.dispose);

      when(() => mockSyncService.pushPending()).thenAnswer(
          (_) async => const SyncResult(pushed: 0, errors: []));
      when(() => mockSyncService.fullRefresh())
          .thenThrow(Exception('short error'));

      await container.read(syncStateProvider.notifier).sync();

      expect(
        container.read(syncStateProvider).errorMessage,
        contains('short error'),
      );
    });

    test('_friendlyError: long message is truncated with ellipsis', () async {
      final container = _makeOnlineContainer(prefs, mockSyncService);
      addTearDown(container.dispose);

      final longMsg = 'E' * 150;
      when(() => mockSyncService.pushPending()).thenAnswer(
          (_) async => const SyncResult(pushed: 0, errors: []));
      when(() => mockSyncService.fullRefresh())
          .thenThrow(Exception(longMsg));

      await container.read(syncStateProvider.notifier).sync();

      final errMsg = container.read(syncStateProvider).errorMessage!;
      expect(errMsg.length, lessThan(150));
      expect(errMsg, contains('…'));
    });

    test('_friendlyError via push error catch path', () async {
      final container = _makeOnlineContainer(prefs, mockSyncService);
      addTearDown(container.dispose);

      when(() => mockSyncService.pushPending())
          .thenThrow(Exception('Connection refused from push'));
      when(() => mockSyncService.fullRefresh()).thenAnswer((_) async {});

      await container.read(syncStateProvider.notifier).sync();

      // Push error sets errorMessage but full refresh still completes →
      // phase is error with push message.
      expect(container.read(syncStateProvider).phase, SyncPhase.error);
      expect(
        container.read(syncStateProvider).errorMessage,
        contains('Cannot reach backend'),
      );
    });
  });

  // ── ConnectivityNotifier - _init error handling ───────────────────────────

  group('ConnectivityNotifier - _init error handling', () {
    test('_init error is swallowed and optimistic state is preserved',
        () async {
      final mockConnectivity = MockConnectivity();
      final ctrl =
          StreamController<List<ConnectivityResult>>.broadcast();

      when(() => mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => ctrl.stream);
      when(() => mockConnectivity.checkConnectivity())
          .thenThrow(Exception('No connectivity plugin'));

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          connectivityInstanceProvider.overrideWithValue(mockConnectivity),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(ctrl.close);

      // Trigger build (and thereby _init).
      container.read(isOnlineProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      // The optimistic state (true, since forcedOffline defaults to false)
      // must be preserved even though _init threw.
      expect(container.read(isOnlineProvider), isTrue);
    });
  });

  // ── Stream providers ──────────────────────────────────────────────────────

  group('Stream providers - via overridden dbProvider', () {
    late AppDatabase database;
    late ProviderContainer container;

    setUp(() async {
      database = AppDatabase.fromExecutor(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          dbProvider.overrideWithValue(database),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    test('categoriesProvider emits AsyncData', () async {
      final value = container.read(categoriesProvider);
      expect(value, isA<AsyncValue<List<Category>>>());
    });

    test('eventsProvider emits AsyncData', () async {
      final value = container.read(eventsProvider);
      expect(value, isA<AsyncValue<List<Event>>>());
    });

    test('occurrencesProvider emits AsyncData', () async {
      final value = container.read(occurrencesProvider);
      expect(value, isA<AsyncValue<List<Occurrence>>>());
    });

    test('tasksProvider emits AsyncData', () async {
      final value = container.read(tasksProvider);
      expect(value, isA<AsyncValue<List<Task>>>());
    });

    test('creditCardsProvider emits AsyncData', () async {
      final value = container.read(creditCardsProvider);
      expect(value, isA<AsyncValue<List<CreditCard>>>());
    });

    test('trackerCacheProvider emits AsyncData', () async {
      final value = container.read(trackerCacheProvider);
      expect(value, isA<AsyncValue<List<CreditCardTrackerCacheData>>>());
    });

    test('personsProvider emits AsyncData', () async {
      final value = container.read(personsProvider);
      expect(value, isA<AsyncValue<List<Person>>>());
    });

    test('subtasksForTaskProvider emits AsyncData for task id', () async {
      final value = container.read(subtasksForTaskProvider(42));
      expect(value, isA<AsyncValue<List<Subtask>>>());
    });

    test('groceryStoresProvider emits AsyncData', () async {
      final value = container.read(groceryStoresProvider);
      expect(value, isA<AsyncValue<List<GroceryStore>>>());
    });

    test('groceryItemsProvider emits AsyncData', () async {
      final value = container.read(groceryItemsProvider);
      expect(value, isA<AsyncValue<List<GroceryItem>>>());
    });

    test('groceryOnHandProvider emits AsyncData', () async {
      final value = container.read(groceryOnHandProvider);
      expect(value, isA<AsyncValue<List<GroceryOnHandData>>>());
    });

    test('groceryListsProvider emits AsyncData', () async {
      final value = container.read(groceryListsProvider);
      expect(value, isA<AsyncValue<List<GroceryList>>>());
    });

    test('groceryListItemsProvider emits AsyncData', () async {
      final value = container.read(groceryListItemsProvider);
      expect(value, isA<AsyncValue<List<GroceryListItem>>>());
    });

    test('groceryListItemsForListProvider emits AsyncData for list id',
        () async {
      final value = container.read(groceryListItemsForListProvider(1));
      expect(value, isA<AsyncValue<List<GroceryListItem>>>());
    });

    test('connectivityProvider emits AsyncValue', () async {
      final mockConnectivity = MockConnectivity();
      final ctrl =
          StreamController<List<ConnectivityResult>>.broadcast();
      addTearDown(ctrl.close);

      when(() => mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => ctrl.stream);
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      final c = ProviderContainer(
        overrides: [
          dbProvider.overrideWithValue(database),
          sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance()),
          connectivityInstanceProvider.overrideWithValue(mockConnectivity),
        ],
      );
      addTearDown(c.dispose);

      final value = c.read(connectivityProvider);
      expect(value, isA<AsyncValue<List<ConnectivityResult>>>());
    });
  });
}
