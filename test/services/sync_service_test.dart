import 'package:calendar_mobile/api/api_client.dart';
import 'package:calendar_mobile/api/api_models.dart';
import 'package:calendar_mobile/database/app_database.dart';
import 'package:calendar_mobile/services/sync_service.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late SyncService syncService;
  late AppDatabase database;
  late MockApiClient mockApi;

  setUp(() {
    database = AppDatabase.fromExecutor(NativeDatabase.memory());
    mockApi = MockApiClient();
    syncService = SyncService(database, mockApi);
  });

  tearDown(() async {
    await database.close();
  });

  group('SyncService.fullRefresh', () {
    test('refreshes categories successfully', () async {
      when(() => mockApi.fetchCategories()).thenAnswer((_) async => [
            const ApiCategory(id: 1, name: 'Work', color: '#ff0000', icon: '💼'),
          ]);
      when(() => mockApi.fetchPersons()).thenAnswer((_) async => []);
      when(() => mockApi.fetchOccurrences(startDate: any(named: 'startDate'), endDate: any(named: 'endDate')))
          .thenAnswer((_) async => []);
      when(() => mockApi.fetchTasks()).thenAnswer((_) async => []);
      when(() => mockApi.fetchCreditCards()).thenAnswer((_) async => []);
      when(() => mockApi.fetchTrackerRows()).thenAnswer((_) async => []);
      when(() => mockApi.fetchStores()).thenAnswer((_) async => []);
      when(() => mockApi.fetchGroceryItems()).thenAnswer((_) async => []);
      when(() => mockApi.fetchOnHand()).thenAnswer((_) async => []);
      when(() => mockApi.fetchGroceryLists()).thenAnswer((_) async => []);

      await syncService.fullRefresh();

      final categories = await database.getAllCategories();
      expect(categories.length, 1);
      expect(categories.first.serverId, 1);
      expect(categories.first.name, 'Work');
    });

    test('throws exception if any refresh fails', () async {
      when(() => mockApi.fetchCategories()).thenThrow(Exception('API Error'));
      // ... mock others as empty
      when(() => mockApi.fetchPersons()).thenAnswer((_) async => []);
      when(() => mockApi.fetchOccurrences(startDate: any(named: 'startDate'), endDate: any(named: 'endDate')))
          .thenAnswer((_) async => []);
      when(() => mockApi.fetchTasks()).thenAnswer((_) async => []);
      when(() => mockApi.fetchCreditCards()).thenAnswer((_) async => []);
      when(() => mockApi.fetchTrackerRows()).thenAnswer((_) async => []);
      when(() => mockApi.fetchStores()).thenAnswer((_) async => []);
      when(() => mockApi.fetchGroceryItems()).thenAnswer((_) async => []);
      when(() => mockApi.fetchOnHand()).thenAnswer((_) async => []);
      when(() => mockApi.fetchGroceryLists()).thenAnswer((_) async => []);

      expect(() => syncService.fullRefresh(), throwsException);
    });
  });

  group('SyncService.pushPending', () {
    test('pushes pending task creation', () async {
      // Insert a pending task
      final taskId = await database.insertTask(
        const TasksCompanion(
          title: Value('New Task'),
          syncStatus: Value(1), // pendingCreate
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );

      when(() => mockApi.createTask(any())).thenAnswer((_) async => ApiTask(
            id: 500,
            title: 'New Task',
            status: 'todo',
            priority: 'medium',
            recurrence: 'none',
            order: 0,
            subtasks: [],
            createdAt: '2026-01-01',
            updatedAt: '2026-01-01',
          ));

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      expect(result.errors, isEmpty);

      final task = await database.getTaskById(taskId);
      expect(task!.serverId, 500);
      expect(task.syncStatus, 0); // synced
      verify(() => mockApi.createTask(any())).called(1);
    });

    test('pushes pending task update', () async {
      final taskId = await database.insertTask(
        const TasksCompanion(
          serverId: Value(501),
          title: Value('Updated Task'),
          syncStatus: Value(2), // pendingUpdate
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );

      when(() => mockApi.patchTask(any(), any())).thenAnswer((_) async => Response(requestOptions: RequestOptions()));

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => mockApi.patchTask(501, any())).called(1);
    });

    test('pushes pending task deletion', () async {
      final taskId = await database.insertTask(
        const TasksCompanion(
          serverId: Value(502),
          title: Value('Deleted Task'),
          syncStatus: Value(3), // pendingDelete
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      );

      when(() => mockApi.deleteTask(any())).thenAnswer((_) async => Response(requestOptions: RequestOptions()));

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      final task = await database.getTaskById(taskId);
      expect(task, isNull);
      verify(() => mockApi.deleteTask(502)).called(1);
    });
  });

  group('SyncService.pushPending - task recovery (no serverId)', () {
    test('creates task on server when pendingUpdate has no serverId', () async {
      final taskId = await database.insertTask(const TasksCompanion(
        title: Value('Offline Task'),
        syncStatus: Value(2), // pendingUpdate but never pushed
        createdAt: Value('2026-01-01'),
        updatedAt: Value('2026-01-01'),
      ));

      when(() => mockApi.createTask(any())).thenAnswer((_) async => ApiTask(
            id: 600,
            title: 'Offline Task',
            status: 'todo',
            priority: 'medium',
            recurrence: 'none',
            order: 0,
            subtasks: [],
            createdAt: '2026-01-01',
            updatedAt: '2026-01-01',
          ));

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      expect(result.errors, isEmpty);
      final task = await database.getTaskById(taskId);
      expect(task!.serverId, 600);
      expect(task.syncStatus, 0); // synced
      verify(() => mockApi.createTask(any())).called(1);
      verifyNever(() => mockApi.patchTask(any(), any()));
    });

    test('deletes locally when pendingDelete has no serverId', () async {
      final taskId = await database.insertTask(const TasksCompanion(
        title: Value('Never-pushed Deleted Task'),
        syncStatus: Value(3), // pendingDelete but no serverId
        createdAt: Value('2026-01-01'),
        updatedAt: Value('2026-01-01'),
      ));

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      expect(result.errors, isEmpty);
      final task = await database.getTaskById(taskId);
      expect(task, isNull);
      verifyNever(() => mockApi.deleteTask(any()));
    });
  });

  group('SyncService.pushPending - subtasks', () {
    late int taskId;

    setUp(() async {
      taskId = await database.insertTask(const TasksCompanion(
        serverId: Value(10),
        title: Value('Parent Task'),
        syncStatus: Value(0),
        createdAt: Value('2026-01-01'),
        updatedAt: Value('2026-01-01'),
      ));
    });

    test('creates subtask on server when pendingCreate', () async {
      final subId = await database.insertSubtask(SubtasksCompanion(
        taskLocalId: Value(taskId),
        taskServerId: const Value(10),
        title: const Value('New Subtask'),
        status: const Value('todo'),
        syncStatus: const Value(1), // pendingCreate
      ));

      when(() => mockApi.createSubtask(any(), any()))
          .thenAnswer((_) async => const ApiSubtask(
                id: 700, taskId: 10, title: 'New Subtask', status: 'todo', order: 0));

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      final subs = await database.getSubtasksForTask(taskId);
      expect(subs.first.serverId, 700);
      expect(subs.first.syncStatus, 0);
      verify(() => mockApi.createSubtask(10, any())).called(1);
    });

    test('patches subtask on server when pendingUpdate with serverId', () async {
      await database.insertSubtask(SubtasksCompanion(
        serverId: const Value(701),
        taskLocalId: Value(taskId),
        taskServerId: const Value(10),
        title: const Value('Updated Subtask'),
        status: const Value('done'),
        syncStatus: const Value(2), // pendingUpdate
      ));

      when(() => mockApi.patchSubtask(any(), any(), any()))
          .thenAnswer((_) async {});

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      verify(() => mockApi.patchSubtask(10, 701, any())).called(1);
      verifyNever(() => mockApi.createSubtask(any(), any()));
    });

    test('deletes subtask on server when pendingDelete with serverId', () async {
      final subId = await database.insertSubtask(SubtasksCompanion(
        serverId: const Value(702),
        taskLocalId: Value(taskId),
        taskServerId: const Value(10),
        title: const Value('Deleted Subtask'),
        status: const Value('todo'),
        syncStatus: const Value(3), // pendingDelete
      ));

      when(() => mockApi.deleteSubtask(any(), any())).thenAnswer((_) async {});

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      final subs = await database.getSubtasksForTask(taskId);
      expect(subs, isEmpty);
      verify(() => mockApi.deleteSubtask(10, 702)).called(1);
    });

    test('creates subtask on server when pendingUpdate has no serverId', () async {
      final subId = await database.insertSubtask(SubtasksCompanion(
        taskLocalId: Value(taskId),
        taskServerId: const Value(10),
        title: const Value('Offline Subtask'),
        status: const Value('todo'),
        syncStatus: const Value(2), // pendingUpdate but never pushed
      ));

      when(() => mockApi.createSubtask(any(), any()))
          .thenAnswer((_) async => const ApiSubtask(
                id: 703, taskId: 10, title: 'Offline Subtask', status: 'todo', order: 0));

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      final subs = await database.getSubtasksForTask(taskId);
      expect(subs.first.serverId, 703);
      expect(subs.first.syncStatus, 0);
      verify(() => mockApi.createSubtask(10, any())).called(1);
      verifyNever(() => mockApi.patchSubtask(any(), any(), any()));
    });

    test('deletes subtask locally when pendingDelete has no serverId', () async {
      final subId = await database.insertSubtask(SubtasksCompanion(
        taskLocalId: Value(taskId),
        taskServerId: const Value(10),
        title: const Value('Never-pushed Deleted Subtask'),
        status: const Value('todo'),
        syncStatus: const Value(3), // pendingDelete but no serverId
      ));

      final result = await syncService.pushPending();

      expect(result.pushed, 1);
      final subs = await database.getSubtasksForTask(taskId);
      expect(subs, isEmpty);
      verifyNever(() => mockApi.deleteSubtask(any(), any()));
    });
  });

  group('SyncService._refreshTasks pending-mutation protection', () {
    void stubOtherRefreshApis() {
      when(() => mockApi.fetchCategories()).thenAnswer((_) async => []);
      when(() => mockApi.fetchPersons()).thenAnswer((_) async => []);
      when(() => mockApi.fetchOccurrences(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => []);
      when(() => mockApi.fetchCreditCards()).thenAnswer((_) async => []);
      when(() => mockApi.fetchTrackerRows()).thenAnswer((_) async => []);
      when(() => mockApi.fetchStores()).thenAnswer((_) async => []);
      when(() => mockApi.fetchGroceryItems()).thenAnswer((_) async => []);
      when(() => mockApi.fetchOnHand()).thenAnswer((_) async => []);
      when(() => mockApi.fetchGroceryLists()).thenAnswer((_) async => []);
    }

    ApiTask serverTask(int id, String title, {List<ApiSubtask> subtasks = const []}) =>
        ApiTask(
          id: id,
          title: title,
          status: 'todo',
          priority: 'medium',
          recurrence: 'none',
          order: 0,
          subtasks: subtasks,
          createdAt: '2026-01-01',
          updatedAt: '2026-01-01',
        );

    test('does not overwrite a pendingUpdate task on fullRefresh', () async {
      await database.insertTask(const TasksCompanion(
        serverId: Value(100),
        title: Value('Local Modified Title'),
        syncStatus: Value(2), // pendingUpdate
        createdAt: Value('2026-01-01'),
        updatedAt: Value('2026-01-01'),
      ));

      when(() => mockApi.fetchTasks())
          .thenAnswer((_) async => [serverTask(100, 'Server Title')]);
      stubOtherRefreshApis();

      await syncService.fullRefresh();

      final tasks = await database.getTasks();
      expect(tasks.length, 1);
      expect(tasks.first.syncStatus, 2, reason: 'pendingUpdate must survive fullRefresh');
      expect(tasks.first.title, 'Local Modified Title',
          reason: 'local changes must not be reverted by the server pull');
    });

    test('does not overwrite a pendingDelete task on fullRefresh', () async {
      await database.insertTask(const TasksCompanion(
        serverId: Value(100),
        title: Value('Task To Delete'),
        syncStatus: Value(3), // pendingDelete
        createdAt: Value('2026-01-01'),
        updatedAt: Value('2026-01-01'),
      ));

      when(() => mockApi.fetchTasks())
          .thenAnswer((_) async => [serverTask(100, 'Task To Delete')]);
      stubOtherRefreshApis();

      await syncService.fullRefresh();

      final tasks = await database.getTasks();
      expect(tasks.length, 1);
      expect(tasks.first.syncStatus, 3, reason: 'pendingDelete must survive fullRefresh');
    });

    test('does not overwrite a pending subtask on fullRefresh', () async {
      final taskId = await database.insertTask(const TasksCompanion(
        serverId: Value(100),
        title: Value('Synced Task'),
        syncStatus: Value(0),
        createdAt: Value('2026-01-01'),
        updatedAt: Value('2026-01-01'),
      ));
      await database.insertSubtask(SubtasksCompanion(
        serverId: const Value(200),
        taskLocalId: Value(taskId),
        taskServerId: const Value(100),
        title: const Value('Local Modified Subtask'),
        status: const Value('open'),
        syncStatus: const Value(2), // pendingUpdate
      ));

      when(() => mockApi.fetchTasks()).thenAnswer((_) async => [
            serverTask(100, 'Synced Task', subtasks: [
              const ApiSubtask(
                  id: 200,
                  taskId: 100,
                  title: 'Server Subtask Title',
                  status: 'open',
                  order: 0),
            ]),
          ]);
      stubOtherRefreshApis();

      await syncService.fullRefresh();

      final subtasks = await database.getSubtasksForTask(taskId);
      expect(subtasks.length, 1);
      expect(subtasks.first.syncStatus, 2,
          reason: 'pending subtask syncStatus must survive fullRefresh');
      expect(subtasks.first.title, 'Local Modified Subtask',
          reason: 'local subtask changes must not be reverted');
    });

    test('does not touch subtasks of a pending task on fullRefresh', () async {
      final taskId = await database.insertTask(const TasksCompanion(
        serverId: Value(100),
        title: Value('Local Modified Task'),
        syncStatus: Value(2), // pendingUpdate
        createdAt: Value('2026-01-01'),
        updatedAt: Value('2026-01-01'),
      ));
      await database.insertSubtask(SubtasksCompanion(
        serverId: const Value(200),
        taskLocalId: Value(taskId),
        taskServerId: const Value(100),
        title: const Value('Local Subtask'),
        status: const Value('open'),
        syncStatus: const Value(0),
      ));

      when(() => mockApi.fetchTasks()).thenAnswer((_) async => [
            serverTask(100, 'Server Task Title', subtasks: [
              const ApiSubtask(
                  id: 200,
                  taskId: 100,
                  title: 'Server Subtask Title',
                  status: 'done',
                  order: 0),
            ]),
          ]);
      stubOtherRefreshApis();

      await syncService.fullRefresh();

      final tasks = await database.getTasks();
      expect(tasks.first.title, 'Local Modified Task',
          reason: 'pending task title must not be reverted');
      expect(tasks.first.syncStatus, 2);

      final subtasks = await database.getSubtasksForTask(taskId);
      expect(subtasks.length, 1);
      expect(subtasks.first.title, 'Local Subtask',
          reason: 'subtasks of a pending task must not be overwritten');
    });
  });

  group('SyncService orphan purging', () {
    test('_refreshTasks purges orphans', () async {
      await database.upsertTasks([
        const TasksCompanion(
          serverId: Value(100),
          title: Value('Keep Me'),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
        const TasksCompanion(
          serverId: Value(101),
          title: Value('Purge Me'),
          createdAt: Value('2026-01-01'),
          updatedAt: Value('2026-01-01'),
        ),
      ]);

      when(() => mockApi.fetchTasks()).thenAnswer((_) async => [
            ApiTask(
              id: 100,
              title: 'Keep Me',
              status: 'todo',
              priority: 'medium',
              recurrence: 'none',
              order: 0,
              subtasks: [],
              createdAt: '2026-01-01',
              updatedAt: '2026-01-01',
            ),
          ]);

      // We need to call the private method or trigger it via fullRefresh
      // Trigger via fullRefresh but mock everything else to succeed
      when(() => mockApi.fetchCategories()).thenAnswer((_) async => []);
      when(() => mockApi.fetchPersons()).thenAnswer((_) async => []);
      when(() => mockApi.fetchOccurrences(startDate: any(named: 'startDate'), endDate: any(named: 'endDate')))
          .thenAnswer((_) async => []);
      when(() => mockApi.fetchCreditCards()).thenAnswer((_) async => []);
      when(() => mockApi.fetchTrackerRows()).thenAnswer((_) async => []);
      when(() => mockApi.fetchStores()).thenAnswer((_) async => []);
      when(() => mockApi.fetchGroceryItems()).thenAnswer((_) async => []);
      when(() => mockApi.fetchOnHand()).thenAnswer((_) async => []);
      when(() => mockApi.fetchGroceryLists()).thenAnswer((_) async => []);

      await syncService.fullRefresh();

      final tasks = await database.getTasks();
      expect(tasks.length, 1);
      expect(tasks.first.serverId, 100);
    });
  });
}
