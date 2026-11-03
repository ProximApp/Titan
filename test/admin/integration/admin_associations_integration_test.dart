import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [CoreGroupSimple(name: 'admin', id: adminGroupId)],
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    // Stubbed for the admin main page mounted underneath the sub-page.
    scaffold.stubAdminMainPage();
    when(() => scaffold.repository.mypaymentStructuresGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), <Structure>[]),
    );
    when(() => scaffold.repository.membershipsGet()).thenAnswer(
      (_) async =>
          chopper.Response(http.Response('body', 200), <MembershipSimple>[]),
    );
  });

  // Deep link to the associations sub-page. qlevar_router 1.12.4 only
  // processes the init-path middleware chain on the first navigation of the
  // isolate, so every sub-page shell lives in its own file with a single
  // deep-link test (see the purchases test NOTE).
  testWidgets('associations page renders its section', (tester) async {
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: adminUser),
      initialPath: '/admin/association',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/admin/association');
    expect(find.text('Associations'), findsWidgets);
  });
}
