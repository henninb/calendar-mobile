import 'package:calendar_mobile/core/constants.dart';
import 'package:calendar_mobile/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.fromExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  // ── Category DAO ─────────────────────────────────────────────────────────

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

      final cats = await database.getAllCategories();
      expect(cats.length, 1);
      expect(cats.first.name, 'Work');
    });

    test('upsert updates existing row on serverId conflict', () async {
      await database.upsertCategories([
        const CategoriesCompanion(serverId: Value(1), name: Value('Old')),
      ]);
      await database.upsertCategories([
        const CategoriesCompanion(serverId: Value(1), name: Value('New')),
      ]);

      final cats = await database.getAllCategories();
      expect(cats.length, 1);
      expect(cats.first.name, 'New');
    });

    test('watchCategories emits updates', () async {
      final stream = database.watchCategories();

      final expectation = expectLater(
        stream,
        emitsInOrder([isEmpty, hasLength(1)]),
      );

      await Future.delayed(Duration.zero);

      await database.upsertCategories([
        const CategoriesCompanion(serverId: Value(1), name: Value('Work')),
      ]);

      await expectation;
    });
  });

  // ── Person DAO ───────────────────────────────────────────────────────────

  group('Person DAO', () {
    test('upsert and get all persons', () async {
      await database.upsertPersons([
        const PersonsCompanion(
          serverId: Value(1),
          name: Value('Alice'),
          email: Value('alice@example.com'),
        ),
      ]);

      final persons = await database.getAllPersons();
      expect(persons.length, 1);
      expect(persons.first.name, 'Alice');
      expect(persons.first.email, 'alice@example.com');
    });

    test('upsert updates existing person on serverId conflict', () async {
      await database.upsertPersons([
        const PersonsCompanion(serverId: Value(10), name: Value('Bob')),
      ]);
      await database.upsertPersons([
        const PersonsCompanion(
          serverId: Value(10),
          name: Value('Bob Updated'),
          email: Value('bob@example.com'),
        ),
      ]);

      final persons = await database.getAllPersons();
      expect(persons.length, 1);
      expect(persons.first.name, 'Bob Updated');
    });

    test('watchPersons emits updates', () async {
      final stream = database.watchPersons();

      final expectation = expectLater(
        stream,
        emitsInOrder([isEmpty, hasLength(1)]),
      );

      await Future.delayed(Duration.zero);
      await database.upsertPersons([
        const PersonsCompanion(serverId: Value(1), name: Value('Carol')),
      ]);

      await expectation;
    });

    test('upsert multiple persons', () async {
      await database.upsertPersons([
        const PersonsCompanion(serverId: Value(1), name: Value('A')),
        const PersonsCompanion(serverId: Value(2), name: Value('B')),
        const PersonsCompanion(serverId: Value(3), name: Value('C')),
      ]);

      final persons = await database.getAllPersons();
      expect(persons.length, 3);
    });
  });

  // ── Event DAO ────────────────────────────────────────────────────────────

  group('Event DAO', () {
    test('upsert and get all events', () async {
      await database.upsertEvents([
        const EventsCompanion(
          serverId: Value(1),
          title: Value('Team meeting'),
          categoryServerId: Value(10),
          dtstart: Value('2026-05-01'),
        ),
      ]);

      final events = await database.getAllEvents();
      expect(events.length, 1);
      expect(events.first.title, 'Team meeting');
    });

    test('upsert updates existing event on serverId conflict', () async {
      await database.upsertEvents([
        const EventsCompanion(
          serverId: Value(1),
          title: Value('Old title'),
          categoryServerId: Value(10),
          dtstart: Value('2026-05-01'),
        ),
      ]);
      await database.upsertEvents([
        const EventsCompanion(
          serverId: Value(1),
          title: Value('New title'),
          categoryServerId: Value(10),
          dtstart: Value('2026-05-01'),
        ),
      ]);

      final events = await database.getAllEvents();
      expect(events.length, 1);
      expect(events.first.title, 'New title');
    });

    test('watchEvents emits updates', () async {
      final stream = database.watchEvents();

      final expectation = expectLater(
        stream,
        emitsInOrder([isEmpty, hasLength(1)]),
      );

      await Future.delayed(Duration.zero);
      await database.upsertEvents([
        const EventsCompanion(
          serverId: Value(1),
          title: Value('Event'),
          categoryServerId: Value(10),
          dtstart: Value('2026-05-01'),
        ),
      ]);

      await expectation;
    });

    test('event default values are applied', () async {
      await database.upsertEvents([
        const EventsCompanion(
          serverId: Value(1),
          title: Value('Minimal event'),
          categoryServerId: Value(10),
          dtstart: Value('2026-05-01'),
        ),
      ]);

      final events = await database.getAllEvents();
      expect(events.first.priority, 'medium');
      expect(events.first.isActive, true);
      expect(events.first.durationDays, 1);
    });
  });

  // ── Occurrence DAO ───────────────────────────────────────────────────────

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

      final results = await database.getOccurrencesByDateRange(
        '2026-05-01',
        '2026-05-31',
      );
      expect(results.length, 2);
      expect(results[0].occurrenceDate, '2026-05-01');
      expect(results[1].occurrenceDate, '2026-05-15');
    });

    test('getOccurrencesByDateRange returns empty when no matches', () async {
      await database.upsertOccurrences([
        const OccurrencesCompanion(
          serverId: Value(1),
          eventServerId: Value(100),
          occurrenceDate: Value('2026-07-01'),
        ),
      ]);

      final results = await database.getOccurrencesByDateRange(
        '2026-05-01',
        '2026-05-31',
      );
      expect(results, isEmpty);
    });

    test('getPendingOccurrences returns only non-zero syncStatus', () async {
      await database.upsertOccurrences([
        const OccurrencesCompanion(
          serverId: Value(1),
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
          syncStatus: Value(0),
        ),
      ]);
      final id2 = await database.into(database.occurrences).insert(
        const OccurrencesCompanion(
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-02'),
          syncStatus: Value(1),
        ),
      );

      final pending = await database.getPendingOccurrences();
      expect(pending.length, 1);
      expect(pending.first.id, id2);
    });

    test('updateOccurrenceStatus updates status and sets pendingUpdate', () async {
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

      final updated = await (database.select(database.occurrences)
            ..where((o) => o.id.equals(id)))
          .getSingle();
      expect(updated.status, 'completed');
      expect(updated.syncStatus, SyncStatus.pendingUpdate.value);
    });

    test(
      'updateOccurrenceStatus preserves pendingCreate syncStatus',
      () async {
        final id = await database.into(database.occurrences).insert(
          const OccurrencesCompanion(
            eventServerId: Value(100),
            occurrenceDate: Value('2026-05-01'),
            syncStatus: Value(1),
          ),
        );

        await database.updateOccurrenceStatus(id, 'completed');

        final updated = await (database.select(database.occurrences)
              ..where((o) => o.id.equals(id)))
            .getSingle();
        expect(updated.syncStatus, SyncStatus.pendingCreate.value);
      },
    );

    test('updateOccurrenceStatus no-ops for non-existent id', () async {
      await database.updateOccurrenceStatus(999, 'completed');
    });

    test('markOccurrenceSynced sets serverId and clears syncStatus', () async {
      final id = await database.into(database.occurrences).insert(
        const OccurrencesCompanion(
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
          syncStatus: Value(1),
        ),
      );

      await database.markOccurrenceSynced(id, 42);

      final row = await (database.select(database.occurrences)
            ..where((o) => o.id.equals(id)))
          .getSingle();
      expect(row.serverId, 42);
      expect(row.syncStatus, SyncStatus.synced.value);
    });

    test(
      'markOccurrenceDeleted purges local-only occurrence (no serverId)',
      () async {
        final id = await database.into(database.occurrences).insert(
          const OccurrencesCompanion(
            eventServerId: Value(100),
            occurrenceDate: Value('2026-05-01'),
          ),
        );

        await database.markOccurrenceDeleted(id);

        final rows = await database.getOccurrences();
        expect(rows, isEmpty);
      },
    );

    test(
      'markOccurrenceDeleted sets pendingDelete for synced occurrence',
      () async {
        final id = await database.into(database.occurrences).insert(
          const OccurrencesCompanion(
            serverId: Value(5),
            eventServerId: Value(100),
            occurrenceDate: Value('2026-05-01'),
            syncStatus: Value(0),
          ),
        );

        await database.markOccurrenceDeleted(id);

        final row = await (database.select(database.occurrences)
              ..where((o) => o.id.equals(id)))
            .getSingle();
        expect(row.syncStatus, SyncStatus.pendingDelete.value);
      },
    );

    test('markOccurrenceDeleted no-ops for non-existent id', () async {
      await database.markOccurrenceDeleted(999);
    });

    test('deleteOccurrenceLocal removes the row', () async {
      final id = await database.into(database.occurrences).insert(
        const OccurrencesCompanion(
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
        ),
      );

      await database.deleteOccurrenceLocal(id);

      final rows = await database.getOccurrences();
      expect(rows, isEmpty);
    });

    test('deleteOccurrencesLocalBatch removes all specified rows', () async {
      final id1 = await database.into(database.occurrences).insert(
        const OccurrencesCompanion(
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
        ),
      );
      final id2 = await database.into(database.occurrences).insert(
        const OccurrencesCompanion(
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-02'),
        ),
      );
      await database.into(database.occurrences).insert(
        const OccurrencesCompanion(
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-03'),
        ),
      );

      await database.deleteOccurrencesLocalBatch([id1, id2]);

      final rows = await database.getOccurrences();
      expect(rows.length, 1);
      expect(rows.first.occurrenceDate, '2026-05-03');
    });

    test('deleteOccurrencesLocalBatch is no-op for empty list', () async {
      await database.into(database.occurrences).insert(
        const OccurrencesCompanion(
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
        ),
      );

      await database.deleteOccurrencesLocalBatch([]);

      final rows = await database.getOccurrences();
      expect(rows.length, 1);
    });

    test('watchOccurrences emits updates', () async {
      final stream = database.watchOccurrences();

      final expectation = expectLater(
        stream,
        emitsInOrder([isEmpty, hasLength(1)]),
      );

      await Future.delayed(Duration.zero);
      await database.upsertOccurrences([
        const OccurrencesCompanion(
          serverId: Value(1),
          eventServerId: Value(100),
          occurrenceDate: Value('2026-05-01'),
        ),
      ]);

      await expectation;
    });
  });

  // ── Task DAO ─────────────────────────────────────────────────────────────

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

      final subtask = await (database.select(database.subtasks)
            ..where((s) => s.id.equals(subtaskId)))
          .getSingle();
      expect(subtask.taskServerId, 500);
    });

    test('getTasks returns all tasks', () async {
      await database.insertTask(
        const TasksCompanion(
          title: Value('Task A'),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );
      await database.insertTask(
        const TasksCompanion(
          title: Value('Task B'),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );

      final tasks = await database.getTasks();
      expect(tasks.length, 2);
    });

    test('getPendingTasks returns only tasks with non-zero syncStatus', () async {
      await database.insertTask(
        const TasksCompanion(
          title: Value('Synced'),
          syncStatus: Value(0),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );
      final pendingId = await database.insertTask(
        const TasksCompanion(
          title: Value('Pending'),
          syncStatus: Value(1),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );

      final pending = await database.getPendingTasks();
      expect(pending.length, 1);
      expect(pending.first.id, pendingId);
    });

    test('updateTask modifies the specified task', () async {
      final id = await database.insertTask(
        const TasksCompanion(
          title: Value('Original'),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );

      await database.updateTask(
        id,
        const TasksCompanion(
          title: Value('Updated'),
          status: Value('done'),
          updatedAt: Value('2026-01-02'),
        ),
      );

      final task = await database.getTaskById(id);
      expect(task!.title, 'Updated');
      expect(task.status, 'done');
    });

    test('getTaskById returns null for non-existent id', () async {
      final task = await database.getTaskById(999);
      expect(task, isNull);
    });

    test(
      'markTaskDeleted purges local-only task (no serverId)',
      () async {
        final id = await database.insertTask(
          const TasksCompanion(
            title: Value('Local only'),
            createdAt: Value('2026-01-01'),
            updatedAt: Value('2026-01-01'),
          ),
        );

        await database.markTaskDeleted(id);

        final task = await database.getTaskById(id);
        expect(task, isNull);
      },
    );

    test('markTaskDeleted sets pendingDelete for synced task', () async {
      final id = await database.insertTask(
        const TasksCompanion(
          serverId: Value(10),
          title: Value('Synced task'),
          syncStatus: Value(0),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );

      await database.markTaskDeleted(id);

      final task = await database.getTaskById(id);
      expect(task!.syncStatus, SyncStatus.pendingDelete.value);
    });

    test('markTaskDeleted no-ops for non-existent id', () async {
      await database.markTaskDeleted(999);
    });

    test('deleteTaskLocal removes task and its subtasks', () async {
      final taskId = await database.insertTask(
        const TasksCompanion(
          title: Value('Task with subtasks'),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );
      await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('Sub 1'),
        ),
      );
      await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('Sub 2'),
        ),
      );

      await database.deleteTaskLocal(taskId);

      final tasks = await database.getTasks();
      expect(tasks, isEmpty);
      final subs = await database.getAllSubtasks();
      expect(subs, isEmpty);
    });

    test('upsertTasks updates on serverId conflict', () async {
      await database.upsertTasks([
        const TasksCompanion(
          serverId: Value(1),
          title: Value('Old'),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      ]);
      await database.upsertTasks([
        const TasksCompanion(
          serverId: Value(1),
          title: Value('New'),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-02'),
        ),
      ]);

      final tasks = await database.getTasks();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'New');
    });

    test('deleteTasksLocalBatch removes tasks and their subtasks', () async {
      final id1 = await database.insertTask(
        const TasksCompanion(
          title: Value('T1'),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );
      final id2 = await database.insertTask(
        const TasksCompanion(
          title: Value('T2'),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );
      await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(id1),
          title: const Value('S1'),
        ),
      );

      await database.deleteTasksLocalBatch([id1, id2]);

      expect(await database.getTasks(), isEmpty);
      expect(await database.getAllSubtasks(), isEmpty);
    });

    test('deleteTasksLocalBatch is no-op for empty list', () async {
      await database.insertTask(
        const TasksCompanion(
          title: Value('Keep me'),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );

      await database.deleteTasksLocalBatch([]);

      expect(await database.getTasks(), hasLength(1));
    });

    test('watchTasks emits updates', () async {
      final stream = database.watchTasks();

      final expectation = expectLater(
        stream,
        emitsInOrder([isEmpty, hasLength(1)]),
      );

      await Future.delayed(Duration.zero);
      await database.insertTask(
        const TasksCompanion(
          title: Value('Task'),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );

      await expectation;
    });
  });

  // ── Subtask DAO ──────────────────────────────────────────────────────────

  group('Subtask DAO', () {
    late int taskId;

    setUp(() async {
      taskId = await database.insertTask(
        const TasksCompanion(
          title: Value('Parent task'),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );
    });

    test('insert and getAllSubtasks', () async {
      await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('Do something'),
        ),
      );

      final subs = await database.getAllSubtasks();
      expect(subs.length, 1);
      expect(subs.first.title, 'Do something');
    });

    test('getSubtasksForTask returns in order', () async {
      await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('B'),
          order: const Value(2),
        ),
      );
      await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('A'),
          order: const Value(1),
        ),
      );

      final subs = await database.getSubtasksForTask(taskId);
      expect(subs.length, 2);
      expect(subs[0].title, 'A');
      expect(subs[1].title, 'B');
    });

    test('getSubtasksForTask returns empty for unknown taskId', () async {
      final subs = await database.getSubtasksForTask(999);
      expect(subs, isEmpty);
    });

    test('getPendingSubtasks returns only non-zero syncStatus', () async {
      await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('Synced'),
          syncStatus: const Value(0),
        ),
      );
      final pendingId = await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('Pending'),
          syncStatus: const Value(1),
        ),
      );

      final pending = await database.getPendingSubtasks();
      expect(pending.length, 1);
      expect(pending.first.id, pendingId);
    });

    test('updateSubtask modifies the row', () async {
      final id = await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('Old'),
        ),
      );

      await database.updateSubtask(
        id,
        const SubtasksCompanion(
          title: Value('New'),
          status: Value('done'),
        ),
      );

      final sub = await (database.select(database.subtasks)
            ..where((s) => s.id.equals(id)))
          .getSingle();
      expect(sub.title, 'New');
      expect(sub.status, 'done');
    });

    test(
      'markSubtaskDeleted purges local-only subtask (no serverId)',
      () async {
        final id = await database.insertSubtask(
          SubtasksCompanion(
            taskLocalId: Value(taskId),
            title: const Value('Local only'),
          ),
        );

        await database.markSubtaskDeleted(id);

        expect(await database.getAllSubtasks(), isEmpty);
      },
    );

    test('markSubtaskDeleted sets pendingDelete for synced subtask', () async {
      final id = await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('Synced'),
          serverId: const Value(20),
          syncStatus: const Value(0),
        ),
      );

      await database.markSubtaskDeleted(id);

      final sub = await (database.select(database.subtasks)
            ..where((s) => s.id.equals(id)))
          .getSingle();
      expect(sub.syncStatus, SyncStatus.pendingDelete.value);
    });

    test('markSubtaskDeleted no-ops for non-existent id', () async {
      await database.markSubtaskDeleted(999);
    });

    test('markSubtaskSynced sets serverId and syncStatus', () async {
      final id = await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('Sub'),
          syncStatus: const Value(1),
        ),
      );

      await database.markSubtaskSynced(id, 77);

      final sub = await (database.select(database.subtasks)
            ..where((s) => s.id.equals(id)))
          .getSingle();
      expect(sub.serverId, 77);
      expect(sub.syncStatus, SyncStatus.synced.value);
    });

    test('deleteSubtaskLocal removes the row', () async {
      final id = await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('Delete me'),
        ),
      );

      await database.deleteSubtaskLocal(id);

      expect(await database.getAllSubtasks(), isEmpty);
    });

    test('deleteSubtasksLocalBatch removes specified rows', () async {
      final id1 = await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('S1'),
        ),
      );
      final id2 = await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('S2'),
        ),
      );
      await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('S3'),
        ),
      );

      await database.deleteSubtasksLocalBatch([id1, id2]);

      final remaining = await database.getAllSubtasks();
      expect(remaining.length, 1);
      expect(remaining.first.title, 'S3');
    });

    test('deleteSubtasksLocalBatch is no-op for empty list', () async {
      await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('Keep'),
        ),
      );

      await database.deleteSubtasksLocalBatch([]);

      expect(await database.getAllSubtasks(), hasLength(1));
    });

    test('upsertSubtasks updates on serverId conflict', () async {
      await database.upsertSubtasks([
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          serverId: const Value(1),
          title: const Value('Old'),
        ),
      ]);
      await database.upsertSubtasks([
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          serverId: const Value(1),
          title: const Value('New'),
        ),
      ]);

      final subs = await database.getAllSubtasks();
      expect(subs.length, 1);
      expect(subs.first.title, 'New');
    });

    test('watchSubtasksForTask emits updates', () async {
      final stream = database.watchSubtasksForTask(taskId);

      final expectation = expectLater(
        stream,
        emitsInOrder([isEmpty, hasLength(1)]),
      );

      await Future.delayed(Duration.zero);
      await database.insertSubtask(
        SubtasksCompanion(
          taskLocalId: Value(taskId),
          title: const Value('New sub'),
        ),
      );

      await expectation;
    });
  });

  // ── Credit Card DAO ──────────────────────────────────────────────────────

  group('Credit Card DAO', () {
    test('insert and getCreditCards', () async {
      await database.insertCreditCard(
        const CreditCardsCompanion(
          serverId: Value(1),
          name: Value('Visa Platinum'),
          syncStatus: Value(0),
        ),
      );

      final cards = await database.getCreditCards();
      expect(cards.length, 1);
      expect(cards.first.name, 'Visa Platinum');
    });

    test('getPendingCreditCards returns only non-zero syncStatus', () async {
      await database.insertCreditCard(
        const CreditCardsCompanion(
          serverId: Value(1),
          name: Value('Synced'),
          syncStatus: Value(0),
        ),
      );
      final pendingId = await database.insertCreditCard(
        const CreditCardsCompanion(
          name: Value('Pending'),
          syncStatus: Value(1),
        ),
      );

      final pending = await database.getPendingCreditCards();
      expect(pending.length, 1);
      expect(pending.first.id, pendingId);
    });

    test('updateCreditCard modifies the row', () async {
      final id = await database.insertCreditCard(
        const CreditCardsCompanion(name: Value('Old name')),
      );

      await database.updateCreditCard(
        id,
        const CreditCardsCompanion(name: Value('New name')),
      );

      final cards = await database.getCreditCards();
      expect(cards.first.name, 'New name');
    });

    test(
      'markCreditCardDeleted purges local-only card (no serverId)',
      () async {
        final id = await database.insertCreditCard(
          const CreditCardsCompanion(name: Value('Local')),
        );

        await database.markCreditCardDeleted(id);

        expect(await database.getCreditCards(), isEmpty);
      },
    );

    test('markCreditCardDeleted sets pendingDelete for synced card', () async {
      final id = await database.insertCreditCard(
        const CreditCardsCompanion(
          serverId: Value(5),
          name: Value('Synced'),
          syncStatus: Value(0),
        ),
      );

      await database.markCreditCardDeleted(id);

      final cards = await database.getCreditCards();
      expect(cards.first.syncStatus, SyncStatus.pendingDelete.value);
    });

    test('markCreditCardDeleted no-ops for non-existent id', () async {
      await database.markCreditCardDeleted(999);
    });

    test('markCreditCardSynced sets serverId and clears syncStatus', () async {
      final id = await database.insertCreditCard(
        const CreditCardsCompanion(
          name: Value('Card'),
          syncStatus: Value(1),
        ),
      );

      await database.markCreditCardSynced(id, 99);

      final cards = await database.getCreditCards();
      expect(cards.first.serverId, 99);
      expect(cards.first.syncStatus, SyncStatus.synced.value);
    });

    test('deleteCreditCardLocal removes the row', () async {
      final id = await database.insertCreditCard(
        const CreditCardsCompanion(name: Value('Delete me')),
      );

      await database.deleteCreditCardLocal(id);

      expect(await database.getCreditCards(), isEmpty);
    });

    test('upsertCreditCards updates on serverId conflict', () async {
      await database.upsertCreditCards([
        const CreditCardsCompanion(serverId: Value(1), name: Value('Old')),
      ]);
      await database.upsertCreditCards([
        const CreditCardsCompanion(serverId: Value(1), name: Value('New')),
      ]);

      final cards = await database.getCreditCards();
      expect(cards.length, 1);
      expect(cards.first.name, 'New');
    });

    test('watchCreditCards emits updates', () async {
      final stream = database.watchCreditCards();

      final expectation = expectLater(
        stream,
        emitsInOrder([isEmpty, hasLength(1)]),
      );

      await Future.delayed(Duration.zero);
      await database.insertCreditCard(
        const CreditCardsCompanion(name: Value('Card')),
      );

      await expectation;
    });
  });

  // ── Credit Card Tracker Cache DAO ────────────────────────────────────────

  group('CreditCardTrackerCache DAO', () {
    CreditCardTrackerCacheCompanion _makeEntry(int cardServerId) =>
        CreditCardTrackerCacheCompanion(
          cardServerId: Value(cardServerId),
          name: const Value('Test Card'),
          grace: const Value('2026-05-15'),
          prevClose: const Value('2026-04-15'),
          prevDue: const Value('2026-05-05'),
          nextClose: const Value('2026-05-15'),
          nextCloseDays: const Value(7),
          nextDue: const Value('2026-06-05'),
          nextDueDays: const Value(28),
        );

    test('replaceTrackerCache inserts rows', () async {
      await database.replaceTrackerCache([_makeEntry(1), _makeEntry(2)]);

      final rows = await database.getTrackerCache();
      expect(rows.length, 2);
    });

    test('replaceTrackerCache replaces previous rows', () async {
      await database.replaceTrackerCache([_makeEntry(1), _makeEntry(2)]);
      await database.replaceTrackerCache([_makeEntry(3)]);

      final rows = await database.getTrackerCache();
      expect(rows.length, 1);
      expect(rows.first.cardServerId, 3);
    });

    test('replaceTrackerCache with empty list clears the table', () async {
      await database.replaceTrackerCache([_makeEntry(1)]);
      await database.replaceTrackerCache([]);

      expect(await database.getTrackerCache(), isEmpty);
    });

    test('watchTrackerCache emits updates', () async {
      final stream = database.watchTrackerCache();

      final expectation = expectLater(
        stream,
        emitsInOrder([isEmpty, hasLength(1)]),
      );

      await Future.delayed(Duration.zero);
      await database.replaceTrackerCache([_makeEntry(1)]);

      await expectation;
    });
  });

  // ── Grocery Store DAO ────────────────────────────────────────────────────

  group('Grocery Store DAO', () {
    test('insert and watchGroceryStores', () async {
      await database.insertGroceryStore(
        const GroceryStoresCompanion(
          serverId: Value(1),
          name: Value('Whole Foods'),
        ),
      );

      final stores = await (database.select(database.groceryStores)).get();
      expect(stores.length, 1);
      expect(stores.first.name, 'Whole Foods');
    });

    test('upsertGroceryStores updates on serverId conflict', () async {
      await database.upsertGroceryStores([
        const GroceryStoresCompanion(serverId: Value(1), name: Value('Old')),
      ]);
      await database.upsertGroceryStores([
        const GroceryStoresCompanion(serverId: Value(1), name: Value('New')),
      ]);

      final stores = await (database.select(database.groceryStores)).get();
      expect(stores.length, 1);
      expect(stores.first.name, 'New');
    });

    test('getPendingGroceryStores returns non-zero syncStatus rows', () async {
      await database.upsertGroceryStores([
        const GroceryStoresCompanion(
          serverId: Value(1),
          name: Value('Synced'),
          syncStatus: Value(0),
        ),
      ]);
      final pendingId = await database.insertGroceryStore(
        const GroceryStoresCompanion(
          name: Value('Pending'),
          syncStatus: Value(1),
        ),
      );

      final pending = await database.getPendingGroceryStores();
      expect(pending.length, 1);
      expect(pending.first.id, pendingId);
    });

    test('markGroceryStoreSynced sets serverId and clears syncStatus', () async {
      final id = await database.insertGroceryStore(
        const GroceryStoresCompanion(
          name: Value('Store'),
          syncStatus: Value(1),
        ),
      );

      await database.markGroceryStoreSynced(id, 55);

      final store = await (database.select(database.groceryStores)
            ..where((s) => s.id.equals(id)))
          .getSingle();
      expect(store.serverId, 55);
      expect(store.syncStatus, SyncStatus.synced.value);
    });

    test(
      'markGroceryStoreDeleted purges local-only store (no serverId)',
      () async {
        final id = await database.insertGroceryStore(
          const GroceryStoresCompanion(name: Value('Local')),
        );

        await database.markGroceryStoreDeleted(id);

        expect(
          await (database.select(database.groceryStores)).get(),
          isEmpty,
        );
      },
    );

    test(
      'markGroceryStoreDeleted sets pendingDelete for synced store',
      () async {
        final id = await database.insertGroceryStore(
          const GroceryStoresCompanion(
            serverId: Value(3),
            name: Value('Synced'),
            syncStatus: Value(0),
          ),
        );

        await database.markGroceryStoreDeleted(id);

        final store = await (database.select(database.groceryStores)
              ..where((s) => s.id.equals(id)))
            .getSingle();
        expect(store.syncStatus, SyncStatus.pendingDelete.value);
      },
    );

    test('markGroceryStoreDeleted no-ops for non-existent id', () async {
      await database.markGroceryStoreDeleted(999);
    });

    test('deleteGroceryStoreLocal removes the row', () async {
      final id = await database.insertGroceryStore(
        const GroceryStoresCompanion(name: Value('Delete me')),
      );

      await database.deleteGroceryStoreLocal(id);

      expect(await (database.select(database.groceryStores)).get(), isEmpty);
    });

    test('purgeGroceryStores removes stores not in keepSet', () async {
      await database.upsertGroceryStores([
        const GroceryStoresCompanion(serverId: Value(1), name: Value('Keep')),
        const GroceryStoresCompanion(serverId: Value(2), name: Value('Remove')),
        const GroceryStoresCompanion(
          serverId: Value(3),
          name: Value('Also keep'),
        ),
      ]);

      await database.purgeGroceryStores({1, 3});

      final stores = await (database.select(database.groceryStores)).get();
      expect(stores.length, 2);
      expect(stores.map((s) => s.serverId), containsAll([1, 3]));
    });

    test('purgeGroceryStores preserves local-only stores (null serverId)',
        () async {
      await database.insertGroceryStore(
        const GroceryStoresCompanion(name: Value('Local only')),
      );

      await database.purgeGroceryStores({});

      expect(await (database.select(database.groceryStores)).get(), hasLength(1));
    });

    test('watchGroceryStores emits updates', () async {
      final stream = database.watchGroceryStores();

      final expectation = expectLater(
        stream,
        emitsInOrder([isEmpty, hasLength(1)]),
      );

      await Future.delayed(Duration.zero);
      await database.insertGroceryStore(
        const GroceryStoresCompanion(name: Value('Store')),
      );

      await expectation;
    });
  });

  // ── Grocery Item DAO ─────────────────────────────────────────────────────

  group('Grocery Item DAO', () {
    test('upsert and getGroceryItems', () async {
      await database.upsertGroceryItems([
        const GroceryItemsCompanion(serverId: Value(1), name: Value('Milk')),
        const GroceryItemsCompanion(serverId: Value(2), name: Value('Eggs')),
      ]);

      final items = await database.getGroceryItems();
      expect(items.length, 2);
    });

    test('upsertGroceryItems updates on serverId conflict', () async {
      await database.upsertGroceryItems([
        const GroceryItemsCompanion(serverId: Value(1), name: Value('Old')),
      ]);
      await database.upsertGroceryItems([
        const GroceryItemsCompanion(serverId: Value(1), name: Value('New')),
      ]);

      final items = await database.getGroceryItems();
      expect(items.length, 1);
      expect(items.first.name, 'New');
    });

    test('purgeGroceryItems removes items not in keepSet', () async {
      await database.upsertGroceryItems([
        const GroceryItemsCompanion(serverId: Value(1), name: Value('Keep')),
        const GroceryItemsCompanion(serverId: Value(2), name: Value('Remove')),
      ]);

      await database.purgeGroceryItems({1});

      final items = await database.getGroceryItems();
      expect(items.length, 1);
      expect(items.first.serverId, 1);
    });

    test('purgeGroceryItems preserves items without serverId', () async {
      await database.into(database.groceryItems).insert(
        const GroceryItemsCompanion(name: Value('Local only')),
      );

      await database.purgeGroceryItems({});

      expect(await database.getGroceryItems(), hasLength(1));
    });

    test('watchGroceryItems emits alphabetically ordered updates', () async {
      final stream = database.watchGroceryItems();

      final expectation = expectLater(
        stream,
        emitsInOrder([
          isEmpty,
          predicate<List<GroceryItem>>(
            (items) =>
                items.length == 2 &&
                items[0].name == 'Apples' &&
                items[1].name == 'Bananas',
          ),
        ]),
      );

      await Future.delayed(Duration.zero);
      await database.upsertGroceryItems([
        const GroceryItemsCompanion(serverId: Value(1), name: Value('Bananas')),
        const GroceryItemsCompanion(serverId: Value(2), name: Value('Apples')),
      ]);

      await expectation;
    });
  });

  // ── Grocery On Hand DAO ──────────────────────────────────────────────────

  group('Grocery On Hand DAO', () {
    test('upsertGroceryOnHand inserts rows', () async {
      await database.upsertGroceryOnHand([
        const GroceryOnHandCompanion(
          itemServerId: Value(1),
          quantity: Value(2.5),
          unit: Value('lb'),
        ),
      ]);

      final rows = await (database.select(database.groceryOnHand)).get();
      expect(rows.length, 1);
      expect(rows.first.quantity, 2.5);
    });

    test(
      'upsertGroceryOnHand updates on itemServerId conflict',
      () async {
        await database.upsertGroceryOnHand([
          const GroceryOnHandCompanion(
            itemServerId: Value(1),
            quantity: Value(1.0),
          ),
        ]);
        await database.upsertGroceryOnHand([
          const GroceryOnHandCompanion(
            itemServerId: Value(1),
            quantity: Value(3.0),
          ),
        ]);

        final rows = await (database.select(database.groceryOnHand)).get();
        expect(rows.length, 1);
        expect(rows.first.quantity, 3.0);
      },
    );

    test('getPendingGroceryOnHand returns non-zero syncStatus rows', () async {
      await database.upsertGroceryOnHand([
        const GroceryOnHandCompanion(
          itemServerId: Value(1),
          syncStatus: Value(0),
        ),
      ]);
      await database.upsertGroceryOnHand([
        const GroceryOnHandCompanion(
          itemServerId: Value(2),
          syncStatus: Value(1),
        ),
      ]);

      final pending = await database.getPendingGroceryOnHand();
      expect(pending.length, 1);
      expect(pending.first.itemServerId, 2);
    });

    test('markGroceryOnHandSynced clears syncStatus', () async {
      await database.upsertGroceryOnHand([
        const GroceryOnHandCompanion(
          itemServerId: Value(1),
          syncStatus: Value(1),
        ),
      ]);
      final row = await (database.select(database.groceryOnHand)).getSingle();

      await database.markGroceryOnHandSynced(row.id);

      final updated = await (database.select(database.groceryOnHand)).getSingle();
      expect(updated.syncStatus, 0);
    });

    test('deleteGroceryOnHandLocal removes the row', () async {
      await database.upsertGroceryOnHand([
        const GroceryOnHandCompanion(itemServerId: Value(1)),
      ]);
      final row = await (database.select(database.groceryOnHand)).getSingle();

      await database.deleteGroceryOnHandLocal(row.id);

      expect(await (database.select(database.groceryOnHand)).get(), isEmpty);
    });

    test('purgeGroceryOnHand removes rows not in keepSet', () async {
      await database.upsertGroceryOnHand([
        const GroceryOnHandCompanion(itemServerId: Value(1)),
        const GroceryOnHandCompanion(itemServerId: Value(2)),
        const GroceryOnHandCompanion(itemServerId: Value(3)),
      ]);

      await database.purgeGroceryOnHand({1, 3});

      final rows = await (database.select(database.groceryOnHand)).get();
      expect(rows.length, 2);
      expect(rows.map((r) => r.itemServerId), containsAll([1, 3]));
    });

    test('watchGroceryOnHand emits updates', () async {
      final stream = database.watchGroceryOnHand();

      final expectation = expectLater(
        stream,
        emitsInOrder([isEmpty, hasLength(1)]),
      );

      await Future.delayed(Duration.zero);
      await database.upsertGroceryOnHand([
        const GroceryOnHandCompanion(itemServerId: Value(1)),
      ]);

      await expectation;
    });
  });

  // ── Grocery List DAO ─────────────────────────────────────────────────────

  group('Grocery List DAO', () {
    test('insert and getGroceryLists', () async {
      await database.insertGroceryList(
        const GroceryListsCompanion(
          serverId: Value(1),
          name: Value('Weekly shop'),
        ),
      );

      final lists = await database.getGroceryLists();
      expect(lists.length, 1);
      expect(lists.first.name, 'Weekly shop');
    });

    test('getPendingGroceryLists returns non-zero syncStatus rows', () async {
      await database.upsertGroceryLists([
        const GroceryListsCompanion(
          serverId: Value(1),
          name: Value('Synced'),
          syncStatus: Value(0),
        ),
      ]);
      final pendingId = await database.insertGroceryList(
        const GroceryListsCompanion(
          name: Value('Pending'),
          syncStatus: Value(1),
        ),
      );

      final pending = await database.getPendingGroceryLists();
      expect(pending.length, 1);
      expect(pending.first.id, pendingId);
    });

    test('getGroceryListById returns the correct list', () async {
      final id = await database.insertGroceryList(
        const GroceryListsCompanion(name: Value('Target')),
      );

      final list = await database.getGroceryListById(id);
      expect(list, isNotNull);
      expect(list!.name, 'Target');
    });

    test('getGroceryListById returns null for unknown id', () async {
      expect(await database.getGroceryListById(999), isNull);
    });

    test('updateGroceryListStatus updates status and sets pendingUpdate',
        () async {
      await database.upsertGroceryLists([
        const GroceryListsCompanion(
          serverId: Value(1),
          name: Value('List'),
          status: Value('draft'),
          syncStatus: Value(0),
        ),
      ]);
      final list = await (database.select(database.groceryLists)).getSingle();

      await database.updateGroceryListStatus(list.id, 'active');

      final updated = await database.getGroceryListById(list.id);
      expect(updated!.status, 'active');
      expect(updated.syncStatus, SyncStatus.pendingUpdate.value);
    });

    test(
      'updateGroceryListStatus preserves pendingCreate syncStatus',
      () async {
        final id = await database.insertGroceryList(
          const GroceryListsCompanion(
            name: Value('List'),
            syncStatus: Value(1),
          ),
        );

        await database.updateGroceryListStatus(id, 'active');

        final updated = await database.getGroceryListById(id);
        expect(updated!.syncStatus, SyncStatus.pendingCreate.value);
      },
    );

    test('updateGroceryListStatus no-ops for non-existent id', () async {
      await database.updateGroceryListStatus(999, 'active');
    });

    test(
      'markGroceryListDeleted purges local-only list and its items',
      () async {
        final listId = await database.insertGroceryList(
          const GroceryListsCompanion(name: Value('Local')),
        );
        await database.insertGroceryListItem(
          GroceryListItemsCompanion(
            listLocalId: Value(listId),
            itemServerId: const Value(1),
          ),
        );

        await database.markGroceryListDeleted(listId);

        expect(await database.getGroceryLists(), isEmpty);
        expect(await database.getGroceryListItems(), isEmpty);
      },
    );

    test('markGroceryListDeleted sets pendingDelete for synced list', () async {
      await database.upsertGroceryLists([
        const GroceryListsCompanion(
          serverId: Value(2),
          name: Value('Synced'),
          syncStatus: Value(0),
        ),
      ]);
      final list = await (database.select(database.groceryLists)).getSingle();

      await database.markGroceryListDeleted(list.id);

      final updated = await database.getGroceryListById(list.id);
      expect(updated!.syncStatus, SyncStatus.pendingDelete.value);
    });

    test('markGroceryListDeleted no-ops for non-existent id', () async {
      await database.markGroceryListDeleted(999);
    });

    test(
      'markGroceryListSynced sets serverId and back-fills list items',
      () async {
        final listId = await database.insertGroceryList(
          const GroceryListsCompanion(
            name: Value('List'),
            syncStatus: Value(1),
          ),
        );
        await database.insertGroceryListItem(
          GroceryListItemsCompanion(
            listLocalId: Value(listId),
            itemServerId: const Value(5),
          ),
        );

        await database.markGroceryListSynced(listId, 88);

        final list = await database.getGroceryListById(listId);
        expect(list!.serverId, 88);
        expect(list.syncStatus, SyncStatus.synced.value);

        final items = await database.getGroceryListItems();
        expect(items.first.listServerId, 88);
      },
    );

    test('deleteGroceryListLocal removes list and its items', () async {
      final listId = await database.insertGroceryList(
        const GroceryListsCompanion(name: Value('List')),
      );
      await database.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          itemServerId: const Value(1),
        ),
      );

      await database.deleteGroceryListLocal(listId);

      expect(await database.getGroceryLists(), isEmpty);
      expect(await database.getGroceryListItems(), isEmpty);
    });

    test('upsertGroceryLists updates on serverId conflict', () async {
      await database.upsertGroceryLists([
        const GroceryListsCompanion(
          serverId: Value(1),
          name: Value('Old'),
        ),
      ]);
      await database.upsertGroceryLists([
        const GroceryListsCompanion(
          serverId: Value(1),
          name: Value('New'),
        ),
      ]);

      final lists = await database.getGroceryLists();
      expect(lists.length, 1);
      expect(lists.first.name, 'New');
    });

    test(
      'deleteGroceryListsLocalBatch removes lists and their items',
      () async {
        final id1 = await database.insertGroceryList(
          const GroceryListsCompanion(name: Value('L1')),
        );
        final id2 = await database.insertGroceryList(
          const GroceryListsCompanion(name: Value('L2')),
        );
        await database.insertGroceryList(
          const GroceryListsCompanion(name: Value('Keep')),
        );
        await database.insertGroceryListItem(
          GroceryListItemsCompanion(
            listLocalId: Value(id1),
            itemServerId: const Value(1),
          ),
        );

        await database.deleteGroceryListsLocalBatch([id1, id2]);

        final lists = await database.getGroceryLists();
        expect(lists.length, 1);
        expect(lists.first.name, 'Keep');
        expect(await database.getGroceryListItems(), isEmpty);
      },
    );

    test('deleteGroceryListsLocalBatch is no-op for empty list', () async {
      await database.insertGroceryList(
        const GroceryListsCompanion(name: Value('Keep')),
      );

      await database.deleteGroceryListsLocalBatch([]);

      expect(await database.getGroceryLists(), hasLength(1));
    });

    test('watchGroceryLists emits updates', () async {
      final stream = database.watchGroceryLists();

      final expectation = expectLater(
        stream,
        emitsInOrder([isEmpty, hasLength(1)]),
      );

      await Future.delayed(Duration.zero);
      await database.insertGroceryList(
        const GroceryListsCompanion(name: Value('List')),
      );

      await expectation;
    });
  });

  // ── Grocery List Item DAO ────────────────────────────────────────────────

  group('Grocery List Item DAO', () {
    late int listId;

    setUp(() async {
      listId = await database.insertGroceryList(
        const GroceryListsCompanion(name: Value('Parent list')),
      );
    });

    test('insert and getGroceryListItems', () async {
      await database.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          itemServerId: const Value(1),
          quantity: const Value(2.0),
          unit: const Value('lb'),
        ),
      );

      final items = await database.getGroceryListItems();
      expect(items.length, 1);
      expect(items.first.quantity, 2.0);
    });

    test('getPendingGroceryListItems returns non-zero syncStatus', () async {
      await database.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          itemServerId: const Value(1),
          syncStatus: const Value(0),
        ),
      );
      final pendingId = await database.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          itemServerId: const Value(2),
          syncStatus: const Value(1),
        ),
      );

      final pending = await database.getPendingGroceryListItems();
      expect(pending.length, 1);
      expect(pending.first.id, pendingId);
    });

    test('updateGroceryListItemStatus updates status and syncStatus', () async {
      await database.upsertGroceryListItems([
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          serverId: const Value(1),
          itemServerId: const Value(10),
          status: const Value('needed'),
          syncStatus: const Value(0),
        ),
      ]);
      final item = await (database.select(database.groceryListItems)).getSingle();

      await database.updateGroceryListItemStatus(item.id, 'in_cart');

      final updated = await (database.select(database.groceryListItems)
            ..where((i) => i.id.equals(item.id)))
          .getSingle();
      expect(updated.status, 'in_cart');
      expect(updated.syncStatus, SyncStatus.pendingUpdate.value);
    });

    test(
      'updateGroceryListItemStatus preserves pendingCreate syncStatus',
      () async {
        final id = await database.insertGroceryListItem(
          GroceryListItemsCompanion(
            listLocalId: Value(listId),
            itemServerId: const Value(10),
            syncStatus: const Value(1),
          ),
        );

        await database.updateGroceryListItemStatus(id, 'in_cart');

        final updated = await (database.select(database.groceryListItems)
              ..where((i) => i.id.equals(id)))
            .getSingle();
        expect(updated.syncStatus, SyncStatus.pendingCreate.value);
      },
    );

    test('updateGroceryListItemStatus no-ops for non-existent id', () async {
      await database.updateGroceryListItemStatus(999, 'in_cart');
    });

    test(
      'markGroceryListItemDeleted purges local-only item (no serverId)',
      () async {
        final id = await database.insertGroceryListItem(
          GroceryListItemsCompanion(
            listLocalId: Value(listId),
            itemServerId: const Value(1),
          ),
        );

        await database.markGroceryListItemDeleted(id);

        expect(await database.getGroceryListItems(), isEmpty);
      },
    );

    test(
      'markGroceryListItemDeleted sets pendingDelete for synced item',
      () async {
        await database.upsertGroceryListItems([
          GroceryListItemsCompanion(
            listLocalId: Value(listId),
            serverId: const Value(5),
            itemServerId: const Value(10),
            syncStatus: const Value(0),
          ),
        ]);
        final item =
            await (database.select(database.groceryListItems)).getSingle();

        await database.markGroceryListItemDeleted(item.id);

        final updated = await (database.select(database.groceryListItems)
              ..where((i) => i.id.equals(item.id)))
            .getSingle();
        expect(updated.syncStatus, SyncStatus.pendingDelete.value);
      },
    );

    test('markGroceryListItemDeleted no-ops for non-existent id', () async {
      await database.markGroceryListItemDeleted(999);
    });

    test('markGroceryListItemSynced sets serverId and clears syncStatus',
        () async {
      final id = await database.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          itemServerId: const Value(1),
          syncStatus: const Value(1),
        ),
      );

      await database.markGroceryListItemSynced(id, 66);

      final item = await (database.select(database.groceryListItems)
            ..where((i) => i.id.equals(id)))
          .getSingle();
      expect(item.serverId, 66);
      expect(item.syncStatus, SyncStatus.synced.value);
    });

    test('deleteGroceryListItemLocal removes the row', () async {
      final id = await database.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          itemServerId: const Value(1),
        ),
      );

      await database.deleteGroceryListItemLocal(id);

      expect(await database.getGroceryListItems(), isEmpty);
    });

    test('upsertGroceryListItems updates on serverId conflict', () async {
      await database.upsertGroceryListItems([
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          serverId: const Value(1),
          itemServerId: const Value(10),
          quantity: const Value(1.0),
        ),
      ]);
      await database.upsertGroceryListItems([
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          serverId: const Value(1),
          itemServerId: const Value(10),
          quantity: const Value(5.0),
        ),
      ]);

      final items = await database.getGroceryListItems();
      expect(items.length, 1);
      expect(items.first.quantity, 5.0);
    });

    test('deleteGroceryListItemsLocalBatch removes specified rows', () async {
      final id1 = await database.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          itemServerId: const Value(1),
        ),
      );
      final id2 = await database.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          itemServerId: const Value(2),
        ),
      );
      await database.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          itemServerId: const Value(3),
        ),
      );

      await database.deleteGroceryListItemsLocalBatch([id1, id2]);

      final remaining = await database.getGroceryListItems();
      expect(remaining.length, 1);
      expect(remaining.first.itemServerId, 3);
    });

    test('deleteGroceryListItemsLocalBatch is no-op for empty list', () async {
      await database.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          itemServerId: const Value(1),
        ),
      );

      await database.deleteGroceryListItemsLocalBatch([]);

      expect(await database.getGroceryListItems(), hasLength(1));
    });

    test('watchGroceryListItems emits updates', () async {
      final stream = database.watchGroceryListItems();

      final expectation = expectLater(
        stream,
        emitsInOrder([isEmpty, hasLength(1)]),
      );

      await Future.delayed(Duration.zero);
      await database.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          itemServerId: const Value(1),
        ),
      );

      await expectation;
    });

    test('watchGroceryListItemsForList filters by listLocalId', () async {
      final otherListId = await database.insertGroceryList(
        const GroceryListsCompanion(name: Value('Other')),
      );
      await database.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(otherListId),
          itemServerId: const Value(99),
        ),
      );

      final stream = database.watchGroceryListItemsForList(listId);

      final expectation = expectLater(
        stream,
        emitsInOrder([
          isEmpty,
          hasLength(1),
        ]),
      );

      await Future.delayed(Duration.zero);
      await database.insertGroceryListItem(
        GroceryListItemsCompanion(
          listLocalId: Value(listId),
          itemServerId: const Value(1),
        ),
      );

      await expectation;
    });
  });
}
