import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_mobile/widgets/status_badge.dart';
import 'package:calendar_mobile/core/constants.dart';
import 'package:calendar_mobile/core/theme.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: buildAppTheme(),
  home: Scaffold(body: child),
);

void main() {
  group('StatusBadge', () {
    testWidgets('upcoming status shows UPCOMING label', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatusBadge(OccurrenceStatus.upcoming)),
      );
      expect(find.text('UPCOMING'), findsOneWidget);
    });

    testWidgets('overdue status shows OVERDUE label', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatusBadge(OccurrenceStatus.overdue)),
      );
      expect(find.text('OVERDUE'), findsOneWidget);
    });

    testWidgets('completed status shows DONE label', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatusBadge(OccurrenceStatus.completed)),
      );
      expect(find.text('DONE'), findsOneWidget);
    });

    testWidgets('skipped status shows SKIPPED label', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatusBadge(OccurrenceStatus.skipped)),
      );
      expect(find.text('SKIPPED'), findsOneWidget);
    });

    testWidgets('unknown status shows uppercased status as label', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const StatusBadge('pending')));
      expect(find.text('PENDING'), findsOneWidget);
    });

    testWidgets('completed status uses completed badge colors', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatusBadge(OccurrenceStatus.completed)),
      );

      final container = tester.widget<Container>(
        find
            .ancestor(of: find.text('DONE'), matching: find.byType(Container))
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final text = tester.widget<Text>(find.text('DONE'));

      expect(decoration.color, AppColors.light.completedBg);
      expect((text.style!).color, AppColors.light.completedFg);
    });
  });

  group('TaskStatusBadge', () {
    testWidgets('todo status shows TODO label', (tester) async {
      await tester.pumpWidget(_wrap(const TaskStatusBadge(TaskStatus.todo)));
      expect(find.text('TODO'), findsOneWidget);
    });

    testWidgets('in_progress status shows IN PROGRESS label', (tester) async {
      await tester.pumpWidget(
        _wrap(const TaskStatusBadge(TaskStatus.inProgress)),
      );
      expect(find.text('IN PROGRESS'), findsOneWidget);
    });

    testWidgets('done status shows DONE label', (tester) async {
      await tester.pumpWidget(_wrap(const TaskStatusBadge(TaskStatus.done)));
      expect(find.text('DONE'), findsOneWidget);
    });

    testWidgets('cancelled status shows CANCELLED label', (tester) async {
      await tester.pumpWidget(
        _wrap(const TaskStatusBadge(TaskStatus.cancelled)),
      );
      expect(find.text('CANCELLED'), findsOneWidget);
    });

    testWidgets('unknown status shows uppercased label', (tester) async {
      await tester.pumpWidget(_wrap(const TaskStatusBadge('archived')));
      expect(find.text('ARCHIVED'), findsOneWidget);
    });

    testWidgets('in progress status uses amber palette', (tester) async {
      await tester.pumpWidget(
        _wrap(const TaskStatusBadge(TaskStatus.inProgress)),
      );

      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('IN PROGRESS'),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final text = tester.widget<Text>(find.text('IN PROGRESS'));

      expect(decoration.color, const Color(0xFFFEF3C7));
      expect((text.style!).color, const Color(0xFF92400E));
    });
  });

  group('QuadrantBadge', () {
    Future<void> pump(WidgetTester t, {required bool i, required bool u}) =>
        t.pumpWidget(_wrap(QuadrantBadge(important: i, urgent: u)));

    testWidgets('important + urgent is DO FIRST', (tester) async {
      await pump(tester, i: true, u: true);
      expect(find.text('DO FIRST'), findsOneWidget);
    });

    testWidgets('important only is SCHEDULE', (tester) async {
      await pump(tester, i: true, u: false);
      expect(find.text('SCHEDULE'), findsOneWidget);
    });

    testWidgets('urgent only is DELEGATE', (tester) async {
      await pump(tester, i: false, u: true);
      expect(find.text('DELEGATE'), findsOneWidget);
    });

    testWidgets('neither is ELIMINATE', (tester) async {
      await pump(tester, i: false, u: false);
      expect(find.text('ELIMINATE'), findsOneWidget);
    });

    testWidgets('DO FIRST badge uses tinted background and border', (
      tester,
    ) async {
      await pump(tester, i: true, u: true);

      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('DO FIRST'),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final text = tester.widget<Text>(find.text('DO FIRST'));

      expect(decoration.color, AppColors.priorityHigh.withAlpha(30));
      expect(
        (decoration.border! as Border).top.color,
        AppColors.priorityHigh.withAlpha(80),
      );
      expect((text.style!).color, AppColors.priorityHigh);
    });
  });
}
