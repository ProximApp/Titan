import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/event/router.dart';
import 'package:titan/event/ui/pages/admin_page/admin_page.dart';
import 'package:titan/event/ui/pages/detail_page/detail_page.dart';
import 'package:titan/event/ui/pages/event_pages/add_edit_event_page.dart';
import 'package:titan/event/ui/pages/main_page/main_page.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/tools/middlewares/admin_middleware.dart';
import 'package:titan/tools/middlewares/authenticated_middleware.dart';
import 'package:titan/tools/middlewares/deferred_middleware.dart';

import '../../shared/app_scaffold.dart';

/// `EventRouter` is not registered in `AppRouter`, so no production path (and
/// no deep-link test) ever executes its `route()` builder. These tests build
/// the tree directly from a real `Ref`: one plain test asserts the gate and
/// loader wiring and runs every deferred page builder, and one widget test
/// evaluates the module metadata closures against a localized context.
///
/// The builders run in a PLAIN test on purpose: awaiting a deferred
/// loadLibrary inside flutter_test's fake-async body never completes (the
/// same trap the localization round-trip documents), while a plain test runs
/// in the real zone where every load finishes.
final _eventRouterProvider = Provider<EventRouter>((ref) => EventRouter(ref));

void main() {
  // The round-trip test's priming, needed by the widget test below:
  // AppLocalizations resolves through a deferred loadLibrary that only
  // completes for the first genuine load in a file under fake async.
  // setUpAll runs in the real zone, so both arb locales are ready before
  // the first pump.
  setUpAll(() async {
    await lookupAppLocalizations(const Locale('en', 'US'));
    await lookupAppLocalizations(const Locale('fr', 'FR'));
  });

  test('the event route tree wires its gates, loaders and builders', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final route = container.read(_eventRouterProvider).route();

    // Root: named '/event', fade page, authenticated + deferred-gated.
    expect(route.name, 'event');
    expect(route.path, EventRouter.root);
    expect(route.pageType, isNotNull);
    expect(route.middleware, hasLength(2));
    expect(route.middleware!.first, isA<AuthenticatedMiddleware>());
    expect(route.middleware!.last, isA<DeferredLoadingMiddleware>());

    // Children: admin (admin-gated), the standalone add_edit and detail.
    expect(route.children, hasLength(3));
    expect(
      route.children!.map((r) => r.path),
      containsAll([EventRouter.admin, EventRouter.addEdit, EventRouter.detail]),
    );

    final adminRoute = route.children!.firstWhere(
      (r) => r.path == EventRouter.admin,
    );
    expect(adminRoute.middleware, hasLength(2));
    expect(adminRoute.middleware!.first, isA<AdminMiddleware>());
    expect(adminRoute.middleware!.last, isA<DeferredLoadingMiddleware>());
    expect(
      adminRoute.children!.map((r) => r.path),
      containsAll([EventRouter.detail, EventRouter.addEdit]),
    );

    // Run every deferred loader the way DeferredLoadingMiddleware.onEnter
    // would, then execute each builder: this is what a navigation does and
    // it pins the builder types to the pages this module ships.
    Future<void> loadAndBuild(QRoute r) async {
      await (r.middleware!.last as DeferredLoadingMiddleware).loader();
    }

    await loadAndBuild(route);
    expect(route.builder!(), isA<EventMainPage>());

    await loadAndBuild(adminRoute);
    expect(adminRoute.builder!(), isA<AdminPage>());

    final adminDetail = adminRoute.children!.firstWhere(
      (r) => r.path == EventRouter.detail,
    );
    await loadAndBuild(adminDetail);
    expect(adminDetail.builder!(), isA<DetailPage>());

    final adminAddEdit = adminRoute.children!.firstWhere(
      (r) => r.path == EventRouter.addEdit,
    );
    await loadAndBuild(adminAddEdit);
    expect(adminAddEdit.builder!(), isA<AddEditEventPage>());

    final rootAddEdit = route.children!.firstWhere(
      (r) => r.path == EventRouter.addEdit,
    );
    await loadAndBuild(rootAddEdit);
    expect(rootAddEdit.builder!(), isA<AddEditEventPage>());

    final rootDetail = route.children!.firstWhere(
      (r) => r.path == EventRouter.detail,
    );
    await loadAndBuild(rootDetail);
    expect(rootDetail.builder!(), isA<DetailPage>());
  });

  testWidgets('the module metadata resolves in a localized context', (
    tester,
  ) async {
    expect(EventRouter.module.root, EventRouter.root);
    String name = '';
    String description = '';
    await pumpWidgetAt(
      tester,
      Builder(
        builder: (context) {
          name = EventRouter.module.getName(context);
          description = EventRouter.module.getDescription(context);
          return const SizedBox();
        },
      ),
      appFonts: false,
    );
    expect(name, isNotEmpty);
    expect(description, isNotEmpty);
  });
}
