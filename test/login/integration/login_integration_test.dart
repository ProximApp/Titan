import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/app_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    QR.reset();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'boot while signed out lands on the login page with its actions',
    (tester) async {
      final scaffold = IntegrationScaffold();
      scaffold.stubInformation();
      final container = scaffold.makeLoggedOutContainer();
      addTearDown(container.dispose);

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/login',
        pumpAndSettle: false,
      );
      await settle(tester);

      expect(find.text('MyEMApp'), findsWidgets);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    },
  );
}
