import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'api_models.dart';

class ApiClient {
  ApiClient(String baseUrl, {String apiKey = ''}) : _dio = _buildDio(baseUrl, apiKey);

  final Dio _dio;

  static Dio _buildDio(String baseUrl, String apiKey) {
    final headers = <String, dynamic>{'Content-Type': 'application/json'};
    if (apiKey.isNotEmpty) headers['X-Api-Key'] = apiKey;
    // When no URL has been configured yet, use a local placeholder so Dio can
    // be constructed. Any request fired before the user sets a real URL will
    // fail with a connection error that surfaces as "Cannot reach backend".
    final effectiveBase = baseUrl.isNotEmpty ? '$baseUrl/api' : 'https://localhost/api';
    final dio = Dio(BaseOptions(
      baseUrl: effectiveBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: headers,
    ));
    // Explicitly reject any certificate that fails standard validation.
    // Replace the callback body with fingerprint comparison to enable pinning:
    //   final fp = _sha256Fingerprint(cert.der);
    //   return fp == _expectedFingerprint && host == 'your-backend.example.com';
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      return HttpClient()
        ..badCertificateCallback = (cert, host, port) => false;
    };
    return dio;
  }

  void updateBaseUrl(String url) {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.scheme != 'https') {
      throw ArgumentError.value(url, 'url', 'Only https:// URLs are accepted');
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

  // ── Categories ───────────────────────────────────────────────────────────────

  Future<List<ApiCategory>> fetchCategories() async {
    final res = await _dio.get<List>('/categories');
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ApiCategory.fromJson)
        .toList();
  }

  // ── Persons ──────────────────────────────────────────────────────────────────

  Future<List<ApiPerson>> fetchPersons() async {
    final res = await _dio.get<List>('/persons');
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ApiPerson.fromJson)
        .toList();
  }

  // ── Occurrences ──────────────────────────────────────────────────────────────

  Future<List<ApiOccurrence>> fetchOccurrences({
    String? startDate,
    String? endDate,
    String? status,
    int? categoryId,
    int limit = 500,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (status != null) params['status'] = status;
    if (categoryId != null) params['category_id'] = categoryId;

    final res = await _dio.get<List>('/occurrences', queryParameters: params);
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ApiOccurrence.fromJson)
        .toList();
  }

  Future<void> patchOccurrence(int serverId, Map<String, dynamic> data) async {
    await _dio.patch('/occurrences/$serverId', data: data);
  }

  Future<void> deleteOccurrence(int serverId) async {
    await _dio.delete('/occurrences/$serverId');
  }

  Future<void> generateAllOccurrences() async {
    await _dio.post('/occurrences/generate-all');
  }

  // ── Tasks ────────────────────────────────────────────────────────────────────

  Future<List<ApiTask>> fetchTasks({int limit = 500}) async {
    final res = await _dio.get<List>('/tasks', queryParameters: {'limit': limit});
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ApiTask.fromJson)
        .toList();
  }

  Future<ApiTask> createTask(Map<String, dynamic> data) async {
    final res = await _dio.post<Map<String, dynamic>>('/tasks', data: data);
    final body = res.data;
    if (body == null) throw const FormatException('Server returned an empty body for createTask');
    return ApiTask.fromJson(body);
  }

  Future<void> patchTask(int serverId, Map<String, dynamic> data) async {
    await _dio.patch('/tasks/$serverId', data: data);
  }

  Future<void> deleteTask(int serverId) async {
    await _dio.delete('/tasks/$serverId');
  }

  // ── Subtasks ─────────────────────────────────────────────────────────────────

  Future<ApiSubtask> createSubtask(int taskServerId, Map<String, dynamic> data) async {
    final res = await _dio.post<Map<String, dynamic>>('/tasks/$taskServerId/subtasks', data: data);
    final body = res.data;
    if (body == null) throw const FormatException('Server returned an empty body for createSubtask');
    return ApiSubtask.fromJson(body);
  }

  Future<void> patchSubtask(int taskServerId, int subtaskServerId, Map<String, dynamic> data) async {
    await _dio.patch('/tasks/$taskServerId/subtasks/$subtaskServerId', data: data);
  }

  Future<void> deleteSubtask(int taskServerId, int subtaskServerId) async {
    await _dio.delete('/tasks/$taskServerId/subtasks/$subtaskServerId');
  }

  // ── Credit Cards ─────────────────────────────────────────────────────────────

  Future<List<ApiCreditCard>> fetchCreditCards({int limit = 500}) async {
    final res = await _dio.get<List>('/credit-cards', queryParameters: {'limit': limit});
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ApiCreditCard.fromJson)
        .toList();
  }

  Future<ApiCreditCard> createCreditCard(Map<String, dynamic> data) async {
    final res = await _dio.post<Map<String, dynamic>>('/credit-cards', data: data);
    final body = res.data;
    if (body == null) throw const FormatException('Server returned an empty body for createCreditCard');
    return ApiCreditCard.fromJson(body);
  }

  Future<ApiCreditCard> updateCreditCard(int serverId, Map<String, dynamic> data) async {
    final res = await _dio.put<Map<String, dynamic>>('/credit-cards/$serverId', data: data);
    final body = res.data;
    if (body == null) throw const FormatException('Server returned an empty body for updateCreditCard');
    return ApiCreditCard.fromJson(body);
  }

  Future<void> deleteCreditCard(int serverId) async {
    await _dio.delete('/credit-cards/$serverId');
  }

  Future<List<ApiTrackerRow>> fetchTrackerRows() async {
    final res = await _dio.get<List>('/credit-cards/tracker');
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ApiTrackerRow.fromJson)
        .toList();
  }

  // ── Stores ───────────────────────────────────────────────────────────────────

  Future<List<ApiStore>> fetchStores() async {
    final res = await _dio.get<List>('/stores');
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ApiStore.fromJson)
        .toList();
  }

  Future<ApiStore> createStore(Map<String, dynamic> data) async {
    final res =
        await _dio.post<Map<String, dynamic>>('/stores', data: data);
    final body = res.data;
    if (body == null) throw const FormatException('Server returned an empty body for createStore');
    return ApiStore.fromJson(body);
  }

  Future<ApiStore> updateStore(
    int serverId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/stores/$serverId',
      data: data,
    );
    final body = res.data;
    if (body == null) throw const FormatException('Server returned an empty body for updateStore');
    return ApiStore.fromJson(body);
  }

  Future<void> deleteStore(int serverId) async {
    await _dio.delete('/stores/$serverId');
  }

  // ── Grocery Items ─────────────────────────────────────────────────────────────

  Future<List<ApiGroceryItem>> fetchGroceryItems({
    String? search,
  }) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await _dio.get<List>(
      '/grocery/items',
      queryParameters: params,
    );
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ApiGroceryItem.fromJson)
        .toList();
  }

  Future<ApiGroceryItem> createGroceryItem(
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/grocery/items',
      data: data,
    );
    final body = res.data;
    if (body == null) throw const FormatException('Server returned an empty body for createGroceryItem');
    return ApiGroceryItem.fromJson(body);
  }

  Future<void> deleteGroceryItem(int serverId) async {
    await _dio.delete('/grocery/items/$serverId');
  }

  // ── On Hand ──────────────────────────────────────────────────────────────────

  Future<List<ApiOnHand>> fetchOnHand() async {
    final res = await _dio.get<List>('/grocery/on-hand');
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ApiOnHand.fromJson)
        .toList();
  }

  Future<ApiOnHand> upsertOnHand(int itemServerId, Map<String, dynamic> data) async {
    final res = await _dio.put<Map<String, dynamic>>('/grocery/on-hand/$itemServerId', data: data);
    final body = res.data;
    if (body == null) throw const FormatException('Server returned an empty body for upsertOnHand');
    return ApiOnHand.fromJson(body);
  }

  Future<void> deleteOnHand(int itemServerId) async {
    await _dio.delete('/grocery/on-hand/$itemServerId');
  }

  // ── Grocery Lists ─────────────────────────────────────────────────────────────

  Future<List<ApiGroceryList>> fetchGroceryLists({
    String? status,
  }) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final res = await _dio.get<List>(
      '/grocery/lists',
      queryParameters: params,
    );
    return (res.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ApiGroceryList.fromJson)
        .toList();
  }

  Future<ApiGroceryList> createGroceryList(
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/grocery/lists',
      data: data,
    );
    final body = res.data;
    if (body == null) throw const FormatException('Server returned an empty body for createGroceryList');
    return ApiGroceryList.fromJson(body);
  }

  Future<ApiGroceryList> updateGroceryList(
    int serverId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/grocery/lists/$serverId',
      data: data,
    );
    final body = res.data;
    if (body == null) throw const FormatException('Server returned an empty body for updateGroceryList');
    return ApiGroceryList.fromJson(body);
  }

  Future<void> deleteGroceryList(int serverId) async {
    await _dio.delete('/grocery/lists/$serverId');
  }

  // ── Grocery List Items ────────────────────────────────────────────────────────

  Future<ApiGroceryListItem> addGroceryListItem(
    int listServerId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/grocery/lists/$listServerId/items',
      data: data,
    );
    final body = res.data;
    if (body == null) throw const FormatException('Server returned an empty body for addGroceryListItem');
    return ApiGroceryListItem.fromJson(body);
  }

  Future<ApiGroceryListItem> updateGroceryListItem(
    int listServerId,
    int itemServerId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/grocery/lists/$listServerId/items/$itemServerId',
      data: data,
    );
    final body = res.data;
    if (body == null) throw const FormatException('Server returned an empty body for updateGroceryListItem');
    return ApiGroceryListItem.fromJson(body);
  }

  Future<void> removeGroceryListItem(
    int listServerId,
    int itemServerId,
  ) async {
    await _dio.delete(
      '/grocery/lists/$listServerId/items/$itemServerId',
    );
  }
}
