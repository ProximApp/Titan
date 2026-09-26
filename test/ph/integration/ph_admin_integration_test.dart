import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/ph/router.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/fixtures.dart';

/// The ph admin gate is a plain Provider over userProvider.groups, so the
/// signed-in user carries the admin_ph group id.

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /ph/admin lists the journals for the admin_ph group',
    (tester) async {
      final container = scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          groups: [
            CoreGroupSimple.empty().copyWith(
              id: adminPhGroupId,
              name: 'admin_ph',
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      scaffold.setWideSurface(tester);
      when(() => scaffold.repository.phGet()).thenAnswer(
        (_) async =>
            chopperListResponse([paperFixture('p1', 'Journal 2026', 2026)]),
      );

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '${PhRouter.root}${PhRouter.admin}',
        pumpAndSettle: false,
      );
      await settle(tester);

      // The admin list renders the card for the current year's journal plus
      // the add button.
      expect(find.text('Journal 2026'), findsOneWidget);
      expect(find.textContaining('March'), findsOneWidget);
      expect(find.text('Add a new journal'), findsOneWidget);
    },
  );
}
