import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_mobile/widgets/category_badge.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('parseCategoryColor', () {
    test('parses 6-digit hex with hash prefix', () {
      expect(parseCategoryColor('#3b82f6'), const Color(0xFF3B82F6));
    });

    test('is case-insensitive for hex digits', () {
      expect(parseCategoryColor('#FFFFFF'), const Color(0xFFFFFFFF));
      expect(parseCategoryColor('#000000'), const Color(0xFF000000));
    });

    test('falls back to blue for empty string', () {
      expect(parseCategoryColor(''), const Color(0xFF3B82F6));
    });

    test('falls back to blue for invalid hex', () {
      expect(parseCategoryColor('#gggggg'), const Color(0xFF3B82F6));
    });

    test('falls back to blue for 3-digit shorthand (not supported)', () {
      expect(parseCategoryColor('#abc'), const Color(0xFF3B82F6));
    });

    test('falls back to blue for string without hash', () {
      // Without '#', the length after replaceAll is 6 — still parsed.
      final result = parseCategoryColor('22c55e');
      expect(result, const Color(0xFF22C55E));
    });
  });

  group('CategoryBadge widget', () {
    testWidgets('renders name', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryBadge(name: 'Work', color: '#3b82f6'),
      ));
      expect(find.textContaining('Work'), findsOneWidget);
    });

    testWidgets('renders icon alongside name when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryBadge(name: 'Health', color: '#22c55e', icon: '🏋️'),
      ));
      expect(find.textContaining('Health'), findsOneWidget);
      expect(find.textContaining('🏋️'), findsOneWidget);
    });

    testWidgets('renders without icon when not provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryBadge(name: 'Personal', color: '#ef4444'),
      ));
      expect(find.textContaining('Personal'), findsOneWidget);
    });

    testWidgets('uses fallback color for invalid hex without throwing', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryBadge(name: 'Bad', color: 'not-a-color'),
      ));
      expect(find.textContaining('Bad'), findsOneWidget);
    });

    testWidgets('applies parsed color to text and decoration', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryBadge(name: 'Work', color: '#22c55e'),
      ));

      final text = tester.widget<Text>(find.text('Work'));
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Work'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration! as BoxDecoration;

      expect((text.style!).color, const Color(0xFF22C55E));
      expect(decoration.color, const Color(0xFF22C55E).withAlpha(33));
      expect((decoration.border! as Border).top.color, const Color(0xFF22C55E).withAlpha(84));
    });

    testWidgets('trims leading icon spacing when icon is absent', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryBadge(name: 'Errands', color: '#ef4444'),
      ));

      expect(find.text(' Errands'), findsNothing);
      expect(find.text('Errands'), findsOneWidget);
    });
  });
}
