import 'package:flutter_test/flutter_test.dart';
import 'package:titan/ph/router.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('deep link to /ph/admin is bounced for a plain user', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${PhRouter.root}${PhRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester);

    // AdminMiddleware forwards non admins to the feed.
    expect(find.text('No news available'), findsOneWidget);
  });
}
