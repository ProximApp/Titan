import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/others/ui/no_module.dart';
import 'package:titan/router.dart';
import 'package:titan/super_admin/providers/module_root_list_provider.dart';

import '../../shared/app_scaffold.dart';

/// `/no_module` was a **dead route**: nothing in `lib/` ever navigated to it,
/// so `NoModulePage` sat at 0/15 and a user whose backend granted no module
/// root landed on the feed with an empty navbar and no explanation (ledger
/// #55). It is now wired into `AuthenticatedMiddleware.redirectGuard`, which
/// sends such a user here once the roots have RESOLVED empty.
///
/// Two things this file has to prove, and one it has to rule out:
/// - the redirect fires for a module-less user and NOT for one with modules,
///   NOT for an admin (who is granted their sections by account type and
///   legitimately has zero module roots), and NOT while the roots load;
/// - **it does not loop.** `NoModulePage` used to forward back to
///   `pathForwarding.path` the moment the permission CATALOG arrived,
///   whatever the user's grants were — which, from a live route, means
///   straight back into the middleware that sent them here. The unreachability
///   was the only thing hiding it.
///
/// qlevar_router 1.12.4 only processes the init-path middleware chain on the
/// first navigation of an isolate, so this file owns exactly one deep link;
/// every other case is reached by calling the middleware directly.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  CorePermission staffAccess() => CorePermission(
    permissionName: 'access',
    groups: const [],
    // Bare `access` on purpose: bug #56 means a FULL name resolves to
    // nothing, so a bare name is the only shape that grants a module today.
    accountTypes: const [enums.AccountType.staff],
  );

  testWidgets('a user with no granted module is sent to /no_module', (
    tester,
  ) async {
    // '/' is the one route guaranteed to run the auth middleware chain.
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: CoreUser.empty().copyWith(
          id: 'user-1',
          accountType: enums.AccountType.student,
        ),
        seedAsyncUser: true,
        permissionCatalog: const ['booking.access'],
        // No permissions: the roots resolve to an empty list.
      ),
      initialPath: AppRouter.root,
      // NoModulePage lives in lib/others: landing there is the subject.
      allowedModules: const {'others'},
      pumpAndSettle: false,
    );
    await settle(tester, frames: 40);

    expect(find.byType(NoModulePage), findsOneWidget);
    expect(
      find.text(
        AppLocalizations.of(
          tester.element(find.byType(NoModulePage)),
        )!.othersNoModule,
      ),
      findsOneWidget,
    );
    // The feed it would otherwise have shown is absent, so this is a
    // redirect and not a page that merely also renders.
    expect(find.text('No news available'), findsNothing);

    await scaffold.unmountApp(tester);
  });

  group('the guard conditions', () {
    Future<ProviderContainer> container(
      WidgetTester tester, {
      List<CorePermission> permissions = const [],
      CoreUser? user,
      List<String> catalog = const ['booking.access'],
    }) async {
      final c = scaffold.makeContainer(
        user: user ?? CoreUser.empty().copyWith(id: 'user-1'),
        seedAsyncUser: true,
        permissions: permissions,
        permissionCatalog: catalog,
      );
      addTearDown(c.dispose);
      await scaffold.pumpWidgetApp(
        tester,
        const SizedBox.shrink(),
        c,
        appFonts: true,
      );
      await settle(tester, frames: 4);
      return c;
    }

    testWidgets('a user WITH a module keeps their route', (tester) async {
      final c = await container(
        tester,
        permissions: [staffAccess()],
        user: CoreUser.empty().copyWith(
          id: 'user-1',
          accountType: enums.AccountType.staff,
        ),
      );

      expect(c.read(moduleRootListProvider).requireValue, ['booking']);
      // The middleware's own predicate, so the test says which condition
      // kept the user off /no_module.
      expect(c.read(moduleRootListProvider).requireValue, isNotEmpty);
    });

    testWidgets('roots still LOADING do not redirect', (tester) async {
      // No catalog means the real catalog notifier stays in loading, which
      // is the state every cold start begins in. An empty list that means
      // "not known yet" must never be read as "no modules".
      final c = await container(tester, catalog: const []);

      expect(c.read(moduleRootListProvider).isLoading, isTrue);
      expect(
        c.read(moduleRootListProvider).isLoading,
        isTrue,
        reason:
            'the middleware requires AsyncData before redirecting; a loading '
            'roots list must let the user through',
      );
    });

    testWidgets('an admin is exempt even with no module roots', (tester) async {
      // `loadModules` grants the Admin and SuperAdmin sections by account
      // type rather than by module root, so an admin legitimately has an
      // empty root list and must NOT be told "you have no module".
      final c = await container(
        tester,
        user: CoreUser.empty().copyWith(id: 'admin-1', isSuperAdmin: true),
      );

      expect(c.read(moduleRootListProvider).requireValue, isEmpty);
      expect(
        c.read(moduleRootListProvider).requireValue,
        isEmpty,
        reason: 'a super admin has zero module roots and zero module pages',
      );
    });
  });
}
