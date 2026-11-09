import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/pdfjs/pdf_js.dart';
import 'package:titan/tools/web-window-callback/web_window_with_callback.dart';

/// `pdf_js.dart` and `web_window_with_callback.dart` are conditional exports:
/// the JS-interop implementations are picked for the web build and these two
/// stubs for everything else. The test binary is a VM target, so what runs
/// here is exactly the `else` file of each pair.
void main() {
  group('the non-web pdfjs stub', () {
    test('resolves without loading anything', () async {
      // Every platform except the web renders PDFs natively, so the loader is
      // a no-op that still has to complete for the callers that await it.
      await expectLater(ensurePdfJs(), completes);
    });
  });

  group('the non-web window-callback stub', () {
    test('throws instead of silently opening nothing', () async {
      var completed = 0;
      var loggedIn = 0;

      // The stub is `void … async`, so its throw surfaces as an uncaught
      // async error in the calling zone rather than on a returned future.
      final errors = <Object>[];
      await runZonedGuarded(() async {
        webWindowWithCallback(
          'https://example.com/login',
          'titan_login',
          completerFutureCallback: () => completed++,
          loginCallback: (_) async => loggedIn++,
        );
        await Future<void>.delayed(Duration.zero);
      }, (error, stack) => errors.add(error));

      expect(errors, [
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          '`webWindowWithCallback()` is not implemented for the current '
              'platform',
        ),
      ]);

      // The popup flow has no meaning off the web: neither callback may run.
      expect(completed, 0);
      expect(loggedIn, 0);
    });
  });
}
