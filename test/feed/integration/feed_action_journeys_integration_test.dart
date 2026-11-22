import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/advert/router.dart';
import 'package:titan/feed/ui/pages/main_page/event_action.dart';
import 'package:titan/feed/ui/pages/main_page/event_card.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/navigation/providers/navbar_module_list.dart';
import 'package:titan/tickets/providers/tickets_on_back_provider.dart';
import 'package:titan/tickets/router.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/route_mock_stub.dart';

/// The three arms of `getActionButtonAction` that LEAVE the feed module:
/// `campagne` (vote), `advert` (adverts) and `tickets` (the booking page with
/// its back handler). They are journeys, so each keeps to itself — but they
/// all start on the same page, which is why they share one deep link
/// (convention 10/19).
///
/// The tickets arm is the interesting one: it must (1) register the template's
/// back callback, (2) forward the booking path WITH the event id as a query
/// parameter, (3) push the tickets module onto the navbar list and (4) route
/// to the booking page. Asserting only the route would pass a half-wired
/// implementation, so all four are checked.
///
/// The second test covers the waiting branch of `TimelineItem`, which builds
/// its `waitingTitle` from `getWaitingTitle`: one item per module, because the
/// three l10n strings are three branches of the same helper.
///
/// `news_helper.dart` 240 (`loading: () {}` inside the ticket-url `when`) stays
/// dark and cannot be reached: `getTicketUrl` awaits `load()`, which resolves
/// to data or error and never to `AsyncLoading`, so the callback that the
/// `AsyncValue.when` would invoke for a loading answer has no producer.
News timelineNews({
  required String module,
  required String title,
  String objectId = 'obj-1',
  DateTime? actionStart,
}) => News.empty().copyWith(
  id: 'n-$objectId',
  title: title,
  module: module,
  moduleObjectId: objectId,
  entity: 'BDE',
  start: DateTime.now().add(const Duration(days: 3)),
  end: DateTime.now().add(const Duration(days: 5)),
  actionStart: actionStart ?? DateTime.now().subtract(const Duration(hours: 1)),
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the campaign action routes to the vote module', (tester) async {
    when(() => scaffold.repository.feedNewsGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), [
        timelineNews(module: 'campagne', title: 'Election du BDE'),
      ]),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/feed',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 10);

    // The campaign arm has its own title and button label, both resolved
    // from l10n (`eventActionCampaign*`).
    expect(find.text('You can vote'), findsOneWidget);
    expect(find.text('Vote'), findsOneWidget);

    final navigation = RecordingRouteMock();
    QR.settings.mockRoute = navigation;
    addTearDown(() => QR.settings.mockRoute = null);

    await tester.tap(find.text('Vote'));
    await settle(tester, frames: 8);

    expect(navigation.navigated, contains(VoteRouter.root));
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the tickets action wires the booking journey end to end', (
    tester,
  ) async {
    when(() => scaffold.repository.feedNewsGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), [
        timelineNews(
          module: 'tickets',
          title: 'Concert de fin',
          objectId: 'tk-1',
        ),
      ]),
    );
    when(
      () => scaffold.repository.ticketsEventsEventIdGet(
        eventId: any(named: 'eventId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response(
        http.Response('body', 200),
        EventPublic.empty().copyWith(soldOut: false),
      ),
    );

    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/feed',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 10);

    expect(find.text('Book'), findsOneWidget);

    final navigation = RecordingRouteMock();
    QR.settings.mockRoute = navigation;
    addTearDown(() => QR.settings.mockRoute = null);

    await tester.tap(find.text('Book'));
    await settle(tester, frames: 8);

    // 1. The booking template gets a back handler that returns to the feed.
    expect(container.read(ticketsOnBackProvider), isNotNull);
    // 2. The booking path carries the event the news points at.
    final forwarding = container.read(pathForwardingProvider);
    expect(forwarding.path, TicketsRouter.root + TicketsRouter.book);
    expect(forwarding.queryParameters, {'ticketEventId': 'tk-1'});
    // 3. The tickets module joins the navbar so the user can come back.
    expect(
      container.read(navbarListModuleProvider).map((module) => module.root),
      contains(TicketsRouter.root),
    );
    // 4. And the router is actually asked for the booking page.
    expect(
      navigation.navigated,
      contains(TicketsRouter.root + TicketsRouter.book),
    );

    // The registered back callback is the feed's own: calling it forwards and
    // routes home instead of popping the tickets stack.
    container.read(ticketsOnBackProvider)!();
    await settle(tester, frames: 4);
    expect(navigation.navigated.last, '/feed');

    await scaffold.unmountApp(tester);
  });

  testWidgets('the advert banner opens the advert module', (tester) async {
    when(() => scaffold.repository.feedNewsGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), [
        timelineNews(module: 'advert', title: 'Promo du BDE'),
      ]),
    );

    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/feed',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 10);

    final navigation = RecordingRouteMock();
    QR.settings.mockRoute = navigation;
    addTearDown(() => QR.settings.mockRoute = null);

    // The banner's own GestureDetector forwards the advert path — the feed
    // timeline is where the user discovers the promotion. The title text sits
    // OUTSIDE that detector (TimelineItem) and is inert, so the press goes to
    // the banner itself.
    await tester.tap(find.byType(EventCard).first);
    await settle(tester, frames: 8);
    expect(container.read(pathForwardingProvider).path, AdvertRouter.root);
    expect(navigation.navigated, contains(AdvertRouter.root));
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('the advert action button opens the advert module', (
    tester,
  ) async {
    when(() => scaffold.repository.feedNewsGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), [
        timelineNews(module: 'advert', title: 'Promo du BDE'),
      ]),
    );

    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/feed',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 10);

    final navigation = RecordingRouteMock();
    QR.settings.mockRoute = navigation;
    addTearDown(() => QR.settings.mockRoute = null);

    // The advert module has no action labels (`getActionTitle` and
    // `getAction*ButtonText` answer ''), so the press is aimed at the button
    // block on the right of the row — after scrolling it into view, since the
    // banner above it is taller than the 600px test surface.
    await tester.ensureVisible(find.byType(EventAction));
    await settle(tester, frames: 4);
    final row = tester.getRect(find.byType(EventAction));
    await tester.tapAt(Offset(row.right - 50, row.center.dy));
    await settle(tester, frames: 8);

    expect(navigation.navigated, contains(AdvertRouter.root));
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });

  testWidgets('a future action window shows each module waiting title', (
    tester,
  ) async {
    final inTwoDays = DateTime.now().add(const Duration(days: 2));
    when(() => scaffold.repository.feedNewsGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), [
        timelineNews(
          module: 'campagne',
          title: 'Election du BDE',
          objectId: 'c-1',
          actionStart: inTwoDays,
        ),
        timelineNews(
          module: 'event',
          title: 'Soiree des clubs',
          objectId: 'e-1',
          actionStart: inTwoDays,
        ),
        timelineNews(
          module: 'tickets',
          title: 'Concert de fin',
          objectId: 't-1',
          actionStart: inTwoDays,
        ),
      ]),
    );
    when(
      () => scaffold.repository.ticketsEventsEventIdGet(
        eventId: any(named: 'eventId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response(
        http.Response('body', 200),
        EventPublic.empty().copyWith(soldOut: false),
      ),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/feed',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 10);

    // `EventAction` swaps the title for the shared "Get ready!" line and
    // renders `waitingTitle(timeToGo)` underneath, which is `getWaitingTitle`:
    // one string per module.
    expect(find.text('Get ready!'), findsNWidgets(3));
    expect(find.textContaining('Vote in'), findsOneWidget);
    expect(find.textContaining('Shotgun in'), findsOneWidget);
    expect(find.textContaining('Opens'), findsOneWidget);
    // The buttons keep their labels; only the press is refused while the
    // window is closed (`isActionEnabled` needs `timeOpening` in the past, so
    // the tap never reaches `getActionButtonAction`).
    expect(find.text('Vote'), findsOneWidget);
    expect(find.text('Reserve'), findsOneWidget);
    expect(find.text('Book'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
