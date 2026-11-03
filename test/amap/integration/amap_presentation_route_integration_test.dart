import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/amap/router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';

import '../../shared/app_scaffold.dart';
import '../amap_fixtures.dart';

/// The presentation route, which no other test reaches (it is only addressable
/// by its deep link).
///
/// NOTE: the admin page's own pull-to-refresh (`admin_page.dart` onRefresh) is
/// not exercised: the three handlers fit the test surface, so the page never
/// scrolls and the sliver refresh control cannot be armed by a drag.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the presentation route mounts from its deep link', (
    tester,
  ) async {
    stubAdminLoads(scaffold);
    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '${AmapRouter.root}${AmapRouter.presentation}',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    // The deferred route resolves and renders without throwing.
    expect(QR.currentPath, contains(AmapRouter.presentation));
    expect(tester.takeException(), isNull);
  });
}
