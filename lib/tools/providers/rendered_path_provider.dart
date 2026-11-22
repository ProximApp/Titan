import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlevar_router/qlevar_router.dart';

/// The path of the route the navigator is actually showing.
///
/// qlevar's own `QR.currentPath` is only trustworthy at the moment a
/// navigation is committed: during a redirect chain a page can be built
/// while it still reports the path that was asked for, and it notifies
/// nobody when it finally changes — so a widget that reads it once
/// in `build` keeps whatever the value happened to be at that frame until
/// something else rebuilds it. A template sitting behind another page keeps
/// showing the other module's state when its own route comes back to the
/// front, for instance.
final ValueNotifier<String> renderedPathListenable = ValueNotifier<String>('');

bool _isTracking = false;

void _sync() => renderedPathListenable.value = QR.currentPath;

Future<void> _onNavigate(String path, dynamic route) async => _sync();

Future<void> _onPop(String path, dynamic route) async => _sync();

void _registerObservers() {
  QR.observer.onNavigate.remove(_onNavigate);
  QR.observer.onPop.remove(_onPop);
  QR.observer.onNavigate.add(_onNavigate);
  QR.observer.onPop.add(_onPop);
  _isTracking = true;
}

void startRenderedPathTracking() {
  _sync();
  _registerObservers();
}

void _ensureTracking() {
  if (_isTracking) return;
  _sync();
  _registerObservers();
}

final renderedPathProvider = NotifierProvider<RenderedPathNotifier, String>(
  RenderedPathNotifier.new,
);

class RenderedPathNotifier extends Notifier<String> {
  @override
  String build() {
    _ensureTracking();

    void listener() {
      if (state != renderedPathListenable.value) {
        state = renderedPathListenable.value;
      }
    }

    renderedPathListenable.addListener(listener);
    ref.onDispose(() => renderedPathListenable.removeListener(listener));
    return renderedPathListenable.value;
  }
}
