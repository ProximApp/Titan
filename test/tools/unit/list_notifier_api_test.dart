import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/providers/list_notifier_api.dart';

import '../../shared/mock_openapi.dart';

/// A keyed item: [rev] makes a `localUpdate`/`update` replacement observable
/// without identity tricks.
class _Item {
  final String id;
  final int rev;
  const _Item(this.id, [this.rev = 0]);
}

class _ListApi extends ListNotifierAPI<_Item> {}

final _apiProvider = NotifierProvider<_ListApi, AsyncValue<List<_Item>>>(
  _ListApi.new,
);

void main() {
  late MockOpenapi repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockOpenapi();
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  _ListApi notifier() => container.read(_apiProvider.notifier);

  group('ListNotifierAPI.build', () {
    test('starts in loading', () {
      expect(container.read(_apiProvider).isLoading, isTrue);
    });
  });

  group('ListNotifierAPI.loadList', () {
    test('stores the response body', () async {
      final result = await notifier().loadList(
        () async => repo.ok([const _Item('a'), const _Item('b')]),
      );
      expect(result.value, hasLength(2));
      expect(container.read(_apiProvider).value, hasLength(2));
    });

    test('answers an error state when the response fails', () async {
      final result = await notifier().loadList(
        () async => repo.fail<List<_Item>>(500),
      );
      expect(result.hasError, isTrue);
      expect(container.read(_apiProvider).hasError, isTrue);
    });
  });

  group('ListNotifierAPI.loadFromList', () {
    test('seeds an empty list for null', () async {
      final result = await notifier().loadFromList(null);
      expect(result.value, isEmpty);
      expect(container.read(_apiProvider).value, isEmpty);
    });

    test('stores the given list', () async {
      final result = await notifier().loadFromList([const _Item('a')]);
      expect(result.value!.single.id, 'a');
    });
  });

  group('ListNotifierAPI.handleState gates', () {
    test('refuses to run while loading and flags an error', () async {
      final n = notifier();
      expect(await n.localAdd(const _Item('x')), isFalse);
      expect(n.state.hasError, isTrue);
    });

    test('a plain error state returns false and stays an error', () async {
      final n = notifier();
      n.state = AsyncValue.error(StateError('boom'), StackTrace.empty);
      expect(await n.localAdd(const _Item('x')), isFalse);
      expect(n.state.hasError, isTrue);
    });

    test('rethrows a token expiration from an error state', () async {
      final n = notifier();
      n.state = AsyncValue.error(
        AppException(ErrorType.tokenExpire, 'expired'),
        StackTrace.empty,
      );
      await expectLater(
        n.localAdd(const _Item('x')),
        throwsA(isA<AppException>()),
      );
    });

    test('rethrows a token expiration raised by the call itself', () async {
      final n = notifier();
      n.state = const AsyncValue.data([]);
      await expectLater(
        n.add<_Item>(
          () async => throw AppException(ErrorType.tokenExpire, 'x'),
          const _Item('x'),
        ),
        throwsA(isA<AppException>()),
      );
      expect(n.state.value, isEmpty);
    });
  });

  group('ListNotifierAPI.add', () {
    test('appends the response body', () async {
      final n = notifier();
      n.state = const AsyncValue.data([]);
      expect(
        await n.add(() async => repo.ok(const _Item('b')), const _Item('b')),
        isTrue,
      );
      expect(n.state.value!.single.id, 'b');
    });

    test('keeps the previous list when the call fails', () async {
      final n = notifier();
      n.state = AsyncValue.data([const _Item('a')]);
      expect(
        await n.add(() async => repo.fail<_Item>(500), const _Item('b')),
        isFalse,
      );
      expect(n.state.value!.single.id, 'a');
    });

    test('localAdd appends without a network call', () async {
      final n = notifier();
      n.state = AsyncValue.data([const _Item('a')]);
      expect(await n.localAdd(const _Item('b')), isTrue);
      expect(n.state.value!.map((e) => e.id), ['a', 'b']);
    });
  });

  group('ListNotifierAPI.addAll', () {
    test('appends every returned body', () async {
      final n = notifier();
      n.state = AsyncValue.data([const _Item('a')]);
      expect(
        await n.addAll(
          (_) async => repo.ok([const _Item('b'), const _Item('c')]),
          <int>[1, 2],
        ),
        isTrue,
      );
      expect(n.state.value!.map((e) => e.id), ['a', 'b', 'c']);
    });

    test('keeps the previous list when the call fails', () async {
      final n = notifier();
      n.state = AsyncValue.data([const _Item('a')]);
      expect(
        await n.addAll((_) async => repo.fail<List<_Item>>(500), <int>[1]),
        isFalse,
      );
      expect(n.state.value!.map((e) => e.id), ['a']);
    });
  });

  group('ListNotifierAPI.update', () {
    test('replaces the keyed item in place', () async {
      final n = notifier();
      n.state = AsyncValue.data([const _Item('a'), const _Item('b')]);
      expect(
        await n.update(
          () async => repo.okVoid(),
          (e) => e.id,
          const _Item('b', 2),
        ),
        isTrue,
      );
      expect(n.state.value!.last.rev, 2);
      expect(n.state.value!.first.id, 'a');
    });

    test('keeps the previous list when the call fails', () async {
      final n = notifier();
      n.state = AsyncValue.data([const _Item('a'), const _Item('b')]);
      expect(
        await n.update(
          () async => repo.fail<void>(500),
          (e) => e.id,
          const _Item('b', 2),
        ),
        isFalse,
      );
      expect(n.state.value!.last.rev, 0);
    });

    test('localUpdate replaces without a network call', () async {
      final n = notifier();
      n.state = AsyncValue.data([const _Item('a'), const _Item('b')]);
      expect(await n.localUpdate((e) => e.id, const _Item('b', 3)), isTrue);
      expect(n.state.value!.last.rev, 3);
    });
  });

  group('ListNotifierAPI.delete', () {
    test('drops the keyed item on success', () async {
      final n = notifier();
      n.state = AsyncValue.data([const _Item('a'), const _Item('b')]);
      expect(
        await n.delete(() async => repo.okVoid(), (e) => e.id, 'a'),
        isTrue,
      );
      expect(n.state.value!.map((e) => e.id), ['b']);
    });

    test('keeps the previous list when the call fails', () async {
      final n = notifier();
      n.state = AsyncValue.data([const _Item('a'), const _Item('b')]);
      expect(
        await n.delete(() async => repo.fail<void>(500), (e) => e.id, 'a'),
        isFalse,
      );
      expect(n.state.value!.map((e) => e.id), ['a', 'b']);
    });

    test('localDelete drops the keyed item without a network call', () async {
      final n = notifier();
      n.state = AsyncValue.data([const _Item('a'), const _Item('b')]);
      expect(await n.localDelete((e) => e.id, 'a'), isTrue);
      expect(n.state.value!.map((e) => e.id), ['b']);
    });
  });
}
