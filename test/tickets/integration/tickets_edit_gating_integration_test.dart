import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// The admin gate on the tickets edit route
/// (AdminMiddleware(canManageTicketEventsProvider)) in isolation.
///
/// This lives in its own file because the bounce is only observable on a
/// file's FIRST deep link: qlevar skips the middleware when the router is
/// already on the target path, and a redirect to /feed wedges the next
/// different-path deep link in the same file (see tickets_edit_integration_test).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the admin gate bounces users without manage rights', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      user: models.CoreUser.empty().copyWith(id: 'me'),
      myStores: [models.UserStore.empty().copyWith(id: 'store-1', name: 'BDE')],
      storeSellers: {
        'store-1': [
          Seller.empty().copyWith(userId: 'me', canManageEvents: false),
        ],
      },
    );

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tickets/edit',
      // AdminMiddleware forwards sellers without canManageEvents to the feed, so the bounce IS this
      // file's subject: the foreign-page guard needs to be told (convention 30).
      allowedModules: const {'feed'},
      pumpAndSettle: false,
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    // AdminMiddleware forwards sellers without canManageEvents to the feed.
    expect(find.text('No news available'), findsOneWidget);
    expect(find.textContaining('Edit ticketing'), findsNothing);
  });
}
