import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/event/ui/components/event_ui.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';

import '../../shared/app_scaffold.dart';

/// The event card's branch matrix. `EventUi` renders three gradient states
/// (upcoming / started / ended), two layouts (member with Edit+Delete, admin
/// with the four decision buttons) and a two-line description preview with
/// the '...' suffix — none of which a page mount asserts one by one.
void main() {
  late IntegrationScaffold scaffold;
  late _RecordingRouteMock mock;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    // The card watches the event list notifier, whose build triggers a
    // confirmed-events load; answering keeps that async load from throwing.
    when(
      () => scaffold.repository.calendarEventsConfirmedGet(),
    ).thenAnswer((_) async => chopperListResponse(<EventCompleteTicketUrl>[]));
    // qlevar's test hook: QR.to resolves against the mock instead of a real
    // navigator, so the card's navigation callbacks run to completion.
    mock = _RecordingRouteMock();
    QR.settings.mockRoute = mock;
  });

  tearDown(() => QR.settings.mockRoute = null);

  final now = DateTime.now();

  final upcoming = EventCompleteTicketUrl.empty().copyWith(
    id: 'e-up',
    name: 'Apéro',
    description: 'Une seule ligne',
    decision: Decision.approved,
    start: now.add(const Duration(days: 3, hours: 18)),
    end: now.add(const Duration(days: 3, hours: 21)),
  );
  final started = EventCompleteTicketUrl.empty().copyWith(
    id: 'e-started',
    name: 'Kermesse',
    description: 'Deux films\nune discussion\net une troisième ligne',
    decision: Decision.pending,
    start: now.subtract(const Duration(hours: 1)),
    end: now.add(const Duration(hours: 3)),
  );
  final expired = EventCompleteTicketUrl.empty().copyWith(
    id: 'e-expired',
    name: 'Vieux bal',
    decision: Decision.declined,
    start: now.subtract(const Duration(days: 10)),
    end: now.subtract(const Duration(days: 5)),
  );

  testWidgets('renders the three time states and the preview truncation', (
    tester,
  ) async {
    final container = scaffold.makeContainer(userId: 'u-1');
    addTearDown(container.dispose);

    await pumpWidgetAt(
      tester,
      Column(
        children: [
          EventUi(event: upcoming),
          EventUi(event: started),
          EventUi(event: expired),
        ],
      ),
      container: container,
      surface: const ui.Size(600, 1400),
    );

    expect(find.text('Apéro'), findsOneWidget);
    expect(find.text('Kermesse'), findsOneWidget);
    expect(find.text('Vieux bal'), findsOneWidget);

    // Single-line descriptions render whole; multi-line ones join the first
    // two lines and append '...'.
    expect(find.text('Une seule ligne'), findsOneWidget);
    expect(find.text('Deux films\nune discussion...'), findsOneWidget);

    // The decision label renders under every card.
    expect(find.text('approved'), findsOneWidget);
    expect(find.text('pending'), findsOneWidget);
    expect(find.text('declined'), findsOneWidget);

    // Member layout: Edit and Delete only (no admin icons).
    expect(find.text('Edit'), findsNWidgets(3));
    expect(find.text('Delete'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the member delete flow confirms, calls the endpoint, toasts', (
    tester,
  ) async {
    when(
      () => scaffold.repository.calendarEventsEventIdDelete(
        eventId: any(named: 'eventId'),
      ),
    ).thenAnswer((_) async => chopperResponse(true));
    final container = scaffold.makeContainer(userId: 'u-1');
    addTearDown(container.dispose);

    await pumpWidgetAt(
      tester,
      EventUi(event: upcoming),
      container: container,
      surface: const ui.Size(600, 1400),
    );

    await tester.tap(find.text('Delete'));
    await settle(tester, frames: 4);
    expect(find.byType(CustomDialogBox), findsOneWidget);
    expect(find.text('Delete the event?'), findsOneWidget);

    // CustomDialogBox's confirm button carries globalConfirm ('Confirm').
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 6);
    verify(
      () => scaffold.repository.calendarEventsEventIdDelete(eventId: 'e-up'),
    ).called(1);
    expect(find.text('Event deleted'), findsOneWidget);
    expect(find.text('Error while deleting'), findsNothing);

    // The toast schedules its auto-dismiss timer; pump it out so no timer
    // outlives the disposed tree.
    await tester.pump(const Duration(seconds: 8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the admin row callbacks fire, guarded by the decision', (
    tester,
  ) async {
    final container = scaffold.makeContainer(userId: 'u-1');
    addTearDown(container.dispose);

    final counts = <String, int>{
      'edit': 0,
      'copy': 0,
      'confirm': 0,
      'decline': 0,
      'info': 0,
    };

    // The admin card holds a Spacer, so it only lays out inside a bounded
    // box — production gives it the 235px HorizontalListView strip.
    Widget adminCard(EventCompleteTicketUrl event) => SizedBox(
      height: 235,
      child: EventUi(
        event: event,
        isDetailPage: true,
        isAdmin: true,
        onEdit: () => counts['edit'] = counts['edit']! + 1,
        onCopy: () => counts['copy'] = counts['copy']! + 1,
        onConfirm: () => counts['confirm'] = counts['confirm']! + 1,
        onDecline: () => counts['decline'] = counts['decline']! + 1,
        onInfo: () => counts['info'] = counts['info']! + 1,
      ),
    );

    await pumpWidgetAt(
      tester,
      Column(
        children: [
          adminCard(
            EventCompleteTicketUrl.empty().copyWith(
              id: 'e-pending',
              name: 'Atelier',
              decision: Decision.pending,
              start: now.add(const Duration(days: 10)),
              end: now.add(const Duration(days: 10, hours: 2)),
            ),
          ),
          adminCard(
            upcoming.copyWith(id: 'e-approved', name: 'Apéro confirmé'),
          ),
          adminCard(expired.copyWith(id: 'e-declined', name: 'Refusé')),
        ],
      ),
      container: container,
      surface: const ui.Size(600, 1400),
    );

    // Four admin icons per card, in row order: pencil, duplicate, check,
    // x-mark.
    findIcons(String name) => find.descendant(
      of: find.ancestor(of: find.text(name), matching: find.byType(EventUi)),
      matching: find.byType(HeroIcon),
    );

    final pendingIcons = findIcons('Atelier');
    expect(pendingIcons, findsNWidgets(4));
    await tester.tap(pendingIcons.at(0)); // pencil
    await tester.tap(pendingIcons.at(1)); // duplicate
    await tester.tap(pendingIcons.at(2)); // check: pending ≠ approved
    await tester.tap(pendingIcons.at(3)); // x-mark: pending ≠ declined
    await tester.tap(find.text('Atelier')); // card tap: onInfo on admin cards
    await settle(tester, frames: 2);
    expect(counts, {
      'edit': 1,
      'copy': 1,
      'confirm': 1,
      'decline': 1,
      'info': 1,
    });

    // The approved card's check is a guarded no-op.
    await tester.tap(findIcons('Apéro confirmé').at(2));
    await settle(tester, frames: 2);
    expect(counts['confirm'], 1);

    // The declined card's x-mark is a guarded no-op too.
    await tester.tap(findIcons('Refusé').at(3));
    await settle(tester, frames: 2);
    expect(counts['decline'], 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('member info and Edit taps run setEvent before the QR throw', (
    tester,
  ) async {
    final container = scaffold.makeContainer(userId: 'u-1');
    addTearDown(container.dispose);

    await pumpWidgetAt(
      tester,
      EventUi(event: upcoming),
      container: container,
      surface: const ui.Size(600, 1400),
    );

    // Info icon: setEvent + QR.to('/event/detail').
    await tester.tap(find.byType(HeroIcon));
    await settle(tester, frames: 2);
    expect(mock.navigated, contains('/event/detail'));

    // Edit button: setEvent + QR.to('/event/add_edit').
    await tester.tap(find.text('Edit'));
    await settle(tester, frames: 2);
    expect(mock.navigated, contains('/event/add_edit'));
    expect(tester.takeException(), isNull);
  });
}

/// qlevar's test hook target: records every QR.to destination.
class _RecordingRouteMock extends RouteMock {
  final navigated = <String>[];

  @override
  String? mockName(String name) => name;

  @override
  QRoute? mockPath(String path) {
    navigated.add(path);
    return QRoute(path: path, builder: () => const SizedBox());
  }
}
