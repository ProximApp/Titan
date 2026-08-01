import 'dart:async';

void webWindowWithCallback(
  String windowUrl,
  String windowName, {
  required void Function() completerFutureCallback,
  required Future<void> Function(String) loginCallback,
  void Function()? popupBlockedCallback,
}) async => throw UnsupportedError(
  "`webWindowWithCallback()` is not implemented for the current platform",
);
