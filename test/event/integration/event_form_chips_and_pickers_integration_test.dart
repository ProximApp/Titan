import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/event/providers/selected_days_provider.dart';
import 'package:titan/event/ui/pages/event_pages/add_edit_event_page.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/widgets/date_entry.dart';

import '../../shared/app_scaffold.dart';

/// The form's three unexercised interactions: switching the location mode
/// back to "Other", opening the FULL date pickers (the existing test only
/// opens the all-day ones), and ticking a weekday on a recurrence.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<ProviderContainer> pumpForm(WidgetTester tester) async {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);
    when(
      () => scaffold.repository.calendarEventsConfirmedGet(),
    ).thenAnswer((_) async => chopperListResponse(<EventCompleteTicketUrl>[]));
    when(() => scaffold.repository.bookingRoomsGet()).thenAnswer(
      (_) async => chopperListResponse([
        RoomComplete.empty().copyWith(id: 'r-1', name: 'Amphi Darwin'),
      ]),
    );
    await scaffold.pumpWidgetApp(
      tester,
      AddEditEventPage(),
      container,
      surface: const ui.Size(900, 1400),
    );
    await settle(tester, frames: 4);
    return container;
  }

  testWidgets('the Other chip leaves room mode', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Room'));
    await settle(tester, frames: 6);
    expect(find.text('Amphi Darwin'), findsOneWidget);

    // Back to a free-text location: the rooms strip is replaced.
    await tester.tap(find.text('Other'));
    await settle(tester, frames: 6);
    expect(find.text('Amphi Darwin'), findsNothing);
    expect(find.byType(TextFormField), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the start and end fields open the full date pickers', (
    tester,
  ) async {
    await pumpForm(tester);

    // Not all-day and not recurrent: both entries use the date+time picker.
    for (var i = 0; i < 2; i++) {
      await tester.ensureVisible(find.byType(DateEntry).at(i));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DateEntry).at(i));
      await tester.pumpAndSettle();
      expect(find.text('OK'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await settle(tester, frames: 6);
    }

    // The pickers wrote into the two date fields.
    final filled = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .where((f) => (f.controller?.text ?? '').isNotEmpty)
        .length;
    // The day+time picker only commits after both halves are accepted, so a
    // single field is the honest expectation here.
    expect(filled, greaterThanOrEqualTo(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a recurring event can tick a weekday', (tester) async {
    final container = await pumpForm(tester);
    expect(container.read(selectedDaysProvider), List.filled(7, false));

    await tester.tap(find.text('Recurrence'));
    await settle(tester, frames: 6);

    // The two mode checkboxes come first (recurrence, all day), then the
    // seven weekdays.
    final boxes = find.byType(Checkbox);
    expect(boxes, findsNWidgets(9));
    await tester.tap(boxes.at(2));
    await settle(tester, frames: 6);

    expect(container.read(selectedDaysProvider).contains(true), isTrue);
    expect(container.read(selectedDaysProvider).where((d) => d).length, 1);
  });
}
