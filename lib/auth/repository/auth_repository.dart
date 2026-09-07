import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart' as models;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/cache/cache_manager.dart';
import 'package:titan/tools/functions.dart';
import 'package:titan/tools/web-window-callback/web_window_with_callback.dart';

class AuthRepository {
  final Openapi openIdRepository;
  final FlutterAppAuth appAuth = const FlutterAppAuth();
  final CacheManager cacheManager = CacheManager();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Future<models.TokenResponse>? _refreshInProgress;
  final Base64Codec base64 = const Base64Codec.urlSafe();
  final String tokenName = "my_ecl_auth_token";
  final String clientId = "Titan";
  final String redirectUrl = "${getTitanPackageName()}://authorized";
  final String redirectURL = "${getTitanURL()}static.html";
  final AuthorizationServiceConfiguration authorizationServiceConfiguration =
      AuthorizationServiceConfiguration(
        authorizationEndpoint: "${getTitanHost()}auth/authorize",
        tokenEndpoint: "${getTitanHost()}auth/token",
      );
  final List<String> scopes = ["API"];

  AuthRepository({required this.openIdRepository});

  String generateRandomString(int len) {
    var r = Random.secure();
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => chars[r.nextInt(chars.length)]).join();
  }

  String hash(String data) {
    return base64.encode(sha256.convert(utf8.encode(data)).bytes);
  }

  Future<models.TokenResponse> getTokenFromRequest() async {
    final codeVerifier = generateRandomString(128);
    models.TokenResponse tokenResponse = models.TokenResponse.empty();

    final authUrl =
        "${getTitanHost()}auth/authorize?client_id=$clientId&response_type=code&scope=${scopes.join(" ")}&redirect_uri=$redirectURL&code_challenge=${hash(codeVerifier)}&code_challenge_method=S256";

    if (kIsWeb) {
      Future<models.TokenResponse> login(String data) async {
        final receivedUri = Uri.parse(data);
        final token = receivedUri.queryParameters["code"];
        try {
          if (token != null && token.isNotEmpty) {
            final response = await openIdRepository.authTokenPost(
              body: {
                "client_id": clientId,
                "code": token,
                "redirect_uri": redirectURL,
                "code_verifier": codeVerifier,
                "grant_type": "authorization_code",
                "refresh_token": token,
              },
            );
            if (response.isSuccessful && response.body != null) {
              await storeToken(response.body!);
              return response.body!;
            } else {
              throw Exception('Wrong credentials');
            }
          } else {
            throw Exception('Wrong credentials');
          }
        } on TimeoutException catch (_) {
          throw Exception('No response from server');
        } catch (e) {
          rethrow;
        }
      }

      final completer = Completer<models.TokenResponse>();
      // The popup posts the code back to us, so the exchange only starts once
      // it answers. Set as soon as a code arrives — before awaiting the token
      // exchange — because closing the popup is what the shim does next, and
      // that must not be mistaken for the user giving up.
      var receivedCode = false;

      webWindowWithCallback(
        authUrl,
        "Hyperion",
        completerFutureCallback: () {
          if (!receivedCode && !completer.isCompleted) {
            completer.complete(tokenResponse);
          }
        },
        popupBlockedCallback: () {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Popup blocked'));
          }
        },
        loginCallback: (String data) async {
          if (receivedCode) {
            return;
          }
          receivedCode = true;
          try {
            completer.complete(await login(data));
          } catch (e, stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(e, stackTrace);
            }
          }
        },
      );

      return completer.future;
    } else {
      AuthorizationTokenResponse resp = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUrl,
          serviceConfiguration: authorizationServiceConfiguration,
          scopes: scopes,
        ),
      );
      if (resp.accessToken != null && resp.refreshToken != null) {
        tokenResponse = models.TokenResponse(
          accessToken: resp.accessToken!,
          refreshToken: resp.refreshToken!,
        );
        await storeToken(tokenResponse);
        return tokenResponse;
      } else {
        throw Exception('Wrong credentials');
      }
    }
  }

  Future<models.TokenResponse> getTokenFromStorage() => refreshToken();

  Future<models.TokenResponse> refreshToken() {
    final refreshInProgress = _refreshInProgress;
    if (refreshInProgress != null) {
      return refreshInProgress;
    }

    final refresh = _refreshStoredToken();
    _refreshInProgress = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshInProgress, refresh)) {
        _refreshInProgress = null;
      }
    });
  }

  Future<models.TokenResponse> _refreshStoredToken() async {
    final refreshToken = await _secureStorage.read(key: tokenName);
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('No refresh token found');
    }

    try {
      late final models.TokenResponse tokenResponse;
      if (kIsWeb) {
        final response = await openIdRepository.authTokenPost(
          body: {
            "client_id": clientId,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
          },
        );
        if (!response.isSuccessful || response.body == null) {
          if (response.statusCode == 400 || response.statusCode == 401) {
            await _secureStorage.delete(key: tokenName);
          }
          throw Exception('Unable to refresh credentials');
        }
        tokenResponse = response.body!;
      } else {
        final resp = await appAuth.token(
          TokenRequest(
            clientId,
            redirectUrl,
            serviceConfiguration: authorizationServiceConfiguration,
            scopes: scopes,
            refreshToken: refreshToken,
          ),
        );
        if (resp.accessToken == null || resp.refreshToken == null) {
          throw Exception('Unable to refresh credentials');
        }
        tokenResponse = models.TokenResponse(
          accessToken: resp.accessToken!,
          refreshToken: resp.refreshToken!,
        );
      }

      await storeToken(tokenResponse);
      return tokenResponse;
    } on FlutterAppAuthPlatformException catch (error) {
      final oauthError = error.platformErrorDetails.error;
      if (oauthError == FlutterAppAuthOAuthError.invalidGrant ||
          oauthError == FlutterAppAuthOAuthError.invalidRequest) {
        await _secureStorage.delete(key: tokenName);
      }
      rethrow;
    } on TimeoutException catch (_) {
      throw Exception('No response from server');
    }
  }

  Future<void> storeToken(models.TokenResponse tokenResponse) async {
    if (tokenResponse.accessToken.isEmpty ||
        tokenResponse.refreshToken.isEmpty) {
      throw Exception('Invalid token response');
    }
    await _secureStorage.write(
      key: tokenName,
      value: tokenResponse.refreshToken,
    );
  }

  Future<void> deleteToken() async {
    await Future.wait([
      _secureStorage.delete(key: tokenName),
      cacheManager.deleteCache(tokenName),
      cacheManager.deleteCache("id"),
    ]);
  }
}

final authRepositoryProvider = Provider((ref) {
  final openIdRepository = Openapi.create(baseUrl: Uri.parse(getTitanHost()));
  return AuthRepository(openIdRepository: openIdRepository);
});
