import 'package:calendar_mobile/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.fromExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Category DAO', () {
    test('upsert and get all categories', () async {
      await database.upsertCategories([
        const CategoriesCompanion(
          serverId: Value(1),
          name: Value('Work'),
          color: Value('#ff0000'),
          icon: Value('💼'),
        ),
      ]);

      final categories = await database.getAllCategories();
      expect(categories.length, 1);
      expect(categories.first.name, 'Work');
    });

    test('watchCategories emits updates', () async {
      final stream = database.watchCategories();
      
      final expectation = expectLater(
        stream,
        emitsInOrder([
          isEmpty,
          hasLength(1),
        ]),
      );

      // Delay to ensure the first (empty) event is emitted and captured
      await Future.delayed(Duration.zero);

      await database.upsertCategories([
        const CategoriesCompanion(
          serverId: Value(1),
          name: Value('Work'),
        ),
      ]);

      await expectation;
    });
  });

  group('Occurrence DAO', () {
    test('getOccurrencesByDateRange filters correctly', () async {
      await database.upsertOccurrences([
        const OccurrencesCompanion(
          serverId: Value(1),
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
        ),
        const OccurrencesCompanion(
          serverId: Value(2),
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-15'),
        ),
        const OccurrencesCompanion(
          serverId: Value(3),
          eventServerId: Value(100),
          occurrenceDate: Value('2026-06-01'),
        ),
      ]);

      final results = await database.getOccurrencesByDateRange('2026-05-01', '2026-05-31');
      expect(results.length, 2);
      expect(results[0].occurrenceDate, '2026-05-01');
      expect(results[1].occurrenceDate, '2026-05-15');
    });

    test('updateOccurrenceStatus updates status and syncStatus', () async {
      final id = await database.into(database.occurrences).insert(
        const OccurrencesCompanion(
          serverId: Value(1),
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
          status: Value('upcoming'),
          syncStatus: Value(0),
        ),
      );

      await database.updateOccurrenceStatus(id, 'completed');

      final updated = await (database.select(database.occurrences)..where((o) => o.id.equals(id))).getSingle();
      expect(updated.status, 'completed');
      expect(updated.syncStatus, isNot(0));
    });
  });

  group('Task DAO', () {
    test('markTaskSynced updates serverId and back-fills subtasks', () async {
      final taskId = await database.insertTask(
        const TasksCompanion(
          title: Value('Task'),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );

      final subtaskId = await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('Subtask'),
        ),
      );

      await database.markTaskSynced(taskId, 500);

      final task = await database.getTaskById(taskId);
      expect(task!.serverId, 500);

      final subtask = await (database.select(database.subtasks)..where((s) => s.id.equals(subtaskId))).getSingle();
      expect(subtask.taskServerId, 500);
    });
  });
}
