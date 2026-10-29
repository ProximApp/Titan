import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:titan/tools/ui/layouts/card_button.dart';
import 'package:titan/tools/ui/widgets/calendar.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for the shared `Calendar` wrapper: the syncfusion
/// week view, the appointment detail dialog and the loading/error arms of
/// its AsyncChild.
///
/// The week view paints its cells with `TextPainter` — there is no `Text`
/// widget for an appointment, so the dialog's trigger is located with a
/// bounded `tapAt` sweep over the fixed 360x640 surface (syncfusion 34 is
/// pinned, so the geometry is stable). The appointment sits today at 13:00,
/// inside the visible week whatever day the test runs.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Appointment appointment() {
    final now = DateTime.now();
    return Appointment(
      subject: 'Réunion solidaire',
      notes: 'Ordre du jour : budget, planning, buvette',
      startTime: DateTime(now.year, now.month, now.day, 13),
      endTime: DateTime(now.year, now.month, now.day, 14),
    );
  }

  testWidgets('renders the week view and opens the appointment dialog', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Calendar(
        dataSource: AppointmentDataSource([appointment()]),
        items: AsyncValue.data([appointment()]),
      ),
      container,
    );
    expect(find.byType(SfCalendar), findsOneWidget);

    // Sweep until the painted appointment is hit and its dialog opens.
    var opened = false;
    outer:
    for (var y = 40; y < 640; y += 8) {
      for (var x = 8; x < 360; x += 8) {
        await tester.tapAt(Offset(x.toDouble(), y.toDouble()));
        await tester.pump(const Duration(milliseconds: 30));
        if (find.textContaining('budget').evaluate().isNotEmpty) {
          opened = true;
          break outer;
        }
      }
    }
    expect(opened, isTrue, reason: 'appointment dialog never opened');

    // The dialog shows the subject, the dates and the notes.
    expect(find.text('Réunion solidaire'), findsOneWidget);
    expect(find.textContaining('budget'), findsOneWidget);

    // Its anchored close button pops the dialog.
    await tester.tap(
      find
          .descendant(
            of: find.byType(Dialog),
            matching: find.byType(CardButton),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('budget'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the web layout renders the two month-forward arrows', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Calendar(
        dataSource: AppointmentDataSource([appointment()]),
        items: AsyncValue.data([appointment()]),
      ),
      container,
      surface: const Size(1100, 800),
    );

    expect(find.byType(SfCalendar), findsOneWidget);
    final arrows = find.descendant(
      of: find.byType(Calendar),
      matching: find.byType(IconButton),
    );
    expect(arrows, findsNWidgets(2));

    // Both arrows drive the calendar's forward/backward controller
    // callbacks — the only lines of this file that need a press.
    await tester.tap(arrows.at(0));
    await tester.pump();
    await tester.tap(arrows.at(1));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the loader and the error arm', (tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      Calendar(
        dataSource: AppointmentDataSource(const []),
        items: const AsyncValue.loading(),
      ),
      container,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final other = scaffold.makeContainer();
    addTearDown(other.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      Calendar(
        dataSource: AppointmentDataSource(const []),
        items: AsyncValue.error('boom', StackTrace.empty),
      ),
      other,
    );
    expect(find.textContaining('boom'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
