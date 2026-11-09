import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/tools/providers/rendered_path_provider.dart';

/// The provider's own wiring, without the app shell.
///
/// `shellTestSetUp` calls `startRenderedPathTracking()` before every widget
/// test, so `_ensureTracking` (the lazy registration a plain container does)
/// and the pop observer that registration installs are never exercised there.
/// This file owns both.
void main() {
  testWidgets('a bare container registers the tracking observers', (
    tester,
  ) async {
    QR.reset();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // The first read is the lazy path: no `startRenderedPathTracking()` ran,
    // so the notifier syncs once and installs its observers itself.
    expect(container.read(renderedPathProvider), QR.currentPath);

    // qlevar's pop notification, run the way its pages controller runs it.
    expect(QR.observer.onPop, isNotEmpty);
    for (final onPop in List.of(QR.observer.onPop)) {
      await onPop(
        '/phonebook',
        QRoute(path: '/phonebook', builder: () => const SizedBox.shrink()),
      );
    }

    // The callback re-read the router's path into the notifier's source.
    expect(renderedPathListenable.value, QR.currentPath);
  });
}
