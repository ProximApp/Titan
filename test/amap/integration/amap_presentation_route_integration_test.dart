import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/amap/router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../amap_fixtures.dart';

/// The presentation route, reachable two ways: the info button the amap
/// template shows only at the module root, and its own deep link.
///
/// The tap test runs FIRST: qlevar_router 1.12.4 silently drops the first
/// mid-test QR.to() to a route that is not yet mounted once an earlier test
/// ran in the same isolate.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the info icon at the module root opens the presentation', (
    tester,
  ) async {
    stubAdminLoads(scaffold);
    when(
      () => scaffold.repository.amapUsersUserIdCashGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => chopperResponse(cash(0)));
    when(
      () => scaffold.repository.amapUsersUserIdOrdersGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => chopperListResponse(const <OrderReturn>[]));

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: AmapRouter.root,
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.informationCircle,
      ),
    );
    for (
      var i = 0;
      i < 20 && !QR.currentPath.contains(AmapRouter.presentation);
      i++
    ) {
      await settle(tester, frames: 4);
    }

    expect(QR.currentPath, contains(AmapRouter.presentation));
    expect(tester.takeException(), isNull);
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
