import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';
import 'package:titan/tools/ui/styleguide/icon_button.dart';

import '../../shared/app_scaffold.dart';

const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [CoreGroupSimple(name: 'admin', id: adminGroupId)],
);

/// The structures page's two header actions, neither of which the existing
/// structures journey reaches: its pull-to-refresh, and the "+" that opens the
/// create form. The page-shell suite navigates away through a row's Edit
/// action, and qlevar_router 1.12.4 only processes the first mid-test
/// navigation of an isolate, so this lives in its own file.
void main() {
  late IntegrationScaffold scaffold;
  var structuresRequests = 0;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    scaffold.stubAdminMainPage();
    structuresRequests = 0;
  });

  Future<void> pumpStructures(WidgetTester tester) async {
    when(() => scaffold.repository.mypaymentBankAccountHolderGet())
        .thenAnswer((_) async => chopperResponse(Structure.empty()));
    when(() => scaffold.repository.mypaymentStructuresGet())
        .thenAnswer((_) async {
          structuresRequests++;
          return chopperListResponse([
            Structure.empty().copyWith(
              id: 's-1',
              name: 'BDE',
              managerUserId: 'manager-1',
              managerUser: CoreUserSimple.empty().copyWith(
                id: 'manager-1',
                firstname: 'Anne',
                name: 'Martin',
              ),
            ),
          ]);
        });
    when(() => scaffold.repository.membershipsGet()).thenAnswer(
      (_) async => chopperListResponse([
        MembershipSimple.empty().copyWith(id: 'membership-1', name: 'BDE'),
      ]),
    );

    final container = scaffold.makeContainer(user: adminUser);
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/admin/structures',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
    expect(find.text('BDE'), findsOneWidget);
  }

  testWidgets('pulling the structures list refetches it', (tester) async {
    await pumpStructures(tester);
    final before = structuresRequests;

    final refresher = tester.widget<Refresher>(find.byType(Refresher));
    await tester.runAsync(() async {
      await refresher.onRefresh!();
    });
    await settle(tester, frames: 12);

    expect(structuresRequests, before + 1);
    expect(tester.takeException(), isNull);
    await scaffold.unmountApp(tester);
  });

  testWidgets('the plus button opens the create-form route', (tester) async {
    await pumpStructures(tester);

    await tester.tap(find.byType(CustomIconButton).first);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    for (
      var i = 0;
      i < 60 && QR.currentPath != '/admin/structures/add_edit_structure';
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    // The route is the assertion: its body is a deferred library whose first
    // frame never paints under the test clock, so the heading is not checked.
    expect(QR.currentPath, '/admin/structures/add_edit_structure');
    expect(tester.takeException(), isNull);
    await settle(tester, frames: 20);
    await scaffold.unmountApp(tester);
  });
}
