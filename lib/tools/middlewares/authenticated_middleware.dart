// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/admin/providers/is_admin_provider.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/feed/router.dart';
import 'package:titan/login/router.dart';
import 'package:titan/router.dart';
import 'package:titan/super_admin/providers/is_super_admin_provider.dart';
import 'package:titan/super_admin/providers/module_root_list_provider.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';
import 'package:titan/version/providers/titan_version_provider.dart';
import 'package:titan/version/providers/version_verifier_provider.dart';
import 'package:qlevar_router/qlevar_router.dart';

class AuthenticatedMiddleware extends QMiddleware {
  final Ref ref;

  AuthenticatedMiddleware(this.ref);

  /// It cannot loop: `/no_module` carries only `DeferredLoadingMiddleware`,
  /// so landing there never re-enters this guard.
  bool _hasNoModuleRoots() {
    final roots = ref.read(moduleRootListProvider);
    if (roots.isLoading || roots.hasError) return false;
    if (roots.requireValue.isNotEmpty) return false;
    final isAdmin = ref.read(isAdminProvider) || ref.read(isSuperAdminProvider);
    return !isAdmin;
  }

  @override
  Future<String?> redirectGuard(String path) async {
    final pathForwardingNotifier = ref.read(pathForwardingProvider.notifier);
    final versionVerifier = ref.read(versionVerifierProvider);
    final titanVersion = ref.read(titanVersionProvider);
    final isLoggedIn = ref.read(isLoggedInProvider);
    final check = versionVerifier.whenData(
      (value) => value.minimalTitanVersionCode <= titanVersion,
    );
    if (!pathForwardingNotifier.state.isLoggedIn &&
        path != LoginRouter.root &&
        path != "/") {
      pathForwardingNotifier.forward(path);
    }
    return check.when(
      data: (value) {
        if (!value) {
          return AppRouter.update;
        }
        if (path == LoginRouter.root &&
            !pathForwardingNotifier.state.isLoggedIn &&
            !isLoggedIn) {
          return null;
        }
        if (!isLoggedIn) {
          return LoginRouter.root;
        }
        if (!pathForwardingNotifier.state.isLoggedIn) {
          pathForwardingNotifier.login();
        }
        if (pathForwardingNotifier.state.path == "/") {
          if (_hasNoModuleRoots()) {
            return AppRouter.noModule;
          }
          pathForwardingNotifier.forward(FeedRouter.root);
          return FeedRouter.root;
        }
        if (pathForwardingNotifier.state.path != path) {
          return pathForwardingNotifier.state.path;
        }
        if (!pathForwardingNotifier.state.preAuth) {
          pathForwardingNotifier.forward("/");
        }
        return null;
      },
      loading: () => AppRouter.loading,
      error: (error, stack) => AppRouter.noInternet,
    );
  }
}
