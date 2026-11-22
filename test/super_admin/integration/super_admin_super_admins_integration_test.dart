import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/super_admin/ui/pages/super_admins_page/super_admins_page.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('searching a user opens the promote confirm dialog', (
    tester,
  ) async {
    when(() => scaffold.repository.usersSearchGet(query: any(named: 'query')))
        .thenAnswer(
          (_) async => scaffold.repository.ok([
            CoreUserSimple.empty().copyWith(
              id: 'u1',
              firstname: 'John',
              name: 'Doe',
            ),
            CoreUserSimple.empty().copyWith(
              id: 'u2',
              firstname: 'Jane',
              name: 'Roe',
            ),
          ]),
        );
    // The dialog reads the FULL user to decide promote vs demote, so the two
    // rows must answer differently.
    when(() => scaffold.repository.usersUserIdGet(userId: any(named: 'userId')))
        .thenAnswer(
          (_) async => chopper.Response(
            http.Response('body', 200),
            CoreUser.empty().copyWith(id: 'u1', isSuperAdmin: false),
          ),
        );
    when(() => scaffold.repository.usersUserIdGet(userId: 'u2')).thenAnswer(
      (_) async => chopper.Response(
        http.Response('body', 200),
        CoreUser.empty().copyWith(id: 'u2', isSuperAdmin: true),
      ),
    );
    // The first patch succeeds, the second is rejected: both toast arms.
    var patches = 0;
    when(
      () => scaffold.repository.usersUserIdSuperAdminPatch(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async {
      patches++;
      return patches == 1
          ? chopper.Response<void>(http.Response('body', 200), null)
          : chopper.Response<void>(
              http.Response('nope', 400),
              null,
              error: 'Bad request',
            );
    });

    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'sa-1', isSuperAdmin: true),
    );
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/super_admin/super_admins',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/super_admin/super_admins');
    expect(find.byType(SuperAdminsPage), findsOneWidget);
    expect(find.text('Super admins'), findsWidgets);
    // Empty state before any query: the hint doubles as the heading text.
    expect(find.text('Search a user to promote'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'john');
    await settle(tester, frames: 12);
    expect(find.text('John Doe'), findsOneWidget);

    await tester.tap(find.text('John Doe'));
    await settle(tester, frames: 12);
    expect(find.byType(CustomDialogBox), findsOneWidget);
    expect(find.text('Make super admin'), findsOneWidget);

    // Confirming runs the whole chain: the dialog pops, the PATCH lands and the
    // success toast follows. This used to throw before the frame finished —
    // the page's dispose effect wrote userList from the unmount phase, which
    // riverpod rejects — so the write now leaves the build phase first.
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 12);

    expect(find.byType(CustomDialogBox), findsNothing);
    verify(() => scaffold.repository.usersUserIdSuperAdminPatch(userId: 'u1'))
        .called(1);
    expect(find.text('Super admin status updated'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Jane is already a super admin, so the same gesture has to offer the
    // OPPOSITE action — and its failure arm has to say so instead of staying
    // silent while the server refused.
    await tester.tap(find.text('Jane Roe'));
    await settle(tester, frames: 12);
    expect(find.text('Remove super admin'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 12);

    expect(find.byType(CustomDialogBox), findsNothing);
    verify(() => scaffold.repository.usersUserIdSuperAdminPatch(userId: 'u2'))
        .called(1);
    expect(find.text('Failed to update super admin status'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Emptying the query resets the list rather than leaving the last results
    // on screen under an empty field.
    await tester.enterText(find.byType(TextField), '');
    await settle(tester, frames: 12);
    expect(find.text('John Doe'), findsNothing);
    expect(find.text('Jane Roe'), findsNothing);
    expect(find.text('Search a user to promote'), findsWidgets);

    // The toasts hold auto-close timers; expire them before the test ends.
    await tester.pump(const Duration(seconds: 8));
    expect(tester.takeException(), isNull);
  });
}
