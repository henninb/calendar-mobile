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

  // ── Full refresh (pull all server data into local DB) ────────────────────

  Future<void> fullRefresh() async {
    dev.log('fullRefresh: start', name: 'sync');
    final errors = <String>[];

    await Future.wait([
      _refreshCategories().catchError((e) {
        errors.add('categories: $e');
        return;
      }),
      _refreshPersons().catchError((e) {
        errors.add('persons: $e');
        return;
      }),
      _refreshOccurrences().catchError((e) {
        errors.add('occurrences: $e');
        return;
      }),
      _refreshTasks().catchError((e) {
        errors.add('tasks: $e');
        return;
      }),
      _refreshCreditCardList().catchError((e) {
        errors.add('credit cards: $e');
        return;
      }),
      _refreshCreditCardTracker().catchError((e) {
        errors.add('credit card tracker: $e');
        return;
      }),
      _refreshGrocery().catchError((e) {
        errors.add('grocery: $e');
        return;
      }),
    ]);

    if (errors.isNotEmpty) {
      final summary = errors.take(5).join(' | ');
      dev.log('fullRefresh: errors — $summary', name: 'sync', level: 900);
      throw Exception(summary);
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
    final start = DateTime(
      now.year,
      now.month - AppConstants.occurrencePastMonths,
      1,
    );
    final end = DateTime(
      now.year,
      now.month + AppConstants.occurrenceFutureMonths,
      0,
    );
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
    final localOccs =
        await _db.getOccurrencesByDateRange(_fmt(start), _fmt(end));
    final orphanIds = localOccs
        .where((o) => o.serverId != null && !serverOccIds.contains(o.serverId))
        .map((o) {
      dev.log(
        '_refreshOccurrences: purging orphan local=${o.id} serverId=${o.serverId}',
        name: 'sync',
      );
      return o.id;
    }).toList();
    await _db.deleteOccurrencesLocalBatch(orphanIds);

    // Cache events referenced by occurrences.
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

    // Skip overwriting records that have unpushed mutations — mirrors the
    // same protection in _refreshGroceryOnHand(). If pushPending() failed
    // (e.g. a network hiccup), fullRefresh() must not silently clear the
    // pending status and lose the local changes.
    final pendingTaskServerIds = (await _db.getPendingTasks())
        .where((t) => t.serverId != null)
        .map((t) => t.serverId!)
        .toSet();
    final pendingSubtaskServerIds = (await _db.getPendingSubtasks())
        .where((s) => s.serverId != null)
        .map((s) => s.serverId!)
        .toSet();

    await _db.upsertTasks(apiTasks
        .where((t) => !pendingTaskServerIds.contains(t.id))
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

    final serverIds = apiTasks.map((t) => t.id).toSet();
    final localTasks = await _db.getTasks();
    final orphanTaskIds = localTasks
        .where((t) => t.serverId != null && !serverIds.contains(t.serverId))
        .map((t) {
      dev.log(
        '_refreshTasks: purging orphan local=${t.id} serverId=${t.serverId}',
        name: 'sync',
      );
      return t.id;
    }).toList();
    await _db.deleteTasksLocalBatch(orphanTaskIds);

    // Collect all subtasks and upsert in a single transaction.
    // Skip subtasks whose parent task is pending, and skip any subtask that
    // itself has an unpushed mutation.
    final serverToLocal = {for (final t in localTasks) t.serverId: t.id};
    final allSubtasks = <SubtasksCompanion>[];
    for (final t in apiTasks) {
      if (pendingTaskServerIds.contains(t.id)) continue;
      final localTaskId = serverToLocal[t.id];
      if (localTaskId == null) continue;
      allSubtasks.addAll(t.subtasks
          .where((s) => !pendingSubtaskServerIds.contains(s.id))
          .map((s) => SubtasksCompanion(
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
    if (allSubtasks.isNotEmpty) await _db.upsertSubtasks(allSubtasks);

    // Purge orphan subtasks — fetch all in one query to avoid N+1.
    // Skip tasks with pending mutations (their subtasks may not match server yet)
    // and never delete a subtask that itself has an unpushed mutation.
    final allLocalSubtasks = await _db.getAllSubtasks();
    final subtasksByLocalTaskId = <int, List<Subtask>>{};
    for (final s in allLocalSubtasks) {
      subtasksByLocalTaskId.putIfAbsent(s.taskLocalId, () => []).add(s);
    }
    final orphanSubtaskIds = <int>[];
    for (final t in apiTasks) {
      if (pendingTaskServerIds.contains(t.id)) continue;
      final localTaskId = serverToLocal[t.id];
      if (localTaskId == null) continue;
      final serverSubtaskIds = t.subtasks.map((s) => s.id).toSet();
      for (final s in subtasksByLocalTaskId[localTaskId] ?? []) {
        if (s.serverId != null &&
            !serverSubtaskIds.contains(s.serverId) &&
            !pendingSubtaskServerIds.contains(s.serverId)) {
          dev.log(
            '_refreshTasks: purging orphan subtask local=${s.id} serverId=${s.serverId}',
            name: 'sync',
          );
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

  // ── Push pending local mutations ──────────────────────────────────────────

  Future<SyncResult> pushPending() async {
    int pushed = 0;
    final errors = <String>[];

    pushed += await _pushOccurrences(errors);
    pushed += await _pushTasks(errors);
    pushed += await _pushSubtasks(errors);
    pushed += await _pushCreditCards(errors);
    pushed += await _pushGroceryOnHand(errors);
    pushed += await _pushGroceryStores(errors);
    pushed += await _pushGroceryLists(errors);
    // Items are pushed after lists so markGroceryListSynced() has already
    // back-filled listServerId on any items whose parent list was just pushed.
    pushed += await _pushGroceryListItems(errors);

    dev.log('pushPending: pushed=$pushed errors=${errors.length}', name: 'sync');
    return SyncResult(pushed: pushed, errors: errors);
  }

  /// Iterates [pending], calls [process] on each item, and counts successes.
  /// Handles [DioException] (with 404 routed to [on404]) and unexpected errors
  /// uniformly so individual push methods only contain entity-specific logic.
  Future<int> _pushLoop<T>({
    required Future<List<T>> Function() getPending,
    required String Function(T) label,
    required Future<bool> Function(T) process,
    required Future<void> Function(T)? on404,
    required List<String> errors,
  }) async {
    int count = 0;
    final pending = await getPending();
    for (final item in pending) {
      try {
        if (await process(item)) count++;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404 && on404 != null) {
          dev.log('sync: ${label(item)} 404, removing orphan', name: 'sync');
          await on404(item);
        } else {
          final detail = _dioErrorDetail(e);
          dev.log('sync: ${label(item)} $detail', name: 'sync', level: 900);
          errors.add('${label(item)}: $detail');
        }
      } catch (e) {
        dev.log('sync: ${label(item)} unexpected: $e', name: 'sync', level: 900);
        errors.add('${label(item)}: unexpected error');
      }
    }
    return count;
  }

  Future<int> _pushOccurrences(List<String> errors) => _pushLoop(
        getPending: _db.getPendingOccurrences,
        label: (o) => 'Occurrence ${o.serverId ?? o.id}',
        on404: null,
        errors: errors,
        process: (occ) async {
          if (occ.serverId == null) return false;
          switch (SyncStatus.fromInt(occ.syncStatus)) {
            case SyncStatus.synced:
            case SyncStatus.pendingCreate:
              return false; // occurrences cannot be created client-side
            case SyncStatus.pendingUpdate:
              await _api.patchOccurrence(
                occ.serverId!,
                {'status': occ.status, 'notes': occ.notes},
              );
              await _db.markOccurrenceSynced(occ.id, occ.serverId!);
              return true;
            case SyncStatus.pendingDelete:
              await _api.deleteOccurrence(occ.serverId!);
              await _db.deleteOccurrenceLocal(occ.id);
              return true;
          }
        },
      );

  Future<int> _pushTasks(List<String> errors) => _pushLoop(
        getPending: _db.getPendingTasks,
        label: (t) => 'Task ${t.id}',
        on404: (t) => _db.deleteTaskLocal(t.id),
        errors: errors,
        process: (task) async {
          switch (SyncStatus.fromInt(task.syncStatus)) {
            case SyncStatus.synced:
              return false;
            case SyncStatus.pendingCreate:
              final created = await _api.createTask(_taskToJson(task));
              await _db.markTaskSynced(task.id, created.id);
              return true;
            case SyncStatus.pendingUpdate:
              if (task.serverId == null) return false;
              await _api.patchTask(task.serverId!, _taskToJson(task));
              await _db.markTaskSynced(task.id, task.serverId!);
              return true;
            case SyncStatus.pendingDelete:
              if (task.serverId == null) return false;
              await _api.deleteTask(task.serverId!);
              await _db.deleteTaskLocal(task.id);
              return true;
          }
        },
      );

  Future<int> _pushSubtasks(List<String> errors) => _pushLoop(
        getPending: _db.getPendingSubtasks,
        label: (s) => 'Subtask ${s.id}',
        on404: (s) => _db.deleteSubtaskLocal(s.id),
        errors: errors,
        process: (sub) async {
          switch (SyncStatus.fromInt(sub.syncStatus)) {
            case SyncStatus.synced:
              return false;
            case SyncStatus.pendingCreate:
              // markTaskSynced() back-fills taskServerId, but the snapshot was
              // taken before _pushTasks ran, so re-read from the DB when null.
              final createTaskServerId = sub.taskServerId ??
                  (await _db.getTaskById(sub.taskLocalId))?.serverId;
              if (createTaskServerId == null) return false;
              final created =
                  await _api.createSubtask(createTaskServerId, _subtaskToJson(sub));
              await _db.markSubtaskSynced(sub.id, created.id);
              return true;
            case SyncStatus.pendingUpdate:
              final updateTaskServerId = sub.taskServerId ??
                  (await _db.getTaskById(sub.taskLocalId))?.serverId;
              if (sub.serverId == null || updateTaskServerId == null) return false;
              await _api.patchSubtask(
                updateTaskServerId,
                sub.serverId!,
                _subtaskToJson(sub),
              );
              await _db.markSubtaskSynced(sub.id, sub.serverId!);
              return true;
            case SyncStatus.pendingDelete:
              final deleteTaskServerId = sub.taskServerId ??
                  (await _db.getTaskById(sub.taskLocalId))?.serverId;
              if (sub.serverId == null || deleteTaskServerId == null) return false;
              await _api.deleteSubtask(deleteTaskServerId, sub.serverId!);
              await _db.deleteSubtaskLocal(sub.id);
              return true;
          }
        },
      );

  Future<int> _pushCreditCards(List<String> errors) => _pushLoop(
        getPending: _db.getPendingCreditCards,
        label: (c) => 'CreditCard ${c.id}',
        on404: (c) => _db.deleteCreditCardLocal(c.id),
        errors: errors,
        process: (card) async {
          switch (SyncStatus.fromInt(card.syncStatus)) {
            case SyncStatus.synced:
              return false;
            case SyncStatus.pendingCreate:
              final created = await _api.createCreditCard(_cardToJson(card));
              await _db.markCreditCardSynced(card.id, created.id);
              return true;
            case SyncStatus.pendingUpdate:
              if (card.serverId == null) return false;
              await _api.updateCreditCard(card.serverId!, _cardToJson(card));
              await _db.markCreditCardSynced(card.id, card.serverId!);
              return true;
            case SyncStatus.pendingDelete:
              if (card.serverId == null) return false;
              await _api.deleteCreditCard(card.serverId!);
              await _db.deleteCreditCardLocal(card.id);
              return true;
          }
        },
      );

  // ── Grocery ───────────────────────────────────────────────────────────────

  Future<void> _refreshGrocery() => Future.wait([
        _refreshGroceryStores(),
        _refreshGroceryItems(),
        _refreshGroceryOnHand(),
        _refreshGroceryLists(),
      ]);

  Future<void> _refreshGroceryStores() async {
    final stores = await _api.fetchStores();
    await _db.upsertGroceryStores(stores
        .map((s) => GroceryStoresCompanion(
              serverId: Value(s.id),
              name: Value(s.name),
              location: Value(s.location),
              isActive: Value(s.isActive),
              syncStatus: Value(SyncStatus.synced.value),
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
    // Skip overwriting pending rows with stale server data — protects any
    // quantity edits queued offline.
    final pending = await _db.getPendingGroceryOnHand();
    final pendingItemIds = pending.map((o) => o.itemServerId).toSet();
    final toUpsert = onHand
        .where((o) => !pendingItemIds.contains(o.itemId))
        .map((o) => GroceryOnHandCompanion(
              itemServerId: Value(o.itemId),
              quantity: Value(o.quantity),
              unit: Value(o.unit),
              syncStatus: const Value(0),
            ))
        .toList();
    if (toUpsert.isNotEmpty) await _db.upsertGroceryOnHand(toUpsert);
    // Never remove rows that are pending push.
    await _db.purgeGroceryOnHand({
      ...onHand.map((o) => o.itemId),
      ...pendingItemIds,
    });
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

    final serverListIds = apiLists.map((l) => l.id).toSet();
    final localLists = await _db.getGroceryLists();
    final orphanListIds = localLists
        .where((l) => l.serverId != null && !serverListIds.contains(l.serverId))
        .map((l) => l.id)
        .toList();
    await _db.deleteGroceryListsLocalBatch(orphanListIds);

    final serverToLocalList = {for (final l in localLists) l.serverId: l.id};
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

    final serverItemIds = {
      for (final l in apiLists)
        for (final i in l.items) i.id,
    };
    final localItems = await _db.getGroceryListItems();
    final orphanItemIds = localItems
        .where((i) =>
            i.serverId != null &&
            serverListIds.contains(i.listServerId) &&
            !serverItemIds.contains(i.serverId))
        .map((i) => i.id)
        .toList();
    await _db.deleteGroceryListItemsLocalBatch(orphanItemIds);
  }

  Future<int> _pushGroceryOnHand(List<String> errors) => _pushLoop(
        getPending: _db.getPendingGroceryOnHand,
        label: (o) => 'GroceryOnHand ${o.id}',
        on404: (o) => _db.deleteGroceryOnHandLocal(o.id),
        errors: errors,
        process: (oh) async {
          switch (SyncStatus.fromInt(oh.syncStatus)) {
            case SyncStatus.synced:
              return false;
            case SyncStatus.pendingCreate:
            case SyncStatus.pendingUpdate:
              // PUT is an idempotent upsert keyed on item_id, so create and
              // update are handled identically — safe to replay on retry.
              await _api.upsertOnHand(
                oh.itemServerId,
                {'quantity': oh.quantity, 'unit': oh.unit},
              );
              await _db.markGroceryOnHandSynced(oh.id);
              return true;
            case SyncStatus.pendingDelete:
              await _api.deleteOnHand(oh.itemServerId);
              await _db.deleteGroceryOnHandLocal(oh.id);
              return true;
          }
        },
      );

  Future<int> _pushGroceryStores(List<String> errors) => _pushLoop(
        getPending: _db.getPendingGroceryStores,
        label: (s) => 'GroceryStore ${s.id}',
        on404: (s) => _db.deleteGroceryStoreLocal(s.id),
        errors: errors,
        process: (store) async {
          switch (SyncStatus.fromInt(store.syncStatus)) {
            case SyncStatus.synced:
              return false;
            case SyncStatus.pendingCreate:
              final created = await _api.createStore(_storeToJson(store));
              await _db.markGroceryStoreSynced(store.id, created.id);
              return true;
            case SyncStatus.pendingUpdate:
              if (store.serverId == null) return false;
              await _api.updateStore(store.serverId!, _storeToJson(store));
              await _db.markGroceryStoreSynced(store.id, store.serverId!);
              return true;
            case SyncStatus.pendingDelete:
              if (store.serverId == null) return false;
              await _api.deleteStore(store.serverId!);
              await _db.deleteGroceryStoreLocal(store.id);
              return true;
          }
        },
      );

  Future<int> _pushGroceryLists(List<String> errors) => _pushLoop(
        getPending: _db.getPendingGroceryLists,
        label: (l) => 'GroceryList ${l.id}',
        on404: (l) => _db.deleteGroceryListLocal(l.id),
        errors: errors,
        process: (list) async {
          switch (SyncStatus.fromInt(list.syncStatus)) {
            case SyncStatus.synced:
              return false;
            case SyncStatus.pendingCreate:
              final created =
                  await _api.createGroceryList(_groceryListToJson(list));
              await _db.markGroceryListSynced(list.id, created.id);
              return true;
            case SyncStatus.pendingUpdate:
              if (list.serverId == null) return false;
              await _api.updateGroceryList(
                  list.serverId!, _groceryListToJson(list));
              await _db.markGroceryListSynced(list.id, list.serverId!);
              return true;
            case SyncStatus.pendingDelete:
              if (list.serverId == null) return false;
              await _api.deleteGroceryList(list.serverId!);
              await _db.deleteGroceryListLocal(list.id);
              return true;
          }
        },
      );

  Future<int> _pushGroceryListItems(List<String> errors) => _pushLoop(
        getPending: _db.getPendingGroceryListItems,
        label: (i) => 'GroceryListItem ${i.id}',
        on404: (i) => _db.deleteGroceryListItemLocal(i.id),
        errors: errors,
        process: (item) async {
          switch (SyncStatus.fromInt(item.syncStatus)) {
            case SyncStatus.synced:
              return false;
            case SyncStatus.pendingCreate:
              // markGroceryListSynced() back-fills listServerId on child items,
              // but the snapshot predates _pushGroceryLists, so re-read when null.
              final createListServerId = item.listServerId ??
                  (await _db.getGroceryListById(item.listLocalId))?.serverId;
              if (createListServerId == null) return false;
              final created = await _api.addGroceryListItem(
                createListServerId,
                {
                  'item_id': item.itemServerId,
                  'quantity': item.quantity,
                  'unit': item.unit,
                  if (item.price != null) 'price': item.price,
                  if (item.notes != null) 'notes': item.notes,
                },
              );
              await _db.markGroceryListItemSynced(item.id, created.id);
              return true;
            case SyncStatus.pendingUpdate:
              final updateListServerId = item.listServerId ??
                  (await _db.getGroceryListById(item.listLocalId))?.serverId;
              if (updateListServerId == null || item.serverId == null) {
                return false;
              }
              await _api.updateGroceryListItem(
                updateListServerId,
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
              return true;
            case SyncStatus.pendingDelete:
              final deleteListServerId = item.listServerId ??
                  (await _db.getGroceryListById(item.listLocalId))?.serverId;
              if (deleteListServerId == null) return false;
              await _api.removeGroceryListItem(
                  deleteListServerId, item.itemServerId);
              await _db.deleteGroceryListItemLocal(item.id);
              return true;
          }
        },
      );

  // ── JSON serialisers ──────────────────────────────────────────────────────

  Map<String, dynamic> _storeToJson(GroceryStore s) => {
        'name': s.name,
        if (s.location != null) 'location': s.location,
        'is_active': s.isActive,
      };

  Map<String, dynamic> _groceryListToJson(GroceryList l) => {
        'name': l.name,
        'status': l.status,
        if (l.storeServerId != null) 'store_id': l.storeServerId,
        if (l.shoppingDate != null) 'shopping_date': l.shoppingDate,
      };

  Map<String, dynamic> _taskToJson(Task t) => {
        'title': t.title,
        'description': t.description,
        'status': t.status,
        'priority': t.priority,
        if (t.assigneeServerId != null) 'assignee_id': t.assigneeServerId,
        if (t.categoryServerId != null) 'category_id': t.categoryServerId,
        if (t.dueDate != null) 'due_date': t.dueDate,
        if (t.estimatedMinutes != null)
          'estimated_minutes': t.estimatedMinutes,
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
        if (c.statementCloseDay != null)
          'statement_close_day': c.statementCloseDay,
        if (c.gracePeriodDays != null) 'grace_period_days': c.gracePeriodDays,
        if (c.weekendShift != null) 'weekend_shift': c.weekendShift,
        if (c.cycleDays != null) 'cycle_days': c.cycleDays,
        if (c.cycleReferenceDate != null)
          'cycle_reference_date': c.cycleReferenceDate,
        if (c.dueDaySameMonth != null) 'due_day_same_month': c.dueDaySameMonth,
        if (c.dueDayNextMonth != null) 'due_day_next_month': c.dueDayNextMonth,
        if (c.annualFeeMonth != null) 'annual_fee_month': c.annualFeeMonth,
        'is_active': c.isActive,
      };

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// Extracts a loggable detail string from a [DioException].
  /// Full server response bodies are written to the log only — never returned
  /// to callers that surface messages in the UI.
  static String _dioErrorDetail(DioException e) {
    final status = e.response?.statusCode;
    dev.log(
      '_dioErrorDetail: status=$status body=${e.response?.data}',
      name: 'sync',
      level: 900,
    );
    if (status == 400 || status == 422) {
      return 'Validation error (HTTP $status) — check your data';
    }
    if (status != null) return 'Server error (HTTP $status)';
    if (e.type == DioExceptionType.badCertificate) {
      return 'TLS certificate error — connection may be intercepted';
    }
    return e.message ?? 'Network error';
  }
}

class SyncResult {
  const SyncResult({required this.pushed, required this.errors});

  final int pushed;
  final List<String> errors;
}
