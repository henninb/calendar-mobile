import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_mobile/widgets/status_badge.dart';
import 'package:calendar_mobile/core/constants.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('StatusBadge', () {
    testWidgets('upcoming status shows UPCOMING label', (tester) async {
      await tester.pumpWidget(_wrap(const StatusBadge(OccurrenceStatus.upcoming)));
      expect(find.text('UPCOMING'), findsOneWidget);
    });

    testWidgets('overdue status shows OVERDUE label', (tester) async {
      await tester.pumpWidget(_wrap(const StatusBadge(OccurrenceStatus.overdue)));
      expect(find.text('OVERDUE'), findsOneWidget);
    });

    testWidgets('completed status shows DONE label', (tester) async {
      await tester.pumpWidget(_wrap(const StatusBadge(OccurrenceStatus.completed)));
      expect(find.text('DONE'), findsOneWidget);
    });

    testWidgets('skipped status shows SKIPPED label', (tester) async {
      await tester.pumpWidget(_wrap(const StatusBadge(OccurrenceStatus.skipped)));
      expect(find.text('SKIPPED'), findsOneWidget);
    });

    testWidgets('unknown status shows uppercased status as label', (tester) async {
      await tester.pumpWidget(_wrap(const StatusBadge('pending')));
      expect(find.text('PENDING'), findsOneWidget);
    });
  });

  group('TaskStatusBadge', () {
    testWidgets('todo status shows TODO label', (tester) async {
      await tester.pumpWidget(_wrap(const TaskStatusBadge(TaskStatus.todo)));
      expect(find.text('TODO'), findsOneWidget);
    });

    testWidgets('in_progress status shows IN PROGRESS label', (tester) async {
      await tester.pumpWidget(_wrap(const TaskStatusBadge(TaskStatus.inProgress)));
      expect(find.text('IN PROGRESS'), findsOneWidget);
    });

    testWidgets('done status shows DONE label', (tester) async {
      await tester.pumpWidget(_wrap(const TaskStatusBadge(TaskStatus.done)));
      expect(find.text('DONE'), findsOneWidget);
    });

    testWidgets('cancelled status shows CANCELLED label', (tester) async {
      await tester.pumpWidget(_wrap(const TaskStatusBadge(TaskStatus.cancelled)));
      expect(find.text('CANCELLED'), findsOneWidget);
    });

    testWidgets('unknown status shows uppercased label', (tester) async {
      await tester.pumpWidget(_wrap(const TaskStatusBadge('archived')));
      expect(find.text('ARCHIVED'), findsOneWidget);
    });
  });

  group('PriorityBadge', () {
    testWidgets('high priority shows HIGH label', (tester) async {
      await tester.pumpWidget(_wrap(const PriorityBadge('high')));
      expect(find.text('HIGH'), findsOneWidget);
    });

    testWidgets('medium priority shows MED label', (tester) async {
      await tester.pumpWidget(_wrap(const PriorityBadge('medium')));
      expect(find.text('MED'), findsOneWidget);
    });

    testWidgets('low priority shows LOW label', (tester) async {
      await tester.pumpWidget(_wrap(const PriorityBadge('low')));
      expect(find.text('LOW'), findsOneWidget);
    });

    testWidgets('unknown priority shows uppercased label', (tester) async {
      await tester.pumpWidget(_wrap(const PriorityBadge('critical')));
      expect(find.text('CRITICAL'), findsOneWidget);
    });
  });
}
