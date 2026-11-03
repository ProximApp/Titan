import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/feed/router.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';
import 'package:qlevar_router/qlevar_router.dart';

class AdminMiddleware extends QMiddleware {
  final Provider<bool> isAdminProvider;
  final Ref ref;

  /// Polls each async source the gate is derived from (structures, bank
  /// account holder, loaners, …) until it has a value. A cold deep link runs
  /// this guard BEFORE that state has landed: the first read below is what
  /// instantiates the notifiers and starts their load, so judging straight
  /// away would judge the loading state — `false` — and bounce a legitimate
  /// admin. Each entry is a read of the source, e.g.
  /// `() => ref.read(structureListProvider).isLoading`.
  final List<bool Function()> isLoading;

  AdminMiddleware(this.ref, this.isAdminProvider, {this.isLoading = const []});

  @override
  Future<String?> redirectGuard(String path) async {
    for (final source in isLoading) {
      await waitForFirstValue(source);
    }
    if (ref.watch(isAdminProvider)) return null;
    ref.read(pathForwardingProvider.notifier).forward(FeedRouter.root);
    return FeedRouter.root;
  }
}

/// Waits until [isLoading] answers `false`, i.e. the source has left its
/// loading state. An errored source counts as a value — the gate reads it
/// through its own `orElse: () => false` branch — and the ceiling keeps a
/// source that never resolves from hanging navigation: a guard that never
/// answers would strand the route instead of gating it. The poll interval is
/// one frame, and only ever runs on a cold deep link into a gated route.
Future<void> waitForFirstValue(bool Function() isLoading) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (isLoading()) {
    if (DateTime.now().isAfter(deadline)) return;
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
}
