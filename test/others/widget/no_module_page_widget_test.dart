import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/others/ui/no_module.dart';
import 'package:titan/super_admin/providers/module_root_list_provider.dart';

import '../../shared/app_scaffold.dart';

/// `/no_module` used to be a dead route — nothing in `lib/` navigated to it,
/// so the page sat at **0/15** (ledger #55). It is now wired up:
/// `AuthenticatedMiddleware` sends a signed-in user whose granted module
/// roots resolve to an EMPTY list here, because `loadModules` gates every
/// module on `roots.contains(m.root)` and would otherwise leave them on a
/// feed with an empty navbar.
///
/// Wiring it up exposed a second defect that its unreachability had been
/// hiding: the page forwarded back to `pathForwarding.path` as soon as the
/// permission CATALOG arrived, whatever the user's grants were. Since the
/// middleware now sends the user here, that forward bounced them straight
/// back into the middleware — an infinite redirect loop of exactly the kind
/// bug #1 records for the gated deep links. The forward is now conditional on
/// the roots actually being non-empty.
///
/// The middleware half is in
/// `test/tools/integration/no_module_redirect_integration_test.dart`, which
/// owns this isolate's single deep-link navigation; these tests mount the
/// page directly.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    ui.Size surface = const ui.Size(360, 640),
    List<CorePermission> permissions = const [],
  }) async {
    // seedAsyncUser matters here: `moduleRootListProvider` gates on
    // `asyncUserProvider`, and the shell only fakes that when asked — so
    // without it the roots sit in AsyncLoading forever and the page's
    // forward can never be evaluated at all.
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
      seedAsyncUser: true,
      permissionCatalog: const ['booking.access'],
      permissions: permissions,
    );
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      const NoModulePage(),
      container,
      surface: surface,
      appFonts: true,
    );
    await settle(tester, frames: 4);
    return container;
  }

  String l10nOf(WidgetTester tester, String Function(AppLocalizations) get) =>
      get(AppLocalizations.of(tester.element(find.byType(NoModulePage)))!);

  testWidgets('a user with no granted module sees the "no module" copy', (
    tester,
  ) async {
    final container = await pump(tester);

    expect(find.byType(NoModulePage), findsOneWidget);
    expect(find.text(l10nOf(tester, (l) => l.othersNoModule)), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The precondition the middleware keys on: the roots RESOLVED, and they
    // resolved to nothing. A loading or non-empty list would not put the user
    // on this page at all.
    final roots = container.read(moduleRootListProvider);
    expect(roots, isA<AsyncData<List<String>>>());
    expect(roots.requireValue, isEmpty);

    await scaffold.unmountApp(tester);
  });

  testWidgets('KNOWN BUG: it does NOT bounce the user back off the page', (
    tester,
  ) async {
    // The loop, asserted as the thing that must not happen. The page used to
    // call `QR.to(pathForwarding.path)` the moment the CATALOG resolved, so
    // the user went back to the route the middleware had just redirected from
    // and was sent here again — forever. Mounted directly there is no router,
    // so an unconditional forward throws out of build; with no router this
    // test is really asserting "no navigation was attempted".
    await pump(tester);

    expect(find.byType(NoModulePage), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason:
          'the forward is now gated on a non-empty root list; with an empty '
          'one the user stays here',
    );

    await scaffold.unmountApp(tester);
  });

  testWidgets('the page fits a 360px phone', (tester) async {
    await pump(tester);

    expect(find.byType(NoModulePage), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scaffold.unmountApp(tester);
  });
}
