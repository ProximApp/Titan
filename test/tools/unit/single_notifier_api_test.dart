import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/providers/single_notifier_api.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

class _StringApi extends SingleNotifierAPI<String> {}

final _apiProvider = NotifierProvider<_StringApi, AsyncValue<String>>(
  _StringApi.new,
);

void main() {
  late MockOpenapi repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockOpenapi();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  _StringApi notifier() => container.read(_apiProvider.notifier);

  group('SingleNotifierAPI.build', () {
    test('starts in loading', () {
      expect(container.read(_apiProvider).isLoading, isTrue);
    });
  });

  group('SingleNotifierAPI.load', () {
    test('stores the body on success', () async {
      final result = await notifier().load(() async => repo.ok('hello'));
      expect(result.value, 'hello');
      expect(container.read(_apiProvider).value, 'hello');
    });

    test('returns the error state when the response fails', () async {
      final result = await notifier().load(() async => repo.fail<String>(500));
      expect(result.hasError, isTrue);
      expect(container.read(_apiProvider).hasError, isTrue);
    });

    test('rethrows a token expiration to the caller', () async {
      await expectLater(
        notifier().load(() async {
          throw AppException(ErrorType.tokenExpire, 'expired');
        }),
        throwsA(isA<AppException>()),
      );
      expect(container.read(_apiProvider).hasError, isTrue);
    });

    test('wraps any other thrown error into the error state', () async {
      final result = await notifier().load(() async {
        throw StateError('boom');
      });
      expect(result.hasError, isTrue);
    });
  });

  group('SingleNotifierAPI.add', () {
    test('replaces the state with the created body', () async {
      final n = notifier();
      n.state = const AsyncValue.data('seed');
      expect(await n.add((t) async => repo.ok('$t-updated'), 'seed'), isTrue);
      expect(n.state.value, 'seed-updated');
    });

    test('keeps the previous value when the call fails', () async {
      final n = notifier();
      n.state = const AsyncValue.data('seed');
      expect(await n.add((t) async => repo.fail<String>(400), 'seed'), isFalse);
      expect(n.state.value, 'seed');
    });

    test('rethrows a token expiration', () async {
      final n = notifier();
      n.state = const AsyncValue.data('seed');
      await expectLater(
        n.add((t) async {
          throw AppException(ErrorType.tokenExpire, 'expired');
        }, 'seed'),
        throwsA(isA<AppException>()),
      );
      expect(n.state.value, 'seed');
    });

    test('refuses to run while loading', () async {
      final n = notifier();
      expect(await n.add((t) async => repo.ok('x'), 'seed'), isFalse);
      expect(n.state.hasError, isTrue);
    });

    test(
      'refuses to run in an error state and rethrows token expiration',
      () async {
        final n = notifier();
        n.state = AsyncValue.error('boom', StackTrace.empty);
        expect(await n.add((t) async => repo.ok('x'), 'seed'), isFalse);

        n.state = AsyncValue.error(
          AppException(ErrorType.tokenExpire, 'expired'),
          StackTrace.empty,
        );
        await expectLater(
          n.add((t) async => repo.ok('x'), 'seed'),
          throwsA(isA<AppException>()),
        );
      },
    );
  });

  group('SingleNotifierAPI.update', () {
    test('stores the given value on success', () async {
      final n = notifier();
      n.state = const AsyncValue.data('old');
      expect(await n.update(() async => repo.okVoid(), 'new'), isTrue);
      expect(n.state.value, 'new');
    });

    test('keeps the previous value when the call fails', () async {
      final n = notifier();
      n.state = const AsyncValue.data('old');
      expect(await n.update(() async => repo.fail<void>(500), 'new'), isFalse);
      expect(n.state.value, 'old');
    });

    test('refuses to run while loading', () async {
      final n = notifier();
      expect(await n.update(() async => repo.okVoid(), 'new'), isFalse);
      expect(n.state.hasError, isTrue);
    });

    test('rethrows a token expiration from an error state', () async {
      final n = notifier();
      n.state = AsyncValue.error(
        AppException(ErrorType.tokenExpire, 'expired'),
        StackTrace.empty,
      );
      await expectLater(
        n.update(() async => repo.okVoid(), 'new'),
        throwsA(isA<AppException>()),
      );
    });

    test('a plain error state returns false and stays an error', () async {
      final n = notifier();
      n.state = AsyncValue.error(StateError('boom'), StackTrace.empty);

      expect(await n.update(() async => repo.okVoid(), 'new'), isFalse);

      expect(n.state.hasError, isTrue);
      expect(n.state.value, isNull);
    });
  });

  group('SingleNotifierAPI.delete', () {
    test('moves to loading on success', () async {
      final n = notifier();
      n.state = const AsyncValue.data('old');
      expect(await n.delete(() async => repo.okVoid()), isTrue);
      expect(n.state.isLoading, isTrue);
    });

    test('keeps the previous value when the call fails', () async {
      final n = notifier();
      n.state = const AsyncValue.data('old');
      expect(await n.delete(() async => repo.fail<void>(500)), isFalse);
      expect(n.state.value, 'old');
    });

    test('refuses to run while loading', () async {
      final n = notifier();
      expect(await n.delete(() async => repo.okVoid()), isFalse);
      expect(n.state.hasError, isTrue);
    });

    test('a plain error state returns false and stays an error', () async {
      final n = notifier();
      n.state = AsyncValue.error(StateError('boom'), StackTrace.empty);

      expect(await n.delete(() async => repo.okVoid()), isFalse);

      expect(n.state.hasError, isTrue);
      expect(n.state.value, isNull);
    });

    test('rethrows a token expiration from an error state', () async {
      final n = notifier();
      n.state = AsyncValue.error(
        AppException(ErrorType.tokenExpire, 'expired'),
        StackTrace.empty,
      );
      await expectLater(
        n.delete(() async => repo.okVoid()),
        throwsA(isA<AppException>()),
      );
    });
  });
}
