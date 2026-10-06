import 'dart:ui' as ui;

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/super_admin/tools/constants.dart';
import 'package:titan/super_admin/ui/components/admin_button.dart';
import 'package:titan/super_admin/ui/components/text_editing.dart';
import 'package:titan/super_admin/ui/pages/permissions/permission_detail_modal.dart';
import 'package:titan/super_admin/ui/pages/permissions/permission_row.dart';
import 'package:titan/super_admin/ui/pages/permissions/permission_tile.dart';
import 'package:titan/super_admin/ui/pages/schools/school_page/school_button.dart';
import 'package:titan/super_admin/ui/pages/schools/school_page/school_ui.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// super_admin's leaf widgets, at phone width.
///
/// The module had no `widget/` directory at all: 34.3% covered, with the
/// permissions screen (the module's reason to exist) only reachable through
/// `SuperAdminTemplate` -> `TopBar` -> `QR.currentPath`, which is
/// process-global state and so cannot be mounted twice in one file. These are
/// the widgets underneath that shell, and none of them reads the router, so
/// all of them mount through `pumpWidgetApp`.
///
/// `PermissionDetailModal` is the one worth the trouble: it is 193 lines of
/// the permissions flow, and its two interesting behaviours are both in the
/// wiring rather than the layout - a `permission_name` arrives module-prefixed
/// (`core.admin`) from the server and the modal has to find it by its bare
/// name, and a failed write has to surface as a snackbar instead of a
/// silently ignored tap.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Finder heroIcon(HeroIcons icon) => find.byWidgetPredicate(
    (w) => w is HeroIcon && w.icon == icon,
    description: 'HeroIcon($icon)',
  );

  const longLabel =
      'Association des étudiants en medecine de l universite de bordeaux';

  /// `permissionsProvider` reads through the real `PermissionsNotifier`, whose
  /// `build()` calls `permissionsGet` when the session is signed in - which the
  /// harness always is. Seeding the endpoint is how the modal's map gets its
  /// entries without an override, and it is also what the authorize taps post
  /// against.
  void stubPermissions({
    List<CorePermission> permissions = const [],
    bool writesSucceed = true,
  }) {
    when(
      () => scaffold.repository.permissionsGet(),
    ).thenAnswer((_) async => chopperListResponse(permissions));
    chopper.Response<CorePermission> write() => writesSucceed
        ? chopper.Response(http.Response('{}', 200), CorePermission.empty())
        : chopper.Response(
            http.Response('nope', 400),
            CorePermission.empty(),
            error: 'Bad request',
          );
    when(
      () => scaffold.repository.permissionsPost(body: any(named: 'body')),
    ).thenAnswer((_) async => write());
    when(
      () => scaffold.repository.permissionsDelete(body: any(named: 'body')),
    ).thenAnswer((_) async => write());
  }

  CorePermission permission({
    String name = 'admin',
    List<String> groups = const [],
    List<enums.AccountType> types = const [],
  }) =>
      CorePermission(permissionName: name, groups: groups, accountTypes: types);

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget child, {
    ui.Size surface = const ui.Size(360, 640),
    List<CorePermission> permissions = const [],
    bool writesSucceed = true,
    bool scroll = true,
  }) async {
    stubPermissions(permissions: permissions, writesSucceed: writesSucceed);
    final container = scaffold.makeContainer(permissions: permissions);
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      scroll
          ? Scaffold(body: SingleChildScrollView(child: child))
          : Scaffold(body: child),
      container,
      surface: surface,
      appFonts: true,
    );
    await settle(tester, frames: 4);
    return container;
  }

  group('PermissionRow', () {
    testWidgets('an unauthorized row offers the authorize action', (
      tester,
    ) async {
      var authorized = 0;
      var unauthorized = 0;
      await pump(
        tester,
        PermissionRow(
          label: 'students',
          isAuthorized: false,
          onAuthorize: () => authorized++,
          onUnauthorize: () => unauthorized++,
        ),
      );

      expect(find.text('students'), findsOneWidget);
      expect(heroIcon(HeroIcons.xMark), findsOneWidget);
      expect(heroIcon(HeroIcons.check), findsNothing);

      await tester.tap(find.byType(IconButton));
      expect(authorized, 1);
      expect(unauthorized, 0, reason: 'only the offered action may fire');

      await scaffold.unmountApp(tester);
    });

    testWidgets('an authorized row offers the unauthorize action', (
      tester,
    ) async {
      var authorized = 0;
      var unauthorized = 0;
      await pump(
        tester,
        PermissionRow(
          label: 'students',
          isAuthorized: true,
          onAuthorize: () => authorized++,
          onUnauthorize: () => unauthorized++,
        ),
      );

      expect(heroIcon(HeroIcons.check), findsOneWidget);
      expect(heroIcon(HeroIcons.xMark), findsNothing);

      await tester.tap(find.byType(IconButton));
      expect(unauthorized, 1);
      expect(authorized, 0);

      await scaffold.unmountApp(tester);
    });

    testWidgets('a very long label ellipsizes instead of overflowing', (
      tester,
    ) async {
      await pump(
        tester,
        PermissionRow(
          label: longLabel,
          isAuthorized: false,
          onAuthorize: () {},
          onUnauthorize: () {},
        ),
      );

      final text = tester.widget<Text>(find.text(longLabel));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);

      await scaffold.unmountApp(tester);
    });
  });

  group('PermissionTile', () {
    testWidgets('shows both counters and calls onTap', (tester) async {
      var taps = 0;
      await pump(
        tester,
        PermissionTile(
          title: 'Core admin',
          authorizedAccountTypes: 2,
          totalAccountTypes: 5,
          authorizedGroups: 3,
          totalGroups: 4,
          onTap: () => taps++,
        ),
      );

      expect(find.text('Core admin'), findsOneWidget);
      expect(find.text('2/5'), findsOneWidget);
      expect(find.text('3/4'), findsOneWidget);
      expect(heroIcon(HeroIcons.userCircle), findsOneWidget);
      expect(heroIcon(HeroIcons.userGroup), findsOneWidget);
      expect(heroIcon(HeroIcons.chevronRight), findsOneWidget);

      await tester.tap(find.byType(PermissionTile));
      expect(taps, 1);

      await scaffold.unmountApp(tester);
    });

    testWidgets('the counter row stays inside 360px with a long title', (
      tester,
    ) async {
      // The two chips sit in an unbounded `Row` next to the title's
      // `Expanded`, so the title absorbs the width and the chips cannot be
      // squeezed. This asserts that is true rather than hoping: the chip
      // labels are fixed-width digits, so the only way to overflow is a chip
      // label itself.
      await pump(
        tester,
        PermissionTile(
          title: longLabel,
          authorizedAccountTypes: 999999,
          totalAccountTypes: 999999,
          authorizedGroups: 999999,
          totalGroups: 999999,
          onTap: () {},
        ),
      );

      expect(find.text('999999/999999'), findsNWidgets(2));
      expect(tester.takeException(), isNull);

      await scaffold.unmountApp(tester);
    });
  });

  group('PermissionDetailModal', () {
    /// The modal is a bottom sheet, so it needs a Navigator and a
    /// `ScaffoldMessenger` above it; [showCustomBottomModal] supplies both,
    /// plus the navbar animation it parks while a modal is up.
    Future<void> openModal(
      WidgetTester tester,
      Widget modal, {
      required ProviderContainer container,
    }) async {
      await scaffold.pumpWidgetApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  isScrollControlled: true,
                  useRootNavigator: true,
                  context: context,
                  builder: (_) => UncontrolledProviderScope(
                    container: container,
                    child: modal,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        container,
        appFonts: true,
      );
      await settle(tester, frames: 4);
      await tester.tap(find.text('open'));
      await settle(tester, frames: 8);
    }

    testWidgets('mounts and lists every account type and group', (
      tester,
    ) async {
      final container = await pump(
        tester,
        const SizedBox.shrink(),
        permissions: [
          permission(
            name: 'admin',
            groups: ['g-1'],
            types: [enums.AccountType.student],
          ),
        ],
      );

      await openModal(
        tester,
        const PermissionDetailModal(
          permissionName: 'admin',
          accountTypes: ['student', 'staff'],
          groups: [
            CoreGroupSimple(name: 'BDE', id: 'g-1'),
            CoreGroupSimple(name: 'Coloc', id: 'g-2'),
          ],
        ),
        container: container,
      );

      expect(find.byType(PermissionDetailModal), findsOneWidget);
      // The title is the humanized permission name, and both section headers
      // come from the l10n bundle.
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Account types'), findsOneWidget);
      expect(find.text('Groups'), findsOneWidget);
      expect(find.byType(PermissionRow), findsNWidgets(4));

      await scaffold.unmountApp(tester);
    });

    testWidgets('marks the rows the server already authorized', (tester) async {
      final container = await pump(
        tester,
        const SizedBox.shrink(),
        permissions: [
          permission(
            name: 'admin',
            groups: ['g-1'],
            types: [enums.AccountType.student],
          ),
        ],
      );

      await openModal(
        tester,
        const PermissionDetailModal(
          permissionName: 'admin',
          accountTypes: ['student', 'staff'],
          groups: [
            CoreGroupSimple(name: 'BDE', id: 'g-1'),
            CoreGroupSimple(name: 'Coloc', id: 'g-2'),
          ],
        ),
        container: container,
      );

      // One check and one X per section: student and BDE were authorized.
      expect(heroIcon(HeroIcons.check), findsNWidgets(2));
      expect(heroIcon(HeroIcons.xMark), findsNWidgets(2));

      await scaffold.unmountApp(tester);
    });

    testWidgets('finds the permission under its module-prefixed name', (
      tester,
    ) async {
      // `permissions.dart` passes the key straight from
      // `moduleGroupedPermissionsProvider`, which is module-prefixed, while
      // the rows post the bare action name. The modal bridges the two; without
      // the fallback lookup every row would read as unauthorized against a
      // server that has just authorized it.
      final container = await pump(
        tester,
        const SizedBox.shrink(),
        permissions: [
          permission(
            name: 'admin',
            groups: ['g-1'],
            types: [enums.AccountType.student],
          ),
        ],
      );

      await openModal(
        tester,
        const PermissionDetailModal(
          permissionName: 'core.admin',
          accountTypes: ['student'],
          groups: [CoreGroupSimple(name: 'BDE', id: 'g-1')],
        ),
        container: container,
      );

      expect(find.byType(PermissionRow), findsNWidgets(2));
      expect(heroIcon(HeroIcons.check), findsNWidgets(2));
      expect(heroIcon(HeroIcons.xMark), findsNothing);

      await scaffold.unmountApp(tester);
    });

    testWidgets('an unknown permission renders every row unauthorized', (
      tester,
    ) async {
      // No entry in the map at all: `permission` is null, so both callbacks
      // return early and a tap must not throw.
      final container = await pump(tester, const SizedBox.shrink());

      await openModal(
        tester,
        const PermissionDetailModal(
          permissionName: 'unknown',
          accountTypes: ['student'],
          groups: [CoreGroupSimple(name: 'BDE', id: 'g-1')],
        ),
        container: container,
      );

      await tester.tap(find.byType(IconButton).first);
      await settle(tester, frames: 4);
      expect(tester.takeException(), isNull);
      expect(heroIcon(HeroIcons.xMark), findsNWidgets(2));

      await scaffold.unmountApp(tester);
    });

    testWidgets('authorizing a row posts it and flips the icon', (
      tester,
    ) async {
      final container = await pump(
        tester,
        const SizedBox.shrink(),
        permissions: [permission(name: 'admin')],
      );

      await openModal(
        tester,
        const PermissionDetailModal(
          permissionName: 'admin',
          accountTypes: ['staff'],
          groups: [CoreGroupSimple(name: 'BDE', id: 'g-1')],
        ),
        container: container,
      );

      expect(heroIcon(HeroIcons.xMark), findsNWidgets(2));
      await tester.tap(find.byType(IconButton).first);
      await settle(tester, frames: 8);

      final posted =
          verify(
                () => scaffold.repository.permissionsPost(
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as CoreAccountTypePermission;
      expect(posted.permissionName, 'admin');
      expect(posted.accountType, enums.AccountType.staff);
      // The notifier rewrote the row's entry in place, so the icon follows.
      expect(heroIcon(HeroIcons.check), findsNWidgets(1));

      await scaffold.unmountApp(tester);
    });

    testWidgets('unauthorizing posts the deletion and flips the icon', (
      tester,
    ) async {
      final container = await pump(
        tester,
        const SizedBox.shrink(),
        permissions: [
          permission(
            name: 'admin',
            groups: ['g-1'],
            types: [enums.AccountType.staff],
          ),
        ],
      );

      await openModal(
        tester,
        const PermissionDetailModal(
          permissionName: 'admin',
          accountTypes: ['staff'],
          groups: [CoreGroupSimple(name: 'BDE', id: 'g-1')],
        ),
        container: container,
      );

      await tester.tap(find.byType(IconButton).first);
      await settle(tester, frames: 8);

      final deleted =
          verify(
                () => scaffold.repository.permissionsDelete(
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as CoreAccountTypePermission;
      expect(deleted.accountType, enums.AccountType.staff);
      expect(heroIcon(HeroIcons.xMark), findsNWidgets(1));

      await scaffold.unmountApp(tester);
    });

    testWidgets('a rejected write surfaces an error snackbar', (tester) async {
      final container = await pump(
        tester,
        const SizedBox.shrink(),
        permissions: [permission(name: 'admin')],
        writesSucceed: false,
      );

      await openModal(
        tester,
        const PermissionDetailModal(
          permissionName: 'admin',
          accountTypes: ['staff'],
          groups: [CoreGroupSimple(name: 'BDE', id: 'g-1')],
        ),
        container: container,
      );

      await tester.tap(find.byType(IconButton).first);
      await settle(tester, frames: 8);

      // `l10n.adminError`. A silent failure here would read as a dropped tap.
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(
          AppLocalizations.of(
            tester.element(find.byType(SnackBar)),
          )!.adminError,
        ),
        findsOneWidget,
      );

      await scaffold.unmountApp(tester);
    });
  });

  group('ItemCardUi / SchoolButton / SchoolUi', () {
    CoreSchool school(String id, String name) =>
        CoreSchool.empty().copyWith(id: id, name: name);

    testWidgets('SchoolUi shows both actions for a deletable school', (
      tester,
    ) async {
      var edited = 0;
      await pump(
        tester,
        SchoolUi(
          school: school('school-1', 'Bordeaux'),
          onEdit: () => edited++,
          onDelete: () async {},
        ),
      );

      expect(find.text('Bordeaux'), findsOneWidget);
      expect(heroIcon(HeroIcons.eye), findsOneWidget);
      expect(heroIcon(HeroIcons.xMark), findsOneWidget);

      await tester.tap(heroIcon(HeroIcons.eye));
      expect(edited, 1);

      await scaffold.unmountApp(tester);
    });

    testWidgets('the "no school" placeholder has no delete button', (
      tester,
    ) async {
      // `getSchoolNameFromId` rewrites the reserved ids to a localized label,
      // and `SchoolUi` hides the delete button for exactly those ids - a
      // placeholder row must not be deletable.
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      stubPermissions();

      await scaffold.pumpWidgetApp(
        tester,
        SchoolUi(
          school: school(SchoolIdConstant.noSchool.value, 'Whatever'),
          onEdit: () {},
          onDelete: () async {},
        ),
        container,
        appFonts: true,
      );
      await settle(tester, frames: 4);

      final l10n = AppLocalizations.of(tester.element(find.byType(SchoolUi)))!;
      expect(find.text(l10n.adminNoSchool), findsOneWidget);
      expect(heroIcon(HeroIcons.eye), findsOneWidget);
      expect(
        heroIcon(HeroIcons.xMark),
        findsNothing,
        reason: 'the reserved placeholder id must not be deletable',
      );
      expect(tester.takeException(), isNull);

      await scaffold.unmountApp(tester);
    });

    testWidgets('the ECL placeholder row also has no delete button', (
      tester,
    ) async {
      // Same reserved id, different label: this one goes through
      // `getBaseSchoolName()`, which reads the `SCHOOL_NAME` dart-define.
      // The CI command does not define it, so the row cannot render its title
      // at all - which is worth pinning, because the failure mode is a
      // `StateError` from inside a `build`, not an empty row.
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      stubPermissions();

      await scaffold.pumpWidgetApp(
        tester,
        SchoolUi(
          school: school(SchoolIdConstant.eclSchool.value, 'Whatever'),
          onEdit: () {},
          onDelete: () async {},
        ),
        container,
        appFonts: true,
      );

      expect(tester.takeException(), isStateError);
      expect(
        String.fromEnvironment('SCHOOL_NAME'),
        isEmpty,
        reason: 'if this ever becomes defined, the assertion above is wrong',
      );

      await scaffold.unmountApp(tester);
    });

    testWidgets('a very long school name truncates rather than overflowing', (
      tester,
    ) async {
      await pump(
        tester,
        SchoolUi(
          school: school('school-1', longLabel),
          onEdit: () {},
          onDelete: () async {},
        ),
      );

      expect(find.text(longLabel), findsOneWidget);
      expect(tester.takeException(), isNull);

      await scaffold.unmountApp(tester);
    });

    testWidgets('SchoolButton paints its gradient', (tester) async {
      await pump(
        tester,
        const Center(
          child: SchoolButton(
            gradient1: Colors.black,
            gradient2: Colors.blue,
            child: Icon(Icons.add),
          ),
        ),
      );

      final decoration =
          tester
                  .widget<Container>(
                    find.descendant(
                      of: find.byType(SchoolButton),
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.gradient, isNotNull);
      expect(decoration.borderRadius, BorderRadius.circular(10));

      await scaffold.unmountApp(tester);
    });
  });

  group('SuperAdminButton / TextEditing', () {
    testWidgets('SuperAdminButton spans the full width', (tester) async {
      await pump(tester, const SuperAdminButton(child: Text('Save')));

      expect(find.text('Save'), findsOneWidget);
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SuperAdminButton),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(container.constraints?.maxWidth, double.infinity);

      await scaffold.unmountApp(tester);
    });

    testWidgets('TextEditing labels and drives its controller', (tester) async {
      final controller = TextEditingController(text: 'hello');
      addTearDown(controller.dispose);

      await pump(tester, TextEditing(controller: controller, label: 'Name'));

      expect(find.text('Name'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller,
        same(controller),
      );

      await scaffold.unmountApp(tester);
    });
  });
}
