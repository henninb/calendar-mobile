import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_models.dart';
import '../core/constants.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart' show Value;

/// Pulls fresh data from the server and pushes pending local mutations.
class SyncService {
  SyncService(this._db, this._api);

  final AppDatabase _db;
  final ApiClient _api;

  // ── Full refresh (pull all server data into local DB) ────────────────────────

  Future<void> fullRefresh() async {
    final errors = <String>[];

    await Future.wait([
      _refreshCategories().catchError((e) { errors.add('categories: $e'); return; }),
      _refreshPersons().catchError((e) { errors.add('persons: $e'); return; }),
      _refreshOccurrences().catchError((e) { errors.add('occurrences: $e'); return; }),
      _refreshTasks().catchError((e) { errors.add('tasks: $e'); return; }),
      _refreshCreditCardList().catchError((e) { errors.add('credit cards: $e'); return; }),
      _refreshCreditCardTracker().catchError((e) { errors.add('credit card tracker: $e'); return; }),
    ]);

    if (errors.isNotEmpty) {
      throw Exception(errors.join(' | '));
    }
  }

  Future<void> _refreshCategories() async {
    final cats = await _api.fetchCategories();
    await _db.upsertCategories(cats
        .map((c) => CategoriesCompanion(
              serverId: Value(c.id),
              name: Value(c.name),
              color: Value(c.color),
              icon: Value(c.icon),
              description: Value(c.description),
            ))
        .toList());
  }

  Future<void> _refreshPersons() async {
    final persons = await _api.fetchPersons();
    await _db.upsertPersons(persons
        .map((p) => PersonsCompanion(
              serverId: Value(p.id),
              name: Value(p.name),
              email: Value(p.email),
            ))
        .toList());
  }

  Future<void> _refreshOccurrences() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month + 3, 0);
    final occs = await _api.fetchOccurrences(
      startDate: _fmt(start),
      endDate: _fmt(end),
    );
    await _db.upsertOccurrences(occs
        .map((o) => OccurrencesCompanion(
              serverId: Value(o.id),
              eventServerId: Value(o.eventId),
              occurrenceDate: Value(o.occurrenceDate),
              status: Value(o.status),
              notes: Value(o.notes),
              syncStatus: const Value(SyncStatus.synced),
            ))
        .toList());
    // Also cache events referenced by occurrences
    final events = occs
        .where((o) => o.event != null)
        .map((o) => o.event!)
        .fold<Map<int, ApiEvent>>({}, (map, e) {
      map[e.id] = e;
      return map;
    }).values.toList();
    if (events.isNotEmpty) {
      await _db.upsertEvents(events
          .map((e) => EventsCompanion(
                serverId: Value(e.id),
                title: Value(e.title),
                categoryServerId: Value(e.categoryId),
                rrule: Value(e.rrule),
                dtstart: Value(e.dtstart),
                priority: Value(e.priority),
                description: Value(e.description),
                isActive: Value(e.isActive),
              ))
          .toList());
    }
  }

  Future<void> _refreshTasks() async {
    final apiTasks = await _api.fetchTasks();

    await _db.upsertTasks(apiTasks
        .map((t) => TasksCompanion(
              serverId: Value(t.id),
              title: Value(t.title),
              description: Value(t.description),
              status: Value(t.status),
              priority: Value(t.priority),
              assigneeServerId: Value(t.assigneeId),
              categoryServerId: Value(t.categoryId),
              dueDate: Value(t.dueDate),
              estimatedMinutes: Value(t.estimatedMinutes),
              recurrence: Value(t.recurrence),
              occurrenceServerId: Value(t.occurrenceId),
              syncStatus: const Value(SyncStatus.synced),
              createdAt: Value(t.createdAt),
              updatedAt: Value(t.updatedAt),
            ))
        .toList());

    // Upsert subtasks — resolve local task id first
    final localTasks = await _db.getTasks();
    final serverToLocal = {for (final t in localTasks) t.serverId: t.id};

    for (final t in apiTasks) {
      final localTaskId = serverToLocal[t.id];
      if (localTaskId == null) continue;
      await _db.upsertSubtasks(t.subtasks
          .map((s) => SubtasksCompanion(
                serverId: Value(s.id),
                taskLocalId: Value(localTaskId),
                taskServerId: Value(t.id),
                title: Value(s.title),
                status: Value(s.status),
                dueDate: Value(s.dueDate),
                order: Value(s.order),
                syncStatus: const Value(SyncStatus.synced),
              ))
          .toList());
    }
  }

  Future<void> _refreshCreditCardList() async {
    final cards = await _api.fetchCreditCards();
    await _db.upsertCreditCards(cards
        .map((c) => CreditCardsCompanion(
              serverId: Value(c.id),
              name: Value(c.name),
              issuer: Value(c.issuer),
              lastFour: Value(c.lastFour),
              statementCloseDay: Value(c.statementCloseDay),
              gracePeriodDays: Value(c.gracePeriodDays),
              weekendShift: Value(c.weekendShift),
              cycleDays: Value(c.cycleDays),
              cycleReferenceDate: Value(c.cycleReferenceDate),
              dueDaySameMonth: Value(c.dueDaySameMonth),
              dueDayNextMonth: Value(c.dueDayNextMonth),
              annualFeeMonth: Value(c.annualFeeMonth),
              isActive: Value(c.isActive),
              syncStatus: const Value(SyncStatus.synced),
            ))
        .toList());
  }

  Future<void> _refreshCreditCardTracker() async {
    final trackerRows = await _api.fetchTrackerRows();
    await _db.replaceTrackerCache(trackerRows
        .map((r) => CreditCardTrackerCacheCompanion(
              cardServerId: Value(r.id),
              name: Value(r.name),
              issuer: Value(r.issuer),
              lastFour: Value(r.lastFour),
              grace: Value(r.grace),
              prevClose: Value(r.prevClose),
              prevDue: Value(r.prevDue),
              nextClose: Value(r.nextClose),
              nextCloseDays: Value(r.nextCloseDays),
              nextDue: Value(r.nextDue),
              nextDueDays: Value(r.nextDueDays),
              annualFeeDate: Value(r.annualFeeDate),
              annualFeeDays: Value(r.annualFeeDays),
              prevDueOverdue: Value(r.prevDueOverdue),
            ))
        .toList());
  }

  // ── Push pending local mutations ─────────────────────────────────────────────

  Future<SyncResult> pushPending() async {
    int pushed = 0;
    final errors = <String>[];

    pushed += await _pushOccurrences(errors);
    pushed += await _pushTasks(errors);
    pushed += await _pushSubtasks(errors);
    pushed += await _pushCreditCards(errors);

    return SyncResult(pushed: pushed, errors: errors);
  }

  Future<int> _pushOccurrences(List<String> errors) async {
    int count = 0;
    final pending = await _db.getPendingOccurrences();
    for (final occ in pending) {
      if (occ.serverId == null) continue; // can't create occurrences client-side
      try {
        switch (occ.syncStatus) {
          case SyncStatus.pendingUpdate:
            await _api.patchOccurrence(occ.serverId!, {'status': occ.status, 'notes': occ.notes});
            await _db.markOccurrenceSynced(occ.id, occ.serverId!);
            count++;
          case SyncStatus.pendingDelete:
            await _api.deleteOccurrence(occ.serverId!);
            await _db.deleteOccurrenceLocal(occ.id);
            count++;
        }
      } on DioException catch (e) {
        errors.add('Occurrence ${occ.serverId}: ${e.message}');
      }
    }
    return count;
  }

  Future<int> _pushTasks(List<String> errors) async {
    int count = 0;
    final pending = await _db.getPendingTasks();
    for (final task in pending) {
      try {
        switch (task.syncStatus) {
          case SyncStatus.pendingCreate:
            final body = _taskToJson(task);
            final created = await _api.createTask(body);
            await _db.markTaskSynced(task.id, created.id);
            count++;
          case SyncStatus.pendingUpdate:
            if (task.serverId == null) break;
            final body = _taskToJson(task);
            await _api.patchTask(task.serverId!, body);
            await _db.markTaskSynced(task.id, task.serverId!);
            count++;
          case SyncStatus.pendingDelete:
            if (task.serverId == null) break;
            await _api.deleteTask(task.serverId!);
            await _db.deleteTaskLocal(task.id);
            count++;
        }
      } on DioException catch (e) {
        errors.add('Task ${task.id}: ${e.message}');
      }
    }
    return count;
  }

  Future<int> _pushSubtasks(List<String> errors) async {
    int count = 0;
    final pending = await _db.getPendingSubtasks();
    for (final sub in pending) {
      try {
        switch (sub.syncStatus) {
          case SyncStatus.pendingCreate:
            if (sub.taskServerId == null) break;
            final body = _subtaskToJson(sub);
            final created = await _api.createSubtask(sub.taskServerId!, body);
            await _db.markSubtaskSynced(sub.id, created.id);
            count++;
          case SyncStatus.pendingUpdate:
            if (sub.serverId == null || sub.taskServerId == null) break;
            final body = _subtaskToJson(sub);
            await _api.patchSubtask(sub.taskServerId!, sub.serverId!, body);
            await _db.markSubtaskSynced(sub.id, sub.serverId!);
            count++;
          case SyncStatus.pendingDelete:
            if (sub.serverId == null || sub.taskServerId == null) break;
            await _api.deleteSubtask(sub.taskServerId!, sub.serverId!);
            await _db.deleteSubtaskLocal(sub.id);
            count++;
        }
      } on DioException catch (e) {
        errors.add('Subtask ${sub.id}: ${e.message}');
      }
    }
    return count;
  }

  Future<int> _pushCreditCards(List<String> errors) async {
    int count = 0;
    final pending = await _db.getPendingCreditCards();
    for (final card in pending) {
      try {
        switch (card.syncStatus) {
          case SyncStatus.pendingCreate:
            final body = _cardToJson(card);
            final created = await _api.createCreditCard(body);
            await _db.markCreditCardSynced(card.id, created.id);
            count++;
          case SyncStatus.pendingUpdate:
            if (card.serverId == null) break;
            final body = _cardToJson(card);
            await _api.updateCreditCard(card.serverId!, body);
            await _db.markCreditCardSynced(card.id, card.serverId!);
            count++;
          case SyncStatus.pendingDelete:
            if (card.serverId == null) break;
            await _api.deleteCreditCard(card.serverId!);
            await _db.deleteCreditCardLocal(card.id);
            count++;
        }
      } on DioException catch (e) {
        errors.add('CreditCard ${card.id}: ${e.message}');
      }
    }
    return count;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> _taskToJson(Task t) => {
        'title': t.title,
        if (t.description != null) 'description': t.description,
        'status': t.status,
        'priority': t.priority,
        if (t.assigneeServerId != null) 'assignee_id': t.assigneeServerId,
        if (t.categoryServerId != null) 'category_id': t.categoryServerId,
        if (t.dueDate != null) 'due_date': t.dueDate,
        if (t.estimatedMinutes != null) 'estimated_minutes': t.estimatedMinutes,
        'recurrence': t.recurrence,
      };

  Map<String, dynamic> _subtaskToJson(Subtask s) => {
        'title': s.title,
        'status': s.status,
        if (s.dueDate != null) 'due_date': s.dueDate,
        'order': s.order,
      };

  Map<String, dynamic> _cardToJson(CreditCard c) => {
        'name': c.name,
        if (c.issuer != null) 'issuer': c.issuer,
        if (c.lastFour != null) 'last_four': c.lastFour,
        if (c.statementCloseDay != null) 'statement_close_day': c.statementCloseDay,
        if (c.gracePeriodDays != null) 'grace_period_days': c.gracePeriodDays,
        if (c.weekendShift != null) 'weekend_shift': c.weekendShift,
        if (c.cycleDays != null) 'cycle_days': c.cycleDays,
        if (c.cycleReferenceDate != null) 'cycle_reference_date': c.cycleReferenceDate,
        if (c.dueDaySameMonth != null) 'due_day_same_month': c.dueDaySameMonth,
        if (c.dueDayNextMonth != null) 'due_day_next_month': c.dueDayNextMonth,
        if (c.annualFeeMonth != null) 'annual_fee_month': c.annualFeeMonth,
        'is_active': c.isActive,
      };

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class SyncResult {
  final int pushed;
  final List<String> errors;
  SyncResult({required this.pushed, required this.errors});
}
