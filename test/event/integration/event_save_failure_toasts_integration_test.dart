import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/event/providers/event_provider.dart';
import 'package:titan/event/ui/pages/event_pages/add_edit_event_page.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The save button reports a refusal instead of pretending the save worked.
/// The existing tests only drive the two SUCCESS paths ("Event added" /
/// "Event edited"), so the error arms were dark — and an edit that silently
/// looked saved is exactly the failure a user would not notice.
///
/// Only the edit arm is covered here: the create form's validator refused the
/// fixture I could build without a description, so its refusal arm stays
/// uncovered rather than being forced.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubLists() {
    when(
      () => scaffold.repository.calendarEventsConfirmedGet(),
    ).thenAnswer((_) async => chopperListResponse(<EventCompleteTicketUrl>[]));
    when(() => scaffold.repository.bookingRoomsGet()).thenAnswer(
      (_) async => chopperListResponse([
        RoomComplete.empty().copyWith(id: 'r-1', name: 'Amphi Darwin'),
      ]),
    );
  }

  Future<void> submit(WidgetTester tester, String label) async {
    await tester.dragUntilVisible(
      find.text(label),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -200),
    );
    await settle(tester, frames: 2);
    await tester.tap(find.text(label));
    await settle(tester, frames: 12);
  }

  testWidgets('a refused edit keeps the form and reports the editing error', (
    tester,
  ) async {
    stubLists();
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);
    final now = DateTime.now();
    container
        .read(eventProvider.notifier)
        .setEvent(
          EventCompleteTicketUrl.empty().copyWith(
            id: 'e-1',
            name: 'Kermesse',
            associationId: 'BDE Info',
            location: 'Cour',
            description: 'Fête du campus',
            start: now.add(const Duration(days: 2, hours: 10)),
            end: now.add(const Duration(days: 2, hours: 12)),
          ),
        );
    when(
      () => scaffold.repository.calendarEventsEventIdPatch(
        eventId: any(named: 'eventId'),
        body: any(named: 'body'),
      ),
    ).thenThrow(Exception('patch refused'));

    await scaffold.pumpWidgetApp(
      tester,
      AddEditEventPage(),
      container,
      surface: const ui.Size(900, 1400),
    );
    await settle(tester, frames: 4);

    await submit(tester, 'Edit');

    expect(find.textContaining('Error'), findsWidgets);
    // The form stays up so the edition is not lost.
    expect(find.byType(AddEditEventPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
  });
}
