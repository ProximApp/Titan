import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/centralassociation/ui/centralassociation.dart';
import 'package:titan/centralassociation/ui/pages/main_page.dart';

import '../../shared/app_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // The repository behind assoProvider holds a static Logger whose
    // FileLoggerOutput resolves <documents> through path_provider; the
    // fetch error path logs through it (same shim as asso_repository_test).
    await Directory.systemTemp.createTemp('titan_test_documents').then((dir) {
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            switch (call.method) {
              case 'getApplicationDocumentsDirectory':
              case 'getTemporaryDirectory':
                return dir.path;
            }
            return null;
          });
    });
  });

  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  // Deep link to the centralassociation module. qlevar_router 1.12.4 only
  // processes the init-path middleware chain on the first navigation of the
  // isolate, so every deep-link shell lives in its own file with a single
  // test (see the purchases test NOTE).
  testWidgets('deep link to /centralassociation renders the main page', (
    tester,
  ) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/centralassociation',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    expect(QR.currentPath, '/centralassociation');
    expect(find.byType(CentralassociationMainPage), findsOneWidget);
    expect(find.byType(CentralassociationTemplate), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
