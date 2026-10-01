import 'package:flutter_test/flutter_test.dart';
import 'package:titan/phonebook/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/phonebook_fixtures.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    phonebookSetUp(scaffold);
  });

  testWidgets('deep link to /phonebook/admin is bounced for a plain user', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${PhonebookRouter.root}${PhonebookRouter.admin}',
      pumpAndSettle: false,
    );
    await settle(tester);

    // AdminMiddleware forwards non admins to the feed.
    expect(find.text('No news available'), findsOneWidget);
  });
}
