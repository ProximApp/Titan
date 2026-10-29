import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/feed/router.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';
import 'package:qlevar_router/qlevar_router.dart';

class AdminMiddleware extends QMiddleware {
  final Provider<bool> isAdminProvider;
  final Ref ref;

  AdminMiddleware(this.ref, this.isAdminProvider);

  @override
  Future<String?> redirectGuard(String path) async {
    if (ref.watch(isAdminProvider)) return null;
    ref.read(pathForwardingProvider.notifier).forward(FeedRouter.root);
    return FeedRouter.root;
  }
}
