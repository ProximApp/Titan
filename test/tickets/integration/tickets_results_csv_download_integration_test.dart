import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/providers/selected_ticket_event_provider.dart';

import '../../shared/app_scaffold.dart';
import '../tickets_fixtures.dart';

/// The results page's CSV export against an event whose export CAN be
/// fetched: the bytes go to the save dialog and the page announces the save.
///
/// `downloadFile` picks `saveAs` on macOS and calls it through a pigeon
/// channel, so answering that channel is the seam — the real routing and the
/// real name/extension/mime hand-off run, only the plugin's reply is
/// replaced. (The failing half lives in `tickets_results_integration_test.dart`.)
///
/// A file of its own: the success toast is the subject, and the shell's
/// overlay paints the first toast a file raises.
final csvBytes = Uint8List.fromList('name,email\nAda,ada@x.fr\n'.codeUnits);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubResults() {
    when(() => scaffold.repository.ticketsAdminEventsEventIdGet(eventId: 'e-1'))
        .thenAnswer(
          (_) async => chopper.Response(
            http.Response('{}', 200),
            models.EventAdmin.empty().copyWith(
              id: 'e-1',
              name: 'Gala',
              ticketsSold: 5,
              ticketsInCheckout: 2,
              quota: 50,
            ),
          ),
        );
    when(
      () => scaffold.repository.ticketsAdminEventsEventIdTicketsGet(
        eventId: 'e-1',
      ),
    ).thenAnswer(
      (_) async =>
          chopperListResponse(<models.AppCoreTicketsSchemasTicketsTicket>[]),
    );
  }

  testWidgets('a fetched csv is handed to the save dialog and announced', (
    tester,
  ) async {
    final container = sellerContainer(scaffold);
    addTearDown(container.dispose);
    stubResults();
    scaffold.setWideSurface(tester);
    container.read(selectedTicketEventIdProvider.notifier).setId('e-1');

    when(
      () => scaffold.repository.ticketsAdminEventsEventIdTicketsCsvGet(
        eventId: 'e-1',
      ),
    ).thenAnswer(
      (_) async => chopper.Response<List<int>>(
        http.Response.bytes(csvBytes, 200),
        csvBytes,
      ),
    );

    const saveAsChannel =
        'dev.flutter.pigeon.file_saver.FileSaverHostApi.saveAs';
    var saveCalls = 0;
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(saveAsChannel, (
      message,
    ) async {
      saveCalls++;
      return const StandardMessageCodec().encodeMessage(<Object?>[
        '/tmp/Gala_tickets.csv',
      ]);
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        saveAsChannel,
        null,
      ),
    );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/results',
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('View results - Gala'), findsOneWidget);
    await tester.tap(find.text('Download CSV'));
    await settle(tester, frames: 20);

    // The export reached the save dialog exactly once, and only after the
    // bytes came back from the event endpoint.
    expect(saveCalls, 1);
    verify(
      () => scaffold.repository.ticketsAdminEventsEventIdTicketsCsvGet(
        eventId: 'e-1',
      ),
    ).called(1);
    expect(find.text('CSV downloaded successfully'), findsOneWidget);
    await scaffold.drainToast(tester);
    expect(tester.takeException(), isNull);
  });
}
