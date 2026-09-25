import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/super_admin/router.dart';
import 'package:titan/super_admin/ui/pages/main_page/main_page.dart';
import 'package:titan/super_admin/ui/pages/permissions/permission_detail_modal.dart';
import 'package:titan/super_admin/ui/pages/permissions/permission_row.dart';
import 'package:titan/super_admin/ui/pages/permissions/permission_tile.dart';
import 'package:titan/super_admin/ui/pages/permissions/permissions.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The super admin main page and the permissions screen it routes to, in one
/// walk: qlevar's init-path rule only bites on a second, DIFFERENT deep link,
/// and convention 2 drops the first mid-test `QR.to` only when an earlier
/// test already ran in the isolate — so the navigation test owns this file's
/// first slot and the module-l10n test afterwards never navigates.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Finder rowIcon(String label, HeroIcons icon) => find.descendant(
    of: find.ancestor(
      of: find.text(label),
      matching: find.byType(PermissionRow),
    ),
    matching: find.byWidgetPredicate(
      (w) => w is HeroIcon && w.icon == icon,
      description: 'HeroIcon($icon)',
    ),
  );

  testWidgets('the main page routes to permissions, whose rows toggle', (
    tester,
  ) async {
    when(() => scaffold.repository.permissionsListGet())
        .thenAnswer((_) async => scaffold.repository.ok(['core.admin']));
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => scaffold.repository.ok([
        CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'BDE'),
        CoreGroupSimple.empty().copyWith(id: 'g-2', name: 'Coloc'),
      ]),
    );
    when(() => scaffold.repository.usersAccountTypesGet())
        .thenAnswer((_) async => scaffold.repository.ok(['student', 'staff']));
    when(
      () => scaffold.repository.permissionsPost(body: any(named: 'body')),
    ).thenAnswer((_) async => scaffold.repository.ok(CorePermission.empty()));
    when(
      () => scaffold.repository.permissionsDelete(body: any(named: 'body')),
    ).thenAnswer((_) async => scaffold.repository.ok(CorePermission.empty()));

    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'sa-1', isSuperAdmin: true),
      // The catalog is token-gated in the real notifier and the harness
      // carries no token; pre-seeding it is makeContainer's documented seam.
      permissionCatalog: ['core.admin'],
      groups: [
        CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'BDE'),
        CoreGroupSimple.empty().copyWith(id: 'g-2', name: 'Coloc'),
      ],
      permissions: [
        CorePermission.empty().copyWith(
          permissionName: 'core.admin',
          groups: ['g-1'],
          accountTypes: [enums.AccountType.student],
        ),
      ],
    );
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/super_admin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/super_admin');
    expect(find.byType(SuperAdminMainPage), findsOneWidget);
    expect(find.text('Visibilities'), findsOneWidget);
    expect(find.text('Schools'), findsOneWidget);
    expect(find.text('Super admins'), findsOneWidget);

    // First (and only) mid-test navigation of this isolate.
    await tester.tap(find.text('Visibilities'));
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/super_admin/edit_permissions');
    expect(find.byType(PermissionsPage), findsOneWidget);
    // Twice: the page heading and the search bar's hint text.
    expect(find.text('Modify permissions'), findsWidgets);
    expect(find.text('core'), findsOneWidget);
    expect(find.byType(PermissionTile), findsOneWidget);

    // The tile opens the detail modal with the seeded groups and types.
    await tester.tap(find.byType(PermissionTile));
    await settle(tester, frames: 16);

    expect(find.byType(PermissionDetailModal), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('Coloc'), findsOneWidget);
    expect(find.byType(PermissionRow), findsNWidgets(4));

    // Coloc is unauthorized (X icon): authorizing posts the grant and flips
    // the row to the check icon. ensureVisible first — the sheet's group
    // section sits below the fold at the default surface.
    final colocAuthorize = rowIcon('Coloc', HeroIcons.xMark);
    await tester.ensureVisible(colocAuthorize);
    await tester.pump();
    await tester.tap(colocAuthorize);
    await settle(tester, frames: 8);
    expect(find.byType(PermissionDetailModal), findsOneWidget);
    expect(rowIcon('Coloc', HeroIcons.check), findsOneWidget);
    verify(() => scaffold.repository.permissionsPost(body: any(named: 'body')))
        .called(1);

    // BDE is authorized (check icon): unauthorizing posts the removal and
    // flips it back to the X.
    final bdeUnauthorize = rowIcon('BDE', HeroIcons.check);
    await tester.ensureVisible(bdeUnauthorize);
    await tester.pump();
    await tester.tap(bdeUnauthorize);
    await settle(tester, frames: 8);
    expect(rowIcon('BDE', HeroIcons.xMark), findsOneWidget);
    verify(
      () => scaffold.repository.permissionsDelete(body: any(named: 'body')),
    ).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the module exposes its name and description', (tester) async {
    String? name;
    String? description;
    await pumpWidgetAt(
      tester,
      Builder(
        builder: (context) {
          name = SuperAdminRouter.module.getName(context);
          description = SuperAdminRouter.module.getDescription(context);
          return const SizedBox();
        },
      ),
    );

    expect(name, 'Super Admin');
    expect(description, 'Super Admin');
    expect(tester.takeException(), isNull);
  });
}
