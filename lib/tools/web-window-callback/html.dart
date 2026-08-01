import 'dart:async';

import 'package:universal_html/universal_html.dart';

/// The `dart:html` implementation of [webWindowWithCallback], kept for
/// platforms exposing `dart:html` but not `dart:js_interop`.
///
/// See `js_interop.dart` for the documented behaviour.
void webWindowWithCallback(
  String windowUrl,
  String windowName, {
  required void Function() completerFutureCallback,
  required Future<void> Function(String) loginCallback,
  void Function()? popupBlockedCallback,
}) async {
  final WindowBase popupWin = window.open(
    windowUrl,
    windowName,
    "width=800, height=900, scrollbars=yes",
  );

  final completer = Completer();
  void checkWindowClosed() {
    if (popupWin.closed == true) {
      completer.complete();
    } else {
      Future.delayed(const Duration(milliseconds: 100), checkWindowClosed);
    }
  }

  checkWindowClosed();
  completer.future.then((_) => completerFutureCallback());

  window.onMessage.listen((event) {
    final data = event.data.toString();
    if (data.contains('code=')) {
      loginCallback(data);
      popupWin.close();
    }
  });
}
