import 'package:flutter/widgets.dart';
import 'package:qlevar_router/qlevar_router.dart';

/// Route mock that records every navigation it is asked to perform; the
/// three event shells rebuilt this class by hand.
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
