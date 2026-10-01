import 'package:flutter_test/flutter_test.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('deep link to /vote/admin is bounced for a plain user', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${VoteRouter.root}${VoteRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester);

    // AdminMiddleware forwards non admins to the feed.
    expect(find.text('No news available'), findsOneWidget);
  });
}
