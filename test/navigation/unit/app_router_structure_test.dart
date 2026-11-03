import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/admin/router.dart';
import 'package:titan/advert/router.dart';
import 'package:titan/amap/router.dart';
import 'package:titan/booking/router.dart';
import 'package:titan/centralassociation/router.dart';
import 'package:titan/centralisation/router.dart';
import 'package:titan/cinema/router.dart';
import 'package:titan/feed/router.dart';
import 'package:titan/feed/ui/pages/main_page/main_page.dart';
import 'package:titan/flappybird/router.dart';
import 'package:titan/home/router.dart';
import 'package:titan/loan/router.dart';
import 'package:titan/login/router.dart';
import 'package:titan/l10n/app_localizations.dart';
import 'package:titan/mypayment/router.dart';
import 'package:titan/navigation/ui/all_module_page.dart';
import 'package:titan/others/ui/loading_page.dart';
import 'package:titan/others/ui/no_internet_page.dart';
import 'package:titan/others/ui/no_module.dart';
import 'package:titan/others/ui/rollback_page.dart';
import 'package:titan/others/ui/update_page.dart';
import 'package:titan/phonebook/router.dart';
import 'package:titan/ph/router.dart';
import 'package:titan/purchases/router.dart';
import 'package:titan/raffle/router.dart';
import 'package:titan/recommendation/router.dart';
import 'package:titan/router.dart';
import 'package:titan/seed-library/router.dart';
import 'package:titan/settings/router.dart';
import 'package:titan/super_admin/router.dart';
import 'package:titan/tickets/router.dart';
import 'package:titan/tools/middlewares/authenticated_middleware.dart';
import 'package:titan/tools/middlewares/deferred_middleware.dart';
import 'package:titan/tools/ui/styleguide/router.dart';
import 'package:titan/vote/router.dart';

import '../../shared/app_scaffold.dart';

/// `AppRouter` is the app's whole route table, and every deep-link test builds
/// it — but only the routes those tests walk get their `builder` run, and each
/// builder sits behind its own deferred library. This file mirrors the module
/// structure tests (`test/booking/unit/booking_router_structure_test.dart`):
/// the builders run in a PLAIN test, because awaiting a deferred
/// `loadLibrary()` inside flutter_test's fake-async body never completes.
///
/// Two lines of `lib/router.dart` stay dark on purpose: `late List<QRoute>
/// routes = []` is an initializer the constructor always overwrites before the
/// first read (dead by construction), and `QCustomPage.transitionsBuilder` is
/// only invoked by qlevar while it animates a push INTO `/all_modules` — the
/// page is reached from tests through a direct route mock, so no push is ever
/// animated there.
void main() {
  // The metadata-free assertions need no context, but the page types the
  // builders return resolve AppLocalizations on build — priming the deferred
  // translation library here runs in the real zone.
  setUpAll(() async {
    await lookupAppLocalizations(const Locale('en', 'US'));
    await lookupAppLocalizations(const Locale('fr', 'FR'));
  });

  test('the route table mounts the seven standalone pages', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final routes = container.read(appRouterProvider).routes;
    final byPath = {for (final route in routes) route.path: route};

    expect(
      byPath.keys,
      containsAll([
        AppRouter.root,
        AppRouter.loading,
        AppRouter.noInternet,
        AppRouter.update,
        AppRouter.noModule,
        AppRouter.allModules,
        AppRouter.rollback,
      ]),
    );

    // No path is mounted twice: qlevar matches the first entry it sees, so a
    // duplicate would silently shadow a whole page.
    expect(byPath, hasLength(routes.length));
  });

  test('every module router is mounted at its own root', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final routes = container.read(appRouterProvider).routes;
    final paths = routes.map((route) => route.path).toList();
    const standaloneCount = 7;

    final moduleRoots = [
      AdminRouter.root,
      AdvertRouter.root,
      AmapRouter.root,
      BookingRouter.root,
      CentralisationRouter.root,
      CentralassociationRouter.root,
      TicketsRouter.root,
      CinemaRouter.root,
      FlappyBirdRouter.root,
      FeedRouter.root,
      HomeRouter.root,
      LoanRouter.root,
      LoginRouter.root,
      PaymentRouter.root,
      PhonebookRouter.root,
      PhRouter.root,
      PurchasesRouter.root,
      RaffleRouter.root,
      RecommendationRouter.root,
      SettingsRouter.root,
      StyleGuideRouter.root,
      VoteRouter.root,
      SeedLibraryRouter.root,
      SuperAdminRouter.root,
    ];
    expect(moduleRoots, hasLength(24));
    expect(paths, containsAll(moduleRoots));
    expect(routes, hasLength(standaloneCount + moduleRoots.length));
  });

  test('the standalone pages gate the session only where it is needed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final routes = container.read(appRouterProvider).routes;
    final byPath = {for (final route in routes) route.path: route};
    final standalone = routes.take(7).toList();

    for (final path in [AppRouter.root, AppRouter.allModules]) {
      expect(
        byPath[path]!.middleware!.first,
        isA<AuthenticatedMiddleware>(),
        reason: '$path must require a session',
      );
    }

    // The rest report a broken session (no_internet, update, rollback) or
    // explain what is missing (loading, no_module): they must be reachable
    // signed out, or the app could not tell a reader why it is stuck.
    for (final route in standalone.where(
      (r) => r.path != AppRouter.root && r.path != AppRouter.allModules,
    )) {
      expect(
        route.middleware!.whereType<AuthenticatedMiddleware>(),
        isEmpty,
        reason: '${route.path} must not require a session',
      );
    }

    // `/all_modules` is also the one page with a custom transition.
    expect(byPath[AppRouter.allModules]!.pageType, isA<QCustomPage>());
  });

  test(
    'every standalone page defers its library and builds its page',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final routes = container.read(appRouterProvider).routes;
      final byPath = {for (final route in routes) route.path: route};
      final standalone = routes.take(7).toList();

      for (final route in standalone) {
        expect(
          route.middleware!.last,
          isA<DeferredLoadingMiddleware>(),
          reason: '${route.path} must load its page lazily',
        );
      }

      // Run each loader the way DeferredLoadingMiddleware.onEnter does, then
      // build: this is exactly what a navigation does.
      Future<Widget> navigate(String path) async {
        final route = byPath[path]!;
        await (route.middleware!.last as DeferredLoadingMiddleware).loader();
        return route.builder!();
      }

      expect(await navigate(AppRouter.root), isA<FeedMainPage>());
      expect(await navigate(AppRouter.loading), isA<LoadingPage>());
      expect(await navigate(AppRouter.noInternet), isA<NoInternetPage>());
      expect(await navigate(AppRouter.update), isA<UpdatePage>());
      expect(await navigate(AppRouter.noModule), isA<NoModulePage>());
      expect(await navigate(AppRouter.allModules), isA<AllModulePage>());
      expect(await navigate(AppRouter.rollback), isA<RollbackPage>());
    },
  );
}
