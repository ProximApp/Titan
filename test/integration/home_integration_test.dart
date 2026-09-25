import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/generated/openapi.swagger.dart';

import 'app_scaffold.dart';

Future<void> settle(WidgetTester tester, {int frames = 8}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

EventCompleteTicketUrl upcomingEvent(String id, String name) {
  final start = DateTime.now().add(const Duration(days: 2));
  return EventCompleteTicketUrl.empty().copyWith(
    id: id,
    name: name,
    start: start,
    end: start.add(const Duration(hours: 2)),
    location: 'Amphi',
    association: Association.empty().copyWith(name: 'BDE'),
  );
}

AppModulesCdrSchemasCdrTicket usableTicket(String id) =>
    AppModulesCdrSchemasCdrTicket.empty().copyWith(
      id: id,
      name: 'Soirée des clubs',
      scanLeft: 1,
      expiration: DateTime(2100),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IntegrationScaffold scaffold;

  setUp(() {
    QR.reset();
    SharedPreferences.setMockInitialValues({});
    scaffold = IntegrationScaffold();
    scaffold.stubInformation();
    // The middleware redirect chain lands on /feed before reaching the page
    // under test, so the feed endpoints must be stubbed here as well.
    when(
      () => scaffold.repository.feedNewsNewsIdImageGet(
        newsId: any(named: 'newsId'),
      ),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response('{"detail": "File does not exist"}', 404),
        [],
        error: 'File does not exist',
      ),
    );
    when(() => scaffold.repository.feedNewsGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), <News>[]),
    );
  });

  group('Home (calendar) page', () {
    testWidgets('shows upcoming events grouped by day', (tester) async {
      when(() => scaffold.repository.calendarEventsConfirmedGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), [
          upcomingEvent('e-1', 'Gala'),
        ]),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/home',
      );
      await settle(tester, frames: 12);

      expect(find.text('Gala'), findsOneWidget);
      // The card shows the location and the association name.
      expect(find.text('Amphi'), findsOneWidget);
      expect(find.text('BDE'), findsOneWidget);
    });

    testWidgets('shows the empty state without events', (tester) async {
      when(() => scaffold.repository.calendarEventsConfirmedGet()).thenAnswer(
        (_) async => chopper.Response(
          http.Response('body', 200),
          <EventCompleteTicketUrl>[],
        ),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/home',
      );
      await settle(tester, frames: 12);

      expect(find.text('No events'), findsOneWidget);
    });
  });
}
