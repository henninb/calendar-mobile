import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_mobile/core/extensions/date_extensions.dart';

void main() {
  group('DateFormatExt.toIso8601DateString', () {
    test('formats a standard date correctly', () {
      expect(DateTime(2026, 5, 3).toIso8601DateString(), '2026-05-03');
    });

    test('pads month and day with leading zeros', () {
      expect(DateTime(2026, 1, 9).toIso8601DateString(), '2026-01-09');
    });

    test('formats end of year', () {
      expect(DateTime(2026, 12, 31).toIso8601DateString(), '2026-12-31');
    });

    test('formats start of year', () {
      expect(DateTime(2026, 1, 1).toIso8601DateString(), '2026-01-01');
    });

    test('formats leap day', () {
      expect(DateTime(2024, 2, 29).toIso8601DateString(), '2024-02-29');
    });

    test('ignores time component', () {
      expect(DateTime(2026, 5, 3, 23, 59, 59).toIso8601DateString(), '2026-05-03');
    });

    test('result has exactly 10 characters (yyyy-MM-dd)', () {
      expect(DateTime(2026, 7, 4).toIso8601DateString().length, 10);
    });
  });
}
