import 'package:intl/intl.dart';

extension DateFormatExt on DateTime {
  /// Formats to `yyyy-MM-dd` — the canonical date string used throughout the app.
  String toIso8601DateString() => DateFormat('yyyy-MM-dd').format(this);
}
