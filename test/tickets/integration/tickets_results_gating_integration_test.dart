import 'package:flutter_test/flutter_test.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /tickets/results for a non seller is bounced away',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/tickets/results',
        pumpAndSettle: false,
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      // AdminMiddleware forwards non-sellers to the feed page.
      expect(find.text('No news available'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
    },
  );
}
