import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/plausible/plausible.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Plausible', () {
    test('the constructor strips exactly one trailing slash', () {
      expect(
        Plausible('https://plausible.io/', 'myem.fr').serverUrl,
        'https://plausible.io',
      );
      expect(
        Plausible('https://plausible.io', 'myem.fr').serverUrl,
        'https://plausible.io',
      );
    });

    // testWidgets, not test: the binding's fake HttpClient is what keeps
    // this request off the network.
    testWidgets('event posts a pageview and returns the status code', (
      tester,
    ) async {
      PackageInfo.setMockInitialValues(
        appName: 'MyEMApp',
        packageName: 'fr.myemapp.titan',
        version: '1.2.3',
        buildNumber: '42',
        buildSignature: '',
      );

      final plausible = Plausible('https://plausible.io', 'myem.fr');
      // The test binding answers every request with 400 instead of reaching
      // the network (the suite's standard fake HttpClient); what this pins
      // is that the request completes and its status propagates back to the
      // caller. The platform User-Agent branches stay out of reach on the
      // host — Platform is neither Android nor iOS under `flutter test`.
      final status = await plausible.event('feed');
      expect(status, 400);
    });
  });

  test('getPlausible stays null without the PLAUSIBLE_HOST defines', () {
    // String.fromEnvironment is compile-time: `flutter test` passes no
    // PLAUSIBLE_HOST/PLAUSIBLE_DOMAIN, so the guard returns before any
    // instance is built — which is also how main.dart boots in CI.
    expect(getPlausible(), isNull);
  });
}
