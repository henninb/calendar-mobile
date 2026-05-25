import 'package:calendar_mobile/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDatabase constructors', () {
    test('forTesting constructor opens an in-memory database', () async {
      final db = AppDatabase.forTesting(
        DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(db.close);

      // Force schema creation and verify the DB is usable.
      final cats = await db.getAllCategories();
      expect(cats, isEmpty);
    });

    test('forTesting database supports full DAO operations', () async {
      final db = AppDatabase.forTesting(
        DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(db.close);

      await db.upsertCategories([
        const CategoriesCompanion(serverId: Value(1), name: Value('Test')),
      ]);

      final cats = await db.getAllCategories();
      expect(cats.length, 1);
      expect(cats.first.name, 'Test');
    });

    test('_nextSyncStatus preserves non-synced status', () async {
      final db = AppDatabase.fromExecutor(NativeDatabase.memory());
      addTearDown(db.close);

      // Insert with pendingCreate (1) and call updateOccurrenceStatus —
      // _nextSyncStatus should keep pendingCreate, not downgrade to pendingUpdate.
      final id = await db
          .into(db.occurrences)
          .insert(
            const OccurrencesCompanion(
              eventServerId: Value(99),
              occurrenceDate: Value('2026-01-01'),
              syncStatus: Value(1), // pendingCreate
            ),
          );

      await db.updateOccurrenceStatus(id, 'completed');

      final row = await (db.select(
        db.occurrences,
      )..where((o) => o.id.equals(id))).getSingle();
      expect(row.syncStatus, 1); // still pendingCreate
    });
  });
}
