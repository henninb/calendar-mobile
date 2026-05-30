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
}
