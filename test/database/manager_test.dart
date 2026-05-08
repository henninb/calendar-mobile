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

  // ── Category Manager ──────────────────────────────────────────────────────

  group('Manager API - Categories', () {
    test('create and get all', () async {
      await database.managers.categories.create((o) => o(name: 'Work', color: const Value('#ff0000')));
      final cats = await database.managers.categories.get();
      expect(cats.length, 1);
      expect(cats.first.name, 'Work');
    });

    test('createReturning gives back the data class', () async {
      final cat = await database.managers.categories
          .createReturning((o) => o(name: 'Personal', icon: const Value('🏠')));
      expect(cat.name, 'Personal');
      expect(cat.icon, '🏠');
    });

    test('filter by name equals', () async {
      await database.managers.categories.create((o) => o(name: 'Work'));
      await database.managers.categories.create((o) => o(name: 'Personal'));
      final result = await database.managers.categories
          .filter((f) => f.name.equals('Work'))
          .get();
      expect(result.length, 1);
      expect(result.first.name, 'Work');
    });

    test('filter by id equals', () async {
      final cat = await database.managers.categories.createReturning((o) => o(name: 'X'));
      final result = await database.managers.categories
          .filter((f) => f.id.equals(cat.id))
          .get();
      expect(result.length, 1);
    });

    test('filter by color equals', () async {
      await database.managers.categories.create((o) => o(name: 'Red', color: const Value('#ff0000')));
      await database.managers.categories.create((o) => o(name: 'Blue', color: const Value('#0000ff')));
      final result = await database.managers.categories
          .filter((f) => f.color.equals('#ff0000'))
          .get();
      expect(result.length, 1);
      expect(result.first.name, 'Red');
    });

    test('filter by icon equals', () async {
      await database.managers.categories.create((o) => o(name: 'Calendar', icon: const Value('📅')));
      final result = await database.managers.categories
          .filter((f) => f.icon.equals('📅'))
          .get();
      expect(result.length, 1);
    });

    test('filter by serverId equals', () async {
      await database.upsertCategories([
        const CategoriesCompanion(serverId: Value(99), name: Value('Server Cat')),
      ]);
      final result = await database.managers.categories
          .filter((f) => f.serverId.equals(99))
          .get();
      expect(result.length, 1);
    });

    test('filter by serverId isNull', () async {
      await database.managers.categories.create((o) => o(name: 'No server id'));
      final result = await database.managers.categories
          .filter((f) => f.serverId.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by serverId isNotNull', () async {
      await database.upsertCategories([
        const CategoriesCompanion(serverId: Value(1), name: Value('Has server id')),
      ]);
      final result = await database.managers.categories
          .filter((f) => f.serverId.isNotNull())
          .get();
      expect(result.length, 1);
    });

    test('filter name isIn list', () async {
      await database.managers.categories.create((o) => o(name: 'A'));
      await database.managers.categories.create((o) => o(name: 'B'));
      await database.managers.categories.create((o) => o(name: 'C'));
      final result = await database.managers.categories
          .filter((f) => f.name.isIn(['A', 'C']))
          .get();
      expect(result.length, 2);
    });

    test('filter name contains', () async {
      await database.managers.categories.create((o) => o(name: 'WorkSpace'));
      await database.managers.categories.create((o) => o(name: 'Personal'));
      final result = await database.managers.categories
          .filter((f) => f.name.contains('Work'))
          .get();
      expect(result.length, 1);
    });

    test('filter name startsWith', () async {
      await database.managers.categories.create((o) => o(name: 'Work Space'));
      await database.managers.categories.create((o) => o(name: 'Personal'));
      final result = await database.managers.categories
          .filter((f) => f.name.startsWith('Work'))
          .get();
      expect(result.length, 1);
    });

    test('filter name endsWith', () async {
      await database.managers.categories.create((o) => o(name: 'Work Space'));
      await database.managers.categories.create((o) => o(name: 'Personal'));
      final result = await database.managers.categories
          .filter((f) => f.name.endsWith('Space'))
          .get();
      expect(result.length, 1);
    });

    test('orderBy name ascending', () async {
      await database.managers.categories.create((o) => o(name: 'Zebra'));
      await database.managers.categories.create((o) => o(name: 'Apple'));
      final result = await database.managers.categories
          .orderBy((o) => o.name.asc())
          .get();
      expect(result.first.name, 'Apple');
      expect(result.last.name, 'Zebra');
    });

    test('orderBy name descending', () async {
      await database.managers.categories.create((o) => o(name: 'Zebra'));
      await database.managers.categories.create((o) => o(name: 'Apple'));
      final result = await database.managers.categories
          .orderBy((o) => o.name.desc())
          .get();
      expect(result.first.name, 'Zebra');
    });

    test('orderBy id ascending', () async {
      await database.managers.categories.create((o) => o(name: 'First'));
      await database.managers.categories.create((o) => o(name: 'Second'));
      final result = await database.managers.categories
          .orderBy((o) => o.id.asc())
          .get();
      expect(result.first.name, 'First');
    });

    test('orderBy color', () async {
      await database.managers.categories.create((o) => o(name: 'A', color: const Value('#000000')));
      await database.managers.categories.create((o) => o(name: 'B', color: const Value('#ffffff')));
      final result = await database.managers.categories
          .orderBy((o) => o.color.asc())
          .get();
      expect(result.length, 2);
    });

    test('count', () async {
      await database.managers.categories.create((o) => o(name: 'A'));
      await database.managers.categories.create((o) => o(name: 'B'));
      expect(await database.managers.categories.count(), 2);
    });

    test('exists returns true when records exist', () async {
      await database.managers.categories.create((o) => o(name: 'X'));
      expect(await database.managers.categories.exists(), isTrue);
    });

    test('exists returns false when empty', () async {
      expect(await database.managers.categories.exists(), isFalse);
    });

    test('delete via manager filter', () async {
      final cat = await database.managers.categories
          .createReturning((o) => o(name: 'Delete me'));
      await database.managers.categories
          .filter((f) => f.id.equals(cat.id))
          .delete();
      expect(await database.managers.categories.count(), 0);
    });

    test('update via manager filter', () async {
      final cat = await database.managers.categories
          .createReturning((o) => o(name: 'Old'));
      await database.managers.categories
          .filter((f) => f.id.equals(cat.id))
          .update((m) => m(name: const Value('New')));
      final updated = await database.managers.categories
          .filter((f) => f.id.equals(cat.id))
          .getSingle();
      expect(updated.name, 'New');
    });

    test('getSingle returns the single matching row', () async {
      await database.managers.categories.create((o) => o(name: 'Only'));
      final cat = await database.managers.categories.getSingle();
      expect(cat.name, 'Only');
    });

    test('getSingleOrNull returns null when empty', () async {
      final cat = await database.managers.categories.getSingleOrNull();
      expect(cat, isNull);
    });

    test('watch stream emits changes', () async {
      final stream = database.managers.categories.watch();
      final expectation =
          expectLater(stream, emitsInOrder([isEmpty, hasLength(1)]));
      await Future.delayed(Duration.zero);
      await database.managers.categories.create((o) => o(name: 'Stream test'));
      await expectation;
    });
  });

  // ── Person Manager ────────────────────────────────────────────────────────

  group('Manager API - Persons', () {
    test('create and get', () async {
      await database.managers.persons.create(
        (o) => o(name: 'Alice', email: const Value('alice@example.com')),
      );
      final persons = await database.managers.persons.get();
      expect(persons.length, 1);
      expect(persons.first.email, 'alice@example.com');
    });

    test('filter by name', () async {
      await database.managers.persons.create((o) => o(name: 'Alice'));
      await database.managers.persons.create((o) => o(name: 'Bob'));
      final result =
          await database.managers.persons.filter((f) => f.name.equals('Alice')).get();
      expect(result.length, 1);
    });

    test('filter by email equals', () async {
      await database.managers.persons.create(
          (o) => o(name: 'Alice', email: const Value('alice@example.com')));
      final result = await database.managers.persons
          .filter((f) => f.email.equals('alice@example.com'))
          .get();
      expect(result.length, 1);
    });

    test('filter by email isNull', () async {
      await database.managers.persons.create((o) => o(name: 'No email'));
      final result =
          await database.managers.persons.filter((f) => f.email.isNull()).get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by serverId isNull', () async {
      await database.managers.persons.create((o) => o(name: 'Local'));
      final result =
          await database.managers.persons.filter((f) => f.serverId.isNull()).get();
      expect(result.isNotEmpty, isTrue);
    });

    test('orderBy name asc', () async {
      await database.managers.persons.create((o) => o(name: 'Zara'));
      await database.managers.persons.create((o) => o(name: 'Aaron'));
      final result =
          await database.managers.persons.orderBy((o) => o.name.asc()).get();
      expect(result.first.name, 'Aaron');
    });

    test('orderBy id desc', () async {
      await database.managers.persons.create((o) => o(name: 'First'));
      await database.managers.persons.create((o) => o(name: 'Second'));
      final result =
          await database.managers.persons.orderBy((o) => o.id.desc()).get();
      expect(result.first.name, 'Second');
    });

    test('count and exists', () async {
      expect(await database.managers.persons.count(), 0);
      await database.managers.persons.create((o) => o(name: 'X'));
      expect(await database.managers.persons.count(), 1);
      expect(await database.managers.persons.exists(), isTrue);
    });

    test('delete', () async {
      final p = await database.managers.persons.createReturning((o) => o(name: 'Del'));
      await database.managers.persons.filter((f) => f.id.equals(p.id)).delete();
      expect(await database.managers.persons.count(), 0);
    });

    test('update name', () async {
      final p = await database.managers.persons.createReturning((o) => o(name: 'Old'));
      await database.managers.persons
          .filter((f) => f.id.equals(p.id))
          .update((m) => m(name: const Value('New')));
      final updated =
          await database.managers.persons.filter((f) => f.id.equals(p.id)).getSingle();
      expect(updated.name, 'New');
    });
  });

  // ── Event Manager ─────────────────────────────────────────────────────────

  group('Manager API - Events', () {
    test('create and get', () async {
      await database.managers.events.create(
        (o) => o(title: 'Meeting', categoryServerId: 1, dtstart: '2026-05-01'),
      );
      final events = await database.managers.events.get();
      expect(events.length, 1);
      expect(events.first.title, 'Meeting');
    });

    test('filter by title', () async {
      await database.managers.events
          .create((o) => o(title: 'Standup', categoryServerId: 1, dtstart: '2026-05-01'));
      await database.managers.events
          .create((o) => o(title: 'Review', categoryServerId: 1, dtstart: '2026-05-02'));
      final result = await database.managers.events
          .filter((f) => f.title.equals('Standup'))
          .get();
      expect(result.length, 1);
    });

    test('filter by categoryServerId', () async {
      await database.managers.events
          .create((o) => o(title: 'A', categoryServerId: 10, dtstart: '2026-05-01'));
      await database.managers.events
          .create((o) => o(title: 'B', categoryServerId: 20, dtstart: '2026-05-02'));
      final result = await database.managers.events
          .filter((f) => f.categoryServerId.equals(10))
          .get();
      expect(result.length, 1);
    });

    test('filter by dtstart', () async {
      await database.managers.events
          .create((o) => o(title: 'May', categoryServerId: 1, dtstart: '2026-05-01'));
      final result = await database.managers.events
          .filter((f) => f.dtstart.equals('2026-05-01'))
          .get();
      expect(result.length, 1);
    });

    test('filter by priority', () async {
      await database.managers.events.create(
        (o) => o(title: 'High', categoryServerId: 1, dtstart: '2026-05-01',
            priority: const Value('high')),
      );
      await database.managers.events.create(
        (o) => o(title: 'Low', categoryServerId: 1, dtstart: '2026-05-02',
            priority: const Value('low')),
      );
      final result = await database.managers.events
          .filter((f) => f.priority.equals('high'))
          .get();
      expect(result.length, 1);
    });

    test('filter by isActive', () async {
      await database.managers.events.create(
        (o) => o(title: 'Active', categoryServerId: 1, dtstart: '2026-05-01',
            isActive: const Value(true)),
      );
      await database.managers.events.create(
        (o) => o(title: 'Inactive', categoryServerId: 1, dtstart: '2026-05-02',
            isActive: const Value(false)),
      );
      final result = await database.managers.events
          .filter((f) => f.isActive.equals(true))
          .get();
      expect(result.length, 1);
      expect(result.first.title, 'Active');
    });

    test('filter by serverId isNull', () async {
      await database.managers.events
          .create((o) => o(title: 'Local', categoryServerId: 1, dtstart: '2026-05-01'));
      final result =
          await database.managers.events.filter((f) => f.serverId.isNull()).get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by rrule isNull', () async {
      await database.managers.events
          .create((o) => o(title: 'No rrule', categoryServerId: 1, dtstart: '2026-05-01'));
      final result =
          await database.managers.events.filter((f) => f.rrule.isNull()).get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter title contains', () async {
      await database.managers.events
          .create((o) => o(title: 'Sprint Review', categoryServerId: 1, dtstart: '2026-05-01'));
      final result = await database.managers.events
          .filter((f) => f.title.contains('Review'))
          .get();
      expect(result.length, 1);
    });

    test('orderBy title asc', () async {
      await database.managers.events
          .create((o) => o(title: 'Z Event', categoryServerId: 1, dtstart: '2026-05-01'));
      await database.managers.events
          .create((o) => o(title: 'A Event', categoryServerId: 1, dtstart: '2026-05-02'));
      final result =
          await database.managers.events.orderBy((o) => o.title.asc()).get();
      expect(result.first.title, 'A Event');
    });

    test('orderBy dtstart desc', () async {
      await database.managers.events
          .create((o) => o(title: 'Old', categoryServerId: 1, dtstart: '2026-01-01'));
      await database.managers.events
          .create((o) => o(title: 'New', categoryServerId: 1, dtstart: '2026-12-01'));
      final result =
          await database.managers.events.orderBy((o) => o.dtstart.desc()).get();
      expect(result.first.title, 'New');
    });

    test('orderBy categoryServerId', () async {
      await database.managers.events
          .create((o) => o(title: 'B', categoryServerId: 2, dtstart: '2026-05-01'));
      await database.managers.events
          .create((o) => o(title: 'A', categoryServerId: 1, dtstart: '2026-05-02'));
      final result = await database.managers.events
          .orderBy((o) => o.categoryServerId.asc())
          .get();
      expect(result.first.title, 'A');
    });

    test('count and exists', () async {
      expect(await database.managers.events.count(), 0);
      await database.managers.events
          .create((o) => o(title: 'E', categoryServerId: 1, dtstart: '2026-05-01'));
      expect(await database.managers.events.count(), 1);
      expect(await database.managers.events.exists(), isTrue);
    });

    test('delete', () async {
      final ev = await database.managers.events
          .createReturning((o) => o(title: 'Del', categoryServerId: 1, dtstart: '2026-05-01'));
      await database.managers.events.filter((f) => f.id.equals(ev.id)).delete();
      expect(await database.managers.events.count(), 0);
    });
  });

  // ── Occurrence Manager ────────────────────────────────────────────────────

  group('Manager API - Occurrences', () {
    test('create and get', () async {
      await database.managers.occurrences.create(
        (o) => o(eventServerId: 100, occurrenceDate: '2026-05-01'),
      );
      final occs = await database.managers.occurrences.get();
      expect(occs.length, 1);
    });

    test('filter by eventServerId', () async {
      await database.managers.occurrences
          .create((o) => o(eventServerId: 10, occurrenceDate: '2026-05-01'));
      await database.managers.occurrences
          .create((o) => o(eventServerId: 20, occurrenceDate: '2026-05-02'));
      final result = await database.managers.occurrences
          .filter((f) => f.eventServerId.equals(10))
          .get();
      expect(result.length, 1);
    });

    test('filter by status', () async {
      await database.managers.occurrences.create(
        (o) => o(eventServerId: 1, occurrenceDate: '2026-05-01',
            status: const Value('completed')),
      );
      await database.managers.occurrences.create(
        (o) => o(eventServerId: 1, occurrenceDate: '2026-05-02',
            status: const Value('upcoming')),
      );
      final result = await database.managers.occurrences
          .filter((f) => f.status.equals('completed'))
          .get();
      expect(result.length, 1);
    });

    test('filter by occurrenceDate', () async {
      await database.managers.occurrences
          .create((o) => o(eventServerId: 1, occurrenceDate: '2026-05-15'));
      final result = await database.managers.occurrences
          .filter((f) => f.occurrenceDate.equals('2026-05-15'))
          .get();
      expect(result.length, 1);
    });

    test('filter by syncStatus', () async {
      await database.managers.occurrences.create(
        (o) => o(eventServerId: 1, occurrenceDate: '2026-05-01',
            syncStatus: const Value(1)),
      );
      await database.managers.occurrences.create(
        (o) => o(eventServerId: 1, occurrenceDate: '2026-05-02',
            syncStatus: const Value(0)),
      );
      final result = await database.managers.occurrences
          .filter((f) => f.syncStatus.equals(1))
          .get();
      expect(result.length, 1);
    });

    test('filter by notes isNull', () async {
      await database.managers.occurrences
          .create((o) => o(eventServerId: 1, occurrenceDate: '2026-05-01'));
      final result = await database.managers.occurrences
          .filter((f) => f.notes.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('orderBy occurrenceDate asc', () async {
      await database.managers.occurrences
          .create((o) => o(eventServerId: 1, occurrenceDate: '2026-06-01'));
      await database.managers.occurrences
          .create((o) => o(eventServerId: 1, occurrenceDate: '2026-05-01'));
      final result = await database.managers.occurrences
          .orderBy((o) => o.occurrenceDate.asc())
          .get();
      expect(result.first.occurrenceDate, '2026-05-01');
    });

    test('orderBy syncStatus', () async {
      await database.managers.occurrences.create(
          (o) => o(eventServerId: 1, occurrenceDate: '2026-05-01', syncStatus: const Value(2)));
      await database.managers.occurrences.create(
          (o) => o(eventServerId: 1, occurrenceDate: '2026-05-02', syncStatus: const Value(0)));
      final result = await database.managers.occurrences
          .orderBy((o) => o.syncStatus.asc())
          .get();
      expect(result.first.syncStatus, 0);
    });

    test('count and exists', () async {
      expect(await database.managers.occurrences.count(), 0);
      await database.managers.occurrences
          .create((o) => o(eventServerId: 1, occurrenceDate: '2026-05-01'));
      expect(await database.managers.occurrences.count(), 1);
      expect(await database.managers.occurrences.exists(), isTrue);
    });

    test('delete', () async {
      final occ = await database.managers.occurrences.createReturning(
        (o) => o(eventServerId: 1, occurrenceDate: '2026-05-01'),
      );
      await database.managers.occurrences
          .filter((f) => f.id.equals(occ.id))
          .delete();
      expect(await database.managers.occurrences.count(), 0);
    });
  });

  // ── Task Manager ──────────────────────────────────────────────────────────

  group('Manager API - Tasks', () {
    test('create and get', () async {
      await database.managers.tasks.create(
        (o) => o(title: 'Task', createdAt: '2026-01-01', updatedAt: '2026-01-01'),
      );
      final tasks = await database.managers.tasks.get();
      expect(tasks.length, 1);
    });

    test('filter by title', () async {
      await database.managers.tasks.create(
          (o) => o(title: 'Write tests', createdAt: '2026-01-01', updatedAt: '2026-01-01'));
      await database.managers.tasks.create(
          (o) => o(title: 'Fix bug', createdAt: '2026-01-01', updatedAt: '2026-01-01'));
      final result = await database.managers.tasks
          .filter((f) => f.title.equals('Fix bug'))
          .get();
      expect(result.length, 1);
    });

    test('filter by status', () async {
      await database.managers.tasks.create(
        (o) => o(title: 'T', createdAt: '2026-01-01', updatedAt: '2026-01-01',
            status: const Value('done')),
      );
      final result = await database.managers.tasks
          .filter((f) => f.status.equals('done'))
          .get();
      expect(result.length, 1);
    });

    test('filter by priority', () async {
      await database.managers.tasks.create(
        (o) => o(title: 'T', createdAt: '2026-01-01', updatedAt: '2026-01-01',
            priority: const Value('high')),
      );
      final result = await database.managers.tasks
          .filter((f) => f.priority.equals('high'))
          .get();
      expect(result.length, 1);
    });

    test('filter by syncStatus', () async {
      await database.managers.tasks.create(
        (o) => o(title: 'Pending', createdAt: '2026-01-01', updatedAt: '2026-01-01',
            syncStatus: const Value(1)),
      );
      final result = await database.managers.tasks
          .filter((f) => f.syncStatus.equals(1))
          .get();
      expect(result.length, 1);
    });

    test('filter by dueDate isNull', () async {
      await database.managers.tasks.create(
          (o) => o(title: 'No due', createdAt: '2026-01-01', updatedAt: '2026-01-01'));
      final result = await database.managers.tasks
          .filter((f) => f.dueDate.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by assigneeServerId isNull', () async {
      await database.managers.tasks.create(
          (o) => o(title: 'Unassigned', createdAt: '2026-01-01', updatedAt: '2026-01-01'));
      final result = await database.managers.tasks
          .filter((f) => f.assigneeServerId.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by categoryServerId isNull', () async {
      await database.managers.tasks.create(
          (o) => o(title: 'No cat', createdAt: '2026-01-01', updatedAt: '2026-01-01'));
      final result = await database.managers.tasks
          .filter((f) => f.categoryServerId.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by recurrence', () async {
      await database.managers.tasks.create(
        (o) => o(title: 'Daily', createdAt: '2026-01-01', updatedAt: '2026-01-01',
            recurrence: const Value('daily')),
      );
      final result = await database.managers.tasks
          .filter((f) => f.recurrence.equals('daily'))
          .get();
      expect(result.length, 1);
    });

    test('filter by order', () async {
      await database.managers.tasks.create(
        (o) => o(title: 'T', createdAt: '2026-01-01', updatedAt: '2026-01-01',
            order: const Value(5)),
      );
      final result = await database.managers.tasks
          .filter((f) => f.order.equals(5))
          .get();
      expect(result.length, 1);
    });

    test('orderBy title asc', () async {
      await database.managers.tasks.create(
          (o) => o(title: 'Zap', createdAt: '2026-01-01', updatedAt: '2026-01-01'));
      await database.managers.tasks.create(
          (o) => o(title: 'Alpha', createdAt: '2026-01-01', updatedAt: '2026-01-01'));
      final result =
          await database.managers.tasks.orderBy((o) => o.title.asc()).get();
      expect(result.first.title, 'Alpha');
    });

    test('orderBy createdAt', () async {
      await database.managers.tasks.create(
          (o) => o(title: 'Old', createdAt: '2025-01-01', updatedAt: '2025-01-01'));
      await database.managers.tasks.create(
          (o) => o(title: 'New', createdAt: '2026-01-01', updatedAt: '2026-01-01'));
      final result = await database.managers.tasks
          .orderBy((o) => o.createdAt.desc())
          .get();
      expect(result.first.title, 'New');
    });

    test('orderBy order asc', () async {
      await database.managers.tasks.create(
        (o) => o(title: 'B', createdAt: '2026-01-01', updatedAt: '2026-01-01',
            order: const Value(2)),
      );
      await database.managers.tasks.create(
        (o) => o(title: 'A', createdAt: '2026-01-01', updatedAt: '2026-01-01',
            order: const Value(1)),
      );
      final result =
          await database.managers.tasks.orderBy((o) => o.order.asc()).get();
      expect(result.first.title, 'A');
    });

    test('count and exists', () async {
      expect(await database.managers.tasks.count(), 0);
      await database.managers.tasks.create(
          (o) => o(title: 'T', createdAt: '2026-01-01', updatedAt: '2026-01-01'));
      expect(await database.managers.tasks.count(), 1);
      expect(await database.managers.tasks.exists(), isTrue);
    });

    test('delete', () async {
      final task = await database.managers.tasks.createReturning(
        (o) => o(title: 'Del', createdAt: '2026-01-01', updatedAt: '2026-01-01'),
      );
      await database.managers.tasks.filter((f) => f.id.equals(task.id)).delete();
      expect(await database.managers.tasks.count(), 0);
    });
  });

  // ── Subtask Manager ───────────────────────────────────────────────────────

  group('Manager API - Subtasks', () {
    late int taskId;

    setUp(() async {
      taskId = await database.insertTask(
        const TasksCompanion(
          title: Value('Parent'),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );
    });

    test('create and get', () async {
      await database.managers.subtasks.create(
        (o) => o(taskLocalId: taskId, title: 'Sub A'),
      );
      final subs = await database.managers.subtasks.get();
      expect(subs.length, 1);
    });

    test('filter by taskLocalId', () async {
      await database.managers.subtasks.create((o) => o(taskLocalId: taskId, title: 'Sub'));
      final result = await database.managers.subtasks
          .filter((f) => f.taskLocalId.equals(taskId))
          .get();
      expect(result.length, 1);
    });

    test('filter by status', () async {
      await database.managers.subtasks.create(
        (o) => o(taskLocalId: taskId, title: 'Done sub', status: const Value('done')),
      );
      final result = await database.managers.subtasks
          .filter((f) => f.status.equals('done'))
          .get();
      expect(result.length, 1);
    });

    test('filter by title contains', () async {
      await database.managers.subtasks.create((o) => o(taskLocalId: taskId, title: 'Write code'));
      final result = await database.managers.subtasks
          .filter((f) => f.title.contains('code'))
          .get();
      expect(result.length, 1);
    });

    test('filter by syncStatus', () async {
      await database.managers.subtasks.create(
        (o) => o(taskLocalId: taskId, title: 'Pending', syncStatus: const Value(1)),
      );
      final result = await database.managers.subtasks
          .filter((f) => f.syncStatus.equals(1))
          .get();
      expect(result.length, 1);
    });

    test('filter by dueDate isNull', () async {
      await database.managers.subtasks.create((o) => o(taskLocalId: taskId, title: 'No due'));
      final result = await database.managers.subtasks
          .filter((f) => f.dueDate.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by serverId isNull', () async {
      await database.managers.subtasks.create((o) => o(taskLocalId: taskId, title: 'Local'));
      final result = await database.managers.subtasks
          .filter((f) => f.serverId.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('orderBy order asc', () async {
      await database.managers.subtasks.create(
          (o) => o(taskLocalId: taskId, title: 'B', order: const Value(2)));
      await database.managers.subtasks.create(
          (o) => o(taskLocalId: taskId, title: 'A', order: const Value(1)));
      final result =
          await database.managers.subtasks.orderBy((o) => o.order.asc()).get();
      expect(result.first.title, 'A');
    });

    test('orderBy title desc', () async {
      await database.managers.subtasks.create((o) => o(taskLocalId: taskId, title: 'Alpha'));
      await database.managers.subtasks.create((o) => o(taskLocalId: taskId, title: 'Zeta'));
      final result =
          await database.managers.subtasks.orderBy((o) => o.title.desc()).get();
      expect(result.first.title, 'Zeta');
    });

    test('count, exists, delete', () async {
      final sub = await database.managers.subtasks
          .createReturning((o) => o(taskLocalId: taskId, title: 'Del'));
      expect(await database.managers.subtasks.count(), 1);
      expect(await database.managers.subtasks.exists(), isTrue);
      await database.managers.subtasks.filter((f) => f.id.equals(sub.id)).delete();
      expect(await database.managers.subtasks.count(), 0);
    });
  });

  // ── Credit Card Manager ───────────────────────────────────────────────────

  group('Manager API - CreditCards', () {
    test('create and get', () async {
      await database.managers.creditCards.create((o) => o(name: 'Visa'));
      final cards = await database.managers.creditCards.get();
      expect(cards.length, 1);
    });

    test('filter by name', () async {
      await database.managers.creditCards.create((o) => o(name: 'Visa'));
      await database.managers.creditCards.create((o) => o(name: 'Amex'));
      final result = await database.managers.creditCards
          .filter((f) => f.name.equals('Visa'))
          .get();
      expect(result.length, 1);
    });

    test('filter by isActive', () async {
      await database.managers.creditCards.create(
          (o) => o(name: 'Active', isActive: const Value(true)));
      await database.managers.creditCards.create(
          (o) => o(name: 'Inactive', isActive: const Value(false)));
      final result = await database.managers.creditCards
          .filter((f) => f.isActive.equals(true))
          .get();
      expect(result.length, 1);
    });

    test('filter by syncStatus', () async {
      await database.managers.creditCards.create(
          (o) => o(name: 'Card', syncStatus: const Value(1)));
      final result = await database.managers.creditCards
          .filter((f) => f.syncStatus.equals(1))
          .get();
      expect(result.length, 1);
    });

    test('filter by serverId isNull', () async {
      await database.managers.creditCards.create((o) => o(name: 'Local'));
      final result = await database.managers.creditCards
          .filter((f) => f.serverId.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by issuer isNull', () async {
      await database.managers.creditCards.create((o) => o(name: 'No issuer'));
      final result = await database.managers.creditCards
          .filter((f) => f.issuer.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by lastFour isNull', () async {
      await database.managers.creditCards.create((o) => o(name: 'No last four'));
      final result = await database.managers.creditCards
          .filter((f) => f.lastFour.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('orderBy name asc', () async {
      await database.managers.creditCards.create((o) => o(name: 'Zara'));
      await database.managers.creditCards.create((o) => o(name: 'Amex'));
      final result = await database.managers.creditCards
          .orderBy((o) => o.name.asc())
          .get();
      expect(result.first.name, 'Amex');
    });

    test('orderBy syncStatus', () async {
      await database.managers.creditCards.create(
          (o) => o(name: 'A', syncStatus: const Value(2)));
      await database.managers.creditCards.create(
          (o) => o(name: 'B', syncStatus: const Value(0)));
      final result = await database.managers.creditCards
          .orderBy((o) => o.syncStatus.asc())
          .get();
      expect(result.first.syncStatus, 0);
    });

    test('count, exists, delete', () async {
      final card =
          await database.managers.creditCards.createReturning((o) => o(name: 'Del'));
      expect(await database.managers.creditCards.count(), 1);
      expect(await database.managers.creditCards.exists(), isTrue);
      await database.managers.creditCards.filter((f) => f.id.equals(card.id)).delete();
      expect(await database.managers.creditCards.count(), 0);
    });
  });

  // ── CreditCardTrackerCache Manager ────────────────────────────────────────

  group('Manager API - CreditCardTrackerCache', () {
    CreditCardTrackerCacheCompanion _entry(int cardServerId) =>
        CreditCardTrackerCacheCompanion(
          cardServerId: Value(cardServerId),
          name: const Value('Card'),
          grace: const Value('2026-05-15'),
          prevClose: const Value('2026-04-15'),
          prevDue: const Value('2026-05-05'),
          nextClose: const Value('2026-05-15'),
          nextCloseDays: const Value(7),
          nextDue: const Value('2026-06-05'),
          nextDueDays: const Value(28),
        );

    test('get via manager', () async {
      await database.replaceTrackerCache([_entry(1), _entry(2)]);
      final rows = await database.managers.creditCardTrackerCache.get();
      expect(rows.length, 2);
    });

    test('filter by cardServerId', () async {
      await database.replaceTrackerCache([_entry(1), _entry(2)]);
      final result = await database.managers.creditCardTrackerCache
          .filter((f) => f.cardServerId.equals(1))
          .get();
      expect(result.length, 1);
    });

    test('filter by name', () async {
      await database.replaceTrackerCache([_entry(1)]);
      final result = await database.managers.creditCardTrackerCache
          .filter((f) => f.name.equals('Card'))
          .get();
      expect(result.length, 1);
    });

    test('filter by nextDueDays', () async {
      await database.replaceTrackerCache([_entry(1)]);
      final result = await database.managers.creditCardTrackerCache
          .filter((f) => f.nextDueDays.equals(28))
          .get();
      expect(result.length, 1);
    });

    test('filter by prevDueOverdue', () async {
      await database.replaceTrackerCache([_entry(1)]);
      final result = await database.managers.creditCardTrackerCache
          .filter((f) => f.prevDueOverdue.equals(false))
          .get();
      expect(result.length, 1);
    });

    test('filter by issuer isNull', () async {
      await database.replaceTrackerCache([_entry(1)]);
      final result = await database.managers.creditCardTrackerCache
          .filter((f) => f.issuer.isNull())
          .get();
      expect(result.length, 1);
    });

    test('filter by annualFeeDate isNull', () async {
      await database.replaceTrackerCache([_entry(1)]);
      final result = await database.managers.creditCardTrackerCache
          .filter((f) => f.annualFeeDate.isNull())
          .get();
      expect(result.length, 1);
    });

    test('orderBy nextDueDays asc', () async {
      await database.replaceTrackerCache([_entry(1), _entry(2)]);
      final result = await database.managers.creditCardTrackerCache
          .orderBy((o) => o.nextDueDays.asc())
          .get();
      expect(result.length, 2);
    });

    test('orderBy cardServerId desc', () async {
      await database.replaceTrackerCache([_entry(1), _entry(2)]);
      final result = await database.managers.creditCardTrackerCache
          .orderBy((o) => o.cardServerId.desc())
          .get();
      expect(result.first.cardServerId, 2);
    });

    test('count and exists', () async {
      expect(await database.managers.creditCardTrackerCache.count(), 0);
      await database.replaceTrackerCache([_entry(1)]);
      expect(await database.managers.creditCardTrackerCache.count(), 1);
      expect(await database.managers.creditCardTrackerCache.exists(), isTrue);
    });
  });

  // ── GroceryStore Manager ──────────────────────────────────────────────────

  group('Manager API - GroceryStores', () {
    test('create and get', () async {
      await database.managers.groceryStores.create((o) => o(name: 'Whole Foods'));
      final stores = await database.managers.groceryStores.get();
      expect(stores.length, 1);
    });

    test('filter by name', () async {
      await database.managers.groceryStores.create((o) => o(name: 'Whole Foods'));
      await database.managers.groceryStores.create((o) => o(name: 'Trader Joes'));
      final result = await database.managers.groceryStores
          .filter((f) => f.name.equals('Whole Foods'))
          .get();
      expect(result.length, 1);
    });

    test('filter by isActive', () async {
      await database.managers.groceryStores.create(
          (o) => o(name: 'Active', isActive: const Value(true)));
      await database.managers.groceryStores.create(
          (o) => o(name: 'Closed', isActive: const Value(false)));
      final result = await database.managers.groceryStores
          .filter((f) => f.isActive.equals(true))
          .get();
      expect(result.length, 1);
    });

    test('filter by syncStatus', () async {
      await database.managers.groceryStores.create(
          (o) => o(name: 'Pending', syncStatus: const Value(1)));
      final result = await database.managers.groceryStores
          .filter((f) => f.syncStatus.equals(1))
          .get();
      expect(result.length, 1);
    });

    test('filter by location isNull', () async {
      await database.managers.groceryStores.create((o) => o(name: 'No loc'));
      final result = await database.managers.groceryStores
          .filter((f) => f.location.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by serverId isNull', () async {
      await database.managers.groceryStores.create((o) => o(name: 'Local'));
      final result = await database.managers.groceryStores
          .filter((f) => f.serverId.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('orderBy name asc', () async {
      await database.managers.groceryStores.create((o) => o(name: 'Z Store'));
      await database.managers.groceryStores.create((o) => o(name: 'A Store'));
      final result = await database.managers.groceryStores
          .orderBy((o) => o.name.asc())
          .get();
      expect(result.first.name, 'A Store');
    });

    test('orderBy syncStatus', () async {
      await database.managers.groceryStores.create(
          (o) => o(name: 'A', syncStatus: const Value(2)));
      await database.managers.groceryStores.create(
          (o) => o(name: 'B', syncStatus: const Value(0)));
      final result = await database.managers.groceryStores
          .orderBy((o) => o.syncStatus.asc())
          .get();
      expect(result.first.syncStatus, 0);
    });

    test('count, exists, delete', () async {
      final store =
          await database.managers.groceryStores.createReturning((o) => o(name: 'Del'));
      expect(await database.managers.groceryStores.count(), 1);
      expect(await database.managers.groceryStores.exists(), isTrue);
      await database.managers.groceryStores
          .filter((f) => f.id.equals(store.id))
          .delete();
      expect(await database.managers.groceryStores.count(), 0);
    });
  });

  // ── GroceryItem Manager ───────────────────────────────────────────────────

  group('Manager API - GroceryItems', () {
    test('create and get', () async {
      await database.managers.groceryItems.create((o) => o(name: 'Milk'));
      final items = await database.managers.groceryItems.get();
      expect(items.length, 1);
    });

    test('filter by name equals', () async {
      await database.managers.groceryItems.create((o) => o(name: 'Milk'));
      await database.managers.groceryItems.create((o) => o(name: 'Eggs'));
      final result = await database.managers.groceryItems
          .filter((f) => f.name.equals('Milk'))
          .get();
      expect(result.length, 1);
    });

    test('filter by defaultUnit', () async {
      await database.managers.groceryItems.create(
          (o) => o(name: 'Milk', defaultUnit: const Value('gallon')));
      final result = await database.managers.groceryItems
          .filter((f) => f.defaultUnit.equals('gallon'))
          .get();
      expect(result.length, 1);
    });

    test('filter by defaultStoreServerId isNull', () async {
      await database.managers.groceryItems.create((o) => o(name: 'No store'));
      final result = await database.managers.groceryItems
          .filter((f) => f.defaultStoreServerId.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by serverId isNull', () async {
      await database.managers.groceryItems.create((o) => o(name: 'Local'));
      final result = await database.managers.groceryItems
          .filter((f) => f.serverId.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter name contains', () async {
      await database.managers.groceryItems.create((o) => o(name: 'Whole Milk'));
      final result = await database.managers.groceryItems
          .filter((f) => f.name.contains('Milk'))
          .get();
      expect(result.length, 1);
    });

    test('orderBy name asc', () async {
      await database.managers.groceryItems.create((o) => o(name: 'Zucchini'));
      await database.managers.groceryItems.create((o) => o(name: 'Apple'));
      final result = await database.managers.groceryItems
          .orderBy((o) => o.name.asc())
          .get();
      expect(result.first.name, 'Apple');
    });

    test('count, exists, delete', () async {
      final item =
          await database.managers.groceryItems.createReturning((o) => o(name: 'Del'));
      expect(await database.managers.groceryItems.count(), 1);
      expect(await database.managers.groceryItems.exists(), isTrue);
      await database.managers.groceryItems
          .filter((f) => f.id.equals(item.id))
          .delete();
      expect(await database.managers.groceryItems.count(), 0);
    });
  });

  // ── GroceryOnHand Manager ─────────────────────────────────────────────────

  group('Manager API - GroceryOnHand', () {
    test('create and get', () async {
      await database.managers.groceryOnHand.create((o) => o(itemServerId: 1));
      final rows = await database.managers.groceryOnHand.get();
      expect(rows.length, 1);
    });

    test('filter by itemServerId', () async {
      await database.managers.groceryOnHand.create((o) => o(itemServerId: 10));
      await database.managers.groceryOnHand.create((o) => o(itemServerId: 20));
      final result = await database.managers.groceryOnHand
          .filter((f) => f.itemServerId.equals(10))
          .get();
      expect(result.length, 1);
    });

    test('filter by syncStatus', () async {
      await database.managers.groceryOnHand.create(
          (o) => o(itemServerId: 1, syncStatus: const Value(1)));
      final result = await database.managers.groceryOnHand
          .filter((f) => f.syncStatus.equals(1))
          .get();
      expect(result.length, 1);
    });

    test('filter by unit', () async {
      await database.managers.groceryOnHand.create(
          (o) => o(itemServerId: 1, unit: const Value('lb')));
      final result = await database.managers.groceryOnHand
          .filter((f) => f.unit.equals('lb'))
          .get();
      expect(result.length, 1);
    });

    test('orderBy itemServerId asc', () async {
      await database.managers.groceryOnHand.create((o) => o(itemServerId: 5));
      await database.managers.groceryOnHand.create((o) => o(itemServerId: 1));
      final result = await database.managers.groceryOnHand
          .orderBy((o) => o.itemServerId.asc())
          .get();
      expect(result.first.itemServerId, 1);
    });

    test('orderBy syncStatus desc', () async {
      await database.managers.groceryOnHand.create(
          (o) => o(itemServerId: 1, syncStatus: const Value(0)));
      await database.managers.groceryOnHand.create(
          (o) => o(itemServerId: 2, syncStatus: const Value(2)));
      final result = await database.managers.groceryOnHand
          .orderBy((o) => o.syncStatus.desc())
          .get();
      expect(result.first.syncStatus, 2);
    });

    test('count, exists, delete', () async {
      final row = await database.managers.groceryOnHand
          .createReturning((o) => o(itemServerId: 99));
      expect(await database.managers.groceryOnHand.count(), 1);
      expect(await database.managers.groceryOnHand.exists(), isTrue);
      await database.managers.groceryOnHand
          .filter((f) => f.id.equals(row.id))
          .delete();
      expect(await database.managers.groceryOnHand.count(), 0);
    });
  });

  // ── GroceryList Manager ───────────────────────────────────────────────────

  group('Manager API - GroceryLists', () {
    test('create and get', () async {
      await database.managers.groceryLists.create((o) => o(name: 'Weekly'));
      final lists = await database.managers.groceryLists.get();
      expect(lists.length, 1);
    });

    test('filter by name', () async {
      await database.managers.groceryLists.create((o) => o(name: 'Weekly'));
      await database.managers.groceryLists.create((o) => o(name: 'Monthly'));
      final result = await database.managers.groceryLists
          .filter((f) => f.name.equals('Weekly'))
          .get();
      expect(result.length, 1);
    });

    test('filter by status', () async {
      await database.managers.groceryLists.create(
          (o) => o(name: 'Active', status: const Value('active')));
      await database.managers.groceryLists.create(
          (o) => o(name: 'Draft', status: const Value('draft')));
      final result = await database.managers.groceryLists
          .filter((f) => f.status.equals('active'))
          .get();
      expect(result.length, 1);
    });

    test('filter by syncStatus', () async {
      await database.managers.groceryLists.create(
          (o) => o(name: 'Pending', syncStatus: const Value(1)));
      final result = await database.managers.groceryLists
          .filter((f) => f.syncStatus.equals(1))
          .get();
      expect(result.length, 1);
    });

    test('filter by shoppingDate isNull', () async {
      await database.managers.groceryLists.create((o) => o(name: 'No date'));
      final result = await database.managers.groceryLists
          .filter((f) => f.shoppingDate.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by storeServerId isNull', () async {
      await database.managers.groceryLists.create((o) => o(name: 'No store'));
      final result = await database.managers.groceryLists
          .filter((f) => f.storeServerId.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by serverId isNull', () async {
      await database.managers.groceryLists.create((o) => o(name: 'Local'));
      final result = await database.managers.groceryLists
          .filter((f) => f.serverId.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('orderBy name asc', () async {
      await database.managers.groceryLists.create((o) => o(name: 'Z list'));
      await database.managers.groceryLists.create((o) => o(name: 'A list'));
      final result = await database.managers.groceryLists
          .orderBy((o) => o.name.asc())
          .get();
      expect(result.first.name, 'A list');
    });

    test('orderBy status', () async {
      await database.managers.groceryLists.create(
          (o) => o(name: 'Active', status: const Value('active')));
      await database.managers.groceryLists.create(
          (o) => o(name: 'Draft', status: const Value('draft')));
      final result = await database.managers.groceryLists
          .orderBy((o) => o.status.asc())
          .get();
      expect(result.length, 2);
    });

    test('count, exists, delete', () async {
      final list =
          await database.managers.groceryLists.createReturning((o) => o(name: 'Del'));
      expect(await database.managers.groceryLists.count(), 1);
      expect(await database.managers.groceryLists.exists(), isTrue);
      await database.managers.groceryLists
          .filter((f) => f.id.equals(list.id))
          .delete();
      expect(await database.managers.groceryLists.count(), 0);
    });
  });

  // ── GroceryListItem Manager ───────────────────────────────────────────────

  group('Manager API - GroceryListItems', () {
    late int listId;

    setUp(() async {
      listId = await database.insertGroceryList(
        const GroceryListsCompanion(name: Value('Parent')),
      );
    });

    test('create and get', () async {
      await database.managers.groceryListItems.create(
        (o) => o(listLocalId: listId, itemServerId: 1),
      );
      final items = await database.managers.groceryListItems.get();
      expect(items.length, 1);
    });

    test('filter by listLocalId', () async {
      await database.managers.groceryListItems.create(
          (o) => o(listLocalId: listId, itemServerId: 1));
      final result = await database.managers.groceryListItems
          .filter((f) => f.listLocalId.equals(listId))
          .get();
      expect(result.length, 1);
    });

    test('filter by itemServerId', () async {
      await database.managers.groceryListItems.create(
          (o) => o(listLocalId: listId, itemServerId: 10));
      await database.managers.groceryListItems.create(
          (o) => o(listLocalId: listId, itemServerId: 20));
      final result = await database.managers.groceryListItems
          .filter((f) => f.itemServerId.equals(10))
          .get();
      expect(result.length, 1);
    });

    test('filter by status', () async {
      await database.managers.groceryListItems.create(
        (o) => o(listLocalId: listId, itemServerId: 1, status: const Value('in_cart')),
      );
      final result = await database.managers.groceryListItems
          .filter((f) => f.status.equals('in_cart'))
          .get();
      expect(result.length, 1);
    });

    test('filter by syncStatus', () async {
      await database.managers.groceryListItems.create(
        (o) => o(listLocalId: listId, itemServerId: 1, syncStatus: const Value(1)),
      );
      final result = await database.managers.groceryListItems
          .filter((f) => f.syncStatus.equals(1))
          .get();
      expect(result.length, 1);
    });

    test('filter by unit', () async {
      await database.managers.groceryListItems.create(
        (o) => o(listLocalId: listId, itemServerId: 1, unit: const Value('lb')),
      );
      final result = await database.managers.groceryListItems
          .filter((f) => f.unit.equals('lb'))
          .get();
      expect(result.length, 1);
    });

    test('filter by serverId isNull', () async {
      await database.managers.groceryListItems.create(
          (o) => o(listLocalId: listId, itemServerId: 1));
      final result = await database.managers.groceryListItems
          .filter((f) => f.serverId.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by listServerId isNull', () async {
      await database.managers.groceryListItems.create(
          (o) => o(listLocalId: listId, itemServerId: 1));
      final result = await database.managers.groceryListItems
          .filter((f) => f.listServerId.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by notes isNull', () async {
      await database.managers.groceryListItems.create(
          (o) => o(listLocalId: listId, itemServerId: 1));
      final result = await database.managers.groceryListItems
          .filter((f) => f.notes.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('filter by price isNull', () async {
      await database.managers.groceryListItems.create(
          (o) => o(listLocalId: listId, itemServerId: 1));
      final result = await database.managers.groceryListItems
          .filter((f) => f.price.isNull())
          .get();
      expect(result.isNotEmpty, isTrue);
    });

    test('orderBy itemServerId asc', () async {
      await database.managers.groceryListItems.create(
          (o) => o(listLocalId: listId, itemServerId: 5));
      await database.managers.groceryListItems.create(
          (o) => o(listLocalId: listId, itemServerId: 1));
      final result = await database.managers.groceryListItems
          .orderBy((o) => o.itemServerId.asc())
          .get();
      expect(result.first.itemServerId, 1);
    });

    test('orderBy status', () async {
      await database.managers.groceryListItems.create(
        (o) => o(listLocalId: listId, itemServerId: 1, status: const Value('needed')),
      );
      await database.managers.groceryListItems.create(
        (o) => o(listLocalId: listId, itemServerId: 2, status: const Value('in_cart')),
      );
      final result = await database.managers.groceryListItems
          .orderBy((o) => o.status.asc())
          .get();
      expect(result.length, 2);
    });

    test('count, exists, delete', () async {
      final item = await database.managers.groceryListItems.createReturning(
        (o) => o(listLocalId: listId, itemServerId: 1),
      );
      expect(await database.managers.groceryListItems.count(), 1);
      expect(await database.managers.groceryListItems.exists(), isTrue);
      await database.managers.groceryListItems
          .filter((f) => f.id.equals(item.id))
          .delete();
      expect(await database.managers.groceryListItems.count(), 0);
    });
  });

  // ── AnnotationComposer (computedField) tests ──────────────────────────────
  // These tests exercise the AnnotationComposer column getters and the
  // withReferenceMapper lambda by calling computedField + withFields().get().

  group('AnnotationComposer - Categories', () {
    test('computedField covers all column getters', () async {
      await database.managers.categories.create((o) => o(name: 'Work'));
      final nameField = database.managers.categories.computedField((a) {
        a.id; a.serverId; a.color; a.icon; a.description;
        return a.name;
      });
      final rows = await database.managers.categories
          .withFields([nameField]).get();
      expect(rows.length, 1);
      expect(rows.first.$1.name, 'Work');
    });
  });

  group('AnnotationComposer - Persons', () {
    test('computedField covers all column getters', () async {
      await database.managers.persons.create((o) => o(name: 'Alice'));
      final nameField = database.managers.persons.computedField((a) {
        a.id; a.serverId; a.email;
        return a.name;
      });
      final rows = await database.managers.persons
          .withFields([nameField]).get();
      expect(rows.length, 1);
      expect(rows.first.$1.name, 'Alice');
    });
  });

  group('AnnotationComposer - Events', () {
    test('computedField covers all column getters', () async {
      await database.managers.events.create(
        (o) => o(title: 'Meeting', categoryServerId: 1, dtstart: '2026-05-01'),
      );
      final titleField = database.managers.events.computedField((a) {
        a.id; a.serverId; a.categoryServerId; a.rrule; a.dtstart;
        a.priority; a.description; a.isActive; a.amount; a.location;
        a.durationDays;
        return a.title;
      });
      final rows = await database.managers.events
          .withFields([titleField]).get();
      expect(rows.length, 1);
      expect(rows.first.$1.title, 'Meeting');
    });
  });

  group('AnnotationComposer - Occurrences', () {
    test('computedField covers all column getters', () async {
      await database.managers.occurrences.create(
        (o) => o(eventServerId: 100, occurrenceDate: '2026-05-01'),
      );
      final dateField = database.managers.occurrences.computedField((a) {
        a.id; a.serverId; a.eventServerId; a.status; a.notes; a.syncStatus;
        return a.occurrenceDate;
      });
      final rows = await database.managers.occurrences
          .withFields([dateField]).get();
      expect(rows.length, 1);
      expect(rows.first.$1.occurrenceDate, '2026-05-01');
    });
  });

  group('AnnotationComposer - Tasks', () {
    test('computedField covers all column getters', () async {
      await database.managers.tasks.create(
        (o) => o(title: 'Do work', createdAt: '2026-01-01', updatedAt: '2026-01-01'),
      );
      final titleField = database.managers.tasks.computedField((a) {
        a.id; a.serverId; a.description; a.status; a.priority;
        a.assigneeServerId; a.categoryServerId; a.dueDate; a.estimatedMinutes;
        a.recurrence; a.occurrenceServerId; a.order; a.syncStatus;
        a.completedAt; a.createdAt; a.updatedAt;
        return a.title;
      });
      final rows = await database.managers.tasks
          .withFields([titleField]).get();
      expect(rows.length, 1);
      expect(rows.first.$1.title, 'Do work');
    });
  });

  group('AnnotationComposer - Subtasks', () {
    late int taskId;
    setUp(() async {
      taskId = await database.managers.tasks.create(
        (o) => o(title: 'Parent', createdAt: '2026-01-01', updatedAt: '2026-01-01'),
      );
    });

    test('computedField covers all column getters', () async {
      await database.managers.subtasks.create(
        (o) => o(taskLocalId: taskId, title: 'Sub'),
      );
      final titleField = database.managers.subtasks.computedField((a) {
        a.id; a.serverId; a.taskLocalId; a.taskServerId; a.status;
        a.dueDate; a.order; a.completedAt; a.syncStatus;
        return a.title;
      });
      final rows = await database.managers.subtasks
          .withFields([titleField]).get();
      expect(rows.length, 1);
      expect(rows.first.$1.title, 'Sub');
    });
  });

  group('AnnotationComposer - CreditCards', () {
    test('computedField covers all column getters', () async {
      await database.managers.creditCards.create((o) => o(name: 'Visa'));
      final nameField = database.managers.creditCards.computedField((a) {
        a.id; a.serverId; a.issuer; a.lastFour; a.statementCloseDay;
        a.gracePeriodDays; a.weekendShift; a.cycleDays; a.cycleReferenceDate;
        a.dueDaySameMonth; a.dueDayNextMonth; a.annualFeeMonth;
        a.isActive; a.syncStatus;
        return a.name;
      });
      final rows = await database.managers.creditCards
          .withFields([nameField]).get();
      expect(rows.length, 1);
      expect(rows.first.$1.name, 'Visa');
    });
  });

  group('AnnotationComposer - CreditCardTrackerCache', () {
    test('computedField covers all column getters', () async {
      await database.managers.creditCardTrackerCache.create(
        (o) => o(
          cardServerId: 1,
          name: 'Card',
          grace: '2026-05-15',
          prevClose: '2026-04-15',
          prevDue: '2026-05-05',
          nextClose: '2026-05-15',
          nextCloseDays: 7,
          nextDue: '2026-06-05',
          nextDueDays: 28,
        ),
      );
      final nameField = database.managers.creditCardTrackerCache.computedField((a) {
        a.id; a.cardServerId; a.issuer; a.lastFour; a.grace; a.prevClose;
        a.prevDue; a.nextClose; a.nextCloseDays; a.nextDue; a.nextDueDays;
        a.annualFeeDate; a.annualFeeDays; a.prevDueOverdue;
        return a.name;
      });
      final rows = await database.managers.creditCardTrackerCache
          .withFields([nameField]).get();
      expect(rows.length, 1);
      expect(rows.first.$1.name, 'Card');
    });
  });

  group('AnnotationComposer - GroceryStores', () {
    test('computedField covers all column getters', () async {
      await database.managers.groceryStores.create((o) => o(name: 'Walmart'));
      final nameField = database.managers.groceryStores.computedField((a) {
        a.id; a.serverId; a.location; a.isActive; a.syncStatus;
        return a.name;
      });
      final rows = await database.managers.groceryStores
          .withFields([nameField]).get();
      expect(rows.length, 1);
      expect(rows.first.$1.name, 'Walmart');
    });
  });

  group('AnnotationComposer - GroceryItems', () {
    test('computedField covers all column getters', () async {
      await database.managers.groceryItems.create((o) => o(name: 'Milk'));
      final nameField = database.managers.groceryItems.computedField((a) {
        a.id; a.serverId; a.defaultUnit; a.defaultStoreServerId;
        return a.name;
      });
      final rows = await database.managers.groceryItems
          .withFields([nameField]).get();
      expect(rows.length, 1);
      expect(rows.first.$1.name, 'Milk');
    });
  });

  group('AnnotationComposer - GroceryOnHand', () {
    test('computedField covers all column getters', () async {
      await database.managers.groceryOnHand.create((o) => o(itemServerId: 1));
      final field = database.managers.groceryOnHand.computedField((a) {
        a.id; a.quantity; a.unit; a.syncStatus;
        return a.itemServerId;
      });
      final rows = await database.managers.groceryOnHand
          .withFields([field]).get();
      expect(rows.length, 1);
      expect(rows.first.$1.itemServerId, 1);
    });
  });

  group('AnnotationComposer - GroceryLists', () {
    test('computedField covers all column getters', () async {
      await database.managers.groceryLists.create((o) => o(name: 'Weekly'));
      final nameField = database.managers.groceryLists.computedField((a) {
        a.id; a.serverId; a.storeServerId; a.status; a.shoppingDate;
        a.syncStatus;
        return a.name;
      });
      final rows = await database.managers.groceryLists
          .withFields([nameField]).get();
      expect(rows.length, 1);
      expect(rows.first.$1.name, 'Weekly');
    });
  });

  group('AnnotationComposer - GroceryListItems', () {
    late int listId;
    setUp(() async {
      listId = await database.managers.groceryLists.create(
        (o) => o(name: 'Parent'),
      );
    });

    test('computedField covers all column getters', () async {
      await database.managers.groceryListItems.create(
        (o) => o(listLocalId: listId, itemServerId: 5),
      );
      final field = database.managers.groceryListItems.computedField((a) {
        a.id; a.serverId; a.listServerId; a.itemServerId; a.quantity;
        a.unit; a.price; a.status; a.notes; a.syncStatus;
        return a.listLocalId;
      });
      final rows = await database.managers.groceryListItems
          .withFields([field]).get();
      expect(rows.length, 1);
      expect(rows.first.$1.listLocalId, listId);
    });
  });
}
