import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_mobile/core/constants.dart';

void main() {
  group('SyncStatus', () {
    test('fromInt round-trips every known value', () {
      for (final s in SyncStatus.values) {
        expect(SyncStatus.fromInt(s.value), s);
      }
    });

    test('fromInt falls back to synced for unknown values', () {
      expect(SyncStatus.fromInt(99), SyncStatus.synced);
      expect(SyncStatus.fromInt(-1), SyncStatus.synced);
    });

    test('value integers are stable', () {
      expect(SyncStatus.synced.value, 0);
      expect(SyncStatus.pendingCreate.value, 1);
      expect(SyncStatus.pendingUpdate.value, 2);
      expect(SyncStatus.pendingDelete.value, 3);
    });
  });
}
