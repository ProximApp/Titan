import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';
import '../raffle_fixtures.dart';

/// The raffle main page's two statuses that belong to no section: a raffle
/// whose status the backend left null, and one it answered with the
/// generated "unknown enum value". Both must fall through the switch and
/// leave the page on its single empty line instead of rendering a card.
///
/// Own file for the deep-link rule (convention 11): `/tombola` is this
/// isolate's only deep link.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('a raffle with an unknown or missing status lands in no section', (
    tester,
  ) async {
    when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
      (_) async => chopperListResponse([
        raffleFixture('r-null', 'Statut nul', null),
        raffleFixture(
          'r-unknown',
          'Statut inconnu',
          RaffleStatusType.swaggerGeneratedUnknown,
        ),
      ]),
    );
    when(
      () => scaffold.repository.tombolaUsersUserIdTicketsGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer(
      (_) async =>
          chopperListResponse(<AppModulesRaffleSchemasRaffleTicketComplete>[]),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
      initialPath: '/tombola',
      pumpAndSettle: false,
    );
    for (
      var i = 0;
      i < 40 && find.text('There is no ongoing raffle').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(
      find.text('Statut nul'),
      findsNothing,
      reason: 'visible: ${visibleTexts(tester)}',
    );
    expect(find.text('Statut inconnu'), findsNothing);
    expect(find.text('There is no ongoing raffle'), findsOneWidget);
  });
}
