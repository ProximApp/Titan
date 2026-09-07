import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';

class AppAuthenticator implements Authenticator {
  AppAuthenticator({required this.refreshAccessToken});

  final Future<String> Function() refreshAccessToken;

  @override
  FutureOr<Request?> authenticate(
    Request request,
    Response response, [
    Request? originalRequest,
  ]) async {
    // 401
    if (response.statusCode == HttpStatus.unauthorized) {
      // Trying to update token only 1 time
      if (request.headers['Retry-Count'] != null) {
        debugPrint(
          '[AppAuthenticator] Unable to refresh token, retry count exceeded',
        );
        return null;
      }

      try {
        final newToken = await _refreshToken();

        return applyHeaders(request, {
          HttpHeaders.authorizationHeader: 'Bearer $newToken',
          // Setting the retry count to not end up in an infinite loop
          // of unsuccessful updates
          'Retry-Count': '1',
        });
      } catch (e) {
        debugPrint('[AppAuthenticator] Unable to refresh token: $e');
        return null;
      }
    }

    return null;
  }

  Future<String>? _refreshInProgress;

  Future<String> _refreshToken() {
    final refreshInProgress = _refreshInProgress;
    if (refreshInProgress != null) {
      debugPrint('Token refresh is already in progress');
      return refreshInProgress;
    }

    final refresh = refreshAccessToken().then((token) {
      debugPrint('[AppAuthenticator] Refreshed token');
      return token;
    });
    _refreshInProgress = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshInProgress, refresh)) {
        _refreshInProgress = null;
      }
    });
  }

  @override
  AuthenticationCallback? get onAuthenticationFailed => null;

  @override
  AuthenticationCallback? get onAuthenticationSuccessful => null;
}

final authenticatorProvider = Provider<AppAuthenticator>((ref) {
  return AppAuthenticator(
    refreshAccessToken: ref.read(authTokenProvider.notifier).refreshAccessToken,
  );
});
