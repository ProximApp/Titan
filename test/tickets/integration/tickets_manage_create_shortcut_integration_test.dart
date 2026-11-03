import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';
import '../tickets_fixtures.dart';

/// The manage page's create shortcut: the "+" in the header.
///
/// The page is otherwise covered (store picker, list, empty state, refresh),
/// but the header button — the only route into `/tickets/create` from this
/// screen — was never pressed, so its navigation was unverified.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the header plus opens the ticketing creation page', (
    tester,
  ) async {
    when(() => scaffold.repository.ticketsEventsGet()).thenAnswer(
      (_) async => chopperListResponse<EventSimple>(<EventSimple>[]),
    );
    final container = scaffold.makeContainer(
      user: models.CoreUser.empty().copyWith(id: 'me'),
      myStores: [models.UserStore.empty().copyWith(id: 'store-1', name: 'BDE')],
      storeSellers: {
        'store-1': [
          Seller.empty().copyWith(userId: 'me', canManageEvents: true),
        ],
      },
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/manage',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 20);
    // The header shortcut is the page's only entry point into creation.
    expect(find.byTooltip('New ticketing'), findsOneWidget);

    await tester.tap(find.byTooltip('New ticketing'));
    await settle(tester, frames: 20);

    // The create route is behind the same admin gate, so arriving there also
    // proves the seller's manage right travels with the navigation.
    expect(QR.currentPath, '/tickets/create');
    expect(tester.takeException(), isNull);
  });
}
