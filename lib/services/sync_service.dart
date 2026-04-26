import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
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
    dev.log('fullRefresh: start', name: 'sync');
    final errors = <String>[];

    await Future.wait([
      _refreshCategories().catchError((e) { errors.add('categories: $e'); return; }),
      _refreshPersons().catchError((e) { errors.add('persons: $e'); return; }),
      _refreshOccurrences().catchError((e) { errors.add('occurrences: $e'); return; }),
      _refreshTasks().catchError((e) { errors.add('tasks: $e'); return; }),
      _refreshCreditCardList().catchError((e) { errors.add('credit cards: $e'); return; }),
      _refreshCreditCardTracker().catchError((e) { errors.add('credit card tracker: $e'); return; }),
      _refreshGrocery().catchError((e) { errors.add('grocery: $e'); return; }),
    ]);

    if (errors.isNotEmpty) {
      dev.log('fullRefresh: errors — ${errors.join(' | ')}', name: 'sync', level: 900);
      throw Exception(errors.join(' | '));
    }
    dev.log('fullRefresh: complete', name: 'sync');
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
              syncStatus: Value(SyncStatus.synced.value),
            ))
        .toList());
    // Purge local occurrences within the synced window that no longer exist on the server.
    final serverOccIds = occs.map((o) => o.id).toSet();
    final localOccs = await _db.getOccurrencesByDateRange(_fmt(start), _fmt(end));
    final orphanOccs = localOccs
        .where((o) => o.serverId != null && !serverOccIds.contains(o.serverId))
        .toList();
    for (final local in orphanOccs) {
      dev.log('_refreshOccurrences: purging orphan local=${local.id} serverId=${local.serverId}', name: 'sync');
    }
    // Fix: one SQL DELETE IN (...) instead of N individual deletes.
    await _db.deleteOccurrencesLocalBatch(orphanOccs.map((o) => o.id).toList());
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
                amount: Value(e.amount),
                location: Value(e.location),
                durationDays: Value(e.durationDays),
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
              order: Value(t.order),
              syncStatus: Value(SyncStatus.synced.value),
              completedAt: Value(t.completedAt),
              createdAt: Value(t.createdAt),
              updatedAt: Value(t.updatedAt),
            ))
        .toList());

    // Purge local tasks that were deleted on the server, then reuse the
    // refreshed list to resolve local IDs for subtask upserts.
    final serverIds = apiTasks.map((t) => t.id).toSet();
    final localTasks = await _db.getTasks();
    final orphanTasks = localTasks
        .where((t) => t.serverId != null && !serverIds.contains(t.serverId))
        .toList();
    for (final local in orphanTasks) {
      dev.log('_refreshTasks: purging orphan local=${local.id} serverId=${local.serverId}', name: 'sync');
    }
    await _db.deleteTasksLocalBatch(orphanTasks.map((t) => t.id).toList());

    // Fix #8: collect all subtasks first, then upsert in a single transaction.
    final serverToLocal = {for (final t in localTasks) t.serverId: t.id};
    final allSubtasks = <SubtasksCompanion>[];
    for (final t in apiTasks) {
      final localTaskId = serverToLocal[t.id];
      if (localTaskId == null) continue;
      allSubtasks.addAll(t.subtasks.map((s) => SubtasksCompanion(
            serverId: Value(s.id),
            taskLocalId: Value(localTaskId),
            taskServerId: Value(t.id),
            title: Value(s.title),
            status: Value(s.status),
            dueDate: Value(s.dueDate),
            order: Value(s.order),
            completedAt: Value(s.completedAt),
            syncStatus: Value(SyncStatus.synced.value),
          )));
    }
    if (allSubtasks.isNotEmpty) {
      await _db.upsertSubtasks(allSubtasks);
    }

    // Fetch all local subtasks in one query and group by task to avoid N+1.
    final allLocalSubtasks = await _db.getAllSubtasks();
    final subtasksByLocalTaskId = <int, List<Subtask>>{};
    for (final s in allLocalSubtasks) {
      subtasksByLocalTaskId.putIfAbsent(s.taskLocalId, () => []).add(s);
    }
    final orphanSubtaskIds = <int>[];
    for (final t in apiTasks) {
      final localTaskId = serverToLocal[t.id];
      if (localTaskId == null) continue;
      final serverSubtaskIds = t.subtasks.map((s) => s.id).toSet();
      for (final s in subtasksByLocalTaskId[localTaskId] ?? []) {
        if (s.serverId != null && !serverSubtaskIds.contains(s.serverId)) {
          dev.log('_refreshTasks: purging orphan subtask local=${s.id} serverId=${s.serverId}', name: 'sync');
          orphanSubtaskIds.add(s.id);
        }
      }
    }
    if (orphanSubtaskIds.isNotEmpty) {
      await _db.deleteSubtasksLocalBatch(orphanSubtaskIds);
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
              syncStatus: Value(SyncStatus.synced.value),
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
    pushed += await _pushGroceryLists(errors);
    pushed += await _pushGroceryListItems(errors);

    dev.log('pushPending: pushed=$pushed errors=${errors.length}', name: 'sync');
    return SyncResult(pushed: pushed, errors: errors);
  }

  Future<int> _pushOccurrences(List<String> errors) async {
    int count = 0;
    final pending = await _db.getPendingOccurrences();
    for (final occ in pending) {
      if (occ.serverId == null) continue; // can't create occurrences client-side
      try {
        // Fix #5 + #12: exhaustive enum switch surfaces the formerly-silent pendingCreate case.
        switch (SyncStatus.fromInt(occ.syncStatus)) {
          case SyncStatus.synced:
          case SyncStatus.pendingCreate:
            break; // occurrences cannot be created client-side
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
        final detail = _dioErrorDetail(e);
        dev.log('_pushOccurrences: serverId=${occ.serverId} $detail', name: 'sync', level: 900);
        errors.add('Occurrence ${occ.serverId}: $detail');
      }
    }
    return count;
  }

  Future<int> _pushTasks(List<String> errors) async {
    int count = 0;
    final pending = await _db.getPendingTasks();
    for (final task in pending) {
      try {
        switch (SyncStatus.fromInt(task.syncStatus)) {
          case SyncStatus.synced:
            break;
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
        if (e.response?.statusCode == 404) {
          // Task was deleted on the server; remove the orphaned local record.
          dev.log('_pushTasks: 404 for local=${task.id}, removing orphan', name: 'sync');
          await _db.deleteTaskLocal(task.id);
        } else {
          final detail = _dioErrorDetail(e);
          dev.log('_pushTasks: local=${task.id} $detail', name: 'sync', level: 900);
          errors.add('Task ${task.id}: $detail');
        }
      }
    }
    return count;
  }

  Future<int> _pushSubtasks(List<String> errors) async {
    int count = 0;
    final pending = await _db.getPendingSubtasks();
    for (final sub in pending) {
      try {
        switch (SyncStatus.fromInt(sub.syncStatus)) {
          case SyncStatus.synced:
            break;
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
        final detail = _dioErrorDetail(e);
        dev.log('_pushSubtasks: local=${sub.id} $detail', name: 'sync', level: 900);
        errors.add('Subtask ${sub.id}: $detail');
      }
    }
    return count;
  }

  Future<int> _pushCreditCards(List<String> errors) async {
    int count = 0;
    final pending = await _db.getPendingCreditCards();
    for (final card in pending) {
      try {
        switch (SyncStatus.fromInt(card.syncStatus)) {
          case SyncStatus.synced:
            break;
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
        if (e.response?.statusCode == 404) {
          dev.log('_pushCreditCards: 404 for local=${card.id}, removing orphan', name: 'sync');
          await _db.deleteCreditCardLocal(card.id);
        } else {
          final detail = _dioErrorDetail(e);
          dev.log('_pushCreditCards: local=${card.id} $detail', name: 'sync', level: 900);
          errors.add('CreditCard ${card.id}: $detail');
        }
      } catch (e) {
        dev.log('_pushCreditCards: local=${card.id} unexpected error: $e', name: 'sync', level: 900);
        errors.add('CreditCard ${card.id}: $e');
      }
    }
    return count;
  }

  // ── Grocery ──────────────────────────────────────────────────────────────────

  Future<void> _refreshGrocery() async {
    await Future.wait([
      _refreshGroceryStores(),
      _refreshGroceryItems(),
      _refreshGroceryOnHand(),
      _refreshGroceryLists(),
    ]);
  }

  Future<void> _refreshGroceryStores() async {
    final stores = await _api.fetchStores();
    await _db.upsertGroceryStores(stores
        .map((s) => GroceryStoresCompanion(
              serverId: Value(s.id),
              name: Value(s.name),
              location: Value(s.location),
              isActive: Value(s.isActive),
            ))
        .toList());
    await _db.purgeGroceryStores(stores.map((s) => s.id).toSet());
  }

  Future<void> _refreshGroceryItems() async {
    final items = await _api.fetchGroceryItems();
    await _db.upsertGroceryItems(items
        .map((i) => GroceryItemsCompanion(
              serverId: Value(i.id),
              name: Value(i.name),
              defaultUnit: Value(i.defaultUnit),
              defaultStoreServerId: Value(i.defaultStoreId),
            ))
        .toList());
    await _db.purgeGroceryItems(items.map((i) => i.id).toSet());
  }

  Future<void> _refreshGroceryOnHand() async {
    final onHand = await _api.fetchOnHand();
    await _db.upsertGroceryOnHand(onHand
        .map((o) => GroceryOnHandCompanion(
              itemServerId: Value(o.itemId),
              quantity: Value(o.quantity),
              unit: Value(o.unit),
            ))
        .toList());
    await _db.purgeGroceryOnHand(onHand.map((o) => o.itemId).toSet());
  }

  Future<void> _refreshGroceryLists() async {
    final apiLists = await _api.fetchGroceryLists();

    await _db.upsertGroceryLists(apiLists
        .map((l) => GroceryListsCompanion(
              serverId: Value(l.id),
              name: Value(l.name),
              storeServerId: Value(l.storeId),
              status: Value(l.status),
              shoppingDate: Value(l.shoppingDate),
              syncStatus: Value(SyncStatus.synced.value),
            ))
        .toList());

    // Purge local lists deleted on the server.
    final serverListIds = apiLists.map((l) => l.id).toSet();
    final localLists = await _db.getGroceryLists();
    final orphanLists = localLists
        .where(
          (l) => l.serverId != null && !serverListIds.contains(l.serverId),
        )
        .toList();
    await _db.deleteGroceryListsLocalBatch(
      orphanLists.map((l) => l.id).toList(),
    );

    // Resolve local list ids for list item upserts.
    final serverToLocalList = {
      for (final l in localLists) l.serverId: l.id,
    };

    // Collect all list items from the embedded payload.
    final allItems = <GroceryListItemsCompanion>[];
    for (final l in apiLists) {
      final localListId = serverToLocalList[l.id];
      if (localListId == null) continue;
      allItems.addAll(l.items.map((i) => GroceryListItemsCompanion(
            serverId: Value(i.id),
            listLocalId: Value(localListId),
            listServerId: Value(l.id),
            itemServerId: Value(i.itemId),
            quantity: Value(i.quantity),
            unit: Value(i.unit),
            price: Value(i.price),
            status: Value(i.status),
            notes: Value(i.notes),
            syncStatus: Value(SyncStatus.synced.value),
          )));
    }
    if (allItems.isNotEmpty) await _db.upsertGroceryListItems(allItems);

    // Purge orphan list items for lists that still exist.
    final serverItemIds = {
      for (final l in apiLists)
        for (final i in l.items) i.id,
    };
    final localItems = await _db.getGroceryListItems();
    final orphanItemIds = localItems
        .where(
          (i) =>
              i.serverId != null &&
              serverListIds.contains(i.listServerId) &&
              !serverItemIds.contains(i.serverId),
        )
        .map((i) => i.id)
        .toList();
    await _db.deleteGroceryListItemsLocalBatch(orphanItemIds);
  }

  Future<int> _pushGroceryLists(List<String> errors) async {
    int count = 0;
    final pending = await _db.getPendingGroceryLists();
    for (final list in pending) {
      try {
        switch (SyncStatus.fromInt(list.syncStatus)) {
          case SyncStatus.synced:
            break;
          case SyncStatus.pendingCreate:
            final body = _groceryListToJson(list);
            final created = await _api.createGroceryList(body);
            await _db.markGroceryListSynced(list.id, created.id);
            count++;
          case SyncStatus.pendingUpdate:
            if (list.serverId == null) break;
            final body = _groceryListToJson(list);
            await _api.updateGroceryList(list.serverId!, body);
            await _db.markGroceryListSynced(list.id, list.serverId!);
            count++;
          case SyncStatus.pendingDelete:
            if (list.serverId == null) break;
            await _api.deleteGroceryList(list.serverId!);
            await _db.deleteGroceryListLocal(list.id);
            count++;
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          dev.log(
            '_pushGroceryLists: 404 for local=${list.id}, removing orphan',
            name: 'sync',
          );
          await _db.deleteGroceryListLocal(list.id);
        } else {
          final detail = _dioErrorDetail(e);
          dev.log(
            '_pushGroceryLists: local=${list.id} $detail',
            name: 'sync',
            level: 900,
          );
          errors.add('GroceryList ${list.id}: $detail');
        }
      }
    }
    return count;
  }

  Future<int> _pushGroceryListItems(List<String> errors) async {
    int count = 0;
    final pending = await _db.getPendingGroceryListItems();
    for (final item in pending) {
      try {
        switch (SyncStatus.fromInt(item.syncStatus)) {
          case SyncStatus.synced:
            break;
          case SyncStatus.pendingCreate:
            // Parent list must be synced before creating items.
            if (item.listServerId == null) break;
            final created = await _api.addGroceryListItem(
              item.listServerId!,
              {
                'item_id': item.itemServerId,
                'quantity': item.quantity,
                'unit': item.unit,
                if (item.price != null) 'price': item.price,
                if (item.notes != null) 'notes': item.notes,
              },
            );
            await _db.markGroceryListItemSynced(item.id, created.id);
            count++;
          case SyncStatus.pendingUpdate:
            if (item.listServerId == null || item.serverId == null) break;
            // Route is /lists/{listId}/items/{itemServerId} — the server keys
            // on the catalog item id, not the list-item record's own server id.
            await _api.updateGroceryListItem(
              item.listServerId!,
              item.itemServerId,
              {
                'status': item.status,
                'quantity': item.quantity,
                'unit': item.unit,
                if (item.price != null) 'price': item.price,
                if (item.notes != null) 'notes': item.notes,
              },
            );
            await _db.markGroceryListItemSynced(item.id, item.serverId!);
            count++;
          case SyncStatus.pendingDelete:
            if (item.listServerId == null) break;
            await _api.removeGroceryListItem(
              item.listServerId!,
              item.itemServerId,
            );
            await _db.deleteGroceryListItemLocal(item.id);
            count++;
        }
      } on DioException catch (e) {
        final detail = _dioErrorDetail(e);
        dev.log(
          '_pushGroceryListItems: local=${item.id} $detail',
          name: 'sync',
          level: 900,
        );
        errors.add('GroceryListItem ${item.id}: $detail');
      }
    }
    return count;
  }

  Map<String, dynamic> _groceryListToJson(GroceryList l) => {
        'name': l.name,
        'status': l.status,
        if (l.storeServerId != null) 'store_id': l.storeServerId,
        if (l.shoppingDate != null) 'shopping_date': l.shoppingDate,
      };

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> _taskToJson(Task t) => {
        'title': t.title,
        'description': t.description,
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

  // Fix #11: use DateFormat instead of manual pad-left string building.
  static String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// Extract a loggable detail string from a DioException.
  /// Full server response bodies are written to the log only — never returned
  /// to callers that surface messages in the UI.
  static String _dioErrorDetail(DioException e) {
    final status = e.response?.statusCode;
    // Log full server body for developer debugging without exposing it to the UI.
    dev.log(
      '_dioErrorDetail: status=$status body=${e.response?.data}',
      name: 'sync',
      level: 900,
    );
    if (status == 400 || status == 422) return 'Validation error (HTTP $status) — check your data';
    if (status != null) return 'Server error (HTTP $status)';
    if (e.type == DioExceptionType.badCertificate) return 'TLS certificate error — connection may be intercepted';
    return e.message ?? 'Network error';
  }
}

class SyncResult {
  final int pushed;
  final List<String> errors;
  SyncResult({required this.pushed, required this.errors});
}
