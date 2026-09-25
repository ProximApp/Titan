import 'dart:ui' as dart_typing;
import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';

import 'app_scaffold.dart';

chopper.Response<T> chopperResponse<T>(T body) =>
    chopper.Response(http.Response('body', 200), body);

chopper.Response<List<T>> chopperListResponse<T>(List<T> body) =>
    chopper.Response(http.Response('body', 200), body);

Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

final seedLibraryAdminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    CoreGroupSimple(
      name: 'admin_seed_library',
      id: '09153d2a-14f4-49a4-be57-5d0f265261b9',
    ),
  ],
);

/// The plants destination page wraps ListTiles in a white ColoredBox, a
/// debug-mode ink-splash visibility warning with no user-facing effect.
void ignoreListTileInkWarning() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exception.toString().contains(
      'ListTile background color or ink splashes may be invisible',
    )) {
      return;
    }
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
}

void stubSeedLibrary(IntegrationScaffold scaffold) {
  // Auto-loaded by informationProvider on the main page; the menu cards
  // open the facebook/forum URLs only when they are set.
  when(() => scaffold.repository.seedLibraryInformationGet()).thenAnswer(
    (_) async => chopperResponse(
      SeedLibraryInformation.empty().copyWith(
        facebookUrl: 'https://facebook.com/test',
        forumUrl: 'https://forum.test',
      ),
    ),
  );
  when(
    () => scaffold.repository.seedLibraryPlantsUsersMeGet(),
  ).thenAnswer((_) async => chopperListResponse(<PlantSimple>[]));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IntegrationScaffold scaffold;

  setUp(() {
    QR.reset();
    SharedPreferences.setMockInitialValues({});
    scaffold = IntegrationScaffold();
    scaffold.stubInformation();
    scaffold.stubFeed();
  });

  group('Seed library main page', () {
    // NOTE on ordering: qlevar_router 1.12.4 silently drops the first
    // mid-test QR.to() to a route that is not yet mounted when an earlier
    // test already ran in the same isolate. The navigation test is kept
    // first; the remaining tests only assert on already-mounted routes.
    testWidgets('menu card navigates to the plants page', (tester) async {
      stubSeedLibrary(scaffold);
      ignoreListTileInkWarning();

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(user: seedLibraryAdminUser),
        initialPath: '/seed_library',
      );
      await settle(tester);

      await tester.tap(find.text('Mes plantes'));
      await settle(tester, frames: 16);

      expect(QR.currentPath, '/seed_library/plants');
    });

    testWidgets('renders the menu grid with the admin species card', (
      tester,
    ) async {
      stubSeedLibrary(scaffold);
      // The menu is a lazy GridView whose cards are ~500px tall; enlarge
      // the surface so every row is built.
      tester.view.physicalSize = const dart_typing.Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(user: seedLibraryAdminUser),
        initialPath: '/seed_library',
      );
      await settle(tester);

      // French constants, not l10n strings.
      expect(find.text('Mes plantes'), findsOneWidget);
      expect(find.text('Stock disponible'), findsOneWidget);
      expect(find.text('Dépôt de plantes'), findsOneWidget);
      expect(find.text('Fiches sur les plantes'), findsOneWidget);
      expect(
        find.text("Oskour maman j'ai tué ma plante - Forum d'aide"),
        findsOneWidget,
      );
      expect(find.text('Espèce'), findsOneWidget);
    });

    testWidgets('hides the admin species card for regular users', (
      tester,
    ) async {
      stubSeedLibrary(scaffold);

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
        initialPath: '/seed_library',
      );
      await settle(tester);

      expect(find.text('Espèce'), findsNothing);
      expect(find.text('Mes plantes'), findsOneWidget);
    });
  });
}
