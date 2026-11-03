import 'package:flutter/widgets.dart';
import 'package:qlevar_router/qlevar_router.dart';

/// A [RouteMock] that accepts every navigation the app asks for, builds a real
/// (empty) route for it and records the path in [navigated].
///
/// qlevar only processes the init-path middleware chain on the FIRST
/// navigation of an isolate, so a test that wants to assert WHERE the app went
/// without mounting a real page installs this as the router's mock and reads
/// [navigated] afterwards. Install it and restore the previous mock in an
/// `addTearDown`.
///
/// Shared by navigation's quit-dialog test, service's local-notification test
/// and settings' actions test, which each carried an identical copy.
class RecordingRouteMock extends RouteMock {
  final navigated = <String>[];

  @override
  String? mockName(String name) => name;

  @override
  QRoute? mockPath(String path) {
    navigated.add(path);
    return QRoute(path: path, builder: () => const SizedBox());
  }
}
