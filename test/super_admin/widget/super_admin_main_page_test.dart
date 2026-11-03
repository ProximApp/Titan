import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/super_admin/router.dart';
import 'package:titan/super_admin/ui/pages/main_page/main_page.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/route_mock_stub.dart';

/// The super admin landing page is three cards, and only the first of them
/// ("Visibilities") was ever tapped: the permissions integration test walks it
/// into the permissions screen. The other two route callbacks —
/// `/super_admin/schools` and `/super_admin/super_admins` — were dead lines.
///
/// The page is pumped on its own with the router mocked, so all three cards
/// can be tapped in one test: qlevar only guarantees the first mid-test `QR.to`
/// of an isolate, and that budget belongs to the integration files.
void main() {
  late IntegrationScaffold scaffold;
  late RecordingRouteMock mock;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    mock = RecordingRouteMock();
    QR.settings.mockRoute = mock;
  });

  tearDown(() => QR.settings.mockRoute = null);

  testWidgets('every card routes to the screen it names', (tester) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'sa-1', isSuperAdmin: true),
    );
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      const SuperAdminMainPage(),
      container,
      surface: const ui.Size(600, 900),
      appFonts: true,
    );
    await settle(tester, frames: 6);

    for (final label in ['Visibilities', 'Schools', 'Super admins']) {
      expect(find.text(label), findsOneWidget, reason: 'missing $label');
    }

    await tester.tap(find.text('Schools'));
    await settle(tester, frames: 4);
    expect(
      mock.navigated,
      contains('${SuperAdminRouter.root}${SuperAdminRouter.schools}'),
    );

    await tester.tap(find.text('Super admins'));
    await settle(tester, frames: 4);
    expect(
      mock.navigated,
      contains('${SuperAdminRouter.root}${SuperAdminRouter.superAdmins}'),
    );

    await tester.tap(find.text('Visibilities'));
    await settle(tester, frames: 4);
    expect(
      mock.navigated,
      contains('${SuperAdminRouter.root}${SuperAdminRouter.editPermissions}'),
    );

    // Each card routes exactly once: a double push would stack the same screen.
    expect(mock.navigated, hasLength(3));
    expect(tester.takeException(), isNull);
  });
}
