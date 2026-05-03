import 'package:calendar_mobile/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('theme styles render expected scaffold elements', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          appBar: AppBar(title: const Text('Calendar')),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          body: const Chip(label: Text('Status')),
        ),
      ),
    );

    final context = tester.element(find.text('Calendar'));
    final theme = Theme.of(context);
    final chip = tester.widget<Chip>(find.byType(Chip));

    expect(find.text('Calendar'), findsOneWidget);
    expect(theme.appBarTheme.backgroundColor, AppColors.darkSurface);
    expect(
      theme.floatingActionButtonTheme.backgroundColor,
      AppColors.primary,
    );
    expect(chip.label, isA<Text>());
  });
}
