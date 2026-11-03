import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

// This code was taken from the plugin plausible_analytics and adapted
// We should switch to a plugin when one will work

/// Which User-Agent [Plausible.event] sends.
///
/// Split out from the `kIsWeb`/`Platform` branch so the choice and the string
/// it produces are testable on a host, where `Platform` is neither Android nor
/// iOS and the branch is otherwise unreachable.
enum PlausibleUserAgent { none, android, ios }

/// The branch for a native build.
///
/// Do not reach this on the web: a browser already sends its own User-Agent,
/// and `dart:io`'s `Platform` is only safe to read off the browser.
PlausibleUserAgent userAgentKindFor({
  required bool isAndroid,
  required bool isIOS,
}) {
  if (isAndroid) return PlausibleUserAgent.android;
  if (isIOS) return PlausibleUserAgent.ios;
  return PlausibleUserAgent.none;
}

/// The Android User-Agent plausible's dashboard parses.
@visibleForTesting
String androidUserAgent({
  required String appName,
  required String version,
  required String release,
  required int sdkInt,
  required String model,
  required String id,
}) => '$appName/$version Android/$release (SDK $sdkInt; $model Build/$id)';

/// The iOS User-Agent plausible's dashboard parses.
@visibleForTesting
String iosUserAgent({
  required String appName,
  required String version,
  required String systemVersion,
  required String model,
}) => '$appName/$version iOS/$systemVersion ($model)';

/// Plausible class. Use the constructor to set the parameters.
class Plausible {
  /// The url of your plausible server e.g. https://plausible.io
  final String serverUrl;
  final String domain;

  /// Constructor
  Plausible(String serverUrl, this.domain)
    // Remove trailing slash '/'
    : serverUrl = serverUrl.endsWith("/")
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;

  /// Post event to plausible
  Future<int> event(String page) async {
    // https://plausible.io/docs/events-api#request-body-json-parameters
    page = "app://localhost/$page";

    final Map<String, String> headers = {"Content-Type": "application/json"};

    // The browser sends its own User-Agent, so it must not be overwritten —
    // and `Platform` is only safe to read off the web.
    final userAgentKind = kIsWeb
        ? PlausibleUserAgent.none
        : userAgentKindFor(
            isAndroid: Platform.isAndroid,
            isIOS: Platform.isIOS,
          );
    if (userAgentKind != PlausibleUserAgent.none) {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfoPlugin = DeviceInfoPlugin();
      switch (userAgentKind) {
        case PlausibleUserAgent.android:
          final androidInfo = await deviceInfoPlugin.androidInfo;
          headers["User-Agent"] = androidUserAgent(
            appName: packageInfo.appName,
            version: packageInfo.version,
            release: androidInfo.version.release,
            sdkInt: androidInfo.version.sdkInt,
            model: androidInfo.model,
            id: androidInfo.id,
          );
        case PlausibleUserAgent.ios:
          final iosInfo = await deviceInfoPlugin.iosInfo;
          headers["User-Agent"] = iosUserAgent(
            appName: packageInfo.appName,
            version: packageInfo.version,
            systemVersion: iosInfo.systemVersion,
            model: iosInfo.model,
          );
        case PlausibleUserAgent.none:
          break;
      }
    }

    final Map<String, String> body = {
      "domain": domain,
      "name": "pageview",
      "url": page,
    };

    final response = await http.post(
      Uri.parse('$serverUrl/api/event'),
      body: jsonEncode(body),
      headers: headers,
    );

    return response.statusCode;
  }
}
