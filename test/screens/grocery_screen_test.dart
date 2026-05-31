import 'package:calendar_mobile/core/constants.dart';
import 'package:calendar_mobile/core/theme.dart';
import 'package:calendar_mobile/database/app_database.dart';
import 'package:calendar_mobile/providers/providers.dart';
import 'package:calendar_mobile/screens/grocery_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

class _NoOpSyncNotifier extends SyncNotifier {
  @override
  SyncState build() => const SyncState();

  @override
  void syncIfOnline() {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Mocking all StreamProviders with Stream.value avoids:
//   • the loading-state CircularProgressIndicator (which would keep
//     pumpAndSettle spinning indefinitely)
//   • Drift cleanup timers that fail the "no pending timers" assertion
//
// The real DB is only passed in for tests that need to verify writes.
Widget _wrap({
  List<GroceryItem> items = const [],
  List<GroceryOnHandData> onHand = const [],
  AppDatabase? db,
}) {
  return ProviderScope(
    overrides: [
      groceryItemsProvider.overrideWith((_) => Stream.value(items)),
      groceryOnHandProvider.overrideWith((_) => Stream.value(onHand)),
      groceryListsProvider.overrideWith((_) => Stream.value([])),
      groceryListItemsProvider.overrideWith((_) => Stream.value([])),
      groceryStoresProvider.overrideWith((_) => Stream.value([])),
      syncStateProvider.overrideWith(_NoOpSyncNotifier.new),
      if (db != null) dbProvider.overrideWithValue(db),
    ],
    child: MaterialApp(
      theme: buildAppTheme(),
      home: const Scaffold(body: GroceryScreen()),
    ),
  );
}

Future<void> _goToPantry(WidgetTester tester) async {
  await tester.tap(find.text('Pantry'));
  await tester.pumpAndSettle();
}

GroceryItem _item({
  required int id,
  required int serverId,
  required String name,
  String defaultUnit = 'each',
}) => GroceryItem(
  id: id,
  serverId: serverId,
  name: name,
  defaultUnit: defaultUnit,
);

GroceryOnHandData _onHand({
  required int id,
  required int itemServerId,
  required double quantity,
  String unit = 'each',
  int syncStatus = 0,
}) => GroceryOnHandData(
  id: id,
  itemServerId: itemServerId,
  quantity: quantity,
  unit: unit,
  syncStatus: syncStatus,
);

// ---------------------------------------------------------------------------
// Additional helpers
// ---------------------------------------------------------------------------

// Wraps the full GroceryScreen with a seeded grocery list so tests can
// navigate into _ListDetailView and open _AddItemSheet.
Widget _wrapWithList({
  required GroceryList list,
  List<GroceryItem> catalogItems = const [],
}) => ProviderScope(
  overrides: [
    groceryListsProvider.overrideWith((_) => Stream.value([list])),
    groceryListItemsProvider.overrideWith((_) => Stream.value([])),
    groceryListItemsForListProvider(
      list.id,
    ).overrideWith((_) => Stream.value([])),
    groceryItemsProvider.overrideWith((_) => Stream.value(catalogItems)),
    groceryOnHandProvider.overrideWith((_) => Stream.value([])),
    groceryStoresProvider.overrideWith((_) => Stream.value([])),
    syncStateProvider.overrideWith(_NoOpSyncNotifier.new),
  ],
  child: MaterialApp(
    theme: buildAppTheme(),
    home: const Scaffold(body: GroceryScreen()),
  ),
);

const _activeList = GroceryList(
  id: 1,
  name: 'Weekly Shop',
  status: 'active',
  syncStatus: 0,
);

// ---------------------------------------------------------------------------
// Extra stubs
// ---------------------------------------------------------------------------

class _EmptyBaseUrlNotifier extends BaseUrlNotifier {
  @override
  String build() => '';
}

class _OnlineConnectivityNotifier extends ConnectivityNotifier {
  @override
  bool build() => true;
}

// ---------------------------------------------------------------------------
// Extra data helpers
// ---------------------------------------------------------------------------

GroceryListItem _listItem({
  required int id,
  required int listLocalId,
  required int itemServerId,
  double quantity = 1.0,
  String unit = 'each',
  String status = 'needed',
}) => GroceryListItem(
  id: id,
  listLocalId: listLocalId,
  itemServerId: itemServerId,
  quantity: quantity,
  unit: unit,
  status: status,
  syncStatus: 0,
);

GroceryStore _store({
  required int id,
  required String name,
  String? location,
  int? serverId,
}) => GroceryStore(
  id: id,
  serverId: serverId,
  name: name,
  location: location,
  isActive: true,
  syncStatus: 0,
);

// ---------------------------------------------------------------------------
// Extra widget helpers
// ---------------------------------------------------------------------------

// Lists-overview wrapper: seeds groceryListsProvider, allItems, stores.
Widget _wrapLists({
  List<GroceryList> lists = const [],
  List<GroceryListItem> allItems = const [],
  List<GroceryStore> stores = const [],
  AppDatabase? db,
}) => ProviderScope(
  overrides: [
    groceryListsProvider.overrideWith((_) => Stream.value(lists)),
    groceryListItemsProvider.overrideWith((_) => Stream.value(allItems)),
    groceryItemsProvider.overrideWith((_) => Stream.value([])),
    groceryOnHandProvider.overrideWith((_) => Stream.value([])),
    groceryStoresProvider.overrideWith((_) => Stream.value(stores)),
    syncStateProvider.overrideWith(_NoOpSyncNotifier.new),
    if (db != null) dbProvider.overrideWithValue(db),
  ],
  child: MaterialApp(
    theme: buildAppTheme(),
    home: const Scaffold(body: GroceryScreen()),
  ),
);

// Detail wrapper: seeds a single list so tests can tap into _ListDetailView.
Widget _wrapDetail({
  required GroceryList list,
  List<GroceryListItem> listItems = const [],
  List<GroceryItem> catalogItems = const [],
  AppDatabase? db,
}) => ProviderScope(
  overrides: [
    groceryListsProvider.overrideWith((_) => Stream.value([list])),
    groceryListItemsProvider.overrideWith((_) => Stream.value(listItems)),
    groceryListItemsForListProvider(
      list.id,
    ).overrideWith((_) => Stream.value(listItems)),
    groceryItemsProvider.overrideWith((_) => Stream.value(catalogItems)),
    groceryOnHandProvider.overrideWith((_) => Stream.value([])),
    groceryStoresProvider.overrideWith((_) => Stream.value([])),
    syncStateProvider.overrideWith(_NoOpSyncNotifier.new),
    if (db != null) dbProvider.overrideWithValue(db),
  ],
  child: MaterialApp(
    theme: buildAppTheme(),
    home: const Scaffold(body: GroceryScreen()),
  ),
);

Future<void> _goToStores(WidgetTester tester) async {
  await tester.tap(find.text('Stores'));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('GroceryScreen – Pantry tab (display)', () {
    testWidgets('shows catalog items with no on-hand quantity', (tester) async {
      await tester.pumpWidget(
        _wrap(items: [_item(id: 1, serverId: 1, name: 'Milk')]),
      );
      await tester.pumpAndSettle();
      await _goToPantry(tester);

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('shows on-hand quantity when a record exists', (tester) async {
      await tester.pumpWidget(
        _wrap(
          items: [_item(id: 1, serverId: 1, name: 'Eggs')],
          onHand: [_onHand(id: 1, itemServerId: 1, quantity: 12.0)],
        ),
      );
      await tester.pumpAndSettle();
      await _goToPantry(tester);

      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('tapping an item opens the Set On-Hand sheet', (tester) async {
      await tester.pumpWidget(
        _wrap(items: [_item(id: 1, serverId: 1, name: 'Butter')]),
      );
      await tester.pumpAndSettle();
      await _goToPantry(tester);

      await tester.tap(find.text('Butter'));
      await tester.pumpAndSettle();

      expect(find.text('Set On-Hand: Butter'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows Update title when on-hand record already exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          items: [_item(id: 1, serverId: 2, name: 'Flour', defaultUnit: 'lb')],
          onHand: [_onHand(id: 1, itemServerId: 2, quantity: 2.0, unit: 'lb')],
        ),
      );
      await tester.pumpAndSettle();
      await _goToPantry(tester);

      await tester.tap(find.text('Flour'));
      await tester.pumpAndSettle();

      expect(find.text('Update On-Hand: Flour'), findsOneWidget);
    });

    testWidgets('sheet dismisses after saving', (tester) async {
      final db = AppDatabase.fromExecutor(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        _wrap(
          items: [_item(id: 1, serverId: 5, name: 'Salt')],
          db: db,
        ),
      );
      await tester.pumpAndSettle();
      await _goToPantry(tester);

      await tester.tap(find.text('Salt'));
      await tester.pumpAndSettle();

      expect(find.text('Set On-Hand: Salt'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, '3');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Set On-Hand: Salt'), findsNothing);
    });

    testWidgets('FAB is always visible on the Pantry tab', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await _goToPantry(tester);

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB opens the New Pantry Item sheet', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await _goToPantry(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('New Pantry Item'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Item name *'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });
  });

  group('GroceryScreen – Pantry tab (writes)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.fromExecutor(NativeDatabase.memory());
    });

    tearDown(() => db.close());

    testWidgets('saving the sheet creates a new on-hand record', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          items: [_item(id: 1, serverId: 3, name: 'Olive Oil')],
          db: db,
        ),
      );
      await tester.pumpAndSettle();
      await _goToPantry(tester);

      await tester.tap(find.text('Olive Oil'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '2');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final rows = await db.select(db.groceryOnHand).get();
      expect(rows.length, 1);
      expect(rows.first.itemServerId, 3);
      expect(rows.first.quantity, 2.0);
      expect(rows.first.syncStatus, SyncStatus.pendingCreate.value);
    });

    testWidgets('saving the sheet updates an existing on-hand record', (
      tester,
    ) async {
      await db.upsertGroceryOnHand([
        const GroceryOnHandCompanion(
          itemServerId: Value(4),
          quantity: Value(1.0),
          unit: Value('lb'),
          syncStatus: Value(0),
        ),
      ]);

      await tester.pumpWidget(
        _wrap(
          items: [_item(id: 1, serverId: 4, name: 'Sugar', defaultUnit: 'lb')],
          onHand: [_onHand(id: 1, itemServerId: 4, quantity: 1.0, unit: 'lb')],
          db: db,
        ),
      );
      await tester.pumpAndSettle();
      await _goToPantry(tester);

      await tester.tap(find.text('Sugar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '5');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final rows = await db.select(db.groceryOnHand).get();
      expect(rows.length, 1);
      expect(rows.first.quantity, 5.0);
      expect(rows.first.syncStatus, SyncStatus.pendingUpdate.value);
    });
  });

  // ── _AddItemSheet searchable picker ────────────────────────────────────────

  group('GroceryScreen – Add Item sheet (searchable picker)', () {
    Future<void> openAddItemSheet(WidgetTester tester) async {
      // Tap the list card to enter _ListDetailView.
      await tester.tap(find.text('Weekly Shop'));
      await tester.pumpAndSettle();
      // Tap the FAB to open _AddItemSheet.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
    }

    testWidgets('Phase 1: search field is shown when sheet opens', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithList(
          list: _activeList,
          catalogItems: [_item(id: 1, serverId: 1, name: 'Apple')],
        ),
      );
      await tester.pumpAndSettle();
      await openAddItemSheet(tester);

      expect(find.widgetWithText(TextField, 'Search items *'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('Phase 1: typing filters the item list', (tester) async {
      await tester.pumpWidget(
        _wrapWithList(
          list: _activeList,
          catalogItems: [
            _item(id: 1, serverId: 1, name: 'Apple'),
            _item(id: 2, serverId: 2, name: 'Bread'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await openAddItemSheet(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Search items *'),
        'app',
      );
      await tester.pump();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Bread'), findsNothing);
    });

    testWidgets('Phase 1: shows "No matching items" when filter is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithList(
          list: _activeList,
          catalogItems: [_item(id: 1, serverId: 1, name: 'Apple')],
        ),
      );
      await tester.pumpAndSettle();
      await openAddItemSheet(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Search items *'),
        'zzz',
      );
      await tester.pump();

      expect(find.text('No matching items'), findsOneWidget);
    });

    testWidgets('Phase 2: tapping an item shows selected chip', (tester) async {
      await tester.pumpWidget(
        _wrapWithList(
          list: _activeList,
          catalogItems: [_item(id: 1, serverId: 1, name: 'Apple')],
        ),
      );
      await tester.pumpAndSettle();
      await openAddItemSheet(tester);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      // Phase 2: chip with item name + clear button; search field gone.
      expect(find.text('Apple'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Search items *'), findsNothing);
    });

    testWidgets('Phase 2: clear button returns to Phase 1', (tester) async {
      await tester.pumpWidget(
        _wrapWithList(
          list: _activeList,
          catalogItems: [_item(id: 1, serverId: 1, name: 'Apple')],
        ),
      );
      await tester.pumpAndSettle();
      await openAddItemSheet(tester);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Search items *'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('Add button is disabled until an item is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithList(
          list: _activeList,
          catalogItems: [_item(id: 1, serverId: 1, name: 'Apple')],
        ),
      );
      await tester.pumpAndSettle();
      await openAddItemSheet(tester);

      final addButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Add'),
      );
      expect(addButton.onPressed, isNull);
    });

    testWidgets('Add button is enabled after selecting an item', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithList(
          list: _activeList,
          catalogItems: [_item(id: 1, serverId: 1, name: 'Apple')],
        ),
      );
      await tester.pumpAndSettle();
      await openAddItemSheet(tester);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      final addButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Add'),
      );
      expect(addButton.onPressed, isNotNull);
    });
  });

  // ── Top-level ───────────────────────────────────────────────────────────────

  group('GroceryScreen – top-level', () {
    testWidgets('renders all three tab labels', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Lists'), findsOneWidget);
      expect(find.text('Pantry'), findsOneWidget);
      expect(find.text('Stores'), findsOneWidget);
    });
  });

  // ── Lists tab ───────────────────────────────────────────────────────────────

  group('GroceryScreen – Lists tab', () {
    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(_wrapLists());
      await tester.pumpAndSettle();
      expect(find.text('No grocery lists yet'), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groceryListsProvider.overrideWith(
              (_) => Stream.error(Exception('fail')),
            ),
            groceryListItemsProvider.overrideWith((_) => Stream.value([])),
            groceryItemsProvider.overrideWith((_) => Stream.value([])),
            groceryOnHandProvider.overrideWith((_) => Stream.value([])),
            groceryStoresProvider.overrideWith((_) => Stream.value([])),
            syncStateProvider.overrideWith(_NoOpSyncNotifier.new),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(body: GroceryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Error'), findsOneWidget);
    });

    testWidgets('renders list card with name and status badge', (tester) async {
      await tester.pumpWidget(_wrapLists(lists: [_activeList]));
      await tester.pumpAndSettle();
      expect(find.text('Weekly Shop'), findsOneWidget);
      expect(find.text('active'), findsOneWidget);
    });

    testWidgets('renders draft status on card', (tester) async {
      const draft = GroceryList(
        id: 2,
        name: 'Draft List',
        status: 'draft',
        syncStatus: 0,
      );
      await tester.pumpWidget(_wrapLists(lists: [draft]));
      await tester.pumpAndSettle();
      expect(find.text('draft'), findsOneWidget);
    });

    testWidgets('renders completed status on card', (tester) async {
      const done = GroceryList(
        id: 3,
        name: 'Done',
        status: 'completed',
        syncStatus: 0,
      );
      await tester.pumpWidget(_wrapLists(lists: [done]));
      await tester.pumpAndSettle();
      expect(find.text('completed'), findsOneWidget);
    });

    testWidgets('shows progress bar and count when items exist', (
      tester,
    ) async {
      const list = GroceryList(
        id: 1,
        name: 'Shop',
        status: 'active',
        syncStatus: 0,
      );
      await tester.pumpWidget(
        _wrapLists(
          lists: [list],
          allItems: [
            _listItem(id: 1, listLocalId: 1, itemServerId: 1, status: 'needed'),
            _listItem(
              id: 2,
              listLocalId: 1,
              itemServerId: 2,
              status: 'purchased',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('shows shopping date on card', (tester) async {
      const list = GroceryList(
        id: 1,
        name: 'Shop',
        status: 'draft',
        syncStatus: 0,
        shoppingDate: '2026-06-15',
      );
      await tester.pumpWidget(_wrapLists(lists: [list]));
      await tester.pumpAndSettle();
      expect(find.text('2026-06-15'), findsOneWidget);
    });

    testWidgets('delete icon is present on list card', (tester) async {
      await tester.pumpWidget(_wrapLists(lists: [_activeList]));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('FAB opens Create List sheet', (tester) async {
      await tester.pumpWidget(_wrapLists());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('New Shopping List'), findsOneWidget);
    });

    testWidgets('tapping list card navigates to detail view', (tester) async {
      await tester.pumpWidget(_wrapDetail(list: _activeList));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekly Shop'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });

  // ── Create List Sheet ───────────────────────────────────────────────────────

  group('GroceryScreen – Create List Sheet', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
    }

    testWidgets('Create button disabled initially', (tester) async {
      await tester.pumpWidget(_wrapLists());
      await tester.pumpAndSettle();
      await openSheet(tester);
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('Create button enabled after entering name', (tester) async {
      await tester.pumpWidget(_wrapLists());
      await tester.pumpAndSettle();
      await openSheet(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'List name *'),
        'My List',
      );
      await tester.pump();
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('store dropdown appears when stores exist', (tester) async {
      // Suppress RenderFlex overflow warnings: the sheet content is taller than
      // the test viewport when a store dropdown is added.
      final savedOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) {
          return;
        }
        savedOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = savedOnError);

      await tester.pumpWidget(
        _wrapLists(stores: [_store(id: 1, name: 'Walmart', serverId: 1)]),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      // The DropdownButtonHideUnderline for store selection is present.
      expect(find.byType(DropdownButtonHideUnderline), findsWidgets);
    });

    testWidgets('creates list and dismisses sheet', (tester) async {
      final db = AppDatabase.fromExecutor(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(_wrapLists(db: db));
      await tester.pumpAndSettle();
      await openSheet(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'List name *'),
        'Groceries',
      );
      await tester.pump(); // rebuild so Create button becomes enabled
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
      await tester.pumpAndSettle();
      expect(find.text('New Shopping List'), findsNothing);
      final rows = await db.select(db.groceryLists).get();
      expect(rows.length, 1);
      expect(rows.first.name, 'Groceries');
    });
  });

  // ── List Detail View ────────────────────────────────────────────────────────

  group('GroceryScreen – List Detail View', () {
    Future<void> openDetail(WidgetTester tester, String name) async {
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
    }

    testWidgets('back button returns to overview', (tester) async {
      await tester.pumpWidget(_wrapDetail(list: _activeList));
      await tester.pumpAndSettle();
      await openDetail(tester, 'Weekly Shop');
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('shows Complete button for active list', (tester) async {
      await tester.pumpWidget(_wrapDetail(list: _activeList));
      await tester.pumpAndSettle();
      await openDetail(tester, 'Weekly Shop');
      expect(find.widgetWithText(TextButton, 'Complete'), findsOneWidget);
    });

    testWidgets('shows Start button for draft list', (tester) async {
      const draft = GroceryList(
        id: 2,
        name: 'Draft',
        status: 'draft',
        syncStatus: 0,
      );
      await tester.pumpWidget(_wrapDetail(list: draft));
      await tester.pumpAndSettle();
      await openDetail(tester, 'Draft');
      expect(find.widgetWithText(TextButton, 'Start'), findsOneWidget);
    });

    testWidgets('no advance button for completed list', (tester) async {
      const done = GroceryList(
        id: 3,
        name: 'Done',
        status: 'completed',
        syncStatus: 0,
      );
      await tester.pumpWidget(_wrapDetail(list: done));
      await tester.pumpAndSettle();
      await openDetail(tester, 'Done');
      expect(find.widgetWithText(TextButton, 'Start'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Complete'), findsNothing);
    });

    testWidgets('FAB hidden for completed list', (tester) async {
      const done = GroceryList(
        id: 3,
        name: 'Done',
        status: 'completed',
        syncStatus: 0,
      );
      await tester.pumpWidget(_wrapDetail(list: done));
      await tester.pumpAndSettle();
      await openDetail(tester, 'Done');
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('shows needed item row', (tester) async {
      final catalogItem = _item(id: 1, serverId: 10, name: 'Apple');
      final listItem = _listItem(
        id: 1,
        listLocalId: 1,
        itemServerId: 10,
        status: 'needed',
      );
      await tester.pumpWidget(
        _wrapDetail(
          list: _activeList,
          listItems: [listItem],
          catalogItems: [catalogItem],
        ),
      );
      await tester.pumpAndSettle();
      await openDetail(tester, 'Weekly Shop');
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('shows Purchased header when purchased items exist', (
      tester,
    ) async {
      final catalogItem = _item(id: 1, serverId: 10, name: 'Milk');
      final listItem = _listItem(
        id: 1,
        listLocalId: 1,
        itemServerId: 10,
        status: 'purchased',
      );
      await tester.pumpWidget(
        _wrapDetail(
          list: _activeList,
          listItems: [listItem],
          catalogItems: [catalogItem],
        ),
      );
      await tester.pumpAndSettle();
      await openDetail(tester, 'Weekly Shop');
      expect(find.text('Purchased'), findsOneWidget);
    });

    testWidgets('lb unit shows whole-number qty subtitle', (tester) async {
      final catalogItem = _item(
        id: 1,
        serverId: 10,
        name: 'Sugar',
        defaultUnit: 'lb',
      );
      final listItem = _listItem(
        id: 1,
        listLocalId: 1,
        itemServerId: 10,
        quantity: 2.0,
        unit: 'lb',
        status: 'needed',
      );
      await tester.pumpWidget(
        _wrapDetail(
          list: _activeList,
          listItems: [listItem],
          catalogItems: [catalogItem],
        ),
      );
      await tester.pumpAndSettle();
      await openDetail(tester, 'Weekly Shop');
      expect(find.text('2 lb'), findsOneWidget);
    });

    testWidgets('each unit > 1 shows × count subtitle', (tester) async {
      final catalogItem = _item(id: 1, serverId: 10, name: 'Eggs');
      final listItem = _listItem(
        id: 1,
        listLocalId: 1,
        itemServerId: 10,
        quantity: 6.0,
        unit: 'each',
        status: 'needed',
      );
      await tester.pumpWidget(
        _wrapDetail(
          list: _activeList,
          listItems: [listItem],
          catalogItems: [catalogItem],
        ),
      );
      await tester.pumpAndSettle();
      await openDetail(tester, 'Weekly Shop');
      expect(find.text('× 6'), findsOneWidget);
    });

    testWidgets('fractional each qty shows as × qty', (tester) async {
      final catalogItem = _item(id: 1, serverId: 10, name: 'Apple');
      final listItem = _listItem(
        id: 1,
        listLocalId: 1,
        itemServerId: 10,
        quantity: 1.5,
        unit: 'each',
        status: 'needed',
      );
      await tester.pumpWidget(
        _wrapDetail(
          list: _activeList,
          listItems: [listItem],
          catalogItems: [catalogItem],
        ),
      );
      await tester.pumpAndSettle();
      await openDetail(tester, 'Weekly Shop');
      expect(find.text('× 1.5'), findsOneWidget);
    });

    testWidgets('fractional lb qty shows toString format', (tester) async {
      final catalogItem = _item(
        id: 1,
        serverId: 10,
        name: 'Cheese',
        defaultUnit: 'lb',
      );
      final listItem = _listItem(
        id: 1,
        listLocalId: 1,
        itemServerId: 10,
        quantity: 1.5,
        unit: 'lb',
        status: 'needed',
      );
      await tester.pumpWidget(
        _wrapDetail(
          list: _activeList,
          listItems: [listItem],
          catalogItems: [catalogItem],
        ),
      );
      await tester.pumpAndSettle();
      await openDetail(tester, 'Weekly Shop');
      expect(find.text('1.5 lb'), findsOneWidget);
    });

    testWidgets('each qty=1 has no subtitle', (tester) async {
      final catalogItem = _item(id: 1, serverId: 10, name: 'Apple');
      final listItem = _listItem(
        id: 1,
        listLocalId: 1,
        itemServerId: 10,
        quantity: 1.0,
        unit: 'each',
        status: 'needed',
      );
      await tester.pumpWidget(
        _wrapDetail(
          list: _activeList,
          listItems: [listItem],
          catalogItems: [catalogItem],
        ),
      );
      await tester.pumpAndSettle();
      await openDetail(tester, 'Weekly Shop');
      // _fmtListQty(1.0, 'each') == '' → subtitle is null
      final tile = tester.widget<ListTile>(find.byType(ListTile).first);
      expect(tile.subtitle, isNull);
    });

    testWidgets('advance active → completed updates db', (tester) async {
      final db = AppDatabase.fromExecutor(NativeDatabase.memory());
      addTearDown(db.close);
      final listId = await db.insertGroceryList(
        const GroceryListsCompanion(
          name: Value('Active'),
          status: Value('active'),
          syncStatus: Value(0),
        ),
      );
      final list = GroceryList(
        id: listId,
        name: 'Active',
        status: 'active',
        syncStatus: 0,
      );
      await tester.pumpWidget(_wrapDetail(list: list, db: db));
      await tester.pumpAndSettle();
      await openDetail(tester, 'Active');
      await tester.tap(find.widgetWithText(TextButton, 'Complete'));
      await tester.pumpAndSettle();
      final updated = await db.getGroceryListById(listId);
      expect(updated?.status, 'completed');
    });
  });

  // ── Stores tab ──────────────────────────────────────────────────────────────

  group('GroceryScreen – Stores tab', () {
    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await _goToStores(tester);
      expect(find.text('No stores yet'), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groceryListsProvider.overrideWith((_) => Stream.value([])),
            groceryListItemsProvider.overrideWith((_) => Stream.value([])),
            groceryItemsProvider.overrideWith((_) => Stream.value([])),
            groceryOnHandProvider.overrideWith((_) => Stream.value([])),
            groceryStoresProvider.overrideWith(
              (_) => Stream.error(Exception('err')),
            ),
            syncStateProvider.overrideWith(_NoOpSyncNotifier.new),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(body: GroceryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _goToStores(tester);
      expect(find.textContaining('Error'), findsOneWidget);
    });

    testWidgets('renders store name', (tester) async {
      await tester.pumpWidget(
        _wrapLists(stores: [_store(id: 1, name: 'Costco')]),
      );
      await tester.pumpAndSettle();
      await _goToStores(tester);
      expect(find.text('Costco'), findsOneWidget);
    });

    testWidgets('renders store with location subtitle', (tester) async {
      await tester.pumpWidget(
        _wrapLists(
          stores: [_store(id: 1, name: 'Aldi', location: 'Main St')],
        ),
      );
      await tester.pumpAndSettle();
      await _goToStores(tester);
      expect(find.text('Aldi'), findsOneWidget);
      expect(find.text('Main St'), findsOneWidget);
    });

    testWidgets('store without location shows no subtitle', (tester) async {
      await tester.pumpWidget(
        _wrapLists(stores: [_store(id: 1, name: 'Target')]),
      );
      await tester.pumpAndSettle();
      await _goToStores(tester);
      final tile = tester.widget<ListTile>(find.byType(ListTile).first);
      expect(tile.subtitle, isNull);
    });

    testWidgets('FAB opens Create Store sheet', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await _goToStores(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('New Store'), findsOneWidget);
    });
  });

  // ── Create Store Sheet ──────────────────────────────────────────────────────

  group('GroceryScreen – Create Store Sheet', () {
    Future<void> openSheet(WidgetTester tester) async {
      await _goToStores(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
    }

    testWidgets('Create button disabled when name empty', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await openSheet(tester);
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('Create button enabled after typing name', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await openSheet(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Store name *'),
        'Trader Joes',
      );
      await tester.pump();
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('creates store with location', (tester) async {
      final db = AppDatabase.fromExecutor(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groceryListsProvider.overrideWith((_) => Stream.value([])),
            groceryListItemsProvider.overrideWith((_) => Stream.value([])),
            groceryItemsProvider.overrideWith((_) => Stream.value([])),
            groceryOnHandProvider.overrideWith((_) => Stream.value([])),
            groceryStoresProvider.overrideWith((_) => Stream.value([])),
            syncStateProvider.overrideWith(_NoOpSyncNotifier.new),
            dbProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(body: GroceryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openSheet(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Store name *'),
        'Whole Foods',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Location (optional)'),
        '123 Market St',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
      await tester.pumpAndSettle();
      expect(find.text('New Store'), findsNothing);
      final rows = await db.select(db.groceryStores).get();
      expect(rows.length, 1);
      expect(rows.first.name, 'Whole Foods');
      expect(rows.first.location, '123 Market St');
    });

    testWidgets('creates store without location stores null', (tester) async {
      final db = AppDatabase.fromExecutor(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groceryListsProvider.overrideWith((_) => Stream.value([])),
            groceryListItemsProvider.overrideWith((_) => Stream.value([])),
            groceryItemsProvider.overrideWith((_) => Stream.value([])),
            groceryOnHandProvider.overrideWith((_) => Stream.value([])),
            groceryStoresProvider.overrideWith((_) => Stream.value([])),
            syncStateProvider.overrideWith(_NoOpSyncNotifier.new),
            dbProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(body: GroceryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openSheet(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Store name *'),
        'Aldi',
      );
      await tester.pump(); // rebuild so Create button becomes enabled
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
      await tester.pumpAndSettle();
      final rows = await db.select(db.groceryStores).get();
      expect(rows.length, 1);
      expect(rows.first.location, isNull);
    });
  });

  // ── Pantry tab edge cases ───────────────────────────────────────────────────

  group('GroceryScreen – Pantry tab edge cases', () {
    testWidgets('shows No items when catalog is empty', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await _goToPantry(tester);
      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('search filter narrows item list', (tester) async {
      await tester.pumpWidget(
        _wrap(
          items: [
            _item(id: 1, serverId: 1, name: 'Apple'),
            _item(id: 2, serverId: 2, name: 'Banana'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await _goToPantry(tester);
      await tester.enterText(find.byType(TextField).first, 'app');
      await tester.pump();
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('item without serverId is not tappable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          items: [
            GroceryItem(
              id: 1,
              serverId: null,
              name: 'NoServer',
              defaultUnit: 'each',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await _goToPantry(tester);
      expect(find.text('NoServer'), findsOneWidget);
      await tester.tap(find.text('NoServer'));
      await tester.pumpAndSettle();
      expect(find.text('Set On-Hand: NoServer'), findsNothing);
    });

    testWidgets('on-hand with lb unit shows formatted qty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          items: [_item(id: 1, serverId: 10, name: 'Flour', defaultUnit: 'lb')],
          onHand: [_onHand(id: 1, itemServerId: 10, quantity: 2.5, unit: 'lb')],
        ),
      );
      await tester.pumpAndSettle();
      await _goToPantry(tester);
      expect(find.text('2.50 lb'), findsOneWidget);
    });

    testWidgets('on-hand with zero quantity is displayed', (tester) async {
      await tester.pumpWidget(
        _wrap(
          items: [_item(id: 1, serverId: 10, name: 'Butter')],
          onHand: [_onHand(id: 1, itemServerId: 10, quantity: 0.0)],
        ),
      );
      await tester.pumpAndSettle();
      await _goToPantry(tester);
      expect(find.text('0'), findsOneWidget);
    });
  });

  // ── New Pantry Item Sheet ───────────────────────────────────────────────────

  group('GroceryScreen – New Pantry Item Sheet', () {
    testWidgets('Add button disabled when name is empty', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await _goToPantry(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('New Pantry Item'), findsOneWidget);
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Add'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('Add button enabled after entering name', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await _goToPantry(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Item name *'),
        'NewItem',
      );
      await tester.pump();
      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Add'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('shows snackbar when not configured for network', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groceryItemsProvider.overrideWith((_) => Stream.value([])),
            groceryOnHandProvider.overrideWith((_) => Stream.value([])),
            groceryListsProvider.overrideWith((_) => Stream.value([])),
            groceryListItemsProvider.overrideWith((_) => Stream.value([])),
            groceryStoresProvider.overrideWith((_) => Stream.value([])),
            syncStateProvider.overrideWith(_NoOpSyncNotifier.new),
            baseUrlProvider.overrideWith(() => _EmptyBaseUrlNotifier()),
            isOnlineProvider.overrideWith(() => _OnlineConnectivityNotifier()),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(body: GroceryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _goToPantry(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Item name *'),
        'NewItem',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pump();
      expect(find.textContaining('Connect to the network'), findsOneWidget);
    });
  });

  // ── Add Item Sheet (write path) ─────────────────────────────────────────────

  group('GroceryScreen – Add Item Sheet (write)', () {
    testWidgets('shows placeholder when no catalog items', (tester) async {
      await tester.pumpWidget(
        _wrapWithList(list: _activeList, catalogItems: []),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekly Shop'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('No catalog items available'), findsOneWidget);
    });

    testWidgets('adds item to list and dismisses sheet', (tester) async {
      final db = AppDatabase.fromExecutor(NativeDatabase.memory());
      addTearDown(db.close);
      final catalogItem = _item(id: 1, serverId: 10, name: 'Apple');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groceryListsProvider.overrideWith(
              (_) => Stream.value([_activeList]),
            ),
            groceryListItemsProvider.overrideWith((_) => Stream.value([])),
            groceryListItemsForListProvider(
              _activeList.id,
            ).overrideWith((_) => Stream.value([])),
            groceryItemsProvider.overrideWith(
              (_) => Stream.value([catalogItem]),
            ),
            groceryOnHandProvider.overrideWith((_) => Stream.value([])),
            groceryStoresProvider.overrideWith((_) => Stream.value([])),
            syncStateProvider.overrideWith(_NoOpSyncNotifier.new),
            dbProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(body: GroceryScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekly Shop'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Add Item to'), findsNothing);
      final rows = await db.select(db.groceryListItems).get();
      expect(rows.length, 1);
      expect(rows.first.itemServerId, 10);
    });
  });
}
