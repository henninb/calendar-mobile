import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_mobile/core/constants.dart';

void main() {
  group('AppConstants', () {
    test('sync timing constants are stable', () {
      expect(AppConstants.syncDebounce, const Duration(seconds: 3));
      expect(AppConstants.connectCheck, const Duration(seconds: 5));
      expect(AppConstants.defaultSyncDays, 365);
    });

    test('occurrence window constants are stable', () {
      expect(AppConstants.occurrencePastMonths, 1);
      expect(AppConstants.occurrenceFutureMonths, 3);
    });

    test('preference keys are stable', () {
      expect(AppConstants.prefBaseUrl, 'base_url');
      expect(AppConstants.prefApiKey, 'api_key');
      expect(AppConstants.prefForcedOffline, 'forced_offline');
    });
  });

  group('TaskStatus', () {
    test('status strings are stable', () {
      expect(TaskStatus.todo, 'todo');
      expect(TaskStatus.inProgress, 'in_progress');
      expect(TaskStatus.done, 'done');
      expect(TaskStatus.cancelled, 'cancelled');
    });
  });

  group('OccurrenceStatus', () {
    test('status strings are stable', () {
      expect(OccurrenceStatus.upcoming, 'upcoming');
      expect(OccurrenceStatus.completed, 'completed');
      expect(OccurrenceStatus.skipped, 'skipped');
      expect(OccurrenceStatus.overdue, 'overdue');
    });
  });

  group('GroceryConstants', () {
    test('contains expected base units', () {
      expect(GroceryConstants.units, containsAll(['each', 'lb', 'kg', 'ml']));
    });

    test('does not contain duplicate unit names', () {
      expect(
        GroceryConstants.units.toSet().length,
        GroceryConstants.units.length,
      );
    });
  });

  group('SyncStatus', () {
    test('fromInt round-trips every known value', () {
      for (final s in SyncStatus.values) {
        expect(SyncStatus.fromInt(s.value), s);
      }
    });

    test('fromInt falls back to pendingUpdate for unknown values', () {
      expect(SyncStatus.fromInt(99), SyncStatus.pendingUpdate);
      expect(SyncStatus.fromInt(-1), SyncStatus.pendingUpdate);
    });

    test('value integers are stable', () {
      expect(SyncStatus.synced.value, 0);
      expect(SyncStatus.pendingCreate.value, 1);
      expect(SyncStatus.pendingUpdate.value, 2);
      expect(SyncStatus.pendingDelete.value, 3);
    });

    group('next()', () {
      test('transitions synced to pendingUpdate', () {
        expect(SyncStatus.next(SyncStatus.synced.value),
            SyncStatus.pendingUpdate.value);
      });

      test('preserves pendingCreate so the record is still POSTed', () {
        expect(SyncStatus.next(SyncStatus.pendingCreate.value),
            SyncStatus.pendingCreate.value);
      });

      test('preserves pendingUpdate', () {
        expect(SyncStatus.next(SyncStatus.pendingUpdate.value),
            SyncStatus.pendingUpdate.value);
      });

      test('preserves pendingDelete', () {
        expect(SyncStatus.next(SyncStatus.pendingDelete.value),
            SyncStatus.pendingDelete.value);
      });
    });
  });
}
