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
      // caller. On a host `Platform` is neither Android nor iOS, so this run
      // exercises the no-User-Agent arm; the other two are pinned by the
      // User-Agent group below, which is what the seam in plausible.dart is
      // for.
      final status = await plausible.event('feed');
      expect(status, 400);
    });
  });

  // `event()` used to build the header inline behind `Platform.isAndroid` /
  // `Platform.isIOS`, which no host run can enter — the reason these strings
  // were untested. The seam puts the choice and the formatting in reach.
  group('User-Agent', () {
    test('the Android string carries every field plausible reads', () {
      expect(
        androidUserAgent(
          appName: 'MyEMApp',
          version: '1.2.3',
          release: '14',
          sdkInt: 34,
          model: 'Pixel 7',
          id: 'UQ1A.240205.004',
        ),
        'MyEMApp/1.2.3 Android/14 (SDK 34; Pixel 7 Build/UQ1A.240205.004)',
      );
    });

    test('the iOS string carries the system version and model', () {
      expect(
        iosUserAgent(
          appName: 'MyEMApp',
          version: '1.2.3',
          systemVersion: '17.4',
          model: 'iPhone15,2',
        ),
        'MyEMApp/1.2.3 iOS/17.4 (iPhone15,2)',
      );
    });

    test('Android wins when both flags are set', () {
      expect(
        userAgentKindFor(isAndroid: true, isIOS: true),
        PlausibleUserAgent.android,
        reason:
            'only one branch may write the header — the old two `if`s let the '
            'second overwrite the first',
      );
    });

    test('a host that is neither sends no User-Agent at all', () {
      expect(
        userAgentKindFor(isAndroid: false, isIOS: false),
        PlausibleUserAgent.none,
        reason:
            'this is the arm every `flutter test` run and desktop build takes',
      );
    });
  });

  test('getPlausible stays null without the PLAUSIBLE_HOST defines', () {
    // String.fromEnvironment is compile-time: `flutter test` passes no
    // PLAUSIBLE_HOST/PLAUSIBLE_DOMAIN, so the guard returns before any
    // instance is built — which is also how main.dart boots in CI.
    expect(getPlausible(), isNull);
  });
}
