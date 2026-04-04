import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ── Tables ───────────────────────────────────────────────────────────────────

class Categories extends Table {
  IntColumn get id       => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get name    => text()();
  TextColumn get color   => text().withDefault(const Constant('#3b82f6'))();
  TextColumn get icon    => text().withDefault(const Constant('📅'))();
  TextColumn get description => text().nullable()();
}

class Persons extends Table {
  IntColumn get id       => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get name    => text()();
  TextColumn get email   => text().nullable()();
}

class Events extends Table {
  IntColumn  get id           => integer().autoIncrement()();
  IntColumn  get serverId     => integer().nullable()();
  TextColumn get title        => text()();
  IntColumn  get categoryServerId => integer()();
  TextColumn get rrule        => text().nullable()();
  TextColumn get dtstart      => text()();
  TextColumn get priority     => text().withDefault(const Constant('medium'))();
  TextColumn get description  => text().nullable()();
  BoolColumn get isActive     => boolean().withDefault(const Constant(true))();
}

class Occurrences extends Table {
  IntColumn  get id              => integer().autoIncrement()();
  IntColumn  get serverId        => integer().nullable()();
  IntColumn  get eventServerId   => integer()();
  TextColumn get occurrenceDate  => text()();
  TextColumn get status          => text().withDefault(const Constant('upcoming'))();
  TextColumn get notes           => text().nullable()();
  IntColumn  get syncStatus      => integer().withDefault(const Constant(0))();
}

class Tasks extends Table {
  IntColumn  get id               => integer().autoIncrement()();
  IntColumn  get serverId         => integer().nullable()();
  TextColumn get title            => text()();
  TextColumn get description      => text().nullable()();
  TextColumn get status           => text().withDefault(const Constant('todo'))();
  TextColumn get priority         => text().withDefault(const Constant('medium'))();
  IntColumn  get assigneeServerId => integer().nullable()();
  IntColumn  get categoryServerId => integer().nullable()();
  TextColumn get dueDate          => text().nullable()();
  IntColumn  get estimatedMinutes => integer().nullable()();
  TextColumn get recurrence       => text().withDefault(const Constant('none'))();
  IntColumn  get occurrenceServerId => integer().nullable()();
  IntColumn  get syncStatus       => integer().withDefault(const Constant(0))();
  TextColumn get createdAt        => text()();
  TextColumn get updatedAt        => text()();
}

class Subtasks extends Table {
  IntColumn  get id            => integer().autoIncrement()();
  IntColumn  get serverId      => integer().nullable()();
  IntColumn  get taskLocalId   => integer()();
  IntColumn  get taskServerId  => integer().nullable()();
  TextColumn get title         => text()();
  TextColumn get status        => text().withDefault(const Constant('todo'))();
  TextColumn get dueDate       => text().nullable()();
  IntColumn  get order         => integer().withDefault(const Constant(0))();
  IntColumn  get syncStatus    => integer().withDefault(const Constant(0))();
}

class CreditCards extends Table {
  IntColumn  get id                  => integer().autoIncrement()();
  IntColumn  get serverId            => integer().nullable()();
  TextColumn get name                => text()();
  TextColumn get issuer              => text().nullable()();
  TextColumn get lastFour            => text().nullable()();
  IntColumn  get statementCloseDay   => integer().nullable()();
  IntColumn  get gracePeriodDays     => integer().nullable()();
  TextColumn get weekendShift        => text().nullable()();
  IntColumn  get cycleDays           => integer().nullable()();
  TextColumn get cycleReferenceDate  => text().nullable()();
  IntColumn  get dueDaySameMonth     => integer().nullable()();
  IntColumn  get dueDayNextMonth     => integer().nullable()();
  IntColumn  get annualFeeMonth      => integer().nullable()();
  BoolColumn get isActive            => boolean().withDefault(const Constant(true))();
  IntColumn  get syncStatus          => integer().withDefault(const Constant(0))();
}

class CreditCardTrackerCache extends Table {
  IntColumn  get id              => integer().autoIncrement()();
  IntColumn  get cardServerId    => integer()();
  TextColumn get name            => text()();
  TextColumn get issuer          => text().nullable()();
  TextColumn get lastFour        => text().nullable()();
  TextColumn get grace           => text()();
  TextColumn get prevClose       => text()();
  TextColumn get prevDue         => text()();
  TextColumn get nextClose       => text()();
  IntColumn  get nextCloseDays   => integer()();
  TextColumn get nextDue         => text()();
  IntColumn  get nextDueDays     => integer()();
  TextColumn get annualFeeDate   => text().nullable()();
  IntColumn  get annualFeeDays   => integer().nullable()();
  BoolColumn get prevDueOverdue  => boolean().withDefault(const Constant(false))();
}

// ── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Categories,
  Persons,
  Events,
  Occurrences,
  Tasks,
  Subtasks,
  CreditCards,
  CreditCardTrackerCache,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Remove duplicates introduced by the old INSERT OR REPLACE logic that
        // keyed on the auto-increment id instead of server_id. Keep the row
        // with the lowest local id for each server_id.
        const tablesWithServerId = [
          'categories',
          'persons',
          'events',
          'occurrences',
          'tasks',
          'subtasks',
          'credit_cards',
        ];
        for (final t in tablesWithServerId) {
          await customStatement(
            'DELETE FROM $t '
            'WHERE id NOT IN ('
            '  SELECT MIN(id) FROM $t GROUP BY server_id'
            ') AND server_id IS NOT NULL',
          );
          await customStatement(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_${t}_server_id '
            'ON $t(server_id)',
          );
        }
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'calendar_mobile');
  }

  // ── Category DAO ────────────────────────────────────────────────────────────

  Future<List<Category>> getAllCategories() => select(categories).get();

  Stream<List<Category>> watchCategories() => select(categories).watch();

  Future<void> upsertCategories(List<CategoriesCompanion> rows) async {
    await transaction(() async {
      for (final row in rows) {
        await into(categories).insert(
          row,
          onConflict: DoUpdate((old) => row, target: [categories.serverId]),
        );
      }
    });
  }

  // ── Person DAO ──────────────────────────────────────────────────────────────

  Future<List<Person>> getAllPersons() => select(persons).get();

  Stream<List<Person>> watchPersons() => select(persons).watch();

  Future<void> upsertPersons(List<PersonsCompanion> rows) async {
    await transaction(() async {
      for (final row in rows) {
        await into(persons).insert(
          row,
          onConflict: DoUpdate((old) => row, target: [persons.serverId]),
        );
      }
    });
  }

  // ── Event DAO ───────────────────────────────────────────────────────────────

  Future<List<Event>> getAllEvents() => select(events).get();

  Future<void> upsertEvents(List<EventsCompanion> rows) async {
    await transaction(() async {
      for (final row in rows) {
        await into(events).insert(
          row,
          onConflict: DoUpdate((old) => row, target: [events.serverId]),
        );
      }
    });
  }

  // ── Occurrence DAO ──────────────────────────────────────────────────────────

  Stream<List<Occurrence>> watchOccurrences() => select(occurrences).watch();

  Future<List<Occurrence>> getOccurrences() => select(occurrences).get();

  Future<List<Occurrence>> getOccurrencesByDateRange(String start, String end) {
    return (select(occurrences)
          ..where((o) => o.occurrenceDate.isBiggerOrEqualValue(start))
          ..where((o) => o.occurrenceDate.isSmallerOrEqualValue(end))
          ..orderBy([(o) => OrderingTerm.asc(o.occurrenceDate)]))
        .get();
  }

  Future<List<Occurrence>> getPendingOccurrences() {
    return (select(occurrences)
          ..where((o) => o.syncStatus.isNotValue(0)))
        .get();
  }

  Future<void> upsertOccurrences(List<OccurrencesCompanion> rows) async {
    await transaction(() async {
      for (final row in rows) {
        await into(occurrences).insert(
          row,
          onConflict: DoUpdate((old) => row, target: [occurrences.serverId]),
        );
      }
    });
  }

  Future<void> updateOccurrenceStatus(int localId, String status) async {
    await (update(occurrences)..where((o) => o.id.equals(localId))).write(
      OccurrencesCompanion(
        status: Value(status),
        syncStatus: const Value(2), // pendingUpdate
      ),
    );
  }

  Future<void> markOccurrenceSynced(int localId, int serverId) async {
    await (update(occurrences)..where((o) => o.id.equals(localId))).write(
      OccurrencesCompanion(
        serverId: Value(serverId),
        syncStatus: const Value(0),
      ),
    );
  }

  Future<void> markOccurrenceDeleted(int localId) async {
    final occ = await (select(occurrences)..where((o) => o.id.equals(localId))).getSingleOrNull();
    if (occ == null) return;
    if (occ.serverId == null) {
      await (delete(occurrences)..where((o) => o.id.equals(localId))).go();
    } else {
      await (update(occurrences)..where((o) => o.id.equals(localId))).write(
        const OccurrencesCompanion(syncStatus: Value(3)), // pendingDelete
      );
    }
  }

  Future<void> deleteOccurrenceLocal(int localId) async {
    await (delete(occurrences)..where((o) => o.id.equals(localId))).go();
  }

  // ── Task DAO ────────────────────────────────────────────────────────────────

  Stream<List<Task>> watchTasks() => select(tasks).watch();

  Future<List<Task>> getTasks() => select(tasks).get();

  Future<List<Task>> getPendingTasks() {
    return (select(tasks)..where((t) => t.syncStatus.isNotValue(0))).get();
  }

  Future<int> insertTask(TasksCompanion row) => into(tasks).insert(row);

  Future<void> updateTask(int localId, TasksCompanion row) async {
    await (update(tasks)..where((t) => t.id.equals(localId))).write(row);
  }

  Future<void> markTaskDeleted(int localId) async {
    final task = await (select(tasks)..where((t) => t.id.equals(localId))).getSingleOrNull();
    if (task == null) return;
    if (task.serverId == null) {
      await (delete(tasks)..where((t) => t.id.equals(localId))).go();
    } else {
      await (update(tasks)..where((t) => t.id.equals(localId))).write(
        const TasksCompanion(syncStatus: Value(3)),
      );
    }
  }

  Future<void> markTaskSynced(int localId, int serverId) async {
    await (update(tasks)..where((t) => t.id.equals(localId))).write(
      TasksCompanion(serverId: Value(serverId), syncStatus: const Value(0)),
    );
  }

  Future<void> deleteTaskLocal(int localId) async {
    await (delete(tasks)..where((t) => t.id.equals(localId))).go();
    await (delete(subtasks)..where((s) => s.taskLocalId.equals(localId))).go();
  }

  Future<void> upsertTasks(List<TasksCompanion> rows) async {
    await transaction(() async {
      for (final row in rows) {
        await into(tasks).insert(
          row,
          onConflict: DoUpdate((old) => row, target: [tasks.serverId]),
        );
      }
    });
  }

  // ── Subtask DAO ─────────────────────────────────────────────────────────────

  Future<List<Subtask>> getSubtasksForTask(int taskLocalId) {
    return (select(subtasks)
          ..where((s) => s.taskLocalId.equals(taskLocalId))
          ..orderBy([(s) => OrderingTerm.asc(s.order)]))
        .get();
  }

  Stream<List<Subtask>> watchSubtasksForTask(int taskLocalId) {
    return (select(subtasks)
          ..where((s) => s.taskLocalId.equals(taskLocalId))
          ..orderBy([(s) => OrderingTerm.asc(s.order)]))
        .watch();
  }

  Future<List<Subtask>> getPendingSubtasks() {
    return (select(subtasks)..where((s) => s.syncStatus.isNotValue(0))).get();
  }

  Future<int> insertSubtask(SubtasksCompanion row) => into(subtasks).insert(row);

  Future<void> updateSubtask(int localId, SubtasksCompanion row) async {
    await (update(subtasks)..where((s) => s.id.equals(localId))).write(row);
  }

  Future<void> markSubtaskDeleted(int localId) async {
    final sub = await (select(subtasks)..where((s) => s.id.equals(localId))).getSingleOrNull();
    if (sub == null) return;
    if (sub.serverId == null) {
      await (delete(subtasks)..where((s) => s.id.equals(localId))).go();
    } else {
      await (update(subtasks)..where((s) => s.id.equals(localId))).write(
        const SubtasksCompanion(syncStatus: Value(3)),
      );
    }
  }

  Future<void> markSubtaskSynced(int localId, int serverId) async {
    await (update(subtasks)..where((s) => s.id.equals(localId))).write(
      SubtasksCompanion(serverId: Value(serverId), syncStatus: const Value(0)),
    );
  }

  Future<void> deleteSubtaskLocal(int localId) async {
    await (delete(subtasks)..where((s) => s.id.equals(localId))).go();
  }

  Future<void> upsertSubtasks(List<SubtasksCompanion> rows) async {
    await transaction(() async {
      for (final row in rows) {
        await into(subtasks).insert(
          row,
          onConflict: DoUpdate((old) => row, target: [subtasks.serverId]),
        );
      }
    });
  }

  // ── Credit Card DAO ─────────────────────────────────────────────────────────

  Stream<List<CreditCard>> watchCreditCards() => select(creditCards).watch();

  Future<List<CreditCard>> getCreditCards() => select(creditCards).get();

  Future<List<CreditCard>> getPendingCreditCards() {
    return (select(creditCards)..where((c) => c.syncStatus.isNotValue(0))).get();
  }

  Future<int> insertCreditCard(CreditCardsCompanion row) =>
      into(creditCards).insert(row);

  Future<void> updateCreditCard(int localId, CreditCardsCompanion row) async {
    await (update(creditCards)..where((c) => c.id.equals(localId))).write(row);
  }

  Future<void> markCreditCardDeleted(int localId) async {
    final card = await (select(creditCards)..where((c) => c.id.equals(localId))).getSingleOrNull();
    if (card == null) return;
    if (card.serverId == null) {
      await (delete(creditCards)..where((c) => c.id.equals(localId))).go();
    } else {
      await (update(creditCards)..where((c) => c.id.equals(localId))).write(
        const CreditCardsCompanion(syncStatus: Value(3)),
      );
    }
  }

  Future<void> markCreditCardSynced(int localId, int serverId) async {
    await (update(creditCards)..where((c) => c.id.equals(localId))).write(
      CreditCardsCompanion(serverId: Value(serverId), syncStatus: const Value(0)),
    );
  }

  Future<void> deleteCreditCardLocal(int localId) async {
    await (delete(creditCards)..where((c) => c.id.equals(localId))).go();
  }

  Future<void> upsertCreditCards(List<CreditCardsCompanion> rows) async {
    await transaction(() async {
      for (final row in rows) {
        await into(creditCards).insert(
          row,
          onConflict: DoUpdate((old) => row, target: [creditCards.serverId]),
        );
      }
    });
  }

  // ── Credit Card Tracker Cache DAO ───────────────────────────────────────────

  Future<List<CreditCardTrackerCacheData>> getTrackerCache() =>
      select(creditCardTrackerCache).get();

  Stream<List<CreditCardTrackerCacheData>> watchTrackerCache() =>
      select(creditCardTrackerCache).watch();

  Future<void> replaceTrackerCache(List<CreditCardTrackerCacheCompanion> rows) async {
    await delete(creditCardTrackerCache).go();
    await batch((b) {
      b.insertAll(creditCardTrackerCache, rows);
    });
  }
}
