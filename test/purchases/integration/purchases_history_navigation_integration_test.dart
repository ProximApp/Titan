import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';
import '../purchases_fixtures.dart';

/// The main page's History button: it pushes the history route, which then
/// loads the member's purchases. The history page itself has its own file;
/// this is the one navigation into it from the main page.
///
/// Own file because the tap navigates mid-test and qlevar honours only the
/// isolate's first such push.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the History button opens the purchases history', (tester) async {
    when(() => scaffold.repository.cdrUsersMeTicketsGet()).thenAnswer(
      (_) async =>
          chopperListResponse<AppModulesCdrSchemasCdrTicket>([myTicket()]),
    );
    when(() => scaffold.repository.cdrMePurchasesGet()).thenAnswer(
      (_) async => chopperListResponse<PurchaseReturn>(<PurchaseReturn>[]),
    );

    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpApp(tester, container, initialPath: '/purchases');
    await settle(tester);

    await tester.tap(find.text('History'));
    await settle(tester, frames: 16);

    expect(QR.currentPath, '/purchases/history');
    // The page mounted and answered its purchases call.
    verify(() => scaffold.repository.cdrMePurchasesGet()).called(1);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
