import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/booking/ui/pages/admin_pages/add_edit_manager_page.dart';
import 'package:titan/booking/ui/pages/admin_pages/add_edit_room_page.dart';
import 'package:titan/booking/ui/pages/admin_pages/admin_page.dart';
import 'package:titan/booking/ui/pages/booking_pages/add_edit_booking_page.dart';
import 'package:titan/booking/ui/pages/detail_pages/detail_booking.dart';
import 'package:titan/booking/ui/pages/main_page/main_page.dart';
import 'package:titan/booking/ui/pages/manager_page/manager_page.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/tools/middlewares/admin_middleware.dart';
import 'package:titan/tools/middlewares/authenticated_middleware.dart';
import 'package:titan/tools/middlewares/deferred_middleware.dart';

import '../../shared/app_scaffold.dart';

/// BookingRouter IS registered in AppRouter, so the route CONSTRUCTION runs
/// in every booking deep-link test — but those only navigate the root
/// detail/add_edit variants and never evaluate the module metadata
/// closures (the manager-gated detail/add_edit builders and
/// `module.getDescription` are the residual uncovered router lines). The
/// structure test mirrors test/event/unit/event_router_structure_test.dart:
/// builders run in a PLAIN test on purpose, because awaiting a deferred
/// loadLibrary inside flutter_test's fake-async body never completes.
final _bookingRouterProvider = Provider<BookingRouter>(
  (ref) => BookingRouter(ref),
);

void main() {
  // The metadata widget test below resolves AppLocalizations through a
  // deferred loadLibrary that only completes for the first genuine load in
  // a file under fake async; priming in setUpAll runs in the real zone.
  setUpAll(() async {
    await lookupAppLocalizations(const Locale('en', 'US'));
    await lookupAppLocalizations(const Locale('fr', 'FR'));
  });

  test(
    'the booking route tree wires its gates, loaders and builders',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final route = container.read(_bookingRouterProvider).route();

      // Root: named 'booking', authenticated + deferred-gated.
      expect(route.name, 'booking');
      expect(route.path, BookingRouter.root);
      expect(route.pageType, isNotNull);
      expect(route.middleware, hasLength(2));
      expect(route.middleware!.first, isA<AuthenticatedMiddleware>());
      expect(route.middleware!.last, isA<DeferredLoadingMiddleware>());

      // Children: admin (admin-gated), manager (manager-gated) and the
      // standalone add_edit + detail.
      expect(route.children, hasLength(4));
      expect(
        route.children!.map((r) => r.path),
        containsAll([
          BookingRouter.admin,
          BookingRouter.manager,
          BookingRouter.addEdit,
          BookingRouter.detail,
        ]),
      );

      final adminRoute = route.children!.firstWhere(
        (r) => r.path == BookingRouter.admin,
      );
      expect(adminRoute.middleware, hasLength(2));
      expect(adminRoute.middleware!.first, isA<AdminMiddleware>());
      expect(adminRoute.middleware!.last, isA<DeferredLoadingMiddleware>());
      expect(
        adminRoute.children!.map((r) => r.path),
        containsAll([BookingRouter.room, BookingRouter.manager]),
      );

      // The manager sub-tree is gated on isManagerProvider — this is the gate
      // the admin deep links never walk.
      final managerRoute = route.children!.firstWhere(
        (r) => r.path == BookingRouter.manager,
      );
      expect(managerRoute.middleware, hasLength(2));
      expect(managerRoute.middleware!.first, isA<AdminMiddleware>());
      expect(managerRoute.middleware!.last, isA<DeferredLoadingMiddleware>());
      expect(
        managerRoute.children!.map((r) => r.path),
        containsAll([BookingRouter.detail, BookingRouter.addEdit]),
      );

      // Run every deferred loader the way DeferredLoadingMiddleware.onEnter
      // would, then execute each builder: this is what a navigation does and
      // it pins the builder types to the pages this module ships.
      Future<void> loadAndBuild(QRoute r) async {
        await (r.middleware!.last as DeferredLoadingMiddleware).loader();
      }

      await loadAndBuild(route);
      expect(route.builder!(), isA<BookingMainPage>());

      await loadAndBuild(adminRoute);
      expect(adminRoute.builder!(), isA<AdminPage>());

      final adminRoom = adminRoute.children!.firstWhere(
        (r) => r.path == BookingRouter.room,
      );
      await loadAndBuild(adminRoom);
      expect(adminRoom.builder!(), isA<AddEditRoomPage>());

      final adminManager = adminRoute.children!.firstWhere(
        (r) => r.path == BookingRouter.manager,
      );
      await loadAndBuild(adminManager);
      expect(adminManager.builder!(), isA<AddEditManagerPage>());

      await loadAndBuild(managerRoute);
      expect(managerRoute.builder!(), isA<ManagerPage>());

      // The manager-gated detail (isAdmin: true) and add_edit variants — the
      // builders no deep-link test ever reaches.
      final managerDetail = managerRoute.children!.firstWhere(
        (r) => r.path == BookingRouter.detail,
      );
      await loadAndBuild(managerDetail);
      expect(managerDetail.builder!(), isA<DetailBookingPage>());

      final managerAddEdit = managerRoute.children!.firstWhere(
        (r) => r.path == BookingRouter.addEdit,
      );
      await loadAndBuild(managerAddEdit);
      expect(managerAddEdit.builder!(), isA<AddEditBookingPage>());

      final rootAddEdit = route.children!.firstWhere(
        (r) => r.path == BookingRouter.addEdit,
      );
      await loadAndBuild(rootAddEdit);
      expect(rootAddEdit.builder!(), isA<AddEditBookingPage>());

      final rootDetail = route.children!.firstWhere(
        (r) => r.path == BookingRouter.detail,
      );
      await loadAndBuild(rootDetail);
      expect(rootDetail.builder!(), isA<DetailBookingPage>());
    },
  );

  testWidgets('the module metadata resolves in a localized context', (
    tester,
  ) async {
    expect(BookingRouter.module.root, BookingRouter.root);
    String name = '';
    String description = '';
    await pumpWidgetAt(
      tester,
      Builder(
        builder: (context) {
          name = BookingRouter.module.getName(context);
          description = BookingRouter.module.getDescription(context);
          return const SizedBox();
        },
      ),
      appFonts: false,
    );
    expect(name, isNotEmpty);
    expect(description, isNotEmpty);
  });
}
