import 'dart:convert';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/auth/repository/auth_repository.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/tools/providers/path_forwarding_provider.dart';
import 'package:titan/vote/providers/list_provider.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';

/// Builds a syntactically valid, non-expired JWT whose `sub` claim is [id].
/// The real JwtDecoder parses the payload, so both parts are proper JSON.
String fakeJwt(String id) {
  String part(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'RS256', 'typ': 'JWT'})}.'
      '${part({'sub': id, 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.sig';
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });
  testWidgets(
    'sign-in exchanges the OIDC code, stores the refresh token and replays the deep link',
    (tester) async {
      // The replayed vote page auto-loads its list logo; a 404 falls back
      // to the placeholder asset.
      when(
        () => scaffold.repository.campaignListsListIdLogoGet(
          listId: any(named: 'listId'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response<List<int>>(
          http.Response('{"detail": "File does not exist"}', 404),
          [],
          error: 'File does not exist',
        ),
      );
      // The state that survives the signed-out boot: the deep link the user
      // wanted before being bounced to /login. This is what the flow must
      // replay after sign-in — not /feed.
      const desiredDeepLink = '/vote/detail';
      final container = scaffold.makeSignInFlowContainer(
        // The REAL repository: the flow under test runs the genuine code
        // (code exchange via the mocked native shell, storeToken via the
        // mocked secure storage); only the platform edges are faked. The
        // session is also the real derivation — no isLoggedIn fake.
        authRepository: AuthRepository(openIdRepository: scaffold.repository),
      );
      addTearDown(container.dispose);
      container.read(pathForwardingProvider.notifier).forward(desiredDeepLink);
      // Pre-seed the client-side vote list so the REPLAYED page asserts real
      // content instead of an empty render.
      container
          .read(listProvider.notifier)
          .setId(
            ListReturn.empty().copyWith(
              id: 'list-1',
              description: 'Replay landed here',
              section: SectionComplete.empty().copyWith(
                name: 'Bureau des Sports',
              ),
            ),
          );

      // The OIDC native shell: authorizeAndExchangeCode returns the code
      // exchange result. The JWT is decodable and non-expired so the real
      // IsLoggedInProvider derives `true` from it.
      const storedRefreshToken = 'refresh-token-123';
      final jwt = fakeJwt('user-42');
      final binding = TestDefaultBinaryMessengerBinding.instance;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('crossingthestreams.io/flutter_appauth'),
        (call) async {
          expect(call.method, 'authorizeAndExchangeCode');
          return <String, dynamic>{
            'accessToken': jwt,
            'refreshToken': storedRefreshToken,
          };
        },
      );
      addTearDown(
        () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('crossingthestreams.io/flutter_appauth'),
          null,
        ),
      );
      // storeToken persists the refresh token in secure storage: the real
      // side effect the flow must have performed.
      final writtenKeys = <String, String>{};
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async {
          if (call.method == 'write') {
            final args = Map<String, dynamic>.from(call.arguments as Map);
            writtenKeys[args['key'] as String] = args['value'] as String;
            return null;
          }
          return null;
        },
      );
      addTearDown(
        () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          null,
        ),
      );

      await scaffold.pumpApp(
        tester,
        container,
        initialPath: '/login',
        pumpAndSettle: false,
      );
      await settle(tester);

      // The signed-out boot really rendered the sign-in form.
      expect(find.text('Sign in'), findsOneWidget);

      await tester.tap(find.text('Sign in'));
      await settle(tester, frames: 20);

      // The full round-trip happened: the native shell was asked for a code
      // exchange, the token landed in the provider, and the refresh token
      // was written to secure storage by the real storeToken().
      expect(container.read(authTokenProvider).value!.accessToken, jwt);
      expect(writtenKeys['my_ecl_auth_token'], storedRefreshToken);
      // The pre-auth deep link is what the router replayed — the user is on
      // the page they originally wanted, with its real content rendered.
      expect(find.text('Bureau des Sports'), findsOneWidget);
      expect(find.textContaining('Replay landed here'), findsOneWidget);
      expect(QR.currentPath, desiredDeepLink);
    },
  );
}
