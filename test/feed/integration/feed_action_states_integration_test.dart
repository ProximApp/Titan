import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The timeline's action button in its two non-navigating states: the
/// `event` arm of `getActionButtonAction` (ticket-url fetch → launch, launch
/// refused, fetch failed — all three arms of its `when`), and a sold-out
/// ticket item, whose `isDisabled` flag greys the button out so the press
/// never reaches the dispatcher at all.
///
/// The `campagne` / `advert` / `tickets` arms of the same dispatcher each
/// navigate to another module, so they live in their own journey files
/// (convention 10). Every test here deep-links the SAME path.
const urlChannel = MethodChannel('plugins.flutter.io/url_launcher');

News timelineNews({
  required String module,
  required String title,
  String objectId = 'obj-1',
}) => News.empty().copyWith(
  id: 'n-$objectId',
  title: title,
  module: module,
  moduleObjectId: objectId,
  entity: 'BDE',
  start: DateTime.now().add(const Duration(days: 3)),
  end: DateTime.now().add(const Duration(days: 5)),
  // The action window is open: `timeOpening` in the past, `end` in the
  // future — exactly what `isActionEnabled` demands.
  actionStart: DateTime.now().subtract(const Duration(hours: 1)),
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the event action launches, refuses and reports a dead url', (
    tester,
  ) async {
    when(() => scaffold.repository.feedNewsGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), [
        timelineNews(module: 'event', title: 'Soirée des clubs'),
      ]),
    );
    when(
      () => scaffold.repository.calendarEventsEventIdTicketUrlGet(
        eventId: any(named: 'eventId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response(
        http.Response('body', 200),
        EventTicketUrl.empty().copyWith(
          ticketUrl: 'https://tickets.test/checkout',
        ),
      ),
    );

    var canLaunch = true;
    final launched = <String>[];
    final binding = TestDefaultBinaryMessengerBinding.instance;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(urlChannel, (
      call,
    ) async {
      if (call.method == 'canLaunch') return canLaunch;
      if (call.method == 'launch') {
        final args = Map<String, Object?>.from(call.arguments as Map);
        launched.add(args['url'] as String);
        return true;
      }
      return false;
    });
    addTearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        urlChannel,
        null,
      ),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/feed',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 10);
    expect(find.text('Reserve'), findsOneWidget);

    // Arm 1: url fetch succeeds, the launcher takes it.
    await tester.tap(find.text('Reserve'));
    await settle(tester, frames: 8);
    verify(
      () => scaffold.repository.calendarEventsEventIdTicketUrlGet(
        eventId: any(named: 'eventId'),
      ),
    ).called(1);
    expect(launched, ['https://tickets.test/checkout']);

    // Arm 2: the fetch succeeds but the platform refuses to open it.
    canLaunch = false;
    await tester.tap(find.text('Reserve'));
    await settle(tester, frames: 8);
    verify(
      () => scaffold.repository.calendarEventsEventIdTicketUrlGet(
        eventId: any(named: 'eventId'),
      ),
    ).called(1);
    expect(launched, hasLength(1), reason: 'the refused launch never ran');
    // Clear the failure toast so it cannot swallow the next press.
    await scaffold.drainToast(tester);

    // Arm 3: the fetch itself fails → the error arm.
    when(
      () => scaffold.repository.calendarEventsEventIdTicketUrlGet(
        eventId: any(named: 'eventId'),
      ),
    ).thenAnswer((_) async => scaffold.repository.fail<EventTicketUrl>(500));
    await tester.tap(find.text('Reserve'));
    await settle(tester, frames: 8);
    verify(
      () => scaffold.repository.calendarEventsEventIdTicketUrlGet(
        eventId: any(named: 'eventId'),
      ),
    ).called(1);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
    await scaffold.drainToast(tester);
  });

  testWidgets('a sold-out ticket action shows its disabled label', (
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
        EventPublic.empty().copyWith(soldOut: true),
      ),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/feed',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 10);

    // isSoldOut → disabled label instead of "Book", and `isDisabled` keeps
    // the press from reaching getActionButtonAction.
    expect(find.text('Sold out'), findsOneWidget);
    expect(find.text('Book'), findsNothing);

    await tester.tap(find.text('Sold out'));
    await settle(tester, frames: 6);
    expect(QR.currentPath, '/feed');
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
