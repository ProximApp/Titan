import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class MockData {}

class MockListNotifier extends ListNotifier<MockData> {
  @override
  AsyncValue<List<MockData>> build() {
    return const AsyncLoading();
  }

  Future<AsyncValue<List<MockData>>> testLoadList(
    Future<List<MockData>> Function() f,
  ) async {
    return loadList(f);
  }

  Future<bool> testAdd(
    Future<MockData> Function(MockData t) f,
    MockData t,
  ) async {
    return add(f, t);
  }

  Future<bool> testAddAll(
    Future<List<MockData>> Function(List<MockData> listT) f,
    List<MockData> listT,
  ) async {
    return addAll(f, listT);
  }

  Future<bool> testUpdate(
    Future<bool> Function(MockData t) f,
    List<MockData> Function(List<MockData> listT, MockData t) replace,
    MockData t,
  ) async {
    return update(f, replace, t);
  }

  Future<bool> testDelete(
    Future<bool> Function(String id) f,
    List<MockData> Function(List<MockData> listT, MockData t) replace,
    String id,
    MockData t,
  ) async {
    return delete(f, replace, id, t);
  }
}

final mockListNotifierProvider =
    NotifierProvider<MockListNotifier, AsyncValue<List<MockData>>>(
      MockListNotifier.new,
    );

MockListNotifier makeNotifier() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container.read(mockListNotifierProvider.notifier);
}

void main() {
  group('Testing ListNotifier : loadList', () {
    test('Should initiate to AsyncLoading', () {
      final notifier = makeNotifier();
      expect(notifier.state, isA<AsyncLoading>());
    });

    test('Should state be AsyncData when loading data', () async {
      final notifier = makeNotifier();
      final data = [MockData(), MockData()];
      await notifier.testLoadList(() => Future.value(data));
      expect(notifier.state, AsyncValue.data(data));
    });

    test(
      'Should rethrow AppException for loadList when function throw AppException.tokenExpire',
      () async {
        final notifier = makeNotifier();
        final error = AppException(ErrorType.tokenExpire, 'test');
        try {
          await notifier.testLoadList(() => Future.error(error));
          expect(notifier.state, isA<AsyncData>()); // not reached
        } catch (e) {
          expect(e, error);
          expect(notifier.state, isA<AsyncError>());
        }
      },
    );

    test(
      'Should return AppException.notFound for loadList when function throw AppException.notFound',
      () async {
        final notifier = makeNotifier();
        final error = AppException(ErrorType.notFound, 'test');
        final result = await notifier.testLoadList(() => Future.error(error));
        expect(notifier.state, isA<AsyncError<List<MockData>>>());
        expect(result, isA<AsyncError<List<MockData>>>());
      },
    );

    test(
      'Should return Exception for loadList when function throw other Exception',
      () async {
        final notifier = makeNotifier();
        final error = Exception('test');
        final result = await notifier.testLoadList(() => throw error);
        expect(notifier.state, isA<AsyncError<List<MockData>>>());
        expect(result, isA<AsyncError<List<MockData>>>());
      },
    );
  });

  group('Testing ListNotifier : add', () {
    test('Should returns true and updates state on success', () async {
      final notifier = makeNotifier();
      final data = [MockData(), MockData()];
      notifier.state = AsyncValue.data(data);
      final newData = MockData();
      final newDataList = [...data, newData];
      final result = await notifier.testAdd(
        (t) => Future.value(newData),
        newData,
      );
      expect(result, isTrue);
      expect(notifier.state, isA<AsyncData<List<MockData>>>());
      expect(
        notifier.state.when(
          data: (d) => d,
          error: (e, s) => [],
          loading: () => [],
        ),
        newDataList,
      );
    });

    test(
      'Should throw AppException.tokenExpire and restores state on previous data when add fails with AppException.tokenExpire',
      () async {
        final notifier = makeNotifier();
        final data = [MockData(), MockData()];
        notifier.state = AsyncValue.data(data);
        final newData = MockData();
        final error = AppException(ErrorType.tokenExpire, 'test');
        try {
          await notifier.testAdd((t) => throw error, newData);
          expect(
            notifier.state,
            isA<AsyncData<List<MockData>>>(),
          ); // not reached
        } catch (e) {
          expect(e, error);
          expect(notifier.state, isA<AsyncData<List<MockData>>>());
          expect(
            notifier.state.when(
              data: (d) => d,
              error: (e, s) => [],
              loading: () => [],
            ),
            data,
          );
        }
      },
    );

    test(
      'Should return false and restores state on previous data when add fails with AppException.notFound',
      () async {
        final notifier = makeNotifier();
        final data = [MockData(), MockData()];
        notifier.state = AsyncValue.data(data);
        final newData = MockData();
        final error = AppException(ErrorType.notFound, 'test');
        final result = await notifier.testAdd((t) => throw error, newData);
        expect(result, isFalse);
        expect(notifier.state, isA<AsyncData<List<MockData>>>());
        expect(
          notifier.state.when(
            data: (d) => d,
            error: (e, s) => [],
            loading: () => [],
          ),
          data,
        );
      },
    );

    test(
      'Should return false sets state on error when start state is AsyncLoading',
      () async {
        final notifier = makeNotifier();
        final newData = MockData();
        final result = await notifier.testAdd((t) => Future.value(t), newData);
        expect(result, isFalse);
        expect(notifier.state, isA<AsyncError>());
        expect(notifier.state.error, "Cannot add while loading");
      },
    );

    test(
      'Should return false sets state on error when start state is AsyncError',
      () async {
        final notifier = makeNotifier();
        notifier.state = AsyncValue.error("test", StackTrace.current);
        final newData = MockData();
        final error = AppException(ErrorType.notFound, 'test');
        final result = await notifier.testAdd((t) => throw error, newData);
        expect(result, isFalse);
        expect(notifier.state, isA<AsyncError>());
        expect(notifier.state.error, "test");
      },
    );
  });

  group('Testing ListNotifier : update', () {
    test('Should returns true and updates state on success', () async {
      final notifier = makeNotifier();
      final data = [MockData(), MockData()];
      notifier.state = AsyncValue.data(data);
      final newData = MockData();
      final newDataList = [newData, ...data.skip(1)];
      final result = await notifier.testUpdate(
        (t) => Future.value(true),
        (listT, t) => [t, ...listT.skip(1)],
        newData,
      );
      expect(result, isTrue);
      expect(notifier.state, isA<AsyncData<List<MockData>>>());
      expect(
        notifier.state.when(
          data: (d) => d,
          error: (e, s) => [],
          loading: () => [],
        ),
        newDataList,
      );
    });

    test(
      'Should return false and restores state on previous data when update function return false',
      () async {
        final notifier = makeNotifier();
        final data = [MockData(), MockData()];
        notifier.state = AsyncValue.data(data);
        final newData = MockData();
        final result = await notifier.testUpdate(
          (t) => Future.value(false),
          (listT, t) => [t, ...listT.skip(1)],
          newData,
        );
        expect(result, isFalse);
        expect(notifier.state, isA<AsyncData<List<MockData>>>());
        expect(
          notifier.state.when(
            data: (d) => d,
            error: (e, s) => [],
            loading: () => [],
          ),
          data,
        );
      },
    );

    test(
      'Should throw AppException.tokenExpire and restores state on previous data when add fails with AppException.tokenExpire',
      () async {
        final notifier = makeNotifier();
        final data = [MockData(), MockData()];
        notifier.state = AsyncValue.data(data);
        final newData = MockData();
        final newDataList = [newData, ...data.skip(1)];
        final error = AppException(ErrorType.tokenExpire, 'test');
        try {
          await notifier.testUpdate(
            (t) => throw error,
            (listT, t) => [t, ...listT.skip(1)],
            newData,
          );
          expect(
            notifier.state,
            isA<AsyncData<List<MockData>>>(),
          ); // not reached
        } catch (e) {
          expect(e, error);
          expect(notifier.state, isA<AsyncData<List<MockData>>>());
          expect(
            notifier.state.when(
              data: (d) => d,
              error: (e, s) => [],
              loading: () => [],
            ),
            data,
          );
          expect(
            notifier.state.when(
                  data: (d) => d,
                  error: (e, s) => [],
                  loading: () => [],
                ) ==
                newDataList,
            isFalse,
          );
        }
      },
    );

    test(
      'Should return false and restores state on previous data when add fails with AppException.notFound',
      () async {
        final notifier = makeNotifier();
        final data = [MockData(), MockData()];
        notifier.state = AsyncValue.data(data);
        final newData = MockData();
        final newDataList = [newData, ...data.skip(1)];
        final error = AppException(ErrorType.notFound, 'test');
        final result = await notifier.testUpdate(
          (t) => throw error,
          (listT, t) => [t, ...listT.skip(1)],
          newData,
        );
        expect(result, isFalse);
        expect(notifier.state, isA<AsyncData<List<MockData>>>());
        expect(
          notifier.state.when(
            data: (d) => d,
            error: (e, s) => [],
            loading: () => [],
          ),
          data,
        );
        expect(
          notifier.state.when(
                data: (d) => d,
                error: (e, s) => [],
                loading: () => [],
              ) ==
              newDataList,
          isFalse,
        );
      },
    );

    test(
      'Should return false sets state on error when start state is AsyncLoading',
      () async {
        final notifier = makeNotifier();
        final newData = MockData();
        final result = await notifier.testUpdate(
          (t) => Future.value(true),
          (listT, t) => [t, ...listT.skip(1)],
          newData,
        );
        expect(result, isFalse);
        expect(notifier.state, isA<AsyncError>());
        expect(notifier.state.error, "Cannot update while loading");
      },
    );

    test(
      'Should return false sets state on error when start state is AsyncError',
      () async {
        final notifier = makeNotifier();
        notifier.state = AsyncValue.error("test", StackTrace.current);
        final newData = MockData();
        final result = await notifier.testUpdate(
          (t) => Future.value(true),
          (listT, t) => [t, ...listT.skip(1)],
          newData,
        );
        expect(result, isFalse);
        expect(notifier.state, isA<AsyncError>());
        expect(notifier.state.error, "test");
      },
    );
  });

  group('Testing ListNotifier : delete', () {
    test('Should returns true and updates state on success', () async {
      final notifier = makeNotifier();
      final data = [MockData(), MockData()];
      notifier.state = AsyncValue.data(data);
      final oldData = data.first;
      final newDataList = data.skip(1).toList();
      final result = await notifier.testDelete(
        (id) => Future.value(true),
        (listT, t) => listT.skip(1).toList(),
        'id',
        oldData,
      );
      expect(result, isTrue);
      expect(notifier.state, isA<AsyncData<List<MockData>>>());
      expect(
        notifier.state.when(
          data: (d) => d,
          error: (e, s) => [],
          loading: () => [],
        ),
        newDataList,
      );
    });

    test(
      'Should return false and restores state on previous data when update function return false',
      () async {
        final notifier = makeNotifier();
        final data = [MockData(), MockData()];
        notifier.state = AsyncValue.data(data);
        final oldData = data.first;
        final result = await notifier.testDelete(
          (id) => Future.value(false),
          (listT, t) => listT.skip(1).toList(),
          'id',
          oldData,
        );
        expect(result, isFalse);
        expect(notifier.state, isA<AsyncData<List<MockData>>>());
        expect(
          notifier.state.when(
            data: (d) => d,
            error: (e, s) => [],
            loading: () => [],
          ),
          data,
        );
      },
    );

    test(
      'Should throw AppException.tokenExpire and restores state on previous data when add fails with AppException.tokenExpire',
      () async {
        final notifier = makeNotifier();
        final data = [MockData(), MockData()];
        notifier.state = AsyncValue.data(data);
        final oldData = data.first;
        final newDataList = data.skip(1).toList();
        final error = AppException(ErrorType.tokenExpire, 'test');
        try {
          await notifier.testDelete(
            (t) => throw error,
            (listT, t) => listT.skip(1).toList(),
            'id',
            oldData,
          );
          expect(
            notifier.state,
            isA<AsyncData<List<MockData>>>(),
          ); // not reached
        } catch (e) {
          expect(e, error);
          expect(notifier.state, isA<AsyncData<List<MockData>>>());
          expect(
            notifier.state.when(
              data: (d) => d,
              error: (e, s) => [],
              loading: () => [],
            ),
            data,
          );
          expect(
            notifier.state.when(
                  data: (d) => d,
                  error: (e, s) => [],
                  loading: () => [],
                ) ==
                newDataList,
            isFalse,
          );
        }
      },
    );

    test(
      'Should return false and restores state on previous data when add fails with AppException.notFound',
      () async {
        final notifier = makeNotifier();
        final data = [MockData(), MockData()];
        notifier.state = AsyncValue.data(data);
        final oldData = data.first;
        final newDataList = data.skip(1).toList();
        final error = AppException(ErrorType.notFound, 'test');
        final result = await notifier.testDelete(
          (t) => throw error,
          (listT, t) => listT.skip(1).toList(),
          'id',
          oldData,
        );
        expect(result, isFalse);
        expect(notifier.state, isA<AsyncData<List<MockData>>>());
        expect(
          notifier.state.when(
            data: (d) => d,
            error: (e, s) => [],
            loading: () => [],
          ),
          data,
        );
        expect(
          notifier.state.when(
                data: (d) => d,
                error: (e, s) => [],
                loading: () => [],
              ) ==
              newDataList,
          isFalse,
        );
      },
    );

    test(
      'Should return false sets state on error when start state is AsyncLoading',
      () async {
        final notifier = makeNotifier();
        final data = [MockData(), MockData()];
        final oldData = data.first;
        final result = await notifier.testDelete(
          (id) => Future.value(true),
          (listT, t) => listT.skip(1).toList(),
          'id',
          oldData,
        );
        expect(result, isFalse);
        expect(notifier.state, isA<AsyncError>());
        expect(notifier.state.error, "Cannot delete while loading");
      },
    );

    test(
      'Should return false sets state on error when start state is AsyncError',
      () async {
        final notifier = makeNotifier();
        notifier.state = AsyncValue.error("test", StackTrace.current);
        final data = [MockData(), MockData()];
        final oldData = data.first;
        final result = await notifier.testDelete(
          (id) => Future.value(true),
          (listT, t) => listT.skip(1).toList(),
          'id',
          oldData,
        );
        expect(result, isFalse);
        expect(notifier.state, isA<AsyncError>());
        expect(notifier.state.error, "test");
      },
    );

    test(
      'Should return false sets state on error when start state is AsyncError with AppException.tokenExpire',
      () async {
        final notifier = makeNotifier();
        notifier.state = AsyncValue.error(
          AppException(ErrorType.tokenExpire, "test"),
          StackTrace.current,
        );
        final data = [MockData(), MockData()];
        final oldData = data.first;
        try {
          await notifier.testDelete(
            (id) => Future.value(true),
            (listT, t) => listT.skip(1).toList(),
            'id',
            oldData,
          );
          expect(notifier.state, isA<AsyncError>()); // not reached
        } catch (e) {
          expect(notifier.state, isA<AsyncError>());
          expect(notifier.state.error, isA<AppException>());
        }
      },
    );
  });

  // The whole file above asserts CONTENTS, and in-place mutation changes
  // contents too, so it could not tell the two apart. `add` and `addAll` used
  // to do `d.add(newT); state = AsyncValue.data(d);` where `d` IS the list
  // object already inside `state` — a mutation of provider state, invisible to
  // anyone holding the previous reference and a hard throw if that list ever
  // came from an unmodifiable source.
  group('ListNotifier does not mutate the list inside its own state', () {
    test('add leaves the previous list object untouched', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(mockListNotifierProvider.notifier);
      final existing = MockData();
      notifier.state = AsyncValue.data([existing]);
      final snapshot = notifier.state.value!;

      await notifier.testAdd((_) async => MockData(), MockData());

      // The list the old code would have appended into still has one element.
      expect(snapshot, hasLength(1));
      expect(identical(snapshot, notifier.state.value), isFalse);
      expect(notifier.state.value, hasLength(2));
    });

    test('add leaves the previous list object untouched on failure', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(mockListNotifierProvider.notifier);
      notifier.state = AsyncValue.data([MockData()]);
      final snapshot = notifier.state.value!;

      final ok = await notifier.testAdd(
        (_) async => throw StateError('nope'),
        MockData(),
      );

      expect(ok, isFalse);
      // The `catch` branch re-wraps `d`, so with the old code this snapshot
      // would already carry the half-finished append.
      expect(snapshot, hasLength(1));
      expect(notifier.state.value, hasLength(1));
    });

    test('addAll leaves the previous list object untouched', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(mockListNotifierProvider.notifier);
      notifier.state = AsyncValue.data([MockData()]);
      final snapshot = notifier.state.value!;

      await notifier.testAddAll((_) async => [MockData(), MockData()], []);

      expect(snapshot, hasLength(1));
      expect(identical(snapshot, notifier.state.value), isFalse);
      expect(notifier.state.value, hasLength(3));
    });

    test('add notifies its listeners', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(mockListNotifierProvider.notifier);
      notifier.state = AsyncValue.data([MockData()]);

      var notifications = 0;
      container.listen(
        mockListNotifierProvider,
        (previous, next) => notifications++,
      );

      await notifier.testAdd((_) async => MockData(), MockData());

      expect(notifications, 1);
    });

    test('a listener is handed the untouched previous list', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(mockListNotifierProvider.notifier);
      notifier.state = AsyncValue.data([MockData()]);

      final seen = <int>[];
      container.listen(mockListNotifierProvider, (previous, next) {
        seen.add(previous?.value?.length ?? -1);
      });

      await notifier.testAdd((_) async => MockData(), MockData());

      expect(seen, [1]);
    });
  });
}
