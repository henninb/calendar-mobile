import 'package:calendar_mobile/api/api_client.dart';
import 'package:calendar_mobile/api/api_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late ApiClient client;
  late Dio dio;
  late DioAdapter dioAdapter;

  const baseUrl = 'https://example.com';
  const apiKey = 'test-api-key';

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: '$baseUrl/api'));
    dioAdapter = DioAdapter(dio: dio);
    client = ApiClient(baseUrl, apiKey: apiKey, dio: dio);
  });

  group('ApiClient initialization', () {
    test('updateBaseUrl updates dio options', () {
      client.updateBaseUrl('https://new-api.com');
      expect(dio.options.baseUrl, 'https://new-api.com/api');
    });

    test('updateBaseUrl throws on invalid URL', () {
      expect(() => client.updateBaseUrl('http://insecure.com'), throwsArgumentError);
      expect(() => client.updateBaseUrl('not-a-url'), throwsArgumentError);
    });

    test('updateApiKey updates headers', () {
      client.updateApiKey('new-key');
      expect(dio.options.headers['X-Api-Key'], 'new-key');
    });

    test('updateApiKey removes header when empty', () {
      client.updateApiKey('');
      expect(dio.options.headers.containsKey('X-Api-Key'), isFalse);
    });
  });

  group('ApiClient categories', () {
    test('fetchCategories returns list of categories', () async {
      final payload = [
        {'id': 1, 'name': 'Work', 'color': '#ff0000', 'icon': '💼'},
      ];

      dioAdapter.onGet('/categories', (server) => server.reply(200, payload));

      final result = await client.fetchCategories();
      expect(result, isA<List<ApiCategory>>());
      expect(result.length, 1);
      expect(result.first.name, 'Work');
    });
  });

  group('ApiClient occurrences', () {
    test('fetchOccurrences uses correct query parameters', () async {
      dioAdapter.onGet(
        '/occurrences',
        (server) => server.reply(200, []),
        queryParameters: {
          'limit': 500,
          'start_date': '2026-05-01',
          'status': 'upcoming',
        },
      );

      await client.fetchOccurrences(startDate: '2026-05-01', status: 'upcoming');
    });

    test('patchOccurrence sends PATCH request', () async {
      dioAdapter.onPatch(
        '/occurrences/123',
        (server) => server.reply(200, {}),
        data: {'status': 'completed'},
      );

      await client.patchOccurrence(123, {'status': 'completed'});
    });
  });

  group('ApiClient tasks', () {
    test('fetchTasks returns list of tasks', () async {
      final payload = [
        {
          'id': 1,
          'title': 'Task 1',
          'status': 'todo',
          'priority': 'medium',
          'recurrence': 'none',
          'order': 0,
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        },
      ];

      dioAdapter.onGet('/tasks', (server) => server.reply(200, payload), queryParameters: {'limit': 500});

      final result = await client.fetchTasks();
      expect(result.length, 1);
      expect(result.first.title, 'Task 1');
    });

    test('createTask sends POST request and returns task', () async {
      final payload = {
        'id': 2,
        'title': 'New Task',
        'status': 'todo',
        'priority': 'high',
        'recurrence': 'none',
        'order': 1,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };

      dioAdapter.onPost(
        '/tasks',
        (server) => server.reply(201, payload),
        data: {'title': 'New Task'},
      );

      final result = await client.createTask({'title': 'New Task'});
      expect(result.id, 2);
      expect(result.title, 'New Task');
    });
  });

  group('ApiClient grocery', () {
    test('fetchGroceryItems with search', () async {
      dioAdapter.onGet(
        '/grocery/items',
        (server) => server.reply(200, []),
        queryParameters: {'search': 'apple'},
      );

      await client.fetchGroceryItems(search: 'apple');
    });

    test('upsertOnHand uses PUT', () async {
      final payload = {
        'id': 1,
        'item_id': 10,
        'quantity': 5,
        'unit': 'kg',
      };

      dioAdapter.onPut(
        '/grocery/on-hand/10',
        (server) => server.reply(200, payload),
        data: {'quantity': 5},
      );

      final result = await client.upsertOnHand(10, {'quantity': 5});
      expect(result.quantity, 5);
    });

    test('deleteOnHand sends DELETE', () async {
      dioAdapter.onDelete('/grocery/on-hand/10', (server) => server.reply(204, null));
      await client.deleteOnHand(10);
    });
  });

  group('ApiClient helpers', () {
    test('_getList handles null data', () async {
      dioAdapter.onGet('/categories', (server) => server.reply(200, null));
      final result = await client.fetchCategories();
      expect(result, isEmpty);
    });

    test('_writeJson throws FormatException on null body', () async {
      dioAdapter.onPost('/tasks', (server) => server.reply(201, null), data: {});
      expect(() => client.createTask({}), throwsA(isA<FormatException>()));
    });
  });

  group('ApiClient events', () {
    test('createEvent sends POST and returns event', () async {
      final payload = {
        'id': 1,
        'title': 'Test Event',
        'category_id': 1,
        'dtstart': '2026-05-01',
        'priority': 'medium',
        'is_active': true,
        'category': {'id': 1, 'name': 'Work', 'color': '#3b82f6', 'icon': '💼'},
        'duration_days': 1,
      };

      dioAdapter.onPost(
        '/events',
        (server) => server.reply(201, payload),
        data: {'title': 'Test Event', 'category_id': 1, 'dtstart': '2026-05-01'},
      );

      final result = await client.createEvent({
        'title': 'Test Event',
        'category_id': 1,
        'dtstart': '2026-05-01',
      });
      expect(result.id, 1);
      expect(result.title, 'Test Event');
      expect(result.dtstart, '2026-05-01');
    });
  });

  group('ApiClient occurrence tasks', () {
    test('createTaskFromOccurrence sends POST and returns task', () async {
      final payload = {
        'id': 5,
        'title': 'Task from occurrence',
        'status': 'todo',
        'priority': 'medium',
        'recurrence': 'none',
        'order': 0,
        'subtasks': [],
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };

      dioAdapter.onPost(
        '/occurrences/42/task',
        (server) => server.reply(201, payload),
        data: {},
      );

      final result = await client.createTaskFromOccurrence(42);
      expect(result.id, 5);
      expect(result.title, 'Task from occurrence');
    });
  });

  group('ApiClient other methods', () {
    test('fetchPersons', () async {
      dioAdapter.onGet('/persons', (server) => server.reply(200, []));
      await client.fetchPersons();
    });

    test('deleteOccurrence', () async {
      dioAdapter.onDelete('/occurrences/1', (server) => server.reply(204, null));
      await client.deleteOccurrence(1);
    });

    test('generateAllOccurrences', () async {
      dioAdapter.onPost('/occurrences/generate-all', (server) => server.reply(200, null), data: null);
      await client.generateAllOccurrences();
    });

    test('patchTask', () async {
      dioAdapter.onPatch('/tasks/1', (server) => server.reply(200, null), data: {});
      await client.patchTask(1, {});
    });

    test('deleteTask', () async {
      dioAdapter.onDelete('/tasks/1', (server) => server.reply(204, null));
      await client.deleteTask(1);
    });

    test('createSubtask', () async {
      dioAdapter.onPost('/tasks/1/subtasks', (server) => server.reply(200, {'id': 1, 'task_id': 1, 'title': 'S', 'status': 'todo', 'order': 0}), data: {});
      await client.createSubtask(1, {});
    });

    test('patchSubtask', () async {
      dioAdapter.onPatch('/tasks/1/subtasks/2', (server) => server.reply(200, null), data: {});
      await client.patchSubtask(1, 2, {});
    });

    test('deleteSubtask', () async {
      dioAdapter.onDelete('/tasks/1/subtasks/2', (server) => server.reply(204, null));
      await client.deleteSubtask(1, 2);
    });

    test('fetchCreditCards', () async {
      dioAdapter.onGet('/credit-cards', (server) => server.reply(200, []), queryParameters: {'limit': 500});
      await client.fetchCreditCards();
    });

    test('updateCreditCard', () async {
      dioAdapter.onPut('/credit-cards/1', (server) => server.reply(200, {'id': 1, 'name': 'V', 'is_active': true}), data: {});
      await client.updateCreditCard(1, {});
    });

    test('deleteCreditCard', () async {
      dioAdapter.onDelete('/credit-cards/1', (server) => server.reply(204, null));
      await client.deleteCreditCard(1);
    });

    test('fetchTrackerRows', () async {
      dioAdapter.onGet('/credit-cards/tracker', (server) => server.reply(200, []));
      await client.fetchTrackerRows();
    });

    test('fetchStores', () async {
      dioAdapter.onGet('/stores', (server) => server.reply(200, []));
      await client.fetchStores();
    });

    test('createStore', () async {
      dioAdapter.onPost('/stores', (server) => server.reply(200, {'id': 1, 'name': 'S', 'is_active': true}), data: {});
      await client.createStore({});
    });

    test('updateStore', () async {
      dioAdapter.onPatch('/stores/1', (server) => server.reply(200, {'id': 1, 'name': 'S', 'is_active': true}), data: {});
      await client.updateStore(1, {});
    });

    test('deleteStore', () async {
      dioAdapter.onDelete('/stores/1', (server) => server.reply(204, null));
      await client.deleteStore(1);
    });

    test('createGroceryItem', () async {
      dioAdapter.onPost('/grocery/items', (server) => server.reply(200, {'id': 1, 'name': 'I', 'default_unit': 'each'}), data: {});
      await client.createGroceryItem({});
    });

    test('deleteGroceryItem', () async {
      dioAdapter.onDelete('/grocery/items/1', (server) => server.reply(204, null));
      await client.deleteGroceryItem(1);
    });

    test('fetchOnHand', () async {
      dioAdapter.onGet('/grocery/on-hand', (server) => server.reply(200, []));
      await client.fetchOnHand();
    });

    test('fetchGroceryLists', () async {
      dioAdapter.onGet('/grocery/lists', (server) => server.reply(200, []), queryParameters: {'status': 'active'});
      await client.fetchGroceryLists(status: 'active');
    });

    test('createGroceryList', () async {
      dioAdapter.onPost('/grocery/lists', (server) => server.reply(200, {'id': 1, 'name': 'L', 'status': 'draft', 'items': []}), data: {});
      await client.createGroceryList({});
    });

    test('updateGroceryList', () async {
      dioAdapter.onPatch('/grocery/lists/1', (server) => server.reply(200, {'id': 1, 'name': 'L', 'status': 'draft', 'items': []}), data: {});
      await client.updateGroceryList(1, {});
    });

    test('deleteGroceryList', () async {
      dioAdapter.onDelete('/grocery/lists/1', (server) => server.reply(204, null));
      await client.deleteGroceryList(1);
    });

    test('addGroceryListItem', () async {
      dioAdapter.onPost('/grocery/lists/1/items', (server) => server.reply(200, {'id': 1, 'list_id': 1, 'item_id': 1, 'quantity': 1, 'unit': 'each', 'status': 'needed'}), data: {});
      await client.addGroceryListItem(1, {});
    });

    test('updateGroceryListItem', () async {
      dioAdapter.onPatch('/grocery/lists/1/items/2', (server) => server.reply(200, {'id': 2, 'list_id': 1, 'item_id': 1, 'quantity': 1, 'unit': 'each', 'status': 'needed'}), data: {});
      await client.updateGroceryListItem(1, 2, {});
    });

    test('removeGroceryListItem', () async {
      dioAdapter.onDelete('/grocery/lists/1/items/2', (server) => server.reply(204, null));
      await client.removeGroceryListItem(1, 2);
    });
  });
}
