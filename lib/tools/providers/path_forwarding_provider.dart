import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/tools/class/path_forwarding.dart';

class PathForwardingProvider extends Notifier<PathForwarding> {
  @override
  PathForwarding build() {
    return PathForwarding.empty();
  }

  void forward(String path, {Map<String, String>? queryParameters}) {
    final preAuth = state.path == path
        ? state.preAuth
        : !ref.read(isLoggedInProvider);
    state = state.copyWith(
      path: path,
      queryParameters: queryParameters,
      preAuth: preAuth,
    );
  }

  void clearParams() {
    state = state.copyWith(queryParameters: null);
  }

  void removeQueryParam(String key) {
    final currentParams = state.queryParameters;
    if (currentParams == null) return;
    final newParams = Map<String, String>.from(currentParams)..remove(key);
    state = PathForwarding(
      path: state.path,
      isLoggedIn: state.isLoggedIn,
      preAuth: state.preAuth,
      queryParameters: newParams.isEmpty ? null : newParams,
    );
  }

  void login() {
    state = state.copyWith(isLoggedIn: true);
  }

  void reset() {
    state = PathForwarding.empty();
  }
}

final pathForwardingProvider =
    NotifierProvider<PathForwardingProvider, PathForwarding>(
      () => PathForwardingProvider(),
    );
