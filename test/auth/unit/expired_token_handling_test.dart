import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/tools/authenticator/authenticator.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/providers/list_notifier.dart';

/// A minimal concrete ListNotifier: the base class owns the tokenExpire
/// contract under test, the type parameter is irrelevant to it.
class TestListNotifier extends ListNotifier<int> {
  @override
  AsyncValue<List<int>> build() => const AsyncLoading();
}

final testListProvider =
    NotifierProvider<TestListNotifier, AsyncValue<List<int>>>(
      TestListNotifier.new,
    );

chopper.Request requestWithAuthHeader(String? token) => chopper.Request(
  'GET',
  Uri.parse('/api/something'),
  Uri.parse('https://titan.test'),
  headers: token == null ? {} : {'authorization': 'Bearer $token'},
);

chopper.Response<T> response401<T>() =>
    chopper.Response(http.Response('unauthorized', 401), null);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppAuthenticator (401 → refresh → single retry)', () {
    test(
      'a 401 triggers a refresh and the retried request carries the new token',
      () async {
        var refreshCount = 0;
        final authenticator = AppAuthenticator(
          refreshAccessToken: () async {
            refreshCount++;
            return 'fresh-token';
          },
        );

        final retried = await authenticator.authenticate(
          requestWithAuthHeader('stale-token'),
          response401(),
        );

        expect(refreshCount, 1);
        expect(retried, isNotNull);
        expect(retried!.headers['authorization'], 'Bearer fresh-token');
        // The retry marker prevents an infinite refresh loop on a second 401.
        expect(retried.headers['Retry-Count'], '1');
      },
    );

    test('a non-401 response is left alone (no refresh attempt)', () async {
      var refreshCount = 0;
      final authenticator = AppAuthenticator(
        refreshAccessToken: () async {
          refreshCount++;
          return 'fresh-token';
        },
      );

      final retried = await authenticator.authenticate(
        requestWithAuthHeader('stale-token'),
        chopper.Response(http.Response('nope', 404), null),
      );

      expect(refreshCount, 0);
      expect(retried, isNull);
    });

    test(
      'a failing refresh gives up instead of throwing into the pipeline',
      () async {
        final authenticator = AppAuthenticator(
          refreshAccessToken: () async =>
              throw AppException(ErrorType.tokenExpire, 'refresh rejected'),
        );

        final retried = await authenticator.authenticate(
          requestWithAuthHeader('stale-token'),
          response401(),
        );

        // null = chopper surfaces the original 401; the session loss is then
        // handled downstream (expired token → signed-out state).
        expect(retried, isNull);
      },
    );

    test(
      'the retry marker stops a second refresh after a refreshed 401',
      () async {
        var refreshCount = 0;
        final authenticator = AppAuthenticator(
          refreshAccessToken: () async {
            refreshCount++;
            return 'fresh-token';
          },
        );

        // Simulate the round trip: first 401 → refreshed request...
        final retried = await authenticator.authenticate(
          requestWithAuthHeader('stale-token'),
          response401(),
        );
        // ...which comes back 401 again (e.g. the backend revoked the session).
        final secondAttempt = await authenticator.authenticate(
          retried!,
          response401(),
        );

        expect(refreshCount, 1);
        expect(secondAttempt, isNull);
      },
    );

    test('concurrent 401s share one refresh (single-flight dedup)', () async {
      var refreshCount = 0;
      final authenticator = AppAuthenticator(
        refreshAccessToken: () async {
          refreshCount++;
          // Long enough for the second authenticate() to pile up behind it.
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return 'fresh-token';
        },
      );

      Future<chopper.Request?> hit(String token) async => authenticator
          .authenticate(requestWithAuthHeader(token), response401());

      final results = await Future.wait([hit('a'), hit('b')]);

      expect(refreshCount, 1);
      expect(results, everyElement(isNotNull));
      expect(results[0]!.headers['authorization'], 'Bearer fresh-token');
    });
  });

  group('ListNotifier tokenExpire contract', () {
    test('a successful load lands in the state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(testListProvider.notifier)
          .loadList(() async => [1, 2, 3]);

      expect(container.read(testListProvider).value, [1, 2, 3]);
    });

    test('a tokenExpire failure sets the error state AND rethrows', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(testListProvider.notifier)
            .loadList(
              () async => throw AppException(
                ErrorType.tokenExpire,
                'session expired mid-flight',
              ),
            ),
        throwsA(
          isA<AppException>().having(
            (e) => e.type,
            'type',
            ErrorType.tokenExpire,
          ),
        ),
      );
      // The error state is what the UI renders while the rethrow is what
      // lets outer layers react to the dead session.
      expect(container.read(testListProvider), isA<AsyncError>());
    });

    test(
      'any other failure sets the error state but does not rethrow',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container
            .read(testListProvider.notifier)
            .loadList(
              () async => throw AppException(ErrorType.notFound, 'no such row'),
            );

        expect(container.read(testListProvider), isA<AsyncError>());
      },
    );
  });
}
