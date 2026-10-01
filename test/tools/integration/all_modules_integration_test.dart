import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/providers/prefered_module_root_list_provider.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  group('All modules page', () {
    testWidgets('lists every granted module plus settings', (tester) async {
      // A plain user is only granted the settings page by the backend; the
      // rest of the catalog stays hidden. The navbar reaches the page
      // itself through the Others entry.
      //
      // QRouterDelegate boots its initial route asynchronously and the
      // middleware redirect for non-root paths lands on /feed first; settle
      // through the redirect, then navigate to the page under test through
      // the same router the app uses.
      await scaffold.pumpApp(
        tester,
        scaffold.makeContainerWithModules(),
        initialPath: '/all_modules',
      );
      await settle(tester);
      // The middleware forwards to /feed first and records the requested
      // path; replaying the navigation once the session is registered shows
      // the requested page.
      QR.to('/all_modules');
      await settle(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Calendar'), findsNothing);
      expect(find.text('Phonebook'), findsNothing);
    });

    testWidgets('tapping a module navigates to its root', (tester) async {
      await scaffold.pumpApp(
        tester,
        scaffold.makeContainerWithModules(),
        initialPath: '/all_modules',
      );
      await settle(tester);
      QR.to('/all_modules');
      await settle(tester);

      // Settings is the only granted module for this user.
      await tester.tap(find.text('Settings'));
      await settle(tester);

      expect(QR.currentPath, '/settings');
    });

    testWidgets('bookmarking a module persists the preference for the navbar', (
      tester,
    ) async {
      final container = scaffold.makeContainerWithModules();
      await scaffold.pumpApp(tester, container, initialPath: '/all_modules');
      await settle(tester);
      QR.to('/all_modules');
      await settle(tester);

      // Every HeroIcon carries a semantic label; tap the first outline
      // bookmark, which belongs to the first row of the list (settings).
      final anyBookmark = find.byWidgetPredicate(
        (w) =>
            w is HeroIcon &&
            w.icon == HeroIcons.bookmark &&
            w.style == HeroIconStyle.outline,
      );
      expect(anyBookmark, findsWidgets);
      await tester.tap(anyBookmark.first);
      await settle(tester);

      final saved = (await SharedPreferences.getInstance()).getString(
        PreferedModuleRootListNotifier.preferedModuleRootListKey,
      );
      expect(saved, '/settings');
    });
  });

  group('Navbar (NavigationTemplate)', () {
    testWidgets(
      'shows the feed module, the preferred ones and the Others entry',
      (tester) async {
        // The user has no granted modules, so the navbar falls back to feed
        // + Others; the all-modules page is where they would pick more.
        final container = scaffold.makeContainerWithModules(
          user: CoreUser.empty().copyWith(id: 'me'),
        );
        await scaffold.pumpApp(tester, container, initialPath: '/feed');
        await settle(tester);

        expect(find.text('Events'), findsWidgets);
        expect(find.text('Others'), findsOneWidget);
      },
    );

    testWidgets('tapping a navbar item navigates and forwards the path', (
      tester,
    ) async {
      final container = scaffold.makeContainerWithModules(
        user: CoreUser.empty().copyWith(id: 'me'),
      );
      await scaffold.pumpApp(tester, container, initialPath: '/feed');
      await settle(tester);

      await tester.tap(find.text('Others'));
      await settle(tester);

      expect(QR.currentPath, '/all_modules');
    });
  });
}
