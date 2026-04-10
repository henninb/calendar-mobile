import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_mobile/providers/providers.dart';

void main() {
  group('SyncState.copyWith', () {
    const base = SyncState(
      phase: SyncPhase.idle,
      errorMessage: 'prior error',
      pendingCount: 3,
    );

    test('preserves all fields when nothing is passed', () {
      final result = base.copyWith();
      expect(result.phase, SyncPhase.idle);
      expect(result.errorMessage, 'prior error');
      expect(result.pendingCount, 3);
    });

    test('updates only phase, preserving errorMessage', () {
      final result = base.copyWith(phase: SyncPhase.pulling);
      expect(result.phase, SyncPhase.pulling);
      expect(result.errorMessage, 'prior error'); // must not be cleared
      expect(result.pendingCount, 3);
    });

    test('updates only pendingCount, preserving errorMessage', () {
      final result = base.copyWith(pendingCount: 7);
      expect(result.pendingCount, 7);
      expect(result.errorMessage, 'prior error'); // must not be cleared
      expect(result.phase, SyncPhase.idle);
    });

    test('explicitly passing null clears errorMessage', () {
      final result = base.copyWith(errorMessage: null);
      expect(result.errorMessage, isNull);
    });

    test('can set a new errorMessage', () {
      final result = base.copyWith(errorMessage: 'new error');
      expect(result.errorMessage, 'new error');
    });

    test('phase error with no errorMessage is representable', () {
      final result = SyncState().copyWith(phase: SyncPhase.error, errorMessage: 'oops');
      expect(result.phase, SyncPhase.error);
      expect(result.errorMessage, 'oops');
    });
  });

  group('SyncState defaults', () {
    test('default constructor produces idle with no error', () {
      const s = SyncState();
      expect(s.phase, SyncPhase.idle);
      expect(s.errorMessage, isNull);
      expect(s.pendingCount, 0);
    });
  });
}
