import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  // Allowed side of the gating regression (the bounce is covered by
  // middleware_gating_integration_test.dart): an admin deep link to /admin
  // passes AdminMiddleware and the page mounts directly.
  //
  // qlevar_router 1.12.4 only processes the init-path middleware chain on
  // the first navigation of the isolate, so this file holds exactly one
  // deep-link test (see the purchases test NOTE).
  testWidgets('admin deep link to /admin mounts the page', (tester) async {
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async =>
          chopper.Response(http.Response('body', 200), <CoreGroupSimple>[]),
    );
    when(() => scaffold.repository.mypaymentBankAccountHolderGet()).thenAnswer(
      (_) async =>
          chopper.Response(http.Response('body', 200), Structure.empty()),
    );
    when(() => scaffold.repository.mypaymentStructuresGet()).thenAnswer(
      (_) async => chopper.Response(http.Response('body', 200), <Structure>[]),
    );
    when(() => scaffold.repository.associationsGet()).thenAnswer(
      (_) async =>
          chopper.Response(http.Response('body', 200), <Association>[]),
    );
    when(() => scaffold.repository.membershipsGet()).thenAnswer(
      (_) async =>
          chopper.Response(http.Response('body', 200), <MembershipSimple>[]),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          id: 'user-1',
          groups: [CoreGroupSimple(name: 'admin', id: adminGroupId)],
        ),
      ),
      initialPath: '/admin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 16);

    expect(QR.currentPath, '/admin');
    expect(find.text('Administration'), findsOneWidget);
  });
}
