import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:titan/loan/providers/end_provider.dart';
import 'package:titan/loan/providers/initial_date_provider.dart';
import 'package:titan/loan/ui/pages/loan_group_page/end_date_entry.dart';
import 'package:titan/tools/ui/widgets/date_entry.dart';

import '../../shared/app_scaffold.dart';

/// `EndDateEntry` was only ever checked for layout, so its `onTap` stayed
/// dark: the row has to hand the picker the `initialDateProvider` date and
/// write the picked day back into `endProvider` as the picker's own
/// `DateFormat.yMMMd` string.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the end row opens the picker and writes the day back', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      const Scaffold(body: EndDateEntry()),
      container,
      locale: const Locale('en', 'US'),
      appFonts: true,
    );

    expect(find.text('Loan end date'), findsOneWidget);
    expect(container.read(endProvider), isEmpty);
    // The row starts on the shared initial date (today).
    final initial = container.read(initialDateProvider);
    expect(initial.day, DateTime.now().day);

    await tester.tap(find.byType(DateEntry));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);

    // Step to the next month so the 15th is always selectable, whatever day
    // the suite runs on.
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final picked = DateTime(now.year, now.month + 1, 15);
    final expected = DateFormat.yMMMd('en').format(picked);

    // `getOnlyDayDateFunction` writes the picker's own shape back.
    expect(container.read(endProvider), expected);
    // The row repaints with it.
    expect(find.text(expected), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
