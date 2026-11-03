import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/rendered_path_provider.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// Ledger #7: qlevar's `QR.currentPath` reports the path that was ASKED
/// for while a redirect is still resolving, and notifies nobody when it
/// finally changes — so a widget reading it once in `build` keeps whatever
/// that frame happened to report. `renderedPathProvider` is fed by qlevar's
/// navigation observer instead and is what every lib decision now watches.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'the tracked path follows the REDIRECT the user actually landed on',
    (tester) async {
      when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
        (_) async =>
            chopper.Response(http.Response('body', 200), <RaffleComplete>[]),
      );
      when(
        () => scaffold.repository.tombolaUsersUserIdTicketsGet(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(
          http.Response('body', 200),
          <AppModulesRaffleSchemasRaffleTicketComplete>[],
        ),
      );

      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
      );
      addTearDown(container.dispose);

      await scaffold.pumpApp(
        tester,
        container,
        // The gated deep link bounces to /feed — the path this test asked
        // for is deliberately NOT the path that ends up rendered.
        initialPath: '/tombola/detail',
        allowedModules: const {'feed', 'raffle'},
        pumpAndSettle: false,
      );
      await settle(tester, frames: 40);

      // The rendered page and the tracked path agree on the bounce target.
      expect(find.text('No news available'), findsOneWidget);
      expect(container.read(renderedPathProvider), '/feed');
      expect(QR.currentPath, '/feed');

      // TopBar's conditional (hide the back chevron at the module root)
      // reads the same provider, so it agrees with what is on screen.
      expect(
        find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.chevronLeft,
        ),
        findsNothing,
      );
    },
  );
}
