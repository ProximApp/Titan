import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/event/providers/event_provider.dart';
import 'package:titan/event/ui/components/event_ui.dart';
import 'package:titan/event/ui/pages/detail_page/detail_page.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';

/// Page-level coverage for `DetailPage` — a 0%-covered file before this
/// test. `EventRouter` is not registered in `AppRouter`, so the detail route
/// has no deep link to boot (see the add_edit test's NOTE): both variants
/// are mounted directly against a pre-selected `eventProvider` state.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    // EventUi watches the event list notifier, whose build triggers a
    // confirmed-events load; answering keeps that async load from throwing.
    when(
      () => scaffold.repository.calendarEventsConfirmedGet(),
    ).thenAnswer((_) async => chopperListResponse(<EventCompleteTicketUrl>[]));
  });

  final now = DateTime.now();

  final event = EventCompleteTicketUrl.empty().copyWith(
    id: 'e-detail',
    name: 'Soirée Kino',
    location: 'Amphi Darwin',
    description: 'Deux films, une discussion',
    association: Association.empty().copyWith(name: 'BDE Info'),
    start: now.add(const Duration(days: 2, hours: 20)),
    end: now.add(const Duration(days: 2, hours: 23)),
  );

  testWidgets('the member variant renders the pre-selected event', (
    tester,
  ) async {
    final container = scaffold.makeContainer(userId: 'u-1');
    addTearDown(container.dispose);
    container.read(eventProvider.notifier).setEvent(event);

    await scaffold.pumpWidgetApp(
      tester,
      const DetailPage(isAdmin: false),
      container,
      surface: const ui.Size(900, 1400),
    );
    await settle(tester, frames: 6);

    // The association name renders twice: the page header and the card.
    expect(find.text('BDE Info'), findsNWidgets(2));
    // The description renders twice: the page header block and the card.
    expect(find.text('Deux films, une discussion'), findsNWidgets(2));
    expect(find.text('Soirée Kino'), findsOneWidget);
    // The detail card hides the member Edit/Delete column.
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(find.byType(EventUi), findsOneWidget);

    // Tapping the card on a non-admin detail page is a guarded no-op.
    await tester.tap(find.byType(EventUi));
    await settle(tester, frames: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the admin variant renders the same card with the admin block', (
    tester,
  ) async {
    final container = scaffold.makeContainer(userId: 'u-1');
    addTearDown(container.dispose);
    container.read(eventProvider.notifier).setEvent(event);

    await scaffold.pumpWidgetApp(
      tester,
      const DetailPage(isAdmin: true),
      container,
      surface: const ui.Size(900, 1400),
    );
    await settle(tester, frames: 6);

    expect(find.text('BDE Info'), findsNWidgets(2));
    expect(find.text('Soirée Kino'), findsOneWidget);
    expect(find.byType(EventUi), findsOneWidget);

    // The admin card fires onInfo from the tap (the callback is null on this
    // page, so the tap stays a safe no-op).
    await tester.tap(find.byType(EventUi));
    await settle(tester, frames: 2);
    expect(tester.takeException(), isNull);
  });
}
