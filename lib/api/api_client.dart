import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'api_models.dart';

/// Abstract interface for all API operations.
///
/// Depend on this type in services and notifiers so they can be tested with
/// any implementation (real HTTP, in-memory mock, etc.) without touching
/// the concrete [ApiClient].
abstract class ApiClientBase {
  Future<List<ApiCategory>> fetchCategories();
  Future<List<ApiPerson>> fetchPersons();

  Future<List<ApiOccurrence>> fetchOccurrences({
    String? startDate,
    String? endDate,
    String? status,
    int? categoryId,
    int limit,
  });
  Future<void> patchOccurrence(int serverId, Map<String, dynamic> data);
  Future<void> deleteOccurrence(int serverId);
  Future<void> generateAllOccurrences();
  Future<ApiTask> createTaskFromOccurrence(int occurrenceServerId);

  Future<ApiEvent> createEvent(Map<String, dynamic> data);

  Future<List<ApiTask>> fetchTasks({int limit});
  Future<ApiTask> createTask(Map<String, dynamic> data);
  Future<void> patchTask(int serverId, Map<String, dynamic> data);
  Future<void> deleteTask(int serverId);

  Future<ApiSubtask> createSubtask(int taskServerId, Map<String, dynamic> data);
  Future<void> patchSubtask(
    int taskServerId,
    int subtaskServerId,
    Map<String, dynamic> data,
  );
  Future<void> deleteSubtask(int taskServerId, int subtaskServerId);

  Future<List<ApiCreditCard>> fetchCreditCards({int limit});
  Future<ApiCreditCard> createCreditCard(Map<String, dynamic> data);
  Future<ApiCreditCard> updateCreditCard(
    int serverId,
    Map<String, dynamic> data,
  );
  Future<void> deleteCreditCard(int serverId);
  Future<List<ApiTrackerRow>> fetchTrackerRows();

  Future<List<ApiStore>> fetchStores();
  Future<ApiStore> createStore(Map<String, dynamic> data);
  Future<ApiStore> updateStore(int serverId, Map<String, dynamic> data);
  Future<void> deleteStore(int serverId);

  Future<List<ApiGroceryItem>> fetchGroceryItems({String? search});
  Future<ApiGroceryItem> createGroceryItem(Map<String, dynamic> data);
  Future<void> deleteGroceryItem(int serverId);

  Future<List<ApiOnHand>> fetchOnHand();
  Future<ApiOnHand> upsertOnHand(int itemServerId, Map<String, dynamic> data);
  Future<void> deleteOnHand(int itemServerId);

  Future<List<ApiGroceryList>> fetchGroceryLists({String? status});
  Future<ApiGroceryList> createGroceryList(Map<String, dynamic> data);
  Future<ApiGroceryList> updateGroceryList(
    int serverId,
    Map<String, dynamic> data,
  );
  Future<void> deleteGroceryList(int serverId);

  Future<ApiGroceryListItem> addGroceryListItem(
    int listServerId,
    Map<String, dynamic> data,
  );
  Future<ApiGroceryListItem> updateGroceryListItem(
    int listServerId,
    int itemServerId,
    Map<String, dynamic> data,
  );
  Future<void> removeGroceryListItem(int listServerId, int itemServerId);
}

class ApiClient implements ApiClientBase {
  ApiClient(String baseUrl, {String apiKey = '', Dio? dio})
    : _dio = dio ?? _buildDio(baseUrl, apiKey);

  final Dio _dio;

  static Dio _buildDio(String baseUrl, String apiKey) {
    final headers = <String, dynamic>{'Content-Type': 'application/json'};
    if (apiKey.isNotEmpty) headers['X-Api-Key'] = apiKey;
    // When no URL has been configured yet, use a local placeholder so Dio can
    // be constructed. Any request fired before the user sets a real URL will
    // fail with a connection error that surfaces as "Cannot reach backend".
    final effectiveBase = baseUrl.isNotEmpty
        ? '$baseUrl/api'
        : 'https://localhost/api';
    final dio = Dio(
      BaseOptions(
        baseUrl: effectiveBase,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: headers,
      ),
    );
    // Explicitly reject any certificate that fails standard validation.
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      return HttpClient()..badCertificateCallback = (cert, host, port) => false;
    };
    return dio;
  }

  void updateBaseUrl(String url) {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasScheme ||
        uri.scheme != 'https' ||
        uri.host.isEmpty) {
      throw ArgumentError.value(
        url,
        'url',
        'Only https:// URLs with a hostname are accepted',
      );
    }
    _dio.options.baseUrl = '$url/api';
  }

  void updateApiKey(String apiKey) {
    if (apiKey.isEmpty) {
      _dio.options.headers.remove('X-Api-Key');
    } else {
      _dio.options.headers['X-Api-Key'] = apiKey;
    }
  }

  // ── Private decode helpers ────────────────────────────────────────────────

  Future<List<T>> _getList<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final res = await _dio.get<List>(path, queryParameters: queryParameters);
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }

  Future<T> _writeJson<T>(
    Future<Response<Map<String, dynamic>>> Function() request,
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final res = await request();
    final body = res.data;
    if (body == null) throw FormatException('Empty response body from $path');
    return fromJson(body);
  }

  Future<T> _postJson<T>(
    String path, {
    required Object? data,
    required T Function(Map<String, dynamic>) fromJson,
  }) => _writeJson(
    () => _dio.post<Map<String, dynamic>>(path, data: data),
    path,
    fromJson: fromJson,
  );

  Future<T> _putJson<T>(
    String path, {
    required Object? data,
    required T Function(Map<String, dynamic>) fromJson,
  }) => _writeJson(
    () => _dio.put<Map<String, dynamic>>(path, data: data),
    path,
    fromJson: fromJson,
  );

  Future<T> _patchJson<T>(
    String path, {
    required Object? data,
    required T Function(Map<String, dynamic>) fromJson,
  }) => _writeJson(
    () => _dio.patch<Map<String, dynamic>>(path, data: data),
    path,
    fromJson: fromJson,
  );

  // ── Categories ────────────────────────────────────────────────────────────

  @override
  Future<List<ApiCategory>> fetchCategories() =>
      _getList('/categories', fromJson: ApiCategory.fromJson);

  // ── Persons ───────────────────────────────────────────────────────────────

  @override
  Future<List<ApiPerson>> fetchPersons() =>
      _getList('/persons', fromJson: ApiPerson.fromJson);

  // ── Occurrences ───────────────────────────────────────────────────────────

  @override
  Future<List<ApiOccurrence>> fetchOccurrences({
    String? startDate,
    String? endDate,
    String? status,
    int? categoryId,
    int limit = 500,
  }) {
    final params = <String, dynamic>{'limit': limit};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (status != null) params['status'] = status;
    if (categoryId != null) params['category_id'] = categoryId;
    return _getList(
      '/occurrences',
      queryParameters: params,
      fromJson: ApiOccurrence.fromJson,
    );
  }

  @override
  Future<void> patchOccurrence(int serverId, Map<String, dynamic> data) =>
      _dio.patch('/occurrences/$serverId', data: data);

  @override
  Future<void> deleteOccurrence(int serverId) =>
      _dio.delete('/occurrences/$serverId');

  @override
  Future<void> generateAllOccurrences() =>
      _dio.post('/occurrences/generate-all');

  @override
  Future<ApiTask> createTaskFromOccurrence(int occurrenceServerId) => _postJson(
    '/occurrences/$occurrenceServerId/task',
    data: {},
    fromJson: ApiTask.fromJson,
  );

  // ── Events ────────────────────────────────────────────────────────────────

  @override
  Future<ApiEvent> createEvent(Map<String, dynamic> data) =>
      _postJson('/events', data: data, fromJson: ApiEvent.fromJson);

  // ── Tasks ─────────────────────────────────────────────────────────────────

  @override
  Future<List<ApiTask>> fetchTasks({int limit = 1000}) => _getList(
    '/tasks',
    queryParameters: {'limit': limit},
    fromJson: ApiTask.fromJson,
  );

  @override
  Future<ApiTask> createTask(Map<String, dynamic> data) =>
      _postJson('/tasks', data: data, fromJson: ApiTask.fromJson);

  @override
  Future<void> patchTask(int serverId, Map<String, dynamic> data) =>
      _dio.patch('/tasks/$serverId', data: data);

  @override
  Future<void> deleteTask(int serverId) => _dio.delete('/tasks/$serverId');

  // ── Subtasks ──────────────────────────────────────────────────────────────

  @override
  Future<ApiSubtask> createSubtask(
    int taskServerId,
    Map<String, dynamic> data,
  ) => _postJson(
    '/tasks/$taskServerId/subtasks',
    data: data,
    fromJson: ApiSubtask.fromJson,
  );

  @override
  Future<void> patchSubtask(
    int taskServerId,
    int subtaskServerId,
    Map<String, dynamic> data,
  ) => _dio.patch('/tasks/$taskServerId/subtasks/$subtaskServerId', data: data);

  @override
  Future<void> deleteSubtask(int taskServerId, int subtaskServerId) =>
      _dio.delete('/tasks/$taskServerId/subtasks/$subtaskServerId');

  // ── Credit Cards ──────────────────────────────────────────────────────────

  @override
  Future<List<ApiCreditCard>> fetchCreditCards({int limit = 500}) => _getList(
    '/credit-cards',
    queryParameters: {'limit': limit},
    fromJson: ApiCreditCard.fromJson,
  );

  @override
  Future<ApiCreditCard> createCreditCard(Map<String, dynamic> data) =>
      _postJson('/credit-cards', data: data, fromJson: ApiCreditCard.fromJson);

  @override
  Future<ApiCreditCard> updateCreditCard(
    int serverId,
    Map<String, dynamic> data,
  ) => _putJson(
    '/credit-cards/$serverId',
    data: data,
    fromJson: ApiCreditCard.fromJson,
  );

  @override
  Future<void> deleteCreditCard(int serverId) =>
      _dio.delete('/credit-cards/$serverId');

  @override
  Future<List<ApiTrackerRow>> fetchTrackerRows() =>
      _getList('/credit-cards/tracker', fromJson: ApiTrackerRow.fromJson);

  // ── Stores ────────────────────────────────────────────────────────────────

  @override
  Future<List<ApiStore>> fetchStores() =>
      _getList('/stores', fromJson: ApiStore.fromJson);

  @override
  Future<ApiStore> createStore(Map<String, dynamic> data) =>
      _postJson('/stores', data: data, fromJson: ApiStore.fromJson);

  @override
  Future<ApiStore> updateStore(int serverId, Map<String, dynamic> data) =>
      _patchJson('/stores/$serverId', data: data, fromJson: ApiStore.fromJson);

  @override
  Future<void> deleteStore(int serverId) => _dio.delete('/stores/$serverId');

  // ── Grocery Items ─────────────────────────────────────────────────────────

  @override
  Future<List<ApiGroceryItem>> fetchGroceryItems({String? search}) => _getList(
    '/grocery/items',
    queryParameters: search != null && search.isNotEmpty
        ? {'search': search}
        : null,
    fromJson: ApiGroceryItem.fromJson,
  );

  @override
  Future<ApiGroceryItem> createGroceryItem(Map<String, dynamic> data) =>
      _postJson(
        '/grocery/items',
        data: data,
        fromJson: ApiGroceryItem.fromJson,
      );

  @override
  Future<void> deleteGroceryItem(int serverId) =>
      _dio.delete('/grocery/items/$serverId');

  // ── On Hand ───────────────────────────────────────────────────────────────

  @override
  Future<List<ApiOnHand>> fetchOnHand() =>
      _getList('/grocery/on-hand', fromJson: ApiOnHand.fromJson);

  @override
  Future<ApiOnHand> upsertOnHand(int itemServerId, Map<String, dynamic> data) =>
      _putJson(
        '/grocery/on-hand/$itemServerId',
        data: data,
        fromJson: ApiOnHand.fromJson,
      );

  @override
  Future<void> deleteOnHand(int itemServerId) =>
      _dio.delete('/grocery/on-hand/$itemServerId');

  // ── Grocery Lists ─────────────────────────────────────────────────────────

  @override
  Future<List<ApiGroceryList>> fetchGroceryLists({String? status}) => _getList(
    '/grocery/lists',
    queryParameters: status != null ? {'status': status} : null,
    fromJson: ApiGroceryList.fromJson,
  );

  @override
  Future<ApiGroceryList> createGroceryList(Map<String, dynamic> data) =>
      _postJson(
        '/grocery/lists',
        data: data,
        fromJson: ApiGroceryList.fromJson,
      );

  @override
  Future<ApiGroceryList> updateGroceryList(
    int serverId,
    Map<String, dynamic> data,
  ) => _patchJson(
    '/grocery/lists/$serverId',
    data: data,
    fromJson: ApiGroceryList.fromJson,
  );

  @override
  Future<void> deleteGroceryList(int serverId) =>
      _dio.delete('/grocery/lists/$serverId');

  // ── Grocery List Items ────────────────────────────────────────────────────

  @override
  Future<ApiGroceryListItem> addGroceryListItem(
    int listServerId,
    Map<String, dynamic> data,
  ) => _postJson(
    '/grocery/lists/$listServerId/items',
    data: data,
    fromJson: ApiGroceryListItem.fromJson,
  );

  @override
  Future<ApiGroceryListItem> updateGroceryListItem(
    int listServerId,
    int itemServerId,
    Map<String, dynamic> data,
  ) => _patchJson(
    '/grocery/lists/$listServerId/items/$itemServerId',
    data: data,
    fromJson: ApiGroceryListItem.fromJson,
  );

  @override
  Future<void> removeGroceryListItem(int listServerId, int itemServerId) =>
      _dio.delete('/grocery/lists/$listServerId/items/$itemServerId');
}
