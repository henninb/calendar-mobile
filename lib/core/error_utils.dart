import 'package:dio/dio.dart';

/// Converts any exception into a short, user-safe message.
///
/// Never surfaces raw error strings, stack traces, hostnames, or server
/// response bodies — those belong in the log, not the UI.
String friendlyError(Object e) {
  if (e is DioException) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return 'Authentication failed — check the API key in Settings';
    }
    if (status != null) return 'Server error (HTTP $status)';
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'Request timed out — is the server running?',
      DioExceptionType.connectionError =>
        'Cannot reach backend — check the URL in Settings',
      DioExceptionType.badCertificate =>
        'TLS certificate error — connection may be intercepted',
      _ => 'Network error — check your connection',
    };
  }
  // Non-Dio errors (e.g. database, format): keep generic to avoid leaking
  // internal detail such as file paths or stack-trace fragments.
  final msg = e.toString();
  if (msg.contains('Connection refused') || msg.contains('SocketException')) {
    return 'Cannot reach backend — check the URL in Settings';
  }
  if (msg.contains('timed out')) {
    return 'Request timed out — is the server running?';
  }
  return 'An unexpected error occurred';
}
