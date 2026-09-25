import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/purchases/providers/scanner_provider.dart';
import 'package:titan/purchases/providers/ticket_provider.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';

AppModulesCdrSchemasCdrProductVariantComplete variant() =>
    AppModulesCdrSchemasCdrProductVariantComplete.empty().copyWith(
      id: 'var-1',
      productId: 'prod-1',
      nameFr: 'Demo',
      descriptionFr: 'Description FR',
      descriptionEn: 'Description EN',
    );

AppModulesCdrSchemasCdrTicket myTicket() =>
    AppModulesCdrSchemasCdrTicket.empty().copyWith(
      id: 't-1',
      name: 'Soirée des clubs',
      scanLeft: 9,
      expiration: DateTime(2100),
      productVariant: variant(),
    );

/// The member ticket page in one router-pushing test (convention 19): with
/// a known secret in the scanner notifier the page paints the QR image on
/// its first build (the page watches the notifier OBJECT, so a secret set
/// after mount never rebuilds it — and loadTicketSecret's result is
/// discarded, an app quirk asserted as-is), and a pull-to-refresh
/// re-requests the secret.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the ticket page shows the QR once a secret is known and reloads it on refresh',
    (tester) async {
      when(
        () => scaffold.repository.cdrUsersMeTicketsTicketIdSecretGet(
          ticketId: any(named: 'ticketId'),
        ),
      ).thenAnswer(
        (_) async => chopperResponse(
          TicketSecret.empty().copyWith(qrCodeSecret: 'secret-abc'),
        ),
      );

      final container = scaffold.makeContainer();
      container.read(ticketProvider.notifier).setTicket(myTicket());
      // Known before mount: the page watches the notifier object, so the
      // first build is the only moment the secret can show up.
      container.read(scannerProvider.notifier).setSecret('secret-abc');

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/purchases/ticket',
      );
      await settle(tester, frames: 10);

      expect(find.text('Soirée des clubs'), findsOneWidget);
      expect(find.text('Demo'), findsOneWidget);
      expect(find.text('Description FR'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);

      // Pull to refresh re-requests the secret.
      await tester.drag(find.byType(Refresher), const Offset(0, 1500));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await settle(tester, frames: 8);
      verify(
        () => scaffold.repository.cdrUsersMeTicketsTicketIdSecretGet(
          ticketId: 't-1',
        ),
      ).called(1);
      expect(tester.takeException(), isNull);
    },
  );
}
