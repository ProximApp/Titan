import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

const adminGroupId = '0a25cb76-4b63-4fd3-b939-da6d9feabf28';

/// The users-management sub-page (`/admin/users_management`): its deferred
/// route builder only runs when the route is entered, and its delete-users
/// sheet carries the "import a list" action whose handler is the empty
/// closure under test here. (The sheet's other button is `disabled: true`:
/// Flutter never calls the `onPressed` of a disabled button, so that closure
/// stays dead by construction.)
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the users page mounts and its import action is live', (
    tester,
  ) async {
    // The admin main page renders under this route too, so its own loads are
    // stubbed the way the /admin deep-link test does.
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
    scaffold.setWideSurface(tester);

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          id: 'user-1',
          groups: [CoreGroupSimple(name: 'admin', id: adminGroupId)],
        ),
      ),
      initialPath: '/admin/users_management',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/admin/users_management');
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // The danger sheet: both actions render, and the import one answers.
    await tester.tap(find.text('Delete'));
    await settle(tester, frames: 16);
    expect(find.text('Delete users'), findsOneWidget);
    expect(find.text('Import a list'), findsOneWidget);

    await tester.tap(find.text('Import a list'));
    await settle(tester, frames: 8);
    expect(tester.takeException(), isNull);
  });
}
