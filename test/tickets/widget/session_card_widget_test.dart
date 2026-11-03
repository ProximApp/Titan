import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/ui/components/session_card.dart';

import '../../shared/app_scaffold.dart';

/// `SessionCard` (the ticket form's session rows) sat at 58/72 lines: the add
/// and remove buttons had never been pressed, and `startDatetimeOf`'s three
/// arms — blank, parseable, unparseable — had never run. The third one matters
/// most: the picker writes a locale-formatted date that is not ISO-8601, so a
/// mis-typed field used to be able to throw out of the parent form's
/// `onChanged` instead of falling back to "now".
void main() {
  late IntegrationScaffold scaffold;
  late List<List<SessionCreate>> emissions;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    emissions = <List<SessionCreate>>[];
  });

  Future<void> pumpCard(WidgetTester tester) async {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);
    await pumpWidgetAt(
      tester,
      SessionCard(onChanged: emissions.add),
      container: container,
      surface: const ui.Size(600, 1400),
      appFonts: true,
    );
  }

  // Three fields per session: name, date (inside an AbsorbPointer, hence the
  // controller is written directly), then quota.
  Finder nameField([int i = 0]) => find.byType(TextFormField).at(i * 3);
  Finder quotaField([int i = 0]) => find.byType(TextFormField).at(i * 3 + 2);

  /// Writes the date the picker would have written, then makes the card emit
  /// by touching the name field. The name has to CHANGE — an `enterText` with
  /// the value already in the field fires no `onChanged`, and the card would
  /// keep the previous date.
  Future<void> writeDate(WidgetTester tester, String date, String name) async {
    tester
            .widget<EditableText>(find.byType(EditableText).at(1))
            .controller
            .text =
        date;
    await tester.enterText(nameField(), name);
    await settle(tester, frames: 4);
  }

  testWidgets('adding a session appends a row and a remove button', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(
      find.byType(IconButton),
      findsNothing,
      reason: 'a single session has nothing to remove yet',
    );

    await tester.tap(find.byType(TextButton));
    await settle(tester, frames: 6);

    expect(find.byType(TextFormField), findsNWidgets(6));
    expect(find.byType(IconButton), findsNWidgets(2));
    expect(emissions.last, hasLength(2));

    await tester.tap(find.byType(IconButton).first);
    await settle(tester, frames: 6);

    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byType(IconButton), findsNothing);
    expect(emissions.last, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a blank date reads as now and a blank quota as null', (
    tester,
  ) async {
    await pumpCard(tester);

    await tester.enterText(nameField(), 'Matin');
    await settle(tester, frames: 4);

    final session = emissions.last.single;
    expect(session.name, 'Matin');
    expect(
      session.startDatetime.difference(DateTime.now()).inMinutes.abs(),
      lessThanOrEqualTo(1),
      reason: 'an untouched date field must not block the form',
    );
    expect(
      session.quota,
      isNull,
      reason: 'an empty quota is "unlimited", not 0',
    );

    await tester.enterText(quotaField(), '10');
    await settle(tester, frames: 4);
    expect(emissions.last.single.quota, 10);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a picker date is parsed, and garbage falls back to now', (
    tester,
  ) async {
    await pumpCard(tester);

    // The picker writes what the user sees: en renders M/d/yyyy here, since
    // the app resolves l10n `en` even though numbers format as `fr`.
    await writeDate(tester, '12/31/2100', 'Matin');
    expect(emissions.last.single.startDatetime.year, 2100);
    expect(emissions.last.single.startDatetime.month, 12);
    expect(emissions.last.single.startDatetime.day, 31);

    await writeDate(tester, 'pas une date', 'Soir');
    expect(
      emissions.last.single.startDatetime.year,
      DateTime.now().year,
      reason: 'an unparseable field must fall back, never throw inside notify',
    );
    expect(tester.takeException(), isNull);
  });
}
