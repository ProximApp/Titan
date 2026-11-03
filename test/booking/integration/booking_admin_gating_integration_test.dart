import 'package:flutter_test/flutter_test.dart';
import 'package:titan/booking/router.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('deep link to /booking/admin is bounced for a non admin', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${BookingRouter.root}${BookingRouter.admin}',
      // AdminMiddleware forwards non-admins to the feed, so the bounce IS this
      // file's subject: the foreign-page guard needs to be told (convention 30).
      allowedModules: const {'feed'},
      pumpAndSettle: false,
    );
    await settle(tester);

    expect(find.text('No news available'), findsOneWidget);
  });
}
