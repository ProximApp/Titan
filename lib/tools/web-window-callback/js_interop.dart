import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

/// Opens [windowUrl] in a popup and reports back what happens to it.
///
/// This is the WebAssembly-compatible implementation: `dart:html` — and so
/// `package:universal_html/html.dart` — cannot be compiled to Wasm, only
/// `dart:js_interop` can.
///
/// [loginCallback] receives the payload of every `postMessage` carrying a
/// `code=` parameter, and the popup is closed right after. [popupBlockedCallback]
/// fires when the browser refused to open the popup at all, and
/// [completerFutureCallback] once the popup is gone, whether it was closed by
/// the user or by us.
void webWindowWithCallback(
  String windowUrl,
  String windowName, {
  required void Function() completerFutureCallback,
  required Future<void> Function(String) loginCallback,
  void Function()? popupBlockedCallback,
}) async {
  final Window? popupWin = window.open(
    windowUrl,
    windowName,
    "width=800, height=900, scrollbars=yes",
  );

  if (popupWin == null) {
    popupBlockedCallback?.call();
    return;
  }

  final completer = Completer();
  void checkWindowClosed() {
    if (popupWin.closed) {
      completer.complete();
    } else {
      Future.delayed(const Duration(milliseconds: 100), checkWindowClosed);
    }
  }

  checkWindowClosed();
  completer.future.then((_) => completerFutureCallback());

  window.onMessage.listen((event) {
    // The popup is a foreign document, so its message can be anything: only
    // strings are of interest here and casting the rest would throw.
    final data = event.data;
    if (data.isA<JSString>()) {
      final message = (data as JSString).toDart;
      if (message.contains('code=')) {
        loginCallback(message);
        popupWin.close();
      }
    }
  });
}
