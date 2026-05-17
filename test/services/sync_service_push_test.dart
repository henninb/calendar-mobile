import 'package:calendar_mobile/api/api_client.dart';
import 'package:calendar_mobile/api/api_models.dart';
import 'package:calendar_mobile/core/constants.dart';
import 'package:calendar_mobile/database/app_database.dart';
import 'package:calendar_mobile/services/sync_service.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

// Shared stubs for the refresh APIs that are not under test — avoids
// repetition and ensures fullRefresh() can complete successfully.
void _stubEmptyRefresh(MockApiClient api) {
  when(() => api.fetchCategories()).thenAnswer((_) async => []);
  when(() => api.fetchPersons()).thenAnswer((_) async => []);
  when(() => api.fetchOccurrences(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => []);
  when(() => api.fetchTasks()).thenAnswer((_) async => []);
  when(() => api.fetchCreditCards()).thenAnswer((_) async => []);
  when(() => api.fetchTrackerRows()).thenAnswer((_) async => []);
  when(() => api.fetchStores()).thenAnswer((_) async => []);
  when(() => api.fetchGroceryItems()).thenAnswer((_) async => []);
  when(() => api.fetchOnHand()).thenAnswer((_) async => []);
  when(() => api.fetchGroceryLists()).thenAnswer((_) async => []);
}

void main() {
  late SyncService syncService;
  late AppDatabase db;
  late MockApiClient api;

  setUp(() {
    db = AppDatabase.fromExecutor(NativeDatabase.memory());
    api = MockApiClient();
    syncService = SyncService(db, api);
  });

  tearDown(() async => db.close());

  // ── Occurrences ───────────────────────────────────────────────────────────

  group('pushPending — occurrences', () {
    test('pendingUpdate patches the API and marks synced', () async {
      final id = await db.into(db.occurrences).insert(
        const OccurrencesCompanion(
          serverId: Value(10),
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
          status: Value('completed'),
          syncStatus: Value(2),
        ),
      );

      when(() => api.patchOccurrence(any(), any())).thenAnswer((_) async {});

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      expect(result.errors, isEmpty);
      verify(() => api.patchOccurrence(10, any())).called(1);
      final row = await (db.select(db.occurrences)..where((o) => o.id.equals(id))).getSingle();
      expect(row.syncStatus, SyncStatus.synced.value);
    });

    test('pendingDelete calls API delete and removes locally', () async {
      final id = await db.into(db.occurrences).insert(
        const OccurrencesCompanion(
          serverId: Value(11),
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
          syncStatus: Value(3),
        ),
      );

      when(() => api.deleteOccurrence(any())).thenAnswer((_) async {});

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.deleteOccurrence(11)).called(1);
      expect(await (db.select(db.occurrences)..where((o) => o.id.equals(id))).getSingleOrNull(), isNull);
    });

    test('pendingCreate (no serverId) returns false — occurrences are server-generated', () async {
      await db.into(db.occurrences).insert(
        const OccurrencesCompanion(
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
          syncStatus: Value(1),
        ),
      );

      final result = await syncService.pushPending();

      expect(result.pushed, 0);
      verifyNever(() => api.patchOccurrence(any(), any()));
    });
  });

  // ── Credit Cards ──────────────────────────────────────────────────────────

  group('pushPending — credit cards', () {
    const _apiCard = ApiCreditCard(id: 900, name: 'New Card', isActive: true);

    test('pendingCreate calls createCreditCard and marks synced', () async {
      final localId = await db.insertCreditCard(
        const CreditCardsCompanion(
          name: Value('My Card'),
          syncStatus: Value(1),
        ),
      );

      when(() => api.createCreditCard(any())).thenAnswer((_) async => _apiCard);

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      expect(result.errors, isEmpty);
      verify(() => api.createCreditCard(any())).called(1);
      final card = await (db.select(db.creditCards)..where((c) => c.id.equals(localId))).getSingle();
      expect(card.serverId, 900);
      expect(card.syncStatus, SyncStatus.synced.value);
    });

    test('pendingUpdate with serverId calls updateCreditCard', () async {
      final localId = await db.insertCreditCard(
        const CreditCardsCompanion(
          serverId: Value(50),
          name: Value('Update Me'),
          syncStatus: Value(2),
        ),
      );

      when(() => api.updateCreditCard(any(), any())).thenAnswer((_) async => _apiCard);

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.updateCreditCard(50, any())).called(1);
      final card = await (db.select(db.creditCards)..where((c) => c.id.equals(localId))).getSingle();
      expect(card.syncStatus, SyncStatus.synced.value);
    });

    test('pendingUpdate without serverId returns false', () async {
      await db.insertCreditCard(
        const CreditCardsCompanion(
          name: Value('No Server'),
          syncStatus: Value(2),
        ),
      );

      final result = await syncService.pushPending();

      expect(result.pushed, 0);
      verifyNever(() => api.updateCreditCard(any(), any()));
    });

    test('pendingDelete with serverId calls deleteCreditCard', () async {
      final localId = await db.insertCreditCard(
        const CreditCardsCompanion(
          serverId: Value(51),
          name: Value('Delete Me'),
          syncStatus: Value(3),
        ),
      );

      when(() => api.deleteCreditCard(any())).thenAnswer((_) async {});

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.deleteCreditCard(51)).called(1);
      expect(await (db.select(db.creditCards)..where((c) => c.id.equals(localId))).getSingleOrNull(), isNull);
    });

    test('pendingDelete without serverId returns false', () async {
      await db.insertCreditCard(
        const CreditCardsCompanion(
          name: Value('No Server'),
          syncStatus: Value(3),
        ),
      );

      final result = await syncService.pushPending();

      expect(result.pushed, 0);
      verifyNever(() => api.deleteCreditCard(any()));
    });
  });

  // ── Grocery On Hand ───────────────────────────────────────────────────────

  group('pushPending — grocery on hand', () {
    const _apiOnHand = ApiOnHand(id: 200, itemId: 10, quantity: 2.0, unit: 'lb');

    test('pendingCreate upserts and marks synced', () async {
      await db.upsertGroceryOnHand([
        const GroceryOnHandCompanion(
          itemServerId: Value(10),
          quantity: Value(2.0),
          syncStatus: Value(1),
        ),
      ]);
      final row = await (db.select(db.groceryOnHand)).getSingle();

      when(() => api.upsertOnHand(any(), any())).thenAnswer((_) async => _apiOnHand);

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.upsertOnHand(10, any())).called(1);
      final updated = await (db.select(db.groceryOnHand)..where((o) => o.id.equals(row.id))).getSingle();
      expect(updated.syncStatus, 0);
    });

    test('pendingUpdate also calls upsert', () async {
      await db.upsertGroceryOnHand([
        const GroceryOnHandCompanion(
          itemServerId: Value(11),
          quantity: Value(3.0),
          syncStatus: Value(2),
        ),
      ]);

      when(() => api.upsertOnHand(any(), any())).thenAnswer((_) async => _apiOnHand);

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.upsertOnHand(11, any())).called(1);
    });

    test('pendingDelete calls deleteOnHand and removes locally', () async {
      await db.upsertGroceryOnHand([
        const GroceryOnHandCompanion(
          itemServerId: Value(12),
          syncStatus: Value(3),
        ),
      ]);
      final row = await (db.select(db.groceryOnHand)).getSingle();

      when(() => api.deleteOnHand(any())).thenAnswer((_) async {});

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.deleteOnHand(12)).called(1);
      expect(await (db.select(db.groceryOnHand)..where((o) => o.id.equals(row.id))).getSingleOrNull(), isNull);
    });
  });

  // ── Grocery Stores ────────────────────────────────────────────────────────

  group('pushPending — grocery stores', () {
    const _apiStore = ApiStore(id: 300, name: 'Market', isActive: true);

    test('pendingCreate calls createStore and marks synced', () async {
      final localId = await db.insertGroceryStore(
        const GroceryStoresCompanion(
          name: Value('New Store'),
          syncStatus: Value(1),
        ),
      );

      when(() => api.createStore(any())).thenAnswer((_) async => _apiStore);

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.createStore(any())).called(1);
      final store = await (db.select(db.groceryStores)..where((s) => s.id.equals(localId))).getSingle();
      expect(store.serverId, 300);
      expect(store.syncStatus, SyncStatus.synced.value);
    });

    test('pendingUpdate with serverId calls updateStore', () async {
      final localId = await db.insertGroceryStore(
        const GroceryStoresCompanion(
          serverId: Value(55),
          name: Value('Update Store'),
          syncStatus: Value(2),
        ),
      );

      when(() => api.updateStore(any(), any())).thenAnswer((_) async => _apiStore);

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.updateStore(55, any())).called(1);
    });

    test('pendingUpdate without serverId returns false', () async {
      await db.insertGroceryStore(
        const GroceryStoresCompanion(name: Value('No Server'), syncStatus: Value(2)),
      );

      final result = await syncService.pushPending();

      expect(result.pushed, 0);
      verifyNever(() => api.updateStore(any(), any()));
    });

    test('pendingDelete with serverId calls deleteStore', () async {
      final localId = await db.insertGroceryStore(
        const GroceryStoresCompanion(
          serverId: Value(56),
          name: Value('Delete Store'),
          syncStatus: Value(3),
        ),
      );

      when(() => api.deleteStore(any())).thenAnswer((_) async {});

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.deleteStore(56)).called(1);
      expect(await (db.select(db.groceryStores)..where((s) => s.id.equals(localId))).getSingleOrNull(), isNull);
    });

    test('pendingDelete without serverId returns false', () async {
      await db.insertGroceryStore(
        const GroceryStoresCompanion(name: Value('No Server'), syncStatus: Value(3)),
      );

      final result = await syncService.pushPending();

      expect(result.pushed, 0);
    });
  });

  // ── Grocery Lists ─────────────────────────────────────────────────────────

  group('pushPending — grocery lists', () {
    const _apiList = ApiGroceryList(id: 400, name: 'List', status: 'draft', items: []);

    test('pendingCreate calls createGroceryList and marks synced', () async {
      final localId = await db.insertGroceryList(
        const GroceryListsCompanion(
          name: Value('New List'),
          syncStatus: Value(1),
        ),
      );

      when(() => api.createGroceryList(any())).thenAnswer((_) async => _apiList);

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.createGroceryList(any())).called(1);
      final list = await db.getGroceryListById(localId);
      expect(list!.serverId, 400);
      expect(list.syncStatus, SyncStatus.synced.value);
    });

    test('pendingUpdate with serverId calls updateGroceryList', () async {
      final localId = await db.insertGroceryList(
        const GroceryListsCompanion(
          serverId: Value(60),
          name: Value('Update List'),
          syncStatus: Value(2),
        ),
      );

      when(() => api.updateGroceryList(any(), any())).thenAnswer((_) async => _apiList);

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.updateGroceryList(60, any())).called(1);
    });

    test('pendingUpdate without serverId returns false', () async {
      await db.insertGroceryList(
        const GroceryListsCompanion(name: Value('No Server'), syncStatus: Value(2)),
      );

      final result = await syncService.pushPending();

      expect(result.pushed, 0);
      verifyNever(() => api.updateGroceryList(any(), any()));
    });

    test('pendingDelete with serverId calls deleteGroceryList', () async {
      final localId = await db.insertGroceryList(
        const GroceryListsCompanion(
          serverId: Value(61),
          name: Value('Delete List'),
          syncStatus: Value(3),
        ),
      );

      when(() => api.deleteGroceryList(any())).thenAnswer((_) async {});

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.deleteGroceryList(61)).called(1);
      expect(await db.getGroceryListById(localId), isNull);
    });

    test('pendingDelete without serverId returns false', () async {
      await db.insertGroceryList(
        const GroceryListsCompanion(name: Value('No Server'), syncStatus: Value(3)),
      );

      final result = await syncService.pushPending();

      expect(result.pushed, 0);
    });
  });

  // ── Grocery List Items ────────────────────────────────────────────────────

  group('pushPending — grocery list items', () {
    const _apiItem = ApiGroceryListItem(
      id: 500,
      listId: 60,
      itemId: 10,
      quantity: 2.0,
      unit: 'each',
      status: 'needed',
    );

    late int listLocalId;

    setUp(() async {
      listLocalId = await db.insertGroceryList(
        const GroceryListsCompanion(
          serverId: Value(60),
          name: Value('Parent'),
          syncStatus: Value(0),
        ),
      );
    });

    test('pendingCreate with listServerId calls addGroceryListItem', () async {
      final itemId = await db.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(listLocalId),
          listServerId: const Value(60),
          itemServerId: const Value(10),
          syncStatus: const Value(1),
        ),
      );

      when(() => api.addGroceryListItem(any(), any())).thenAnswer((_) async => _apiItem);

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.addGroceryListItem(60, any())).called(1);
      final item = await (db.select(db.groceryListItems)..where((i) => i.id.equals(itemId))).getSingle();
      expect(item.serverId, 500);
      expect(item.syncStatus, SyncStatus.synced.value);
    });

    test('pendingCreate resolves listServerId from DB when null', () async {
      final itemId = await db.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(listLocalId),
          itemServerId: const Value(10),
          syncStatus: const Value(1),
        ),
      );

      when(() => api.addGroceryListItem(any(), any())).thenAnswer((_) async => _apiItem);

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.addGroceryListItem(60, any())).called(1);
    });

    test('pendingCreate returns false when listServerId cannot be resolved', () async {
      final orphanListId = await db.insertGroceryList(
        const GroceryListsCompanion(
          name: Value('Orphan'),
          syncStatus: Value(0),
        ),
      );
      await db.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(orphanListId),
          itemServerId: const Value(10),
          syncStatus: const Value(1),
        ),
      );

      final result = await syncService.pushPending();

      expect(result.pushed, 0);
      verifyNever(() => api.addGroceryListItem(any(), any()));
    });

    test('pendingUpdate with serverId calls updateGroceryListItem', () async {
      await db.upsertGroceryListItems([
        GroceryListItemsCompanion(
          listLocalId: Value(listLocalId),
          serverId: const Value(501),
          listServerId: const Value(60),
          itemServerId: const Value(11),
          syncStatus: const Value(2),
        ),
      ]);

      when(() => api.updateGroceryListItem(any(), any(), any()))
          .thenAnswer((_) async => _apiItem);

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.updateGroceryListItem(60, 11, any())).called(1);
    });

    test('pendingUpdate without serverId or listServerId returns false', () async {
      final orphanListId = await db.insertGroceryList(
        const GroceryListsCompanion(name: Value('No Server'), syncStatus: Value(0)),
      );
      await db.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(orphanListId),
          itemServerId: const Value(10),
          syncStatus: const Value(2),
        ),
      );

      final result = await syncService.pushPending();

      expect(result.pushed, 0);
    });

    test('pendingDelete calls removeGroceryListItem and deletes locally', () async {
      await db.upsertGroceryListItems([
        GroceryListItemsCompanion(
          listLocalId: Value(listLocalId),
          listServerId: const Value(60),
          itemServerId: const Value(12),
          syncStatus: const Value(3),
        ),
      ]);
      final item = await (db.select(db.groceryListItems)).getSingle();

      when(() => api.removeGroceryListItem(any(), any())).thenAnswer((_) async {});

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.removeGroceryListItem(60, 12)).called(1);
      expect(await (db.select(db.groceryListItems)..where((i) => i.id.equals(item.id))).getSingleOrNull(), isNull);
    });

    test('pendingDelete returns false when listServerId cannot be resolved', () async {
      final orphanListId = await db.insertGroceryList(
        const GroceryListsCompanion(name: Value('Orphan'), syncStatus: Value(0)),
      );
      await db.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(orphanListId),
          itemServerId: const Value(10),
          syncStatus: const Value(3),
        ),
      );

      final result = await syncService.pushPending();

      expect(result.pushed, 0);
      verifyNever(() => api.removeGroceryListItem(any(), any()));
    });
  });

  // ── _pushLoop error handling ──────────────────────────────────────────────

  group('pushPending — _pushLoop error handling', () {
    test('DioException 404 with on404 handler removes the orphan', () async {
      final taskId = await db.insertTask(
        const TasksCompanion(
          serverId: Value(999),
          title: Value('Orphan'),
          syncStatus: Value(2),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );

      when(() => api.patchTask(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/tasks/999'),
          response: Response(
            requestOptions: RequestOptions(path: '/tasks/999'),
            statusCode: 404,
          ),
        ),
      );

      final result = await syncService.pushPending();

      // on404 deletes the task locally; error is not added
      expect(result.errors, isEmpty);
      expect(await db.getTaskById(taskId), isNull);
    });

    test('DioException non-404 adds to errors list', () async {
      await db.into(db.occurrences).insert(
        const OccurrencesCompanion(
          serverId: Value(10),
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
          syncStatus: Value(2),
        ),
      );

      when(() => api.patchOccurrence(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/occurrences/10'),
          response: Response(
            requestOptions: RequestOptions(path: '/occurrences/10'),
            statusCode: 500,
          ),
        ),
      );

      final result = await syncService.pushPending();

      expect(result.pushed, 0);
      expect(result.errors, hasLength(1));
      expect(result.errors.first, contains('500'));
    });

    test('DioException with no response adds network error to list', () async {
      await db.into(db.occurrences).insert(
        const OccurrencesCompanion(
          serverId: Value(10),
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
          syncStatus: Value(2),
        ),
      );

      when(() => api.patchOccurrence(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/occ'),
          message: 'Connection refused',
        ),
      );

      final result = await syncService.pushPending();

      expect(result.errors, hasLength(1));
      expect(result.errors.first, contains('Connection refused'));
    });

    test('unexpected exception adds error entry', () async {
      await db.into(db.occurrences).insert(
        const OccurrencesCompanion(
          serverId: Value(10),
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
          syncStatus: Value(2),
        ),
      );

      when(() => api.patchOccurrence(any(), any())).thenThrow(Exception('Boom'));

      final result = await syncService.pushPending();

      expect(result.errors, hasLength(1));
      expect(result.errors.first, contains('unexpected'));
    });

    test('DioException 404 with no on404 handler adds to errors', () async {
      // Occurrences push has on404: null, so a 404 goes into errors
      await db.into(db.occurrences).insert(
        const OccurrencesCompanion(
          serverId: Value(10),
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
          syncStatus: Value(2),
        ),
      );

      when(() => api.patchOccurrence(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/occ'),
          response: Response(
            requestOptions: RequestOptions(path: '/occ'),
            statusCode: 404,
          ),
        ),
      );

      final result = await syncService.pushPending();

      expect(result.errors, hasLength(1));
      expect(result.errors.first, contains('404'));
    });

    test('DioException badCertificate adds TLS message', () async {
      await db.into(db.occurrences).insert(
        const OccurrencesCompanion(
          serverId: Value(10),
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
          syncStatus: Value(2),
        ),
      );

      when(() => api.patchOccurrence(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/occ'),
          type: DioExceptionType.badCertificate,
        ),
      );

      final result = await syncService.pushPending();

      expect(result.errors, hasLength(1));
      expect(result.errors.first, contains('TLS'));
    });
  });

  // ── fullRefresh — occurrences with events ─────────────────────────────────

  group('fullRefresh — _refreshOccurrences', () {
    test('caches events embedded in occurrences', () async {
      _stubEmptyRefresh(api);

      const event = ApiEvent(
        id: 1,
        title: 'Weekly Sync',
        categoryId: 5,
        dtstart: '2026-05-01',
        priority: 'medium',
        isActive: true,
        category: ApiCategory(id: 5, name: 'Work', color: '#ff0000', icon: '💼'),
      );
      when(() => api.fetchOccurrences(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => [
            ApiOccurrence(
              id: 10,
              eventId: 1,
              occurrenceDate: '2026-05-10',
              status: 'upcoming',
              event: event,
            ),
          ]);

      await syncService.fullRefresh();

      final events = await db.getAllEvents();
      expect(events, hasLength(1));
      expect(events.first.title, 'Weekly Sync');
    });

    test('purges orphan occurrences within the synced window', () async {
      _stubEmptyRefresh(api);

      // Seed a local occurrence that will not be returned by the server.
      await db.upsertOccurrences([
        const OccurrencesCompanion(
          serverId: Value(99),
          eventServerId: Value(1),
          occurrenceDate: Value('2026-05-10'),
          syncStatus: Value(0),
        ),
      ]);

      // Server returns nothing for the window.
      when(() => api.fetchOccurrences(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => []);

      await syncService.fullRefresh();

      // The orphan should have been purged.
      expect(await db.getOccurrences(), isEmpty);
    });
  });

  // ── fullRefresh — _refreshGroceryOnHand ──────────────────────────────────

  group('fullRefresh — _refreshGroceryOnHand', () {
    test('skips overwriting rows that have pending mutations', () async {
      _stubEmptyRefresh(api);

      // Local row with a pending quantity edit.
      await db.upsertGroceryOnHand([
        const GroceryOnHandCompanion(
          itemServerId: Value(1),
          quantity: Value(99.0),
          syncStatus: Value(2),
        ),
      ]);

      // Server returns a different quantity for the same item.
      when(() => api.fetchOnHand()).thenAnswer((_) async => [
            const ApiOnHand(id: 1, itemId: 1, quantity: 1.0, unit: 'each'),
          ]);

      await syncService.fullRefresh();

      // Local pending quantity must be preserved.
      final rows = await (db.select(db.groceryOnHand)).get();
      expect(rows.first.quantity, 99.0);
      expect(rows.first.syncStatus, 2);
    });

    test('upserts non-pending rows from server', () async {
      _stubEmptyRefresh(api);

      when(() => api.fetchOnHand()).thenAnswer((_) async => [
            const ApiOnHand(id: 1, itemId: 10, quantity: 2.5, unit: 'lb'),
          ]);

      await syncService.fullRefresh();

      final rows = await (db.select(db.groceryOnHand)).get();
      expect(rows, hasLength(1));
      expect(rows.first.quantity, 2.5);
    });

    test('purges on-hand rows not returned by server', () async {
      _stubEmptyRefresh(api);

      // Seed two rows; server will only return one.
      await db.upsertGroceryOnHand([
        const GroceryOnHandCompanion(itemServerId: Value(1)),
        const GroceryOnHandCompanion(itemServerId: Value(2)),
      ]);

      when(() => api.fetchOnHand()).thenAnswer((_) async => [
            const ApiOnHand(id: 1, itemId: 1, quantity: 1.0, unit: 'each'),
          ]);

      await syncService.fullRefresh();

      final rows = await (db.select(db.groceryOnHand)).get();
      expect(rows, hasLength(1));
      expect(rows.first.itemServerId, 1);
    });
  });

  // ── fullRefresh — _refreshGroceryLists ───────────────────────────────────

  group('fullRefresh — _refreshGroceryLists', () {
    test('upserts list items from server response', () async {
      _stubEmptyRefresh(api);

      when(() => api.fetchGroceryLists()).thenAnswer((_) async => [
            ApiGroceryList(
              id: 1,
              name: 'My List',
              status: 'draft',
              items: [
                const ApiGroceryListItem(
                  id: 10,
                  listId: 1,
                  itemId: 5,
                  quantity: 2.0,
                  unit: 'each',
                  status: 'needed',
                ),
              ],
            ),
          ]);

      await syncService.fullRefresh();

      final lists = await db.getGroceryLists();
      expect(lists, hasLength(1));
      expect(lists.first.serverId, 1);

      final items = await db.getGroceryListItems();
      expect(items, hasLength(1));
      expect(items.first.itemServerId, 5);
    });

    test('purges orphan lists no longer returned by server', () async {
      _stubEmptyRefresh(api);

      await db.upsertGroceryLists([
        const GroceryListsCompanion(
          serverId: Value(99),
          name: Value('Orphan List'),
          syncStatus: Value(0),
        ),
      ]);

      when(() => api.fetchGroceryLists()).thenAnswer((_) async => []);

      await syncService.fullRefresh();

      expect(await db.getGroceryLists(), isEmpty);
    });

    test('purges orphan items in synced lists', () async {
      _stubEmptyRefresh(api);

      // Seed list + item. Server will return the list but without the item.
      await db.upsertGroceryLists([
        const GroceryListsCompanion(
          serverId: Value(1),
          name: Value('List'),
          syncStatus: Value(0),
        ),
      ]);
      final list = await (db.select(db.groceryLists)).getSingle();
      await db.upsertGroceryListItems([
        GroceryListItemsCompanion(
          listLocalId: Value(list.id),
          serverId: const Value(10),
          listServerId: const Value(1),
          itemServerId: const Value(5),
        ),
      ]);

      // Server returns list without items
      when(() => api.fetchGroceryLists()).thenAnswer((_) async => [
            const ApiGroceryList(id: 1, name: 'List', status: 'draft', items: []),
          ]);

      await syncService.fullRefresh();

      expect(await db.getGroceryListItems(), isEmpty);
    });
  });

  // ── fullRefresh — _refreshPersons ─────────────────────────────────────────

  group('fullRefresh — _refreshPersons', () {
    test('upserts persons returned by server', () async {
      _stubEmptyRefresh(api);
      when(() => api.fetchPersons()).thenAnswer((_) async => [
            const ApiPerson(id: 1, name: 'Alice', email: 'alice@example.com'),
          ]);

      await syncService.fullRefresh();

      final persons = await db.getAllPersons();
      expect(persons, hasLength(1));
      expect(persons.first.serverId, 1);
      expect(persons.first.name, 'Alice');
      expect(persons.first.email, 'alice@example.com');
    });
  });

  // ── fullRefresh — _refreshCreditCardTracker ───────────────────────────────

  group('fullRefresh — _refreshCreditCardTracker', () {
    test('replaces tracker cache with server data', () async {
      _stubEmptyRefresh(api);
      when(() => api.fetchTrackerRows()).thenAnswer((_) async => [
            const ApiTrackerRow(
              id: 1,
              name: 'Visa',
              issuer: 'BigBank',
              lastFour: '1234',
              grace: '2026-05-15',
              prevClose: '2026-04-15',
              prevDue: '2026-05-05',
              nextClose: '2026-05-15',
              nextCloseDays: 7,
              nextDue: '2026-06-05',
              nextDueDays: 28,
              annualFeeDate: '2026-12-01',
              annualFeeDays: 207,
              prevDueOverdue: false,
            ),
          ]);

      await syncService.fullRefresh();

      final cache = await db.getTrackerCache();
      expect(cache, hasLength(1));
      expect(cache.first.name, 'Visa');
      expect(cache.first.issuer, 'BigBank');
    });
  });

  // ── fullRefresh — _refreshGroceryStores ──────────────────────────────────

  group('fullRefresh — _refreshGroceryStores', () {
    test('upserts stores returned by server', () async {
      _stubEmptyRefresh(api);
      when(() => api.fetchStores()).thenAnswer((_) async => [
            const ApiStore(id: 1, name: 'Whole Foods', location: 'Downtown', isActive: true),
          ]);

      await syncService.fullRefresh();

      final stores = await (db.select(db.groceryStores)).get();
      expect(stores, hasLength(1));
      expect(stores.first.name, 'Whole Foods');
      expect(stores.first.location, 'Downtown');
    });
  });

  // ── fullRefresh — _refreshGroceryItems ───────────────────────────────────

  group('fullRefresh — _refreshGroceryItems', () {
    test('upserts grocery items returned by server', () async {
      _stubEmptyRefresh(api);
      when(() => api.fetchGroceryItems()).thenAnswer((_) async => [
            const ApiGroceryItem(
              id: 1, name: 'Milk', defaultUnit: 'gallon', defaultStoreId: 10,
            ),
          ]);

      await syncService.fullRefresh();

      final items = await db.getGroceryItems();
      expect(items, hasLength(1));
      expect(items.first.name, 'Milk');
      expect(items.first.defaultUnit, 'gallon');
    });
  });

  // ── fullRefresh — _refreshTasks (subtask paths) ───────────────────────────

  group('fullRefresh — subtask upsertion and purging', () {
    test('upserts subtasks embedded in task response', () async {
      _stubEmptyRefresh(api);
      when(() => api.fetchTasks()).thenAnswer((_) async => [
            ApiTask(
              id: 10, title: 'Parent Task',
              status: 'todo', priority: 'medium',
              recurrence: 'none', order: 0,
              createdAt: '2026-01-01', updatedAt: '2026-01-01',
              subtasks: [
                const ApiSubtask(
                  id: 100, taskId: 10, title: 'Sub1', status: 'todo', order: 0,
                ),
              ],
            ),
          ]);

      await syncService.fullRefresh();

      final tasks = await db.getTasks();
      expect(tasks, hasLength(1));
      final subtasks = await db.getSubtasksForTask(tasks.first.id);
      expect(subtasks, hasLength(1));
      expect(subtasks.first.serverId, 100);
      expect(subtasks.first.title, 'Sub1');
    });

    test('purges orphan subtasks no longer returned by server', () async {
      _stubEmptyRefresh(api);

      // Seed a synced task with a subtask locally.
      final taskId = await db.insertTask(const TasksCompanion(
        serverId: Value(10),
        title: Value('Task'),
        syncStatus: Value(0),
        createdAt: Value('2026-01-01'),
        updatedAt: Value('2026-01-01'),
      ));
      await db.insertSubtask(SubtasksCompanion(
        serverId: const Value(200),
        taskLocalId: Value(taskId),
        taskServerId: const Value(10),
        title: const Value('Orphan Sub'),
        status: const Value('todo'),
        syncStatus: const Value(0),
      ));

      // Server returns task without that subtask.
      when(() => api.fetchTasks()).thenAnswer((_) async => [
            ApiTask(
              id: 10, title: 'Task',
              status: 'todo', priority: 'medium',
              recurrence: 'none', order: 0,
              createdAt: '2026-01-01', updatedAt: '2026-01-01',
              subtasks: [],
            ),
          ]);

      await syncService.fullRefresh();

      final subtasks = await db.getAllSubtasks();
      expect(subtasks, isEmpty);
    });
  });

  // ── pushPending — subtasks with null taskServerId ─────────────────────────

  group('pushPending — subtask taskServerId resolved from DB', () {
    test('pendingCreate resolves taskServerId from DB when null', () async {
      final taskId = await db.insertTask(const TasksCompanion(
        serverId: Value(10),
        title: Value('Parent'),
        syncStatus: Value(0),
        createdAt: Value('2026-01-01'),
        updatedAt: Value('2026-01-01'),
      ));

      await db.insertSubtask(SubtasksCompanion(
        taskLocalId: Value(taskId),
        // taskServerId intentionally null — should be resolved from DB
        title: const Value('Sub via DB'),
        status: const Value('todo'),
        syncStatus: const Value(1), // pendingCreate
      ));

      when(() => api.createSubtask(any(), any())).thenAnswer(
        (_) async => const ApiSubtask(id: 800, taskId: 10, title: 'Sub via DB', status: 'todo', order: 0),
      );

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.createSubtask(10, any())).called(1);
    });

    test('pendingUpdate resolves taskServerId from DB when null', () async {
      final taskId = await db.insertTask(const TasksCompanion(
        serverId: Value(10),
        title: Value('Parent'),
        syncStatus: Value(0),
        createdAt: Value('2026-01-01'),
        updatedAt: Value('2026-01-01'),
      ));

      await db.insertSubtask(SubtasksCompanion(
        serverId: const Value(701),
        taskLocalId: Value(taskId),
        // taskServerId intentionally null
        title: const Value('Updated Sub'),
        status: const Value('done'),
        syncStatus: const Value(2), // pendingUpdate
      ));

      when(() => api.patchSubtask(any(), any(), any())).thenAnswer((_) async {});

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.patchSubtask(10, 701, any())).called(1);
    });

    test('pendingDelete resolves taskServerId from DB when null', () async {
      final taskId = await db.insertTask(const TasksCompanion(
        serverId: Value(10),
        title: Value('Parent'),
        syncStatus: Value(0),
        createdAt: Value('2026-01-01'),
        updatedAt: Value('2026-01-01'),
      ));

      final subId = await db.insertSubtask(SubtasksCompanion(
        serverId: const Value(702),
        taskLocalId: Value(taskId),
        // taskServerId intentionally null
        title: const Value('Delete Sub'),
        status: const Value('todo'),
        syncStatus: const Value(3), // pendingDelete
      ));

      when(() => api.deleteSubtask(any(), any())).thenAnswer((_) async {});

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => api.deleteSubtask(10, 702)).called(1);
      expect(
        await (db.select(db.subtasks)..where((s) => s.id.equals(subId))).getSingleOrNull(),
        isNull,
      );
    });
  });

  // ── pushPending — 404 on404 handlers ─────────────────────────────────────

  group('pushPending — 404 on404 handlers', () {
    test('subtask 404 triggers on404 and removes locally', () async {
      final taskId = await db.insertTask(const TasksCompanion(
        serverId: Value(10),
        title: Value('Task'),
        syncStatus: Value(0),
        createdAt: Value('2026-01-01'),
        updatedAt: Value('2026-01-01'),
      ));

      final subId = await db.insertSubtask(SubtasksCompanion(
        serverId: const Value(200),
        taskLocalId: Value(taskId),
        taskServerId: const Value(10),
        title: const Value('Orphan Sub'),
        status: const Value('done'),
        syncStatus: const Value(2), // pendingUpdate
      ));

      when(() => api.patchSubtask(any(), any(), any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/subtasks/200'),
        response: Response(
          requestOptions: RequestOptions(path: '/subtasks/200'),
          statusCode: 404,
        ),
      ));

      final result = await syncService.pushPending();

      expect(result.errors, isEmpty);
      expect(
        await (db.select(db.subtasks)..where((s) => s.id.equals(subId))).getSingleOrNull(),
        isNull,
      );
    });

    test('credit card 404 triggers on404 and removes locally', () async {
      final localId = await db.insertCreditCard(const CreditCardsCompanion(
        serverId: Value(50),
        name: Value('Orphan Card'),
        syncStatus: Value(2), // pendingUpdate
      ));

      when(() => api.updateCreditCard(any(), any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/cards/50'),
        response: Response(
          requestOptions: RequestOptions(path: '/cards/50'),
          statusCode: 404,
        ),
      ));

      final result = await syncService.pushPending();

      expect(result.errors, isEmpty);
      expect(
        await (db.select(db.creditCards)..where((c) => c.id.equals(localId))).getSingleOrNull(),
        isNull,
      );
    });

    test('grocery on-hand 404 triggers on404 and removes locally', () async {
      await db.upsertGroceryOnHand([
        const GroceryOnHandCompanion(
          itemServerId: Value(99),
          quantity: Value(1.0),
          syncStatus: Value(2), // pendingUpdate
        ),
      ]);
      final row = await (db.select(db.groceryOnHand)).getSingle();

      when(() => api.upsertOnHand(any(), any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/on-hand/99'),
        response: Response(
          requestOptions: RequestOptions(path: '/on-hand/99'),
          statusCode: 404,
        ),
      ));

      final result = await syncService.pushPending();

      expect(result.errors, isEmpty);
      expect(
        await (db.select(db.groceryOnHand)..where((o) => o.id.equals(row.id))).getSingleOrNull(),
        isNull,
      );
    });

    test('grocery store 404 triggers on404 and removes locally', () async {
      final localId = await db.insertGroceryStore(
        const GroceryStoresCompanion(
          serverId: Value(55),
          name: Value('Orphan Store'),
          syncStatus: Value(2),
        ),
      );

      when(() => api.updateStore(any(), any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/stores/55'),
        response: Response(
          requestOptions: RequestOptions(path: '/stores/55'),
          statusCode: 404,
        ),
      ));

      final result = await syncService.pushPending();

      expect(result.errors, isEmpty);
      expect(
        await (db.select(db.groceryStores)..where((s) => s.id.equals(localId))).getSingleOrNull(),
        isNull,
      );
    });

    test('grocery list 404 triggers on404 and removes locally', () async {
      final localId = await db.insertGroceryList(
        const GroceryListsCompanion(
          serverId: Value(60),
          name: Value('Orphan List'),
          syncStatus: Value(2),
        ),
      );

      when(() => api.updateGroceryList(any(), any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/lists/60'),
        response: Response(
          requestOptions: RequestOptions(path: '/lists/60'),
          statusCode: 404,
        ),
      ));

      final result = await syncService.pushPending();

      expect(result.errors, isEmpty);
      expect(await db.getGroceryListById(localId), isNull);
    });

    test('grocery list item 404 triggers on404 and removes locally', () async {
      final listId = await db.insertGroceryList(
        const GroceryListsCompanion(
          serverId: Value(60),
          name: Value('List'),
          syncStatus: Value(0),
        ),
      );

      await db.upsertGroceryListItems([
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          serverId: const Value(501),
          listServerId: const Value(60),
          itemServerId: const Value(11),
          syncStatus: const Value(2), // pendingUpdate
        ),
      ]);
      final item = await (db.select(db.groceryListItems)).getSingle();

      when(() => api.updateGroceryListItem(any(), any(), any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/list-items/501'),
        response: Response(
          requestOptions: RequestOptions(path: '/list-items/501'),
          statusCode: 404,
        ),
      ));

      final result = await syncService.pushPending();

      expect(result.errors, isEmpty);
      expect(
        await (db.select(db.groceryListItems)..where((i) => i.id.equals(item.id))).getSingleOrNull(),
        isNull,
      );
    });
  });

  // ── JSON serialisers — optional field coverage ────────────────────────────

  group('pushPending — JSON serialiser optional fields', () {
    test('_taskToJson includes estimated_minutes when set', () async {
      await db.insertTask(const TasksCompanion(
        title: Value('Timed Task'),
        estimatedMinutes: Value(30),
        syncStatus: Value(1), // pendingCreate
        createdAt: Value('2026-01-01'),
        updatedAt: Value('2026-01-01'),
      ));

      Map<String, dynamic>? capturedJson;
      when(() => api.createTask(any())).thenAnswer((inv) {
        capturedJson = inv.positionalArguments[0] as Map<String, dynamic>;
        return Future.value(ApiTask(
          id: 901, title: 'Timed Task',
          status: 'todo', priority: 'medium',
          recurrence: 'none', order: 0, subtasks: [],
          createdAt: '2026-01-01', updatedAt: '2026-01-01',
        ));
      });

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      expect(capturedJson!['estimated_minutes'], 30);
    });

    test('_cardToJson includes cycle_days and cycle_reference_date when set', () async {
      await db.insertCreditCard(const CreditCardsCompanion(
        name: Value('Cycle Card'),
        cycleDays: Value(30),
        cycleReferenceDate: Value('2026-01-01'),
        syncStatus: Value(1), // pendingCreate
      ));

      Map<String, dynamic>? capturedJson;
      when(() => api.createCreditCard(any())).thenAnswer((inv) {
        capturedJson = inv.positionalArguments[0] as Map<String, dynamic>;
        return Future.value(const ApiCreditCard(id: 902, name: 'Cycle Card', isActive: true));
      });

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      expect(capturedJson!['cycle_days'], 30);
      expect(capturedJson!['cycle_reference_date'], '2026-01-01');
    });

    test('_dioErrorDetail returns validation error for HTTP 400', () async {
      await db.into(db.occurrences).insert(const OccurrencesCompanion(
        serverId: Value(10),
        eventServerId: Value(100),
        occurrenceDate: Value('2026-05-01'),
        syncStatus: Value(2),
      ));

      when(() => api.patchOccurrence(any(), any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/occ'),
        response: Response(
          requestOptions: RequestOptions(path: '/occ'),
          statusCode: 400,
        ),
      ));

      final result = await syncService.pushPending();

      expect(result.errors, hasLength(1));
      expect(result.errors.first, contains('Validation error'));
    });

    test('_dioErrorDetail returns validation error for HTTP 422', () async {
      await db.into(db.occurrences).insert(const OccurrencesCompanion(
        serverId: Value(11),
        eventServerId: Value(100),
        occurrenceDate: Value('2026-05-02'),
        syncStatus: Value(2),
      ));

      when(() => api.patchOccurrence(any(), any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/occ'),
        response: Response(
          requestOptions: RequestOptions(path: '/occ'),
          statusCode: 422,
        ),
      ));

      final result = await syncService.pushPending();

      expect(result.errors, hasLength(1));
      expect(result.errors.first, contains('Validation error'));
    });
  });
}
