import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';

/// The association-events page's remaining arms.
///
/// The card is a `ListItem` that opens a sheet (Edit / Delete); Delete pops the
/// sheet and opens a confirmation modal whose `onYes` is the only caller of
/// `deleteEvent` — the DELETE itself goes through `ListNotifierAPI.update`,
/// so the card leaves the list only when the endpoint answers successfully.
///
/// The page's `Refresher` reloads the selected association's events; it is
/// driven through the real gesture rather than by calling the callback.
///
/// Its OTHER arm (`selectedAssociation == null` → a completed future, no
/// call) is unreachable: `FeedMiddleware` redirects a user who belongs to no
/// association from `/feed/association_events` back to `/feed`, so the page
/// only ever mounts with an association selected (asserted below).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  EventCompleteTicketUrl event() => EventCompleteTicketUrl.empty().copyWith(
    id: 'e-1',
    name: 'Gala de printemps',
    location: 'Amphi Marie Curie',
    associationId: 'a-1',
    association: Association(name: 'BDE', groupId: 'g-1', id: 'a-1'),
    decision: enums.Decision.approved,
  );

  void stubEvents(void Function()? onList) {
    when(
      () => scaffold.repository.calendarEventsAssociationsAssociationIdGet(
        associationId: any(named: 'associationId'),
      ),
    ).thenAnswer((_) async {
      onList?.call();
      return chopperListResponse([event()]);
    });
    // The card fetches its image on mount; a 404 is the fallback branch.
    when(
      () => scaffold.repository.calendarEventsEventIdImageGet(
        eventId: any(named: 'eventId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response('{"detail": "File does not exist"}', 404),
        [],
        error: 'File does not exist',
      ),
    );
  }

  testWidgets('deleting an association event confirms first, then deletes', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      myAssociations: [Association(name: 'BDE', groupId: 'g-1', id: 'a-1')],
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    stubEvents(null);
    when(
      () => scaffold.repository.calendarEventsEventIdDelete(
        eventId: any(named: 'eventId'),
      ),
    ).thenAnswer((_) async => chopper.Response(http.Response('', 204), null));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/feed/association_events',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);
    expect(find.text('Gala de printemps'), findsOneWidget);

    // 1. The row opens its action sheet.
    await tester.tap(find.text('Gala de printemps'));
    await settle(tester, frames: 8);
    expect(find.text('Delete'), findsOneWidget);

    // 2. Delete closes the sheet and asks for confirmation before touching
    //    the backend — nothing is deleted until "Confirm".
    await tester.tap(find.text('Delete'));
    await settle(tester, frames: 8);
    verifyNever(
      () => scaffold.repository.calendarEventsEventIdDelete(
        eventId: any(named: 'eventId'),
      ),
    );
    expect(find.text('Confirm'), findsOneWidget);

    // 3. Confirm hits the endpoint and the card leaves the list.
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 10);
    verify(
      () => scaffold.repository.calendarEventsEventIdDelete(eventId: 'e-1'),
    ).called(1);
    expect(find.text('Gala de printemps'), findsNothing);
    expect(find.text('No association events'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('a user without associations never reaches the page', (
    tester,
  ) async {
    // The middleware bounce that makes the page's null-association arm dead:
    // no membership means no way in, so `selectedAssociation` is always set
    // while the page is mounted.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    when(() => scaffold.repository.feedNewsGet())
        .thenAnswer((_) async => chopperListResponse(<News>[]));

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/feed/association_events',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);

    expect(QR.currentPath, '/feed');
    expect(find.text('Manage association events'), findsNothing);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('pulling the list reloads the selected association events', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      myAssociations: [Association(name: 'BDE', groupId: 'g-1', id: 'a-1')],
    );
    addTearDown(container.dispose);

    var calls = 0;
    stubEvents(() => calls++);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/feed/association_events',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);
    expect(calls, 1);

    await tester.drag(find.byType(Refresher), const Offset(0, 400));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    expect(calls, greaterThan(1));
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
