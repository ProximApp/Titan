import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/booking/ui/calendar/calendar_dialog.dart';
import 'package:titan/booking/ui/calendar/calendar_dialog_button.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for CalendarDialog: the plain booking recap and the
/// manager-only block (note, mail and sms rows, phone fallback).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  BookingReturnApplicant booking({String? note, String? phone}) =>
      BookingReturnApplicant.empty().copyWith(
        id: 'b-1',
        reason: 'Réunion',
        start: DateTime(2026, 10, 20, 14),
        end: DateTime(2026, 10, 20, 16),
        entity: 'BDE',
        room: RoomComplete.empty().copyWith(id: 'r-1', name: 'Amphi'),
        note: note,
        applicant: Applicant.empty().copyWith(
          id: 'a-1',
          name: 'Delaunay',
          firstname: 'Jean-Baptiste',
          email: 'jb@example.com',
          phone: phone,
        ),
        decision: enums.Decision.approved,
      );

  Future<void> pumpDialog(WidgetTester tester, Widget dialog) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(tester, dialog, container);
  }

  testWidgets('shows the room, reason and booked-for recap', (tester) async {
    await pumpDialog(
      tester,
      CalendarDialog(booking: booking(), isManager: false),
    );

    expect(find.textContaining('Amphi'), findsOneWidget);
    expect(find.textContaining('Réunion'), findsOneWidget);
    expect(find.textContaining('Delaunay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides the manager block for a plain applicant', (tester) async {
    await pumpDialog(
      tester,
      CalendarDialog(booking: booking(), isManager: false),
    );

    expect(find.textContaining('jb@example.com'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows note and contact rows for a manager', (tester) async {
    await pumpDialog(
      tester,
      CalendarDialog(
        booking: booking(
          note: 'Prévoir le vidéoprojecteur',
          phone: '0601020304',
        ),
        isManager: true,
      ),
    );

    expect(find.textContaining('vidéoprojecteur'), findsOneWidget);
    expect(find.textContaining('jb@example.com'), findsOneWidget);
    expect(find.textContaining('0601020304'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to the no-phone label for a manager', (tester) async {
    await pumpDialog(
      tester,
      CalendarDialog(booking: booking(note: 'n'), isManager: true),
    );

    expect(find.textContaining('0601020304'), findsNothing);
    // The phone row shows the localized fallback instead of a number.
    expect(find.text('Number not provided'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a contact button whose launch fails toasts instead of '
      'crashing', (tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    final launcher = FakeUrlLauncher(
      launchError: StateError('test launcher failure'),
    );
    stubUrlLauncher(launcher);
    await scaffold.pumpWidgetApp(
      tester,
      CalendarDialog(
        booking: booking(note: 'n', phone: '0601020304'),
        isManager: true,
      ),
      container,
    );

    // The mailto button (first) carries a non-null uri: launchUrl has no
    // host implementation under test, so the throw travels into the local
    // displayToastWithoutContext catch — the only caller of that closure.
    final buttons = find.byType(CalendarDialogButton);
    expect(buttons, findsNWidgets(2));
    await tester.tap(buttons.at(0));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    // url_launcher returns false; the dialog catches that failure and the
    // fake confirms the requested address without invoking a platform channel.
    expect(launcher.launched, ['mailto:jb@example.com']);
    await scaffold.drainToast(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the close button pops the dialog', (tester) async {
    await pumpDialog(
      tester,
      CalendarDialog(booking: booking(), isManager: false),
    );

    expect(find.byType(Dialog), findsOneWidget);

    // In non-manager mode the only HeroIcon in the dialog is the close X.
    await tester.tap(find.byType(HeroIcon));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
