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

  void updateBaseUrl(String baseUrl) {
    if (baseUrl.isEmpty) return; // not yet configured — keep placeholder
    final uri = Uri.tryParse(baseUrl);
    assert(
      uri != null && uri.hasScheme && uri.scheme == 'https',
      'ApiClient.updateBaseUrl: only https:// URLs are accepted',
    );
    _dio.options.baseUrl = '$baseUrl/api';
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
    return (res.data ?? []).map((j) => ApiCategory.fromJson(j)).toList();
  }

  // ── Persons ──────────────────────────────────────────────────────────────────

  Future<List<ApiPerson>> fetchPersons() async {
    final res = await _dio.get<List>('/persons');
    return (res.data ?? []).map((j) => ApiPerson.fromJson(j)).toList();
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
    return (res.data ?? []).map((j) => ApiOccurrence.fromJson(j)).toList();
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
    return (res.data ?? []).map((j) => ApiTask.fromJson(j)).toList();
  }

  Future<ApiTask> createTask(Map<String, dynamic> data) async {
    final res = await _dio.post<Map<String, dynamic>>('/tasks', data: data);
    return ApiTask.fromJson(res.data!);
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
    return ApiSubtask.fromJson(res.data!);
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
}
